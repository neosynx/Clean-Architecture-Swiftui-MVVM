//
//  WeatherDataAccessStrategy.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Weather Data Access Strategy Protocol

/// Weather-specific data access strategy - bridges to generic protocol
protocol WeatherDataAccessStrategy: DataAccessStrategy where Key == String, Model == ForecastModel {
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
        cache: any WeatherCacheDataSource,
        persistence: any WeatherPersistenceDataSource,
        remote: (any WeatherRemoteDataSource)?,
        logger: AppLogger
    ) async throws -> ForecastModel
}

// MARK: - Weather Strategy Implementations

/// Weather-specific cache-first strategy using generic implementation
struct WeatherCacheFirstStrategy: WeatherDataAccessStrategy {
    private let genericStrategy: CacheFirstStrategy<String, ForecastModel> = CacheFirstStrategy()
    
    func execute<C, P, R>(
        for key: String,
        cache: C,
        persistence: P,
        remote: R?,
        logger: AppLogger
    ) async throws -> ForecastModel
    where C: CacheDataSource, P: PersistenceDataSource, R: RemoteDataSource,
          C.Key == String, P.Key == String, R.Key == String,
          C.Model == ForecastModel, P.Model == ForecastModel, R.Model == ForecastModel {
        
        return try await genericStrategy.execute(
            for: key,
            cache: cache,
            persistence: persistence,
            remote: remote,
            logger: logger
        )
    }
    
    func execute(
        for city: String,
        cache: any WeatherCacheDataSource,
        persistence: any WeatherPersistenceDataSource,
        remote: (any WeatherRemoteDataSource)?,
        logger: AppLogger
    ) async throws -> ForecastModel {
        logger.debug("🏗️ WeatherCacheFirstStrategy.execute for city: \(city)")
        
        // Level 1: Check cache (fastest - ~1ms)
        if let cached = try await cache.get(for: city) {
            logger.debug("🏗️ WeatherCacheFirstStrategy: Cache HIT")
            return cached
        }
        
        // Level 2: Check persistence (medium - ~10ms)
        if let persisted = try await persistence.fetch(for: city) {
            logger.debug("🏗️ WeatherCacheFirstStrategy: Persistence HIT")
            // Update cache for next time
            try await cache.set(persisted, for: city)
            return persisted
        }
        
        // Level 3: Fetch from network (slowest - ~1000ms)
        if let remote = remote, remote.isAvailable {
            logger.debug("🏗️ WeatherCacheFirstStrategy: Falling back to network")
            let item = try await remote.fetch(for: city)
            // Save to both cache and persistence
            try await cache.set(item, for: city)
            try await persistence.save(item)
            return item
        }
        
        throw RepositoryError.dataNotFound(city)
    }
}

/// Weather-specific persistence-first strategy using generic implementation
struct WeatherPersistenceFirstStrategy: WeatherDataAccessStrategy {
    private let genericStrategy: PersistenceFirstStrategy<String, ForecastModel> = PersistenceFirstStrategy()
    
    func execute<C, P, R>(
        for key: String,
        cache: C,
        persistence: P,
        remote: R?,
        logger: AppLogger
    ) async throws -> ForecastModel
    where C: CacheDataSource, P: PersistenceDataSource, R: RemoteDataSource,
          C.Key == String, P.Key == String, R.Key == String,
          C.Model == ForecastModel, P.Model == ForecastModel, R.Model == ForecastModel {
        
        return try await genericStrategy.execute(
            for: key,
            cache: cache,
            persistence: persistence,
            remote: remote,
            logger: logger
        )
    }
    
    func execute(
        for city: String,
        cache: any WeatherCacheDataSource,
        persistence: any WeatherPersistenceDataSource,
        remote: (any WeatherRemoteDataSource)?,
        logger: AppLogger
    ) async throws -> ForecastModel {
        logger.debug("🏗️ WeatherPersistenceFirstStrategy.execute for city: \(city)")
        
        // Level 1: Check persistence (reliable)
        if let persisted = try await persistence.fetch(for: city) {
            logger.debug("🏗️ WeatherPersistenceFirstStrategy: Persistence HIT")
            // Update cache
            try await cache.set(persisted, for: city)
            return persisted
        }
        
        // Level 2: Check cache
        if let cached = try await cache.get(for: city) {
            logger.debug("🏗️ WeatherPersistenceFirstStrategy: Cache HIT")
            return cached
        }
        
        // Level 3: Network fallback
        if let remote = remote, remote.isAvailable {
            logger.debug("🏗️ WeatherPersistenceFirstStrategy: Falling back to network")
            let item = try await remote.fetch(for: city)
            // Save to both persistence and cache
            try await persistence.save(item)
            try await cache.set(item, for: city)
            return item
        }
        
        throw RepositoryError.dataNotFound(city)
    }
}

/// Weather-specific network-first strategy using generic implementation
struct WeatherNetworkFirstStrategy: WeatherDataAccessStrategy {
    private let genericStrategy: NetworkFirstStrategy<String, ForecastModel> = NetworkFirstStrategy()
    
    func execute<C, P, R>(
        for key: String,
        cache: C,
        persistence: P,
        remote: R?,
        logger: AppLogger
    ) async throws -> ForecastModel
    where C: CacheDataSource, P: PersistenceDataSource, R: RemoteDataSource,
          C.Key == String, P.Key == String, R.Key == String,
          C.Model == ForecastModel, P.Model == ForecastModel, R.Model == ForecastModel {
        
        return try await genericStrategy.execute(
            for: key,
            cache: cache,
            persistence: persistence,
            remote: remote,
            logger: logger
        )
    }
    
    func execute(
        for city: String,
        cache: any WeatherCacheDataSource,
        persistence: any WeatherPersistenceDataSource,
        remote: (any WeatherRemoteDataSource)?,
        logger: AppLogger
    ) async throws -> ForecastModel {
        logger.debug("🏗️ WeatherNetworkFirstStrategy.execute for city: \(city)")
        
        // Level 1: Try network first (fresh data)
        if let remote = remote, remote.isAvailable {
            do {
                logger.debug("🏗️ WeatherNetworkFirstStrategy: Attempting network fetch")
                let item = try await remote.fetch(for: city)
                // Save to both cache and persistence
                try await cache.set(item, for: city)
                try await persistence.save(item)
                return item
            } catch {
                logger.debug("🏗️ WeatherNetworkFirstStrategy: Network failed, falling back")
                // Continue to fallbacks
            }
        }
        
        // Level 2: Check cache
        if let cached = try await cache.get(for: city) {
            logger.debug("🏗️ WeatherNetworkFirstStrategy: Cache HIT")
            return cached
        }
        
        // Level 3: Check persistence
        if let persisted = try await persistence.fetch(for: city) {
            logger.debug("🏗️ WeatherNetworkFirstStrategy: Persistence HIT")
            // Update cache
            try await cache.set(persisted, for: city)
            return persisted
        }
        
        throw RepositoryError.dataNotFound(city)
    }
}

// MARK: - Strategy Factory

/// Factory for creating weather data access strategies
struct WeatherDataAccessStrategyFactory {
    static func create(type: WeatherDataAccessStrategyType) -> any WeatherDataAccessStrategy {
        switch type {
        case .cacheFirst:
            return WeatherCacheFirstStrategy()
        case .persistenceFirst:
            return WeatherPersistenceFirstStrategy()
        case .networkFirst:
            return WeatherNetworkFirstStrategy()
        }
    }
}
