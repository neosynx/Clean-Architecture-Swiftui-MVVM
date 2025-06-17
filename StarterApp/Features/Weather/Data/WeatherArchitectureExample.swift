//
//  WeatherArchitectureExample.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Weather Architecture Example Usage

/// Example showing how to use the new protocol composition architecture
class WeatherArchitectureExample {
    
    // MARK: - Example 1: Full Service Configuration
    
    static func createFullWeatherRepository() -> WeatherRepository {
        let networkService = NetworkService(configuration: AppConfiguration())
        
        // Create all services
        let remoteService = WeatherRemoteService(
            networkService: networkService,
            configuration: AppConfiguration()
        )
        
        let fileService = WeatherFileService()
        
        let cacheService = GenericCacheService<String, ForecastFileDTO>(
            expirationInterval: 600, // 10 minutes
            maxEntries: 50
        )
        
        // Repository auto-configures based on available services
        return WeatherRepositoryComposed(
            remoteService: remoteService,
            fileService: fileService,
            cacheService: cacheService,
            strategy: .cacheFirst,
            enableFallback: true
        )
    }
    
    // MARK: - Example 2: Cache-Only Configuration
    
    static func createCacheOnlyWeatherRepository() -> WeatherRepository {
        let cacheService = GenericCacheService<String, ForecastFileDTO>(
            expirationInterval: 300, // 5 minutes
            maxEntries: 20
        )
        
        // Only cache service provided - repository will auto-configure
        return WeatherRepositoryComposed(
            remoteService: nil,
            fileService: nil,
            cacheService: cacheService,
            strategy: .cacheOnly,
            enableFallback: false
        )
    }
    
    // MARK: - Example 3: File-Only Configuration (Offline Mode)
    
    static func createOfflineWeatherRepository() -> WeatherRepository {
        let fileService = WeatherFileService()
        let cacheService = GenericCacheService<String, ForecastFileDTO>()
        
        // File + cache for offline usage
        return WeatherRepositoryComposed(
            remoteService: nil,
            fileService: fileService,
            cacheService: cacheService,
            strategy: .fileFirst,
            enableFallback: true
        )
    }
    
    // MARK: - Example 4: Usage Demonstration
    
    static func demonstrateUsage() async {
        print("🌦️ Weather Architecture Demo")
        print("============================")
        
        // Create repository with protocol composition
        let repository = createFullWeatherRepository()
        
        do {
            // Test fetching weather
            print("📍 Fetching weather for London...")
            let forecast = try await repository.fetchWeather(for: "London")
            print("✅ Success: Got weather for \(forecast.city.name)")
            print("🌡️ Current temp: \(forecast.weatherItems.first?.temperature.current ?? 0)°C")
            
            // Test caching
            print("\n💾 Testing cache...")
            if let cached = try await repository.getCachedWeather(for: "London") {
                print("✅ Cache hit: Found cached data for \(cached.city.name)")
            } else {
                print("❌ Cache miss: No cached data found")
            }
            
            // Test saving
            print("\n💾 Saving weather data...")
            try await repository.saveWeather(forecast)
            print("✅ Weather data saved successfully")
            
            // Test retrieving saved cities
            print("\n📋 Retrieving saved cities...")
            let savedCities = try await repository.getAllSavedCities()
            print("✅ Found \(savedCities.count) saved cities: \(savedCities.joined(separator: ", "))")
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Protocol Composition Benefits Demo

extension WeatherArchitectureExample {
    
    /// Demonstrates how protocol composition enables flexible service configuration
    static func demonstrateProtocolComposition() {
        print("\n🔧 Protocol Composition Benefits")
        print("================================")
        
        // Example 1: Different service combinations
        let scenarios = [
            ("Full Stack", "Remote + File + Cache", createFullWeatherRepository()),
            ("Cache Only", "Memory Cache Only", createCacheOnlyWeatherRepository()),
            ("Offline Mode", "File + Cache", createOfflineWeatherRepository())
        ]
        
        for (name, description, repository) in scenarios {
            print("📋 \(name): \(description)")
            
            Task {
                if let composedRepo = repository as? WeatherRepositoryComposed {
                    let health = await composedRepo.getHealthStatus()
                    print("   Health: \(health.description)")
                }
            }
        }
        
        print("\n✨ Key Benefits:")
        print("• Generic base classes reduce code duplication")
        print("• Protocol composition enables flexible configurations")
        print("• Auto-configuration based on available services")
        print("• Elegant error handling with ServiceError")
        print("• Thread-safe caching with actor-based cache")
        print("• Type-safe mapping with generic protocol mapper")
    }
}