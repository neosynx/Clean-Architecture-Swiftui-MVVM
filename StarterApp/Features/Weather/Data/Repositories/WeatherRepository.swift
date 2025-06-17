//
//  WeatherRepository.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Weather Repository Protocol

protocol WeatherRepository {
    func fetchWeather(for city: String) async throws -> ForecastModel
    func saveWeather(_ forecast: ForecastModel) async throws
    func deleteWeather(for city: String) async throws
    func getAllSavedCities() async throws -> [String]
    func getCachedWeather(for city: String) async throws -> ForecastModel?
    func clearCache() async throws
    func refreshWeather(for city: String) async throws -> ForecastModel
    func getWeatherWithFallback(for city: String) async throws -> ForecastModel
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
