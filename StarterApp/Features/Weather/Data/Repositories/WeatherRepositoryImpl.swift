//
//  WeatherRepositoryImpl.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

class WeatherRepositoryImpl: WeatherRepository {
    private let remoteDataSource: WeatherRemoteDataSource
    private let localDataSource: WeatherLocalDataSource
    private let cacheDataSource: WeatherCacheDataSource
    private let configuration: RepositoryConfiguration
    
    struct RepositoryConfiguration {
        let useCache: Bool
        let useLocalStorage: Bool
        let cacheFirstStrategy: Bool
        let offlineFallback: Bool
        
        static let `default` = RepositoryConfiguration(
            useCache: true,
            useLocalStorage: true,
            cacheFirstStrategy: true,
            offlineFallback: true
        )
    }
    
    init(
        remoteDataSource: WeatherRemoteDataSource,
        localDataSource: WeatherLocalDataSource,
        cacheDataSource: WeatherCacheDataSource,
        configuration: RepositoryConfiguration = .default
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.cacheDataSource = cacheDataSource
        self.configuration = configuration
    }
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        // Strategy 1: Check cache first if enabled
        if configuration.useCache && configuration.cacheFirstStrategy {
            if let cachedForecast = try await getCachedWeather(for: city) {
                return cachedForecast
            }
        }
        
        // Strategy 2: Try remote data source
        do {
            let forecast = try await remoteDataSource.fetchWeather(for: city)
            
            // Cache the result if caching is enabled
            if configuration.useCache {
                try await cacheDataSource.cacheWeather(forecast)
            }
            
            // Save to local storage if enabled
            if configuration.useLocalStorage {
                try await localDataSource.saveWeather(forecast)
            }
            
            return forecast
        } catch {
            // Strategy 3: Fallback to local storage if offline fallback is enabled
            if configuration.offlineFallback && configuration.useLocalStorage {
                if let localForecast = try await localDataSource.fetchWeather(for: city) {
                    return localForecast
                }
            }
            
            throw error
        }
    }
    
    func saveWeather(_ forecast: ForecastModel) async throws {
        guard configuration.useLocalStorage else {
            throw WeatherRepositoryError.storageError
        }
        
        try await localDataSource.saveWeather(forecast)
        
        // Also update cache if enabled
        if configuration.useCache {
            try await cacheDataSource.cacheWeather(forecast)
        }
    }
    
    func deleteWeather(for city: String) async throws {
        // Delete from local storage
        if configuration.useLocalStorage {
            try await localDataSource.deleteWeather(for: city)
        }
        
        // Remove from cache
        if configuration.useCache {
            // Note: MemoryCache doesn't have a specific delete method, but clearing cache works
            // In a real implementation, you might want to add a delete method to the cache protocol
        }
    }
    
    func getAllSavedCities() async throws -> [String] {
        guard configuration.useLocalStorage else {
            return []
        }
        
        return try await localDataSource.getAllSavedCities()
    }
    
    func getCachedWeather(for city: String) async throws -> ForecastModel? {
        guard configuration.useCache else {
            return nil
        }
        
        return try await cacheDataSource.getCachedWeather(for: city)
    }
    
    func clearCache() async throws {
        guard configuration.useCache else {
            return
        }
        
        try await cacheDataSource.clearCache()
    }
    
    // MARK: - Additional Repository Methods
    
    func refreshWeather(for city: String) async throws -> ForecastModel {
        // Force refresh from remote, bypassing cache
        let forecast = try await remoteDataSource.fetchWeather(for: city)
        
        // Update cache and local storage
        if configuration.useCache {
            try await cacheDataSource.cacheWeather(forecast)
        }
        
        if configuration.useLocalStorage {
            try await localDataSource.saveWeather(forecast)
        }
        
        return forecast
    }
    
    func getWeatherWithFallback(for city: String) async throws -> ForecastModel {
        // Try cache first
        if configuration.useCache,
           let cachedForecast = try await getCachedWeather(for: city) {
            return cachedForecast
        }
        
        // Try local storage
        if configuration.useLocalStorage,
           let localForecast = try await localDataSource.fetchWeather(for: city) {
            return localForecast
        }
        
        // Finally try remote
        return try await remoteDataSource.fetchWeather(for: city)
    }
}

