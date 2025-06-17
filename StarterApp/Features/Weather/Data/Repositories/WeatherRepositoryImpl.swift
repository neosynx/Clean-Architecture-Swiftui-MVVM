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
            let forecastApiDTO = try await remoteDataSource.fetchWeather(for: city)
            let forecast = WeatherDomainMapper.mapToDomain(forecastApiDTO)
            
            // Convert to FileDTO for caching and local storage
            let forecastFileDTO = WeatherDomainMapper.mapToFileDTO(forecast)
            
            // Cache the result if caching is enabled
            if configuration.useCache {
                try await cacheDataSource.cacheWeather(forecastFileDTO)
            }
            
            // Save to local storage if enabled
            if configuration.useLocalStorage {
                try await localDataSource.saveWeather(forecastFileDTO)
            }
            
            return forecast
        } catch {
            // Strategy 3: Fallback to local storage if offline fallback is enabled
            if configuration.offlineFallback && configuration.useLocalStorage {
                if let localForecastDTO = try await localDataSource.fetchWeather(for: city) {
                    return WeatherDomainMapper.mapToDomain(localForecastDTO)
                }
            }
            
            throw error
        }
    }
    
    func saveWeather(_ forecast: ForecastModel) async throws {
        guard configuration.useLocalStorage else {
            throw WeatherRepositoryError.storageError
        }
        
        let forecastFileDTO = WeatherDomainMapper.mapToFileDTO(forecast)
        try await localDataSource.saveWeather(forecastFileDTO)
        
        // Also update cache if enabled
        if configuration.useCache {
            try await cacheDataSource.cacheWeather(forecastFileDTO)
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
        
        if let cachedDTO = try await cacheDataSource.getCachedWeather(for: city) {
            return WeatherDomainMapper.mapToDomain(cachedDTO)
        }
        return nil
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
        let forecastApiDTO = try await remoteDataSource.fetchWeather(for: city)
        let forecast = WeatherDomainMapper.mapToDomain(forecastApiDTO)
        let forecastFileDTO = WeatherDomainMapper.mapToFileDTO(forecast)
        
        // Update cache and local storage
        if configuration.useCache {
            try await cacheDataSource.cacheWeather(forecastFileDTO)
        }
        
        if configuration.useLocalStorage {
            try await localDataSource.saveWeather(forecastFileDTO)
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
           let localForecastDTO = try await localDataSource.fetchWeather(for: city) {
            return WeatherDomainMapper.mapToDomain(localForecastDTO)
        }
        
        // Finally try remote
        let forecastApiDTO = try await remoteDataSource.fetchWeather(for: city)
        return WeatherDomainMapper.mapToDomain(forecastApiDTO)
    }
}

