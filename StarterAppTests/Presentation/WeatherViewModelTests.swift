//
//  WeatherViewModelTests.swift
//  ExampleMVVMTests
//
//  Created by MacBook Air M1 on 20/6/24.
//

import XCTest
@testable import StarterApp

class MockWeatherRepository: WeatherRepository {
    func fetchWeather(for city: String) async throws -> ForecastModel {
        return ForecastModel(city: CityModel(name: city, country: "Test"), weatherBundle: [])
    }
    
    func saveWeather(_ forecast: ForecastModel) async throws {}
    func deleteWeather(for city: String) async throws {}
    func getAllSavedCities() async throws -> [String] { return [] }
    func getCachedWeather(for city: String) async throws -> ForecastModel? { return nil }
    func clearCache() async throws {}
    func refreshWeather(for city: String) async throws -> ForecastModel {
        return try await fetchWeather(for: city)
    }
    func getWeatherWithFallback(for city: String) async throws -> ForecastModel {
        return try await fetchWeather(for: city)
    }
}

class WeatherViewModelTests: XCTestCase {
    
    func testWeatherStoreInitialization() {
        // Create a mock repository for testing
        let mockRepository = MockWeatherRepository()
        let weatherStore = WeatherStore(weatherRepository: mockRepository)
        
        XCTAssertNotNil(weatherStore)
    }
    
    func testAppContainerCreatesWeatherStore() {
        let appContainer = AppContainer()
        let weatherStore = appContainer.makeWeatherStore()
        
        XCTAssertNotNil(weatherStore)
    }
}

