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
