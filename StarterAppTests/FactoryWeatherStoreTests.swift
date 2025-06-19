//
//  FactoryWeatherStoreTests.swift
//  StarterAppTests
//
//  Example tests using Factory DI infrastructure
//

import XCTest
import FactoryKit
@testable import StarterApp

final class FactoryWeatherStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Configure Factory for testing with mocks
        Container.configureForTesting()
    }
    
    override func tearDown() {
        // Reset to production state for clean slate
        Container.resetToProduction()
        super.tearDown()
    }
    
    func testWeatherStoreInitialization() {
        // Given: Factory-created store with mocked dependencies
        let store = Container.shared.weatherStore()
        
        // Then: Store should be properly initialized
        XCTAssertNotNil(store)
        XCTAssertNil(store.forecast)
        XCTAssertFalse(store.isLoading)
    }
    
    func testFactoryStoreCreation() {
        // Given: Factory-configured environment
        let store = Container.shared.weatherStore()
        
        // Then: Store should be properly created
        XCTAssertNotNil(store)
        XCTAssertNil(store.forecast)
        XCTAssertFalse(store.isLoading)
    }
    
    func testConstructorInjectionApproach() {
        // This demonstrates the preferred testing approach: constructor injection
        // This bypasses Factory entirely for clean unit testing
        
        // Given: Create mock dependencies directly
        let mockRepository = MockWeatherRepository()
        let mockLogger = MockAppLogger(category: "test") 
        
        // When: Create store with constructor injection
        let store = WeatherStore(weatherRepository: mockRepository, logger: mockLogger)
        
        // Then: Store should be properly initialized
        XCTAssertNotNil(store)
        XCTAssertNil(store.forecast)
        XCTAssertFalse(store.isLoading)
        
        // This approach is preferred for unit testing as it's:
        // - Faster (no Factory overhead)
        // - Clearer (explicit dependencies)
        // - More focused (test only what you need)
    }
    
    func testSharedStoreInstance() {
        // Given: Factory-created stores
        let store1 = Container.shared.weatherStore()
        let store2 = Container.shared.weatherStore()
        
        // Then: Should be the same instance (cached)
        XCTAssertTrue(store1 === store2)
    }
}