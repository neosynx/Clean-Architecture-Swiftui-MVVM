//
//  GenericDataSources.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Generic Cache Data Source Protocol

/// Generic protocol for data caching operations
/// Can be specialized for any feature (Weather, Finance, etc.)
protocol CacheDataSource {
    associatedtype Key: Hashable
    associatedtype Model
    
    /// Get cached data
    func get(for key: Key) async throws -> Model?
    
    /// Set data in cache
    func set(_ item: Model, for key: Key) async throws
    
    /// Remove cached data
    func remove(for key: Key) async throws
    
    /// Clear all cached data
    func clear() async throws
}

// MARK: - Generic Persistence Data Source Protocol

/// Generic protocol for data persistence operations
/// Can be specialized for any feature (Weather, Finance, etc.)
protocol PersistenceDataSource {
    associatedtype Key: Hashable
    associatedtype Model
    associatedtype IdentifierType: Hashable
    
    /// Fetch persisted data
    func fetch(for key: Key) async throws -> Model?
    
    /// Save data to persistence
    func save(_ item: Model) async throws
    
    /// Delete persisted data
    func delete(for key: Key) async throws
    
    /// Get all saved identifiers
    func getAllSavedIdentifiers() async throws -> [IdentifierType]
}

// MARK: - Generic Remote Data Source Protocol

/// Generic protocol for remote data operations
/// Can be specialized for any feature (Weather, Finance, etc.)
protocol RemoteDataSource {
    associatedtype Key: Hashable
    associatedtype Model
    
    /// Fetch data from remote source
    func fetch(for key: Key) async throws -> Model
    
    /// Check if remote service is available
    var isAvailable: Bool { get }
}

// MARK: - Strategy Type Definition

/// Generic data access strategy types
enum DataAccessStrategyType: String, CaseIterable {
    case cacheFirst = "cache_first"
    case persistenceFirst = "persistence_first" 
    case networkFirst = "network_first"
    
    var description: String {
        switch self {
        case .cacheFirst:
            return "Cache → Persistence → Network"
        case .persistenceFirst:
            return "Persistence → Cache → Network"
        case .networkFirst:
            return "Network → Cache → Persistence"
        }
    }
}