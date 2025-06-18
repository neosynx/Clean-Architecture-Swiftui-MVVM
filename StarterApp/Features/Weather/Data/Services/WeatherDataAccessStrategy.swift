//
//  WeatherDataAccessStrategy.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Weather Data Access Strategy Protocol

/// Type-safe protocol for weather data access strategies
/// Defines how data is retrieved using different fallback chains
protocol WeatherDataAccessStrategy {
    /// Execute the data access strategy with type-safe dependencies
    /// - Parameters:
    ///   - city: The city to fetch weather data for
    ///   - cache: Cache data source for fast memory access
    ///   - persistence: Persistence data source for local storage
    ///   - remote: Remote data source for network data
    ///   - logger: Logger for debugging and monitoring
    /// - Returns: The retrieved weather forecast model
    func execute(
        for city: String,
        cache: WeatherCacheDataSource,
        persistence: WeatherPersistenceDataSource,
        remote: WeatherRemoteDataSource?,
        logger: AppLogger
    ) async throws -> ForecastModel
}

// MARK: - Cache First Strategy

/// Strategy that prioritizes cache, then persistence, then network
struct CacheFirstStrategy: WeatherDataAccessStrategy {
    func execute(
        for city: String,
        cache: WeatherCacheDataSource,
        persistence: WeatherPersistenceDataSource,
        remote: WeatherRemoteDataSource?,
        logger: AppLogger
    ) async throws -> ForecastModel {
        logger.debug("🏗️ CacheFirstStrategy.execute for city: \(city)")
        
        // Level 1: Check cache (fastest - ~1ms)
        if let cached = try await cache.get(for: city) {
            logger.debug("🏗️ CacheFirstStrategy: Cache HIT")
            return cached
        }
        
        // Level 2: Check persistence (medium - ~10ms)
        if let persisted = try await persistence.fetch(for: city) {
            logger.debug("🏗️ CacheFirstStrategy: Persistence HIT")
            // Update cache for next time
            try await cache.set(persisted, for: city)
            return persisted
        }
        
        // Level 3: Fetch from network (slowest - ~1000ms)
        if let remote = remote, remote.isAvailable {
            logger.debug("🏗️ CacheFirstStrategy: Falling back to network")
            let forecast = try await remote.fetch(for: city)
            // Save to both cache and persistence
            try await cache.set(forecast, for: city)
            try await persistence.save(forecast)
            return forecast
        }
        
        throw ServiceError.notFound
    }
}

// MARK: - Persistence First Strategy

/// Strategy that prioritizes persistence, then cache, then network
struct PersistenceFirstStrategy: WeatherDataAccessStrategy {
    func execute(
        for city: String,
        cache: WeatherCacheDataSource,
        persistence: WeatherPersistenceDataSource,
        remote: WeatherRemoteDataSource?,
        logger: AppLogger
    ) async throws -> ForecastModel {
        logger.debug("🏗️ PersistenceFirstStrategy.execute for city: \(city)")
        
        // Level 1: Check persistence (reliable)
        if let persisted = try await persistence.fetch(for: city) {
            logger.debug("🏗️ PersistenceFirstStrategy: Persistence HIT")
            // Update cache
            try await cache.set(persisted, for: city)
            return persisted
        }
        
        // Level 2: Check cache
        if let cached = try await cache.get(for: city) {
            logger.debug("🏗️ PersistenceFirstStrategy: Cache HIT")
            return cached
        }
        
        // Level 3: Network fallback
        if let remote = remote, remote.isAvailable {
            logger.debug("🏗️ PersistenceFirstStrategy: Falling back to network")
            let forecast = try await remote.fetch(for: city)
            // Save to both persistence and cache
            try await persistence.save(forecast)
            try await cache.set(forecast, for: city)
            return forecast
        }
        
        throw ServiceError.notFound
    }
}

// MARK: - Network First Strategy

/// Strategy that prioritizes network, then cache, then persistence
struct NetworkFirstStrategy: WeatherDataAccessStrategy {
    func execute(
        for city: String,
        cache: WeatherCacheDataSource,
        persistence: WeatherPersistenceDataSource,
        remote: WeatherRemoteDataSource?,
        logger: AppLogger
    ) async throws -> ForecastModel {
        logger.debug("🏗️ NetworkFirstStrategy.execute for city: \(city)")
        
        // Level 1: Try network first (fresh data)
        if let remote = remote, remote.isAvailable {
            do {
                logger.debug("🏗️ NetworkFirstStrategy: Attempting network fetch")
                let forecast = try await remote.fetch(for: city)
                // Save to both cache and persistence
                try await cache.set(forecast, for: city)
                try await persistence.save(forecast)
                return forecast
            } catch {
                logger.debug("🏗️ NetworkFirstStrategy: Network failed, falling back")
                // Continue to fallbacks
            }
        }
        
        // Level 2: Check cache
        if let cached = try await cache.get(for: city) {
            logger.debug("🏗️ NetworkFirstStrategy: Cache HIT")
            return cached
        }
        
        // Level 3: Check persistence
        if let persisted = try await persistence.fetch(for: city) {
            logger.debug("🏗️ NetworkFirstStrategy: Persistence HIT")
            // Update cache
            try await cache.set(persisted, for: city)
            return persisted
        }
        
        throw ServiceError.notFound
    }
}

// MARK: - Strategy Factory

/// Factory for creating weather data access strategies
struct WeatherDataAccessStrategyFactory {
    static func create(type: WeatherDataAccessStrategyType) -> WeatherDataAccessStrategy {
        switch type {
        case .cacheFirst:
            return CacheFirstStrategy()
        case .persistenceFirst:
            return PersistenceFirstStrategy()
        case .networkFirst:
            return NetworkFirstStrategy()
        }
    }
}