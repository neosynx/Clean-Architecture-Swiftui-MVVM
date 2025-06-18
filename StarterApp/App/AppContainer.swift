//
//  AppContainer.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import Foundation

@Observable
class AppContainer {
    // MARK: - Configuration
    let configuration: AppConfiguration
    var environment: AppEnvironment = .production
    var useLocalData = false
    
    // MARK: - Core Services (Shared across features)
    private(set) var networkService: NetworkService
    private(set) var analyticsService: AnalyticsService
    private(set) var loggerFactory: LoggerFactoryImpl
    private(set) var swiftDataContainer: SwiftDataContainer
    private(set) var secureStorageService: SecureStorageService
    
    // MARK: - Initialization
    init() {
        let env = Self.detectEnvironment()
        
        self.configuration = AppConfiguration()
        self.environment = env
        
        // Initialize logger factory based on environment
        let loggingEnvironment: LoggingEnvironment = {
            switch env {
            case .development: return .debug
            case .staging: return .staging
            case .production: return .production
            }
        }()
        
        let loggingConfig = LoggingConfiguration.configuration(for: loggingEnvironment)
        let loggerFactory = LoggerFactoryImpl(
            subsystem: Bundle.main.bundleIdentifier ?? "com.starterapp",
            configuration: loggingConfig
        )
        self.loggerFactory = loggerFactory
        
        // Configure network service based on environment
        let networkConfig: NetworkConfiguration = {
            switch env {
            case .development:
                return .default
            case .staging:
                return .default
            case .production:
                return NetworkConfiguration(
                    timeout: 60.0,
                    retryAttempts: 5,
                    retryDelay: 2.0,
                    maxConcurrentRequests: 15,
                    enableCaching: true,
                    cachePolicy: .returnCacheDataElseLoad,
                    maxResponseSize: 100 * 1024 * 1024, // 100MB for production
                    waitsForConnectivity: true
                )
            }
        }()
        
        self.networkService = NetworkServiceImpl(
            configuration: configuration,
            loggerFactory: loggerFactory,
            networkConfig: networkConfig
        )
        self.analyticsService = AnalyticsServiceImpl(environment: env, loggerFactory: loggerFactory)
        
        // Initialize SwiftData container
        let appLogger = loggerFactory.createAppLogger()
        do {
            let containerConfig: SwiftDataContainer.Configuration = env == .development ? .inMemory : .default
            self.swiftDataContainer = try SwiftDataContainer(
                configuration: containerConfig,
                logger: appLogger
            )
        } catch {
            appLogger.error("Failed to initialize SwiftData container: \(error)")
            // Fallback to in-memory for safety
            self.swiftDataContainer = try! SwiftDataContainer(
                configuration: .inMemory,
                logger: appLogger
            )
        }
        
        // Initialize secure storage
        self.secureStorageService = SecureStorageService(logger: appLogger)
        
        // Log container initialization
        appLogger.info("AppContainer initialized for environment: \(env)")
    }
    
    // MARK: - Store Factories (Feature-specific)
    func makeWeatherStore() -> WeatherStore {
        let weatherRepository = makeWeatherRepository()
        let logger = loggerFactory.createWeatherLogger()
        return WeatherStore(weatherRepository: weatherRepository, logger: logger)
    }
    
    // MARK: - Repository Factories
    private func makeWeatherRepository() -> WeatherRepository {
        // Create services based on availability and environment
        let remoteService = createWeatherRemoteService()
        
        // Choose strategy based on environment and preferences
        let strategyType: WeatherDataAccessStrategyType = environment == .development ? .persistenceFirst : .cacheFirst
        
        let logger = loggerFactory.createWeatherLogger()
        return WeatherRepositoryImpl(
            swiftDataContainer: swiftDataContainer,
            remoteService: remoteService,
            strategyType: strategyType,
            logger: logger,
            secureStorage: secureStorageService
        )
    }
    
    private func createWeatherRemoteService() -> WeatherRemoteService? {
        // Only create remote service if not in local-only mode
        guard !useLocalData else { return nil }
        
        let logger = loggerFactory.createWeatherLogger()
        return WeatherRemoteService(
            networkService: networkService,
            configuration: configuration,
            logger: logger
        )
    }
    
    // MARK: - Configuration Methods
    
    /// Configure API key securely
    func configureAPIKey(_ apiKey: String, for service: String) async {
        do {
            try await secureStorageService.storeAPIKey(apiKey, for: service)
            let logger = loggerFactory.createAppLogger()
            logger.info("API key configured for service: \(service)")
        } catch {
            let logger = loggerFactory.createAppLogger()
            logger.error("Failed to store API key: \(error)")
        }
    }
    
    /// Get stored API key
    func getAPIKey(for service: String) async -> String? {
        do {
            return try await secureStorageService.retrieveAPIKey(for: service)
        } catch {
            let logger = loggerFactory.createAppLogger()
            logger.error("Failed to retrieve API key: \(error)")
            return nil
        }
    }
    
    // MARK: - Environment Management
    func configureForEnvironment(_ env: AppEnvironment) {
        environment = env
    }
    
    // MARK: - Configuration
    func switchDataSource() {
        useLocalData.toggle()
        let logger = loggerFactory.createAppLogger()
        logger.info("Switched to \(useLocalData ? "local" : "remote") data source")
    }
    
    // MARK: - Environment Detection
    private static func detectEnvironment() -> AppEnvironment {
        // Check for environment variable override first
        if let envOverride = ProcessInfo.processInfo.environment["STARTERAPP_ENVIRONMENT"] {
            switch envOverride.lowercased() {
            case "development", "dev", "debug":
                return .development
            case "staging", "stage":
                return .staging
            case "production", "prod":
                return .production
            default:
                break
            }
        }
        
        // Fallback to build configuration detection
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

// MARK: - App Environment

enum AppEnvironment {
    case development, staging, production
}
