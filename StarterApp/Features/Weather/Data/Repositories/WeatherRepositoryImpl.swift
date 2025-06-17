//
//  WeatherRepositoryComposed.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Weather Repository with Protocol Composition

/// Weather repository that auto-configures based on available services
final class WeatherRepositoryImpl: WeatherRepository {
    
    // MARK: - Service Composition
    
    private let remoteService: WeatherRemoteService?
    private let fileService: WeatherFileService?
    private let cacheService: CacheServiceImpl<String, ForecastFileDTO>
    private let mapper: WeatherProtocolMapper
    private let logger: AppLogger
    
    // MARK: - Configuration
    
    private let strategy: DataStrategy
    private let enableFallback: Bool
    
    // MARK: - Data Strategy
    
    enum DataStrategy {
        case cacheFirst
    }
    
    // MARK: - Initialization
    
    init(
        remoteService: WeatherRemoteService? = nil,
        fileService: WeatherFileService? = nil,
        cacheService: CacheServiceImpl<String, ForecastFileDTO>? = nil,
        mapper: WeatherProtocolMapper = WeatherProtocolMapper(),
        strategy: DataStrategy = .cacheFirst,
        enableFallback: Bool = true,
        logger: AppLogger
    ) {
        self.remoteService = remoteService
        self.fileService = fileService
        self.cacheService = cacheService ?? CacheServiceImpl<String, ForecastFileDTO>()
        self.mapper = mapper
        self.strategy = strategy
        self.enableFallback = enableFallback
        self.logger = logger
    }
    
    // MARK: - WeatherRepository Protocol
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        switch strategy {
        case .cacheFirst:
            return try await fetchWithCacheFirst(for: city)
        }
    }
    
    func saveWeather(_ forecast: ForecastModel) async throws {
        logger.info("💾 Repository.saveWeather starting for city: \(forecast.city.name)")
        
        do {
            logger.debug("💾 Repository.saveWeather: Mapping domain to file DTO...")
            let fileDTO = mapper.mapToFileDTO(forecast)
            let city = forecast.city.name
            logger.debug("💾 Repository.saveWeather: File DTO mapping successful")
            
            // Save to cache
            logger.debug("💾 Repository.saveWeather: Saving to cache...")
            try await cacheService.set(fileDTO, for: city)
            logger.debug("💾 Repository.saveWeather: Cache save successful")
            
            // Save to file if available
           /* if let fileService = fileService {
                logger.debug("💾 Repository.saveWeather: Saving to file service...")
                try await fileService.saveForecast(fileDTO, for: city)
                logger.debug("💾 Repository.saveWeather: File save successful")
            } else {
                logger.warning("💾 Repository.saveWeather: File service not available, skipping file save")
            }*/
            
            //print("💾 Repository.saveWeather: Completed successfully")
        } catch {
            logger.error("💾 Repository.saveWeather: Error occurred:")
            logger.error("   🏷️ Error type: \(type(of: error))")
            logger.error("   📝 Error: \(error.localizedDescription)")
            logger.error("   🔍 Full error: \(error)")
            throw error
        }
    }
    
    func deleteWeather(for city: String) async throws {
        // Remove from cache
        try await cacheService.remove(for: city)
        
        // Remove from file if available
        if let fileService = fileService {
            try await fileService.deleteForecast(for: city)
        }
    }
    
    func getAllSavedCities() async throws -> [String] {
        if let fileService = fileService {
            return try await fileService.getAllKeys()
        }
        return []
    }
    
    func getCachedWeather(for city: String) async throws -> ForecastModel? {
        do {
            if let fileDTO = try await cacheService.get(for: city) {
                return mapper.mapToDomain(fileDTO)
            }
        } catch ServiceError.cacheExpired {
            // Cache expired, return nil to trigger refresh
            return nil
        }
        return nil
    }
    
    func clearCache() async throws {
        try await cacheService.clear()
    }
    
    func refreshWeather(for city: String) async throws -> ForecastModel {
        logger.info("🔄 Repository.refreshWeather starting for city: \(city)")
        
        guard let remoteService = remoteService else {
            logger.error("🔄 Repository.refreshWeather: Remote service is nil!")
            throw ServiceError.serviceUnavailable
        }
        logger.debug("🔄 Repository.refreshWeather: Remote service available")
        
        do {
            logger.debug("🔄 Repository.refreshWeather: Fetching from remote service...")
            let apiDTO = try await remoteService.fetch(for: city)
            logger.debug("🔄 Repository.refreshWeather: Remote fetch successful, received DTO")
            
            logger.debug("🔄 Repository.refreshWeather: Mapping DTO to domain model...")
            let domainModel = mapper.mapToDomain(apiDTO)
            logger.debug("🔄 Repository.refreshWeather: Domain mapping successful")
            
            logger.debug("🔄 Repository.refreshWeather: Saving weather data...")
            try await saveWeather(domainModel)
            logger.debug("🔄 Repository.refreshWeather: Save successful")
            
            logger.info("🔄 Repository.refreshWeather: Completed successfully")
            return domainModel
        } catch {
            logger.error("🔄 Repository.refreshWeather: Error occurred:")
            logger.error("   🏷️ Error type: \(type(of: error))")
            logger.error("   📝 Error: \(error.localizedDescription)")
            logger.error("   🔍 Full error: \(error)")
            throw error
        }
    }
    
    func getWeatherWithFallback(for city: String) async throws -> ForecastModel {
        return try await fetchWithCacheFirst(for: city)
    }
    
    // MARK: - Strategy Implementations
    
    private func fetchWithCacheFirst(for city: String) async throws -> ForecastModel {
        // Try cache first
        if let cachedModel = try await getCachedWeather(for: city) {
            return cachedModel
        }
        
        // Try file next if available and fallback enabled
        if enableFallback, let fileService = fileService {
            do {
                let fileDTO = try await fileService.fetch(for: city)
                let domainModel = mapper.mapToDomain(fileDTO)
                
                // Update cache
                try await cacheService.set(fileDTO, for: city)
                
                return domainModel
            } catch {
                // Continue to remote if file fails
            }
        }
        
        // Finally try remote if available and fallback enabled
        if enableFallback, let remoteService = remoteService {
            do {
                logger.debug("🏗️ Repository: Attempting remote service fetch...")
                let result = try await refreshWeather(for: city)
                logger.debug("🏗️ Repository: Remote service fetch successful")
                return result
            } catch {
                logger.error("🏗️ Repository: Remote service failed:")
                logger.error("   🏷️ Error type: \(type(of: error))")
                logger.error("   📝 Error: \(error.localizedDescription)")
                logger.error("   🔍 Full error: \(error)")
                throw error
            }
        }
        
        throw ServiceError.notFound
    }
    
 
}

// MARK: - Weather Repository Health

struct WeatherRepositoryHealth {
    let cacheHealthy: Bool
    let fileServiceHealthy: Bool
    let remoteServiceHealthy: Bool
    let cacheStatistics: CacheStatistics

    var description: String {
        var status: [String] = []
        if cacheHealthy { status.append("Cache ✅") } else { status.append("Cache ❌") }
        if fileServiceHealthy { status.append("File ✅") } else { status.append("File ❌") }
        if remoteServiceHealthy { status.append("Remote ✅") } else { status.append("Remote ❌") }
        return status.joined(separator: " ")
    }
}
