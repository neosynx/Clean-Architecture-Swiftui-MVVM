//
//  WeatherRepository.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Weather Repository Protocol

/// Weather-specific repository protocol that inherits from BaseRepository
/// Provides weather domain methods while maintaining generic repository pattern
protocol WeatherRepository: BaseRepository where Key == String, Model == ForecastModel, IdentifierType == String {
    
    // MARK: - Weather-Specific Methods
    
    /// Fetch weather data for a specific city
    func fetchWeather(for city: String) async throws -> ForecastModel
    
    /// Save weather forecast data
    func saveWeather(_ forecast: ForecastModel) async throws
    
    /// Delete weather data for a specific city
    func deleteWeather(for city: String) async throws
    
    /// Get all saved city names
    func getAllSavedCities() async throws -> [String]
    
    /// Get cached weather data for a city
    func getCachedWeather(for city: String) async throws -> ForecastModel?
    
    /// Refresh weather data from remote source
    func refreshWeather(for city: String) async throws -> ForecastModel
    
    /// Get weather data with intelligent fallback
    func getWeatherWithFallback(for city: String) async throws -> ForecastModel
}

// MARK: - Default Implementation

/// Provide default implementations that delegate to base repository methods
extension WeatherRepository {
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        return try await fetch(for: city)
    }
    
    func deleteWeather(for city: String) async throws {
        try await delete(for: city)
    }
    
    func getAllSavedCities() async throws -> [String] {
        return try await getAllSavedIdentifiers()
    }
    
    func getCachedWeather(for city: String) async throws -> ForecastModel? {
        return try await getCached(for: city)
    }
    
    func refreshWeather(for city: String) async throws -> ForecastModel {
        return try await refresh(for: city)
    }
    
    func getWeatherWithFallback(for city: String) async throws -> ForecastModel {
        return try await fetchWithFallback(for: city)
    }
}

// MARK: - Repository Errors

enum WeatherRepositoryError: Error, LocalizedError {
    case noDataFound
    case invalidData
    case storageError
    case networkError(Error)
    case cacheError
    
    var errorDescription: String? {
        switch self {
        case .noDataFound:
            return "No weather data found"
        case .invalidData:
            return "Invalid weather data format"
        case .storageError:
            return "Failed to save or retrieve data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .cacheError:
            return "Cache operation failed"
        }
    }
}

// MARK: - Mock Weather Repository for Testing

#if DEBUG
/// Mock implementation of WeatherRepository for testing purposes
final class MockWeatherRepository: WeatherRepository {
    typealias Key = String
    typealias Model = ForecastModel
    typealias IdentifierType = String
    
    // MARK: - Mock Storage
    
    private var storage: [String: ForecastModel] = [:]
    private var shouldFailOperations = false
    private var networkDelay: TimeInterval = 0.1
    
    // MARK: - Call Tracking
    
    private(set) var fetchCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var refreshCallCount = 0
    private(set) var getCachedCallCount = 0
    private(set) var clearCacheCallCount = 0
    
    private(set) var lastFetchedCity: String?
    private(set) var lastSavedForecast: ForecastModel?
    private(set) var lastDeletedCity: String?
    
    // MARK: - Mock Control Methods
    
    /// Configure the mock to fail operations
    func setShouldFailOperations(_ shouldFail: Bool) {
        shouldFailOperations = shouldFail
    }
    
    /// Set network delay for simulating slow operations
    func setNetworkDelay(_ delay: TimeInterval) {
        networkDelay = delay
    }
    
    /// Set mock weather data for a city
    func setMockWeather(_ forecast: ForecastModel, for city: String) {
        storage[city] = forecast
    }
    
    /// Remove mock weather data for a city
    func removeMockWeather(for city: String) {
        storage.removeValue(forKey: city)
    }
    
    /// Clear all mock data
    func clearAllMockData() {
        storage.removeAll()
    }
    
    /// Reset all mock state including call counts
    func reset() {
        storage.removeAll()
        shouldFailOperations = false
        networkDelay = 0.1
        
        fetchCallCount = 0
        saveCallCount = 0
        deleteCallCount = 0
        refreshCallCount = 0
        getCachedCallCount = 0
        clearCacheCallCount = 0
        
        lastFetchedCity = nil
        lastSavedForecast = nil
        lastDeletedCity = nil
    }
    
    // MARK: - Private Helpers
    
    private func simulateNetworkDelay() async throws {
        if networkDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 1_000_000_000))
        }
    }
    
    private func throwIfShouldFail() throws {
        if shouldFailOperations {
            throw WeatherRepositoryError.networkError(URLError(.notConnectedToInternet))
        }
    }
    
    // MARK: - BaseRepository Implementation
    
    func fetch(for key: String) async throws -> ForecastModel {
        fetchCallCount += 1
        lastFetchedCity = key
        
        try await simulateNetworkDelay()
        try throwIfShouldFail()
        
        guard let forecast = storage[key] else {
            throw WeatherRepositoryError.noDataFound
        }
        
        return forecast
    }
    
    func save(_ item: ForecastModel) async throws {
        saveCallCount += 1
        lastSavedForecast = item
        
        try await simulateNetworkDelay()
        try throwIfShouldFail()
        
        storage[item.city.name] = item
    }
    
    func delete(for key: String) async throws {
        deleteCallCount += 1
        lastDeletedCity = key
        
        try await simulateNetworkDelay()
        try throwIfShouldFail()
        
        storage.removeValue(forKey: key)
    }
    
    func getAllSavedIdentifiers() async throws -> [String] {
        try await simulateNetworkDelay()
        try throwIfShouldFail()
        
        return Array(storage.keys)
    }
    
    func getCached(for key: String) async throws -> ForecastModel? {
        getCachedCallCount += 1
        
        // For mock, we just return from storage (simulating cache)
        return storage[key]
    }
    
    func clearCache() async throws {
        clearCacheCallCount += 1
        
        try throwIfShouldFail()
        
        // For mock, we clear the storage
        storage.removeAll()
    }
    
    func refresh(for key: String) async throws -> ForecastModel {
        refreshCallCount += 1
        
        try await simulateNetworkDelay()
        try throwIfShouldFail()
        
        guard let forecast = storage[key] else {
            throw WeatherRepositoryError.noDataFound
        }
        
        return forecast
    }
    
    func fetchWithFallback(for key: String) async throws -> ForecastModel {
        // For mock, fallback is the same as fetch
        return try await fetch(for: key)
    }
    
    // MARK: - WeatherRepository Implementation
    
    func saveWeather(_ forecast: ForecastModel) async throws {
        try await save(forecast)
    }
    
    // MARK: - Test Helpers
    
    /// Get current storage state (for testing)
    var currentStorage: [String: ForecastModel] {
        return storage
    }
    
    /// Get total call count across all operations
    var totalCallCount: Int {
        return fetchCallCount + saveCallCount + deleteCallCount + refreshCallCount + getCachedCallCount + clearCacheCallCount
    }
    
    /// Check if a specific city was accessed
    func wasCityAccessed(_ city: String) -> Bool {
        return lastFetchedCity == city || lastDeletedCity == city || lastSavedForecast?.city.name == city
    }
    
    /// Get number of stored forecasts
    var forecastCount: Int {
        return storage.count
    }
    
    /// Check if city has stored forecast
    func hasStoredForecast(for city: String) -> Bool {
        return storage[city] != nil
    }
}
#endif
