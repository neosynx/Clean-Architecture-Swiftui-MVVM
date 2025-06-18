//
//  BaseRepositoryImpl.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Deprecated Base Repository Implementation

/// Legacy base repository - use specific implementations instead
/// This exists only for build compatibility
@available(*, deprecated, message: "Use specific repository implementations like WeatherRepositoryImpl instead")
open class BaseRepositoryImpl<Key: Hashable, Model, IdentifierType: Hashable, CacheService, PersistenceService, RemoteService> {
    
    // MARK: - Properties (Deprecated)
    
    let cacheService: CacheService
    let persistenceService: PersistenceService
    let remoteService: RemoteService?
    let mapper: any ProtocolMapper
    let logger: AppLogger
    
    // MARK: - Initialization (Deprecated)
    
    init(
        cacheService: CacheService,
        persistenceService: PersistenceService,
        remoteService: RemoteService? = nil,
        mapper: any ProtocolMapper,
        logger: AppLogger
    ) {
        self.cacheService = cacheService
        self.persistenceService = persistenceService
        self.remoteService = remoteService
        self.mapper = mapper
        self.logger = logger
        
        logger.info("BaseRepository (deprecated) initialized")
    }
    
    // MARK: - Deprecated Methods
    
    @available(*, deprecated, message: "Use specific repository fetch methods instead")
    public func fetch(for key: Key) async throws -> Model {
        fatalError("BaseRepositoryImpl is deprecated. Use specific repository implementations.")
    }
}