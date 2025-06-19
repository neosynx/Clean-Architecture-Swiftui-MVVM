//
//  Container+Weather.swift
//  StarterApp
//
//  Weather feature dependencies using Factory DI
//

import Foundation
import FactoryKit

// MARK: - Weather Feature Dependencies

extension Container {
    
    // MARK: - Configuration
    
    var weatherRepositoryConfiguration: Factory<WeatherRepositoryConfiguration> {
        self {
            let environment = self.appEnvironment()
            switch environment {
            case .development:
                return .development
            case .staging:
                return .default
            case .production:
                return .production
            }
        }
        .cached
    }
    
    // MARK: - Mappers
    
    var weatherProtocolMapper: Factory<WeatherProtocolMapper> {
        self { WeatherProtocolMapperImpl() }
            .cached
    }
    
    // MARK: - Remote Services
    
    var weatherRemoteService: Factory<WeatherRemoteService> {
        self {
            WeatherRemoteServiceImpl(
                networkService: self.networkService(),
                configuration: self.appConfiguration(),
                logger: self.weatherLogger()
            )
        }
        .cached
    }
    
    // MARK: - Data Sources
    
    var weatherCacheDataSource: Factory<WeatherCacheDataSource> {
        self {
            let configuration = self.weatherRepositoryConfiguration()
            return WeatherCacheDataSourceImpl(
                countLimit: configuration.cache.countLimit,
                totalCostLimit: configuration.cache.totalCostLimit,
                expirationInterval: configuration.cache.expirationInterval,
                logger: self.weatherLogger()
            )
        }
        .cached
    }
    
    var weatherPersistenceDataSource: Factory<WeatherPersistenceDataSource> {
        self {
            WeatherPersistenceDataSourceImpl(
                persistenceService: self.swiftDataContainer(),
                mapper: self.weatherProtocolMapper(),
                logger: self.weatherLogger()
            )
        }
        .cached
    }
    
    var weatherRemoteDataSource: Factory<WeatherRemoteDataSource> {
        self {
            WeatherRemoteDataSourceImpl(
                remoteService: self.weatherRemoteService(),
                mapper: self.weatherProtocolMapper(),
                logger: self.weatherLogger()
            )
        }
        .cached
    }
    
    // MARK: - Health Service
    
    var weatherRepositoryHealthService: Factory<WeatherRepositoryHealthService> {
        self {
            WeatherRepositoryHealthServiceImpl(
                cacheDataSource: self.weatherCacheDataSource(),
                persistenceDataSource: self.weatherPersistenceDataSource(),
                remoteDataSource: self.weatherRemoteDataSource(),
                configuration: self.weatherRepositoryConfiguration(),
                logger: self.weatherLogger()
            )
        }
        .cached
    }
    
    // MARK: - Repository
    
    var weatherRepository: Factory<WeatherRepository> {
        self {
            let configuration = self.weatherRepositoryConfiguration()
            return WeatherRepositoryImpl(
                swiftDataContainer: self.swiftDataContainer(),
                remoteService: self.weatherRemoteService(),
                mapper: self.weatherProtocolMapper(),
                strategyType: configuration.strategy.type,
                logger: self.weatherLogger(),
                secureStorage: self.secureStorageService()
            )
        }
        .cached
    }
    
    // MARK: - Store (Shared Business Logic)
    
    var weatherStore: Factory<WeatherStore> {
        self {
            WeatherStore(
                weatherRepository: self.weatherRepository(),
                logger: self.weatherLogger()
            )
        }
        .cached // Cached for sharing across views
    }
}
