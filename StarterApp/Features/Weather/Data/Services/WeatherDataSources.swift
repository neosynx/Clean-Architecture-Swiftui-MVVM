//
//  WeatherDataSources.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Weather Data Source Type Aliases

/// Weather-specific cache data source - bridges to generic protocol
protocol WeatherCacheDataSource: CacheDataSource where Key == String, Model == ForecastModel {
    /// Get cached weather data
    func get(for city: String) async throws -> ForecastModel?
    
    /// Set weather data in cache
    func set(_ forecast: ForecastModel, for city: String) async throws
    
    /// Remove cached weather data
    func remove(for city: String) async throws
    
    /// Clear all cached weather data
    func clear() async throws
}

/// Weather-specific persistence data source - bridges to generic protocol
protocol WeatherPersistenceDataSource: PersistenceDataSource where Key == String, Model == ForecastModel, IdentifierType == String {
    /// Fetch persisted weather data
    func fetch(for city: String) async throws -> ForecastModel?
    
    /// Save weather data to persistence
    func save(_ forecast: ForecastModel) async throws
    
    /// Delete persisted weather data
    func delete(for city: String) async throws
    
    /// Get all saved city identifiers
    func getAllSavedCities() async throws -> [String]
}

// MARK: - Default Implementation Bridge

extension WeatherPersistenceDataSource {
    /// Bridge implementation for generic protocol requirement
    func getAllSavedIdentifiers() async throws -> [String] {
        return try await getAllSavedCities()
    }
}

/// Weather-specific remote data source - bridges to generic protocol
protocol WeatherRemoteDataSource: RemoteDataSource where Key == String, Model == ForecastModel {
    /// Fetch weather data from remote source
    func fetch(for city: String) async throws -> ForecastModel
    
    /// Check if remote service is available
    var isAvailable: Bool { get }
}

// MARK: - Weather Strategy Type Alias

/// Weather-specific data access strategy type - maps to generic type
typealias WeatherDataAccessStrategyType = DataAccessStrategyType
