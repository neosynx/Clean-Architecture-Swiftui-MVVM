//
//  WeatherDataSources.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

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


// MARK: - Weather Strategy Type Alias

/// Weather-specific data access strategy type - maps to generic type
typealias WeatherDataAccessStrategyType = DataAccessStrategyType
