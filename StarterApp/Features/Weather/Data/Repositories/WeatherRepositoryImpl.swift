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
        enableFallback: Bool = true
    ) {
        self.remoteService = remoteService
        self.fileService = fileService
        self.cacheService = cacheService ?? CacheServiceImpl<String, ForecastFileDTO>()
        self.mapper = mapper
        self.strategy = strategy
        self.enableFallback = enableFallback
        
    }
    
    // MARK: - WeatherRepository Protocol
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        switch strategy {
        case .cacheFirst:
            return try await fetchWithCacheFirst(for: city)
        }
    }
    
    func saveWeather(_ forecast: ForecastModel) async throws {
        print("💾 Repository.saveWeather starting for city: \(forecast.city.name)")
        
        do {
            print("💾 Repository.saveWeather: Mapping domain to file DTO...")
            let fileDTO = mapper.mapToFileDTO(forecast)
            let city = forecast.city.name
            print("💾 Repository.saveWeather: File DTO mapping successful")
            
            // Save to cache
            print("💾 Repository.saveWeather: Saving to cache...")
            try await cacheService.set(fileDTO, for: city)
            print("💾 Repository.saveWeather: Cache save successful")
            
            // Save to file if available
           /* if let fileService = fileService {
                print("💾 Repository.saveWeather: Saving to file service...")
                try await fileService.saveForecast(fileDTO, for: city)
                print("💾 Repository.saveWeather: File save successful")
            } else {
                print("💾 Repository.saveWeather: File service not available, skipping file save")
            }*/
            
            //print("💾 Repository.saveWeather: Completed successfully")
        } catch {
            print("💾 Repository.saveWeather: Error occurred:")
            print("   🏷️ Error type: \(type(of: error))")
            print("   📝 Error: \(error.localizedDescription)")
            print("   🔍 Full error: \(error)")
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
        print("🔄 Repository.refreshWeather starting for city: \(city)")
        
        guard let remoteService = remoteService else {
            print("🔄 Repository.refreshWeather: Remote service is nil!")
            throw ServiceError.serviceUnavailable
        }
        print("🔄 Repository.refreshWeather: Remote service available")
        
        do {
            print("🔄 Repository.refreshWeather: Fetching from remote service...")
            let apiDTO = try await remoteService.fetch(for: city)
            print("🔄 Repository.refreshWeather: Remote fetch successful, received DTO")
            
            print("🔄 Repository.refreshWeather: Mapping DTO to domain model...")
            let domainModel = mapper.mapToDomain(apiDTO)
            print("🔄 Repository.refreshWeather: Domain mapping successful")
            
            print("🔄 Repository.refreshWeather: Saving weather data...")
            try await saveWeather(domainModel)
            print("🔄 Repository.refreshWeather: Save successful")
            
            print("🔄 Repository.refreshWeather: Completed successfully")
            return domainModel
        } catch {
            print("🔄 Repository.refreshWeather: Error occurred:")
            print("   🏷️ Error type: \(type(of: error))")
            print("   📝 Error: \(error.localizedDescription)")
            print("   🔍 Full error: \(error)")
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
                print("🏗️ Repository: Attempting remote service fetch...")
                let result = try await refreshWeather(for: city)
                print("🏗️ Repository: Remote service fetch successful")
                return result
            } catch {
                print("🏗️ Repository: Remote service failed:")
                print("   🏷️ Error type: \(type(of: error))")
                print("   📝 Error: \(error.localizedDescription)")
                print("   🔍 Full error: \(error)")
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
