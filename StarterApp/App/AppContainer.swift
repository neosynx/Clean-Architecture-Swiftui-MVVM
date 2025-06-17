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
        
        self.networkService = NetworkServiceImpl(configuration: configuration, loggerFactory: loggerFactory)
        self.analyticsService = AnalyticsServiceImpl(environment: env, loggerFactory: loggerFactory)
        
        // Log container initialization
        let logger = loggerFactory.createAppLogger()
        logger.info("AppContainer initialized for environment: \(env)")
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
        let fileService = createWeatherFileService()
        let cacheService = createWeatherCacheService()
        
        // Choose strategy based on environment and preferences
        let strategy: WeatherRepositoryImpl.DataStrategy = .cacheFirst
        
        let logger = loggerFactory.createWeatherLogger()
        return WeatherRepositoryImpl(
            remoteService: remoteService,
            fileService: fileService,
            cacheService: cacheService,
            strategy: strategy,
            enableFallback: true,
            logger: logger
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
    
    private func createWeatherFileService() -> WeatherFileService? {
        // Always create file service for local storage
        let logger = loggerFactory.createWeatherLogger()
        return WeatherFileService(logger: logger)
    }
    
    private func createWeatherCacheService() -> CacheServiceImpl<String, ForecastFileDTO> {
        // Cache configuration based on environment
        let expirationInterval: TimeInterval = environment == .development ? 300 : 600 // 5 min dev, 10 min prod
        let maxEntries = environment == .development ? 20 : 50
        
        return CacheServiceImpl<String, ForecastFileDTO>(
            expirationInterval: expirationInterval,
            maxEntries: maxEntries
        )
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
