//
//  GenericDataAccessStrategies.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation
import codeartis_logging

// MARK: - Generic Cache First Strategy

/// Generic strategy that prioritizes cache, then persistence, then network
struct CacheFirstStrategy<Key: Hashable, Model>: DataAccessStrategy {
    
    func execute<C, P, R>(
        for key: Key,
        cache: C,
        persistence: P,
        remote: R?,
        logger: CodeartisLogger
    ) async throws -> Model
    where C: CacheDataSource, P: PersistenceDataSource, R: RemoteDataSource,
          C.Key == Key, P.Key == Key, R.Key == Key,
          C.Model == Model, P.Model == Model, R.Model == Model {
        
        logger.debug("🏗️ CacheFirstStrategy.execute for key: \(key)")
        
        // Level 1: Check cache (fastest - ~1ms)
        if let cached = try await cache.get(for: key) {
            logger.debug("🏗️ CacheFirstStrategy: Cache HIT")
            return cached
        }
        
        // Level 2: Check persistence (medium - ~10ms)
        if let persisted = try await persistence.fetch(for: key) {
            logger.debug("🏗️ CacheFirstStrategy: Persistence HIT")
            // Update cache for next time
            try await cache.set(persisted, for: key)
            return persisted
        }
        
        // Level 3: Fetch from network (slowest - ~1000ms)
        if let remote = remote, remote.isAvailable {
            logger.debug("🏗️ CacheFirstStrategy: Falling back to network")
            let item = try await remote.fetch(for: key)
            // Save to both cache and persistence
            try await cache.set(item, for: key)
            try await persistence.save(item)
            return item
        }
        
        throw RepositoryError.dataNotFound(String(describing: key))
    }
}

// MARK: - Generic Persistence First Strategy

/// Generic strategy that prioritizes persistence, then cache, then network
struct PersistenceFirstStrategy<Key: Hashable, Model>: DataAccessStrategy {
    
    func execute<C, P, R>(
        for key: Key,
        cache: C,
        persistence: P,
        remote: R?,
        logger: CodeartisLogger
    ) async throws -> Model
    where C: CacheDataSource, P: PersistenceDataSource, R: RemoteDataSource,
          C.Key == Key, P.Key == Key, R.Key == Key,
          C.Model == Model, P.Model == Model, R.Model == Model {
        
        logger.debug("🏗️ PersistenceFirstStrategy.execute for key: \(key)")
        
        // Level 1: Check persistence (reliable)
        if let persisted = try await persistence.fetch(for: key) {
            logger.debug("🏗️ PersistenceFirstStrategy: Persistence HIT")
            // Update cache
            try await cache.set(persisted, for: key)
            return persisted
        }
        
        // Level 2: Check cache
        if let cached = try await cache.get(for: key) {
            logger.debug("🏗️ PersistenceFirstStrategy: Cache HIT")
            return cached
        }
        
        // Level 3: Network fallback
        if let remote = remote, remote.isAvailable {
            logger.debug("🏗️ PersistenceFirstStrategy: Falling back to network")
            let item = try await remote.fetch(for: key)
            // Save to both persistence and cache
            try await persistence.save(item)
            try await cache.set(item, for: key)
            return item
        }
        
        throw RepositoryError.dataNotFound(String(describing: key))
    }
}

// MARK: - Generic Network First Strategy

/// Generic strategy that prioritizes network, then cache, then persistence
struct NetworkFirstStrategy<Key: Hashable, Model>: DataAccessStrategy {
    
    func execute<C, P, R>(
        for key: Key,
        cache: C,
        persistence: P,
        remote: R?,
        logger: CodeartisLogger
    ) async throws -> Model
    where C: CacheDataSource, P: PersistenceDataSource, R: RemoteDataSource,
          C.Key == Key, P.Key == Key, R.Key == Key,
          C.Model == Model, P.Model == Model, R.Model == Model {
        
        logger.debug("🏗️ NetworkFirstStrategy.execute for key: \(key)")
        
        // Level 1: Try network first (fresh data)
        if let remote = remote, remote.isAvailable {
            do {
                logger.debug("🏗️ NetworkFirstStrategy: Attempting network fetch")
                let item = try await remote.fetch(for: key)
                // Save to both cache and persistence
                try await cache.set(item, for: key)
                try await persistence.save(item)
                return item
            } catch {
                logger.debug("🏗️ NetworkFirstStrategy: Network failed, falling back")
                // Continue to fallbacks
            }
        }
        
        // Level 2: Check cache
        if let cached = try await cache.get(for: key) {
            logger.debug("🏗️ NetworkFirstStrategy: Cache HIT")
            return cached
        }
        
        // Level 3: Check persistence
        if let persisted = try await persistence.fetch(for: key) {
            logger.debug("🏗️ NetworkFirstStrategy: Persistence HIT")
            // Update cache
            try await cache.set(persisted, for: key)
            return persisted
        }
        
        throw RepositoryError.dataNotFound(String(describing: key))
    }
}

// MARK: - Generic Strategy Factory

/// Factory for creating generic data access strategies
struct DataAccessStrategyFactory {
    
    /// Create a cache-first strategy for any Key/Model combination
    static func createCacheFirst<Key: Hashable, Model>() -> CacheFirstStrategy<Key, Model> {
        return CacheFirstStrategy<Key, Model>()
    }
    
    /// Create a persistence-first strategy for any Key/Model combination
    static func createPersistenceFirst<Key: Hashable, Model>() -> PersistenceFirstStrategy<Key, Model> {
        return PersistenceFirstStrategy<Key, Model>()
    }
    
    /// Create a network-first strategy for any Key/Model combination
    static func createNetworkFirst<Key: Hashable, Model>() -> NetworkFirstStrategy<Key, Model> {
        return NetworkFirstStrategy<Key, Model>()
    }
}

// MARK: - Generic Repository Error

enum RepositoryError: Error, LocalizedError {
    case dataNotFound(String)
    case invalidData
    case storageError
    case networkError(Error)
    case cacheError
    
    var errorDescription: String? {
        switch self {
        case .dataNotFound(let key):
            return "No data found for key: \(key)"
        case .invalidData:
            return "Invalid data format"
        case .storageError:
            return "Failed to save or retrieve data"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .cacheError:
            return "Cache operation failed"
        }
    }
}