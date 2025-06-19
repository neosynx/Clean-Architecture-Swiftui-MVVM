//
//  WeatherDataAccessStrategy.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation
import codeartis_logging

// MARK: - Weather Data Access Strategy Protocol

/// Weather-specific data access strategy - bridges to generic protocol
protocol WeatherDataAccessStrategy: DataAccessStrategy where Key == String, Model == ForecastModel {
    // Only inherits the generic execute method from DataAccessStrategy
    // No additional weather-specific methods needed
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
        logger: CodeartisLogger
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
}

/// Weather-specific persistence-first strategy using generic implementation
struct WeatherPersistenceFirstStrategy: WeatherDataAccessStrategy {
    private let genericStrategy: PersistenceFirstStrategy<String, ForecastModel> = PersistenceFirstStrategy()
    
    func execute<C, P, R>(
        for key: String,
        cache: C,
        persistence: P,
        remote: R?,
        logger: CodeartisLogger
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
}

/// Weather-specific network-first strategy using generic implementation
struct WeatherNetworkFirstStrategy: WeatherDataAccessStrategy {
    private let genericStrategy: NetworkFirstStrategy<String, ForecastModel> = NetworkFirstStrategy()
    
    func execute<C, P, R>(
        for key: String,
        cache: C,
        persistence: P,
        remote: R?,
        logger: CodeartisLogger
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
