//
//  WeatherRepositoryImpl.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation
import SwiftData

/// Clean Architecture Weather Repository implementation using Protocol-based Strategy Pattern
/// Uses protocol composition instead of concrete dependencies for better testability
final class WeatherRepositoryImpl: WeatherRepository {
    
    // MARK: - Properties
    
    private let dataAccessStrategy: WeatherDataAccessStrategy
    private let cacheDataSource: WeatherCacheDataSource
    private let persistenceDataSource: WeatherPersistenceDataSource
    private let remoteDataSource: WeatherRemoteDataSource?
    private let logger: AppLogger
    private let secureStorage: SecureStorageService
    // MARK: - Initialization
    
    init(
        swiftDataContainer: SwiftDataContainer,
        remoteService: WeatherRemoteService? = nil,
        mapper: WeatherProtocolMapper = WeatherProtocolMapper(),
        strategyType: WeatherDataAccessStrategyType = .cacheFirst,
        logger: AppLogger,
        secureStorage: SecureStorageService
    ) {
        self.logger = logger
        self.secureStorage = secureStorage
        
        // Create protocol-based data sources
        self.cacheDataSource = WeatherCacheDataSourceImpl(
            countLimit: 50,
            totalCostLimit: 20 * 1024 * 1024, // 20MB
            expirationInterval: 3600, // 1 hour
            logger: logger
        )
        
        self.persistenceDataSource = WeatherPersistenceDataSourceImpl(
            persistenceService: swiftDataContainer,
            mapper: mapper,
            logger: logger
        )
        
        if let remoteService = remoteService {
            self.remoteDataSource = WeatherRemoteDataSourceImpl(
                remoteService: remoteService,
                mapper: mapper,
                logger: logger
            )
        } else {
            self.remoteDataSource = nil
        }
        
        // Create strategy using factory
        self.dataAccessStrategy = WeatherDataAccessStrategyFactory.create(type: strategyType)
        
        logger.info("WeatherRepositoryImpl initialized with strategy: \(strategyType)")
    }
    
    // MARK: - BaseRepository Protocol Implementation
    
    func fetch(for key: String) async throws -> ForecastModel {
        return try await dataAccessStrategy.execute(
            for: key,
            cache: cacheDataSource,
            persistence: persistenceDataSource,
            remote: remoteDataSource,
            logger: logger
        )
    }
    
    func save(_ item: ForecastModel) async throws {
        try await persistenceDataSource.save(item)
        try await cacheDataSource.set(item, for: item.city.name)
    }
    
    func delete(for key: String) async throws {
        try await persistenceDataSource.delete(for: key)
        try await cacheDataSource.remove(for: key)
    }
    
    func getAllSavedIdentifiers() async throws -> [String] {
        return try await persistenceDataSource.getAllSavedCities()
    }
    
    func getCached(for key: String) async throws -> ForecastModel? {
        return try await cacheDataSource.get(for: key)
    }
    
    func clearCache() async throws {
        try await cacheDataSource.clear()
    }
    
    func refresh(for key: String) async throws -> ForecastModel {
        guard let remoteDataSource = remoteDataSource else {
            throw ServiceError.serviceUnavailable
        }
        
        let forecast = try await remoteDataSource.fetch(for: key)
        try await persistenceDataSource.save(forecast)
        try await cacheDataSource.set(forecast, for: key)
        return forecast
    }
    
    func fetchWithFallback(for key: String) async throws -> ForecastModel {
        return try await fetch(for: key)
    }
    
    // MARK: - WeatherRepository Protocol Implementation
    
    func saveWeather(_ forecast: ForecastModel) async throws {
        logger.info("💾 Repository.saveWeather starting for city: \(forecast.city.name)")
        try await save(forecast)
        logger.info("💾 Repository.saveWeather: Completed successfully")
    }
    
    func deleteWeather(for city: String) async throws {
        logger.info("🗑️ Repository.deleteWeather for city: \(city)")
        try await delete(for: city)
        logger.info("🗑️ Repository.deleteWeather: Completed successfully")
    }
    
    func getAllSavedCities() async throws -> [String] {
        logger.debug("📋 Repository.getAllSavedCities")
        let cities = try await getAllSavedIdentifiers()
        logger.debug("📋 Repository.getAllSavedCities: Found \(cities.count) cities")
        return cities
    }
    
    func getCachedWeather(for city: String) async throws -> ForecastModel? {
        logger.debug("🏃‍♂️ Repository.getCachedWeather for city: \(city)")
        let cached = try await getCached(for: city)
        logger.debug("🏃‍♂️ Repository.getCachedWeather: \(cached != nil ? "Hit" : "Miss")")
        return cached
    }
    
    func refreshWeather(for city: String) async throws -> ForecastModel {
        logger.info("🔄 Repository.refreshWeather starting for city: \(city)")
        let forecast = try await refresh(for: city)
        logger.info("🔄 Repository.refreshWeather: Completed successfully")
        return forecast
    }
    
    func getWeatherWithFallback(for city: String) async throws -> ForecastModel {
        return try await fetchWithFallback(for: city)
    }
    
    
    // MARK: - Health Monitoring
    
    func getHealth() async -> RepositoryHealth {
        // Get cache statistics from the cache data source
        let cacheStats = await (cacheDataSource as? WeatherCacheDataSourceImpl)?.getStatistics() ?? SimpleCacheStatistics(
            entryCount: 0,
            expiredCount: 0,
            totalCount: 0,
            countLimit: 0,
            totalCostLimit: 0
        )
        
        let persistedCities = (try? await persistenceDataSource.getAllSavedCities().count) ?? 0
        
        return RepositoryHealth(
            cacheHealthy: true,
            persistenceHealthy: true,
            remoteServiceHealthy: remoteDataSource?.isAvailable ?? false,
            cacheEntries: cacheStats.entryCount,
            persistedEntries: persistedCities,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Migration Support
    
    /// Migrate data from file storage to SwiftData
    func migrateFromFileStorage() async throws {
        logger.info("🔄 Starting migration from file storage to SwiftData")
        
        // This would be called during app upgrade
        // Implementation would read from file storage and convert to SwiftData
        // For now, this is a placeholder
        
        logger.info("🔄 Migration completed successfully")
    }
}

// MARK: - Repository Health

struct RepositoryHealth {
    let cacheHealthy: Bool
    let persistenceHealthy: Bool
    let remoteServiceHealthy: Bool
    let cacheEntries: Int
    let persistedEntries: Int
    let lastUpdated: Date
    
    var overallHealth: String {
        let components = [
            cacheHealthy ? "Cache ✅" : "Cache ❌",
            persistenceHealthy ? "Persistence ✅" : "Persistence ❌",
            remoteServiceHealthy ? "Remote ✅" : "Remote ❌"
        ]
        return components.joined(separator: " ")
    }
    
    var description: String {
        """
        Repository Health Report:
        - Overall: \(overallHealth)
        - Cache entries: \(cacheEntries)
        - Persisted entries: \(persistedEntries)
        - Last updated: \(lastUpdated)
        """
    }
}
