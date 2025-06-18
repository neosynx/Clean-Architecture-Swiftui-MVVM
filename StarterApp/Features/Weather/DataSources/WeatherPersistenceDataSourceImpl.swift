//
//  WeatherPersistenceDataSourceImpl.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation
import SwiftData

/// Weather persistence data source implementation using SwiftData
final class WeatherPersistenceDataSourceImpl: WeatherPersistenceDataSource {
    
    // MARK: - Properties
    
    private let persistenceService: SwiftDataContainer
    private let mapper: WeatherProtocolMapper
    private let logger: AppLogger
    
    // MARK: - Initialization
    
    init(
        persistenceService: SwiftDataContainer,
        mapper: WeatherProtocolMapper = WeatherProtocolMapper(),
        logger: AppLogger
    ) {
        self.persistenceService = persistenceService
        self.mapper = mapper
        self.logger = logger
    }
    
    // MARK: - WeatherPersistenceDataSource Protocol Implementation
    
    func fetch(for city: String) async throws -> ForecastModel? {
        logger.debug("🗄️ WeatherPersistenceDataSource.fetch for city: \(city)")
        
        let predicate = WeatherEntity.predicate(forCity: city)
        let descriptor = FetchDescriptor<WeatherEntity>(
            predicate: predicate,
            sortBy: WeatherEntity.sortByLastUpdated
        )
        
        let results = try await persistenceService.fetch(descriptor)
        
        guard let weatherEntity = results.first else {
            logger.debug("🗄️ WeatherPersistenceDataSource.fetch: No data found for city: \(city)")
            return nil
        }
        
        let domainModel = mapper.mapToDomain(weatherEntity)
        logger.debug("🗄️ WeatherPersistenceDataSource.fetch: Successfully mapped to domain model")
        return domainModel
    }
    
    func save(_ forecast: ForecastModel) async throws {
        logger.debug("🗄️ WeatherPersistenceDataSource.save for city: \(forecast.city.name)")
        
        let city = forecast.city.name
        
        // Check if entry exists and update or insert
        let existingEntity = try await fetchSwiftDataEntity(for: city)
        
        if let existing = existingEntity {
            logger.debug("🗄️ WeatherPersistenceDataSource.save: Updating existing entry")
            let updatedEntity = mapper.mapToSwiftDataEntity(forecast)
            
            // Update existing entry fields
            existing.temperatureCurrent = updatedEntity.temperatureCurrent
            existing.temperatureMin = updatedEntity.temperatureMin
            existing.temperatureMax = updatedEntity.temperatureMax
            existing.temperatureFeelsLike = updatedEntity.temperatureFeelsLike
            existing.weatherMain = updatedEntity.weatherMain
            existing.weatherDescription = updatedEntity.weatherDescription
            existing.weatherIcon = updatedEntity.weatherIcon
            existing.pressure = updatedEntity.pressure
            existing.humidity = updatedEntity.humidity
            existing.windSpeed = updatedEntity.windSpeed
            existing.cloudiness = updatedEntity.cloudiness
            existing.dataTimestamp = updatedEntity.dataTimestamp
            existing.lastUpdated = Date()
            
            try await persistenceService.update(existing)
        } else {
            logger.debug("🗄️ WeatherPersistenceDataSource.save: Inserting new entry")
            let swiftDataEntity = mapper.mapToSwiftDataEntity(forecast)
            try await persistenceService.insert(swiftDataEntity)
        }
        
        logger.debug("🗄️ WeatherPersistenceDataSource.save: Completed successfully")
    }
    
    func delete(for city: String) async throws {
        logger.debug("🗄️ WeatherPersistenceDataSource.delete for city: \(city)")
        
        if let swiftDataEntity = try await fetchSwiftDataEntity(for: city) {
            try await persistenceService.delete(swiftDataEntity)
            logger.debug("🗄️ WeatherPersistenceDataSource.delete: Successfully deleted")
        } else {
            logger.debug("🗄️ WeatherPersistenceDataSource.delete: No data found to delete")
        }
    }
    
    func getAllSavedCities() async throws -> [String] {
        logger.debug("🗄️ WeatherPersistenceDataSource.getAllSavedCities")
        
        let descriptor = FetchDescriptor<WeatherEntity>(
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        let allWeather = try await persistenceService.fetch(descriptor)
        let cities = Array(Set(allWeather.map { $0.cityName })).sorted()
        
        logger.debug("🗄️ WeatherPersistenceDataSource.getAllSavedCities: Found \(cities.count) cities")
        return cities
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchSwiftDataEntity(for city: String) async throws -> WeatherEntity? {
        let predicate = WeatherEntity.predicate(forCity: city)
        let descriptor = FetchDescriptor<WeatherEntity>(
            predicate: predicate,
            sortBy: WeatherEntity.sortByLastUpdated
        )
        
        let results = try await persistenceService.fetch(descriptor)
        return results.first
    }
}