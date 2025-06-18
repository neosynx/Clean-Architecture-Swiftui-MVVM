//
//  BaseRepository.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Base Repository Protocol

/// Generic base repository protocol that all feature repositories should inherit from
/// Provides common CRUD operations with associated types for flexibility
protocol BaseRepository {
    associatedtype Key: Hashable
    associatedtype Model
    associatedtype IdentifierType: Hashable
    
    // MARK: - Core CRUD Operations
    
    /// Fetch a single item by key using the configured data access strategy
    func fetch(for key: Key) async throws -> Model
    
    /// Save an item to persistent storage and cache
    func save(_ item: Model) async throws
    
    /// Delete an item by key from all storage layers
    func delete(for key: Key) async throws
    
    /// Get all saved identifiers (e.g., city names, user IDs)
    func getAllSavedIdentifiers() async throws -> [IdentifierType]
    
    // MARK: - Cache Operations
    
    /// Get cached item without hitting persistence or network
    func getCached(for key: Key) async throws -> Model?
    
    /// Clear all cached items
    func clearCache() async throws
    
    // MARK: - Refresh Operations
    
    /// Force refresh from remote source, bypassing cache and persistence
    func refresh(for key: Key) async throws -> Model
    
    /// Fetch with intelligent fallback chain based on strategy
    func fetchWithFallback(for key: Key) async throws -> Model
}

// MARK: - Repository Health Protocol

/// Protocol for repository health monitoring
protocol RepositoryHealthProvider {
    associatedtype HealthType
    
    /// Get current health status of the repository
    func getHealth() async -> HealthType
}

// MARK: - Repository Migration Protocol

/// Protocol for repository data migration support
protocol RepositoryMigrationSupport {
    /// Migrate data from legacy storage systems
    func migrateFromLegacyStorage() async throws
}