//
//  WeatherRemoteDataSourceImpl.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

/// Weather remote data source implementation using WeatherRemoteService
final class WeatherRemoteDataSourceImpl: WeatherRemoteDataSource {
    
    // MARK: - Properties
    
    private let remoteService: WeatherRemoteService
    private let mapper: WeatherProtocolMapper
    private let logger: AppLogger
    
    // MARK: - Initialization
    
    init(
        remoteService: WeatherRemoteService,
        mapper: WeatherProtocolMapper,
        logger: AppLogger
    ) {
        self.remoteService = remoteService
        self.mapper = mapper
        self.logger = logger
    }
    
    // MARK: - WeatherRemoteDataSource Protocol Implementation
    
    func fetch(for city: String) async throws -> ForecastModel {
        logger.debug("☁️ WeatherRemoteDataSource.fetch for city: \(city)")
        
        let apiDTO = try await remoteService.fetch(for: city)
        let domainModel = mapper.mapToDomain(apiDTO)
        
        logger.debug("☁️ WeatherRemoteDataSource.fetch: Successfully mapped to domain model")
        return domainModel
    }
    
    var isAvailable: Bool {
        // Could check network connectivity, API key availability, etc.
        // For now, assume always available
        return true
    }
}