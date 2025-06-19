//
//  AppContainer.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import Foundation
import FactoryKit
import codeartis_logging

// MARK: - Protocol

/// Protocol for application dependency injection container
/// Provides access to all core services and configuration
protocol AppContainer {
    
    // MARK: - Configuration
    
    var configuration: AppConfiguration { get }
    var environment: AppEnvironment { get set }
    var useLocalData: Bool { get set }
    
    // MARK: - Core Services
    
    var networkService: NetworkService { get }
    var analyticsService: AnalyticsService { get }
    var loggerFactory: LoggerFactory { get }
    var swiftDataContainer: SwiftDataContainer { get }
    var secureStorageService: SecureStorageService { get }
    
    // MARK: - Store Factories
    
    func makeWeatherStore() -> WeatherStore
    
    // MARK: - Configuration Methods
    
    func configureAPIKey(_ apiKey: String, for service: String) async
    func getAPIKey(for service: String) async -> String?
    func configureForEnvironment(_ env: AppEnvironment)
    func switchDataSource()
}

// MARK: - Implementation

@Observable
class AppContainerImpl: AppContainer {
    // MARK: - Configuration
    let configuration: AppConfiguration
    var environment: AppEnvironment
    var useLocalData = false
    
    // MARK: - Core Services (Delegated to Factory)
    var networkService: NetworkService {
        Container.shared.networkService()
    }
    
    var analyticsService: AnalyticsService {
        Container.shared.analyticsService()
    }
    
    var loggerFactory: LoggerFactory {
        Container.shared.loggerFactory()
    }
    
    var swiftDataContainer: SwiftDataContainer {
        Container.shared.swiftDataContainer()
    }
    
    var secureStorageService: SecureStorageService {
        Container.shared.secureStorageService()
    }
    
    // MARK: - Initialization
    init() {
        // Get configuration and environment from Factory
        self.configuration = Container.shared.appConfiguration()
        self.environment = Container.shared.appEnvironment()
        
        // Log container initialization
        let logger = Container.shared.appLogger()
        logger.info("AppContainer initialized with Factory for environment: \(environment)")
    }
    
    // MARK: - Store Factories (Simplified with Factory)
    func makeWeatherStore() -> WeatherStore {
        return Container.shared.weatherStore()
    }
    
    // MARK: - Configuration Methods
    
    /// Configure API key securely
    func configureAPIKey(_ apiKey: String, for service: String) async {
        do {
            try await secureStorageService.storeAPIKey(apiKey, for: service)
            let logger = loggerFactory.createLogger(category: "app")
            logger.info("API key configured for service: \(service)")
        } catch {
            let logger = loggerFactory.createLogger(category: "app")
            logger.error("Failed to store API key: \(error)")
        }
    }
    
    /// Get stored API key
    func getAPIKey(for service: String) async -> String? {
        do {
            return try await secureStorageService.retrieveAPIKey(for: service)
        } catch {
            let logger = loggerFactory.createLogger(category: "app")
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
        let logger = loggerFactory.createLogger(category: "app")
        logger.info("Switched to \(useLocalData ? "local" : "remote") data source")
    }
    
    // MARK: - Environment Detection (Moved to Factory)
    // Environment detection is now handled in Container+Core.swift
}

// MARK: - App Environment

enum AppEnvironment {
    case development, staging, production
}
