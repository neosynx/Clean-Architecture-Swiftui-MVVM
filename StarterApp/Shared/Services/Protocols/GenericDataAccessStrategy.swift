//
//  GenericDataAccessStrategy.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Generic Data Access Strategy Protocol

/// Generic protocol for data access strategies
/// Defines how data is retrieved using different fallback chains
/// Can be specialized for any feature (Weather, Finance, etc.)
protocol DataAccessStrategy {
    associatedtype Key: Hashable
    associatedtype Model
    
    /// Execute the data access strategy with type-safe dependencies
    /// - Parameters:
    ///   - key: The key to fetch data for
    ///   - cache: Cache data source for fast memory access
    ///   - persistence: Persistence data source for local storage
    ///   - remote: Remote data source for network data
    ///   - logger: Logger for debugging and monitoring
    /// - Returns: The retrieved model
    func execute<C, P, R>(
        for key: Key,
        cache: C,
        persistence: P,
        remote: R?,
        logger: AppLogger
    ) async throws -> Model
    where C: CacheDataSource, P: PersistenceDataSource, R: RemoteDataSource,
          C.Key == Key, P.Key == Key, R.Key == Key,
          C.Model == Model, P.Model == Model, R.Model == Model
}