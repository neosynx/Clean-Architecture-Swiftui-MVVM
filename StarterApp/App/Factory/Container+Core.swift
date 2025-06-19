//
//  Container+Core.swift
//  StarterApp
//
//  Core infrastructure services using Factory DI
//

import Foundation
import FactoryKit

// MARK: - Core Infrastructure Services

extension Container {
    
    // MARK: - Configuration
    
    var appConfiguration: Factory<AppConfiguration> {
        self { AppConfiguration() }
            .singleton
    }
    
    var appEnvironment: Factory<AppEnvironment> {
        self { Self.detectEnvironment() }
            .singleton
    }
    
    // MARK: - Logging
    
    var loggerFactory: Factory<LoggerFactoryImpl> {
        self {
            let environment = self.appEnvironment()
            let loggingEnvironment: LoggingEnvironment = {
                switch environment {
                case .development: return .debug
                case .staging: return .staging
                case .production: return .production
                }
            }()
            
            let loggingConfig = LoggingConfiguration.configuration(for: loggingEnvironment)
            return LoggerFactoryImpl(
                subsystem: Bundle.main.bundleIdentifier ?? "com.starterapp",
                configuration: loggingConfig
            )
        }
        .singleton
    }
    
    var appLogger: Factory<AppLogger> {
        self { self.loggerFactory().createAppLogger() }
            .cached
    }
    
    var weatherLogger: Factory<AppLogger> {
        self { self.loggerFactory().createWeatherLogger() }
            .cached
    }
    
    // MARK: - Network Configuration
    
    var networkConfiguration: Factory<NetworkConfiguration> {
        self {
            let environment = self.appEnvironment()
            switch environment {
            case .development, .staging:
                return .default
            case .production:
                return NetworkConfiguration(
                    timeout: 60.0,
                    retryAttempts: 5,
                    retryDelay: 2.0,
                    maxConcurrentRequests: 15,
                    enableCaching: true,
                    cachePolicy: .returnCacheDataElseLoad,
                    maxResponseSize: 100 * 1024 * 1024, // 100MB
                    waitsForConnectivity: true
                )
            }
        }
        .cached
    }
    
    // MARK: - Core Services
    
    var networkService: Factory<NetworkService> {
        self {
            NetworkServiceImpl(
                configuration: self.appConfiguration(),
                loggerFactory: self.loggerFactory(),
                networkConfig: self.networkConfiguration()
            )
        }
        .singleton
    }
    
    var analyticsService: Factory<AnalyticsService> {
        self {
            AnalyticsServiceImpl(
                environment: self.appEnvironment(),
                loggerFactory: self.loggerFactory()
            )
        }
        .singleton
    }
    
    var swiftDataContainer: Factory<SwiftDataContainer> {
        self {
            let environment = self.appEnvironment()
            let appLogger = self.appLogger()
            
            do {
                let containerConfig: SwiftDataContainerImpl.Configuration = 
                    environment == .development ? .inMemory : .default
                return try MainActor.assumeIsolated {
                    try SwiftDataContainerImpl(
                        configuration: containerConfig,
                        logger: appLogger
                    )
                }
            } catch {
                appLogger.error("Failed to initialize SwiftData container: \(error)")
                // Fallback to in-memory
                do {
                    return try MainActor.assumeIsolated {
                        try SwiftDataContainerImpl(
                            configuration: .inMemory,
                            logger: appLogger
                        )
                    }
                } catch let fallbackError {
                    appLogger.error("Failed to initialize fallback in-memory container: \(fallbackError)")
                    fatalError("Unable to initialize any SwiftData container")
                }
            }
        }
        .singleton
    }
    
    var secureStorageService: Factory<SecureStorageService> {
        self {
            SecureStorageServiceImpl(logger: self.appLogger())
        }
        .singleton
    }
}

// MARK: - Environment Detection

private extension Container {
    static func detectEnvironment() -> AppEnvironment {
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
