//
//  Container+Testing.swift
//  StarterApp
//
//  Testing infrastructure using Factory DI
//

import Foundation
import FactoryKit

// MARK: - Testing Configuration

extension Container {
    
    /// Configure the container for testing with mock dependencies
    static func configureForTesting() {
        // Reset to ensure clean state
        Container.shared.reset()
        
        // Override core services with existing mocks from the project
        Container.shared.networkService.register { MockNetworkService() }
        
        // For testing, we can use simplified mock implementations
        // These would typically be more sophisticated in a real test suite
        
        // Keep real configuration and environment for tests
        // (These are lightweight and don't require mocking)
    }
    
    /// Configure specific services for targeted testing
    static func configureWithMocks(
        networkService: NetworkService? = nil,
        weatherRepository: (any WeatherRepository)? = nil,
        loggerFactory: LoggerFactoryImpl? = nil
    ) {
        if let networkService = networkService {
            Container.shared.networkService.register { networkService }
        }
        
        if let weatherRepository = weatherRepository {
            Container.shared.weatherRepository.register { weatherRepository }
        }
        
        if let loggerFactory = loggerFactory {
            Container.shared.loggerFactory.register { loggerFactory }
        }
    }
    
    /// Reset container to production state (useful for cleanup)
    static func resetToProduction() {
        Container.shared.reset()
    }
}

// MARK: - Factory Testing Examples

// Example of how to use Factory for testing:
//
// 1. Use existing project mocks (MockNetworkService, etc.)
// 2. Create targeted test doubles for specific scenarios
// 3. Use constructor injection for unit testing individual components
//
// Example test setup:
//
// override func setUp() {
//     super.setUp()
//     Container.configureForTesting()
//     
//     // Override specific services as needed
//     Container.shared.weatherRepository.register { 
//         TestWeatherRepository(mockData: yourTestData) 
//     }
// }
//
// Example constructor testing (bypassing Factory):
//
// func testWeatherStoreDirectly() {
//     let mockRepo = MockWeatherRepository()
//     let mockLogger = MockAppLogger()
//     let store = WeatherStore(weatherRepository: mockRepo, logger: mockLogger)
//     // Test store behavior
// }