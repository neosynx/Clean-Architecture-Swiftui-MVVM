//
//  WeatherMemoryCacheDataSource.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

class WeatherMemoryCacheDataSource: WeatherCacheDataSource {
    private actor CacheActor {
        private var cache: [String: CachedWeather] = [:]
        private let cacheExpirationTime: TimeInterval
        
        init(cacheExpirationTime: TimeInterval = 300) { // 5 minutes default
            self.cacheExpirationTime = cacheExpirationTime
        }
        
        func get(for city: String) -> CachedWeather? {
            return cache[city.lowercased()]
        }
        
        func set(_ forecast: ForecastModel, for city: String) {
            cache[city.lowercased()] = CachedWeather(
                forecast: forecast,
                timestamp: Date()
            )
        }
        
        func remove(for city: String) {
            cache.removeValue(forKey: city.lowercased())
        }
        
        func clear() {
            cache.removeAll()
        }
        
        func isExpired(for city: String) -> Bool {
            guard let cachedWeather = cache[city.lowercased()] else {
                return true
            }
            
            let timeElapsed = Date().timeIntervalSince(cachedWeather.timestamp)
            return timeElapsed > cacheExpirationTime
        }
        
        func cleanExpiredEntries() {
            let now = Date()
            cache = cache.filter { _, cachedWeather in
                let timeElapsed = now.timeIntervalSince(cachedWeather.timestamp)
                return timeElapsed <= cacheExpirationTime
            }
        }
    }
    
    private struct CachedWeather {
        let forecast: ForecastModel
        let timestamp: Date
    }
    
    private let cacheActor: CacheActor
    
    init(cacheExpirationTime: TimeInterval = 300) {
        self.cacheActor = CacheActor(cacheExpirationTime: cacheExpirationTime)
    }
    
    func getCachedWeather(for city: String) async throws -> ForecastModel? {
        let cachedWeather = await cacheActor.get(for: city)
        
        guard let cachedWeather = cachedWeather else {
            return nil
        }
        
        let isExpired = await cacheActor.isExpired(for: city)
        if isExpired {
            await cacheActor.remove(for: city)
            return nil
        }
        
        return cachedWeather.forecast
    }
    
    func cacheWeather(_ forecast: ForecastModel) async throws {
        await cacheActor.set(forecast, for: forecast.city.name)
    }
    
    func clearCache() async throws {
        await cacheActor.clear()
    }
    
    func isExpired(for city: String) async -> Bool {
        return await cacheActor.isExpired(for: city)
    }
    
    func cleanExpiredEntries() async {
        await cacheActor.cleanExpiredEntries()
    }
}