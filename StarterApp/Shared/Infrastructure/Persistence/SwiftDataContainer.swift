//
//  SwiftDataContainer 2.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/19.
//

import Foundation
import SwiftData


// MARK: - Protocol

/// Protocol for SwiftData container operations
/// Provides a unified interface for persistent storage management
@MainActor
protocol SwiftDataContainer {
    
    // MARK: - Configuration
    
    /// Configuration type for the container
    associatedtype ContainerConfiguration
    
    // MARK: - CRUD Operations
    
    /// Fetch models matching the given descriptor
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T]
    
    /// Fetch all models of a given type
    func fetchAll<T: PersistentModel>(_ type: T.Type) throws -> [T]
    
    /// Fetch a single model by predicate
    func fetchOne<T: PersistentModel>(
        _ type: T.Type,
        where predicate: Predicate<T>
    ) throws -> T?
    
    /// Insert a new model
    func insert<T: PersistentModel>(_ model: T) throws
    
    /// Insert multiple models
    func insertBatch<T: PersistentModel>(_ models: [T]) throws
    
    /// Update an existing model
    func update<T: PersistentModel>(_ model: T) throws
    
    /// Delete a model
    func delete<T: PersistentModel>(_ model: T) throws
    
    /// Delete all models matching a predicate
    func deleteAll<T: PersistentModel>(
        _ type: T.Type,
        where predicate: Predicate<T>?
    ) throws
    
    /// Count models matching a predicate
    func count<T: PersistentModel>(
        _ type: T.Type,
        where predicate: Predicate<T>?
    ) throws -> Int
    
    // MARK: - Transaction Support
    
    /// Perform operations in a transaction
    func transaction<T>(_ block: @escaping () throws -> T) throws -> T
    
    // MARK: - Maintenance
    
    /// Clear all data (useful for testing)
    func clearAllData() throws
    
    /// Get storage statistics
    func getStatistics() throws -> StorageStatistics
}
