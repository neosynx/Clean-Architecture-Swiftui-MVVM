//
//  WeatherCacheDataSource.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//


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