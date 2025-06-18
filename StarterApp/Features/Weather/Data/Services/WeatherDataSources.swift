//
//  WeatherDataSources.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Weather Cache Data Source Protocol

/// Protocol for weather data caching operations
protocol WeatherCacheDataSource {
    /// Get cached weather data
    func get(for city: String) async throws -> ForecastModel?
    
    /// Set weather data in cache
    func set(_ forecast: ForecastModel, for city: String) async throws
    
    /// Remove cached weather data
    func remove(for city: String) async throws
    
    /// Clear all cached weather data
    func clear() async throws
}

// MARK: - Weather Persistence Data Source Protocol

/// Protocol for weather data persistence operations
protocol WeatherPersistenceDataSource {
    /// Fetch persisted weather data
    func fetch(for city: String) async throws -> ForecastModel?
    
    /// Save weather data to persistence
    func save(_ forecast: ForecastModel) async throws
    
    /// Delete persisted weather data
    func delete(for city: String) async throws
    
    /// Get all saved city identifiers
    func getAllSavedCities() async throws -> [String]
}

// MARK: - Weather Remote Data Source Protocol

/// Protocol for weather data remote operations
protocol WeatherRemoteDataSource {
    /// Fetch weather data from remote source
    func fetch(for city: String) async throws -> ForecastModel
    
    /// Check if remote service is available
    var isAvailable: Bool { get }
}

// MARK: - Strategy Type Definition

/// Data access strategy types for weather data
enum WeatherDataAccessStrategyType: String, CaseIterable {
    case cacheFirst = "cache_first"
    case persistenceFirst = "persistence_first" 
    case networkFirst = "network_first"
    
    var description: String {
        switch self {
        case .cacheFirst:
            return "Cache → Persistence → Network"
        case .persistenceFirst:
            return "Persistence → Cache → Network"
        case .networkFirst:
            return "Network → Cache → Persistence"
        }
    }
}
