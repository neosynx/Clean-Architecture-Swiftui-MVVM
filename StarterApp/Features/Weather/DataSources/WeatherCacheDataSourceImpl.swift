//
//  WeatherCacheDataSourceImpl.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

/// Weather cache data source implementation using DomainModelCache
final class WeatherCacheDataSourceImpl: WeatherCacheDataSource {
    
    // MARK: - Properties
    
    private let cache: DomainModelCache<String, ForecastModel>
    
    // MARK: - Initialization
    
    init(
        countLimit: Int = 50,
        totalCostLimit: Int = 20 * 1024 * 1024, // 20MB
        expirationInterval: TimeInterval = 3600, // 1 hour
        logger: AppLogger
    ) {
        self.cache = DomainModelCache<String, ForecastModel>(
            countLimit: countLimit,
            totalCostLimit: totalCostLimit,
            expirationInterval: expirationInterval,
            logger: logger
        )
    }
    
    // MARK: - WeatherCacheDataSource Protocol Implementation
    
    func get(for city: String) async throws -> ForecastModel? {
        do {
            return await cache.get(for: city)
        } catch ServiceError.cacheExpired {
            return nil
        }
    }
    
    func set(_ forecast: ForecastModel, for city: String) async throws {
        await cache.set(forecast, for: city)
    }
    
    func remove(for city: String) async throws {
        await cache.remove(for: city)
    }
    
    func clear() async throws {
        await cache.clear()
    }
    
    // MARK: - Additional Methods
    
    /// Get cache statistics for monitoring
    func getStatistics() async -> SimpleCacheStatistics {
        return await cache.getStatistics()
    }
}