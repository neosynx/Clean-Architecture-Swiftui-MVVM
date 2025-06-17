//
//  WeatherArchitectureExample.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//
/*
import Foundation

 // MARK: - Weather Architecture Example Usage

 /// Example showing how to use the new protocol composition architecture
 class WeatherArchitectureExample {

     // MARK: - Example 1: Full Service Configuration

     static func createFullWeatherRepository(logger: AppLoggerProtocol) -> WeatherRepository {
         let networkService = NetworkService(configuration: AppConfiguration(), loggerFactory: LoggerFactory.shared)

         // Create all services
         let remoteService = WeatherRemoteService(
             networkService: networkService,
             configuration: AppConfiguration(),
             logger: logger
         )

         let fileService = WeatherFileService(logger: logger)

         let cacheService = CacheServiceImpl<String, ForecastFileDTO>(
             expirationInterval: 600, // 10 minutes
             maxEntries: 50
         )

         // Repository auto-configures based on available services
         return WeatherRepositoryImpl(
             remoteService: remoteService,
             fileService: fileService,
             cacheService: cacheService,
             strategy: .cacheFirst,
             enableFallback: true,
             logger: logger
         )
     }

     // MARK: - Example 2: Cache-Only Configuration

     static func createCacheOnlyWeatherRepository(logger: AppLoggerProtocol) -> WeatherRepository {
         let cacheService = CacheServiceImpl<String, ForecastFileDTO>(
             expirationInterval: 300, // 5 minutes
             maxEntries: 20
         )

         // Only cache service provided - repository will auto-configure
         return WeatherRepositoryImpl(
             remoteService: nil,
             fileService: nil,
             cacheService: cacheService,
             strategy: .cacheFirst,
             enableFallback: false,
             logger: logger
         )
     }

     // MARK: - Example 3: File-Only Configuration (Offline Mode)

     static func createOfflineWeatherRepository(logger: AppLoggerProtocol) -> WeatherRepository {
         let fileService = WeatherFileService(logger: logger)
         let cacheService = CacheServiceImpl<String, ForecastFileDTO>()

         // File + cache for offline usage
         return WeatherRepositoryImpl(
             remoteService: nil,
             fileService: fileService,
             cacheService: cacheService,
             strategy: .cacheFirst,
             enableFallback: true,
             logger: logger
         )
     }

     // MARK: - Example 4: Usage Demonstration

     static func demonstrateUsage(logger: AppLoggerProtocol = LoggerFactory.shared.createLogger(category: "Demo")) async {
         logger.debug("🌦️ Weather Architecture Demo")
         logger.debug("============================")

         // Create repository with protocol composition
         let repository = createFullWeatherRepository(logger: logger)

         do {
             // Test fetching weather
             logger.debug("📍 Fetching weather for London...")
             let forecast = try await repository.fetchWeather(for: "London")
             logger.debug("✅ Success: Got weather for \(forecast.city.name)")
             logger.debug("🌡️ Current temp: \(forecast.weatherItems.first?.temperature.current ?? 0)°C")

             // Test caching
             logger.debug("\n💾 Testing cache...")
             if let cached = try await repository.getCachedWeather(for: "London") {
                 logger.debug("✅ Cache hit: Found cached data for \(cached.city.name)")
             } else {
                 logger.debug("❌ Cache miss: No cached data found")
             }

             // Test saving
             logger.debug("\n💾 Saving weather data...")
             try await repository.saveWeather(forecast)
             logger.debug("✅ Weather data saved successfully")

             // Test retrieving saved cities
             logger.debug("\n📋 Retrieving saved cities...")
             let savedCities = try await repository.getAllSavedCities()
             logger.debug("✅ Found \(savedCities.count) saved cities: \(savedCities.joined(separator: ", "))")

         } catch {
             logger.error("❌ Error: \(error.localizedDescription)")
         }
     }
 }

 // MARK: - Protocol Composition Benefits Demo

 extension WeatherArchitectureExample {

     /// Demonstrates how protocol composition enables flexible service configuration
     static func demonstrateProtocolComposition(logger: AppLoggerProtocol = LoggerFactory.shared.createLogger(category: "Demo")) {
         logger.debug("\n🔧 Protocol Composition Benefits")
         logger.debug("================================")

         // Example 1: Different service combinations
         let scenarios = [
             ("Full Stack", "Remote + File + Cache", createFullWeatherRepository(logger: logger)),
             ("Cache Only", "Memory Cache Only", createCacheOnlyWeatherRepository(logger: logger)),
             ("Offline Mode", "File + Cache", createOfflineWeatherRepository(logger: logger))
         ]

         for (name, description, repository) in scenarios {
             logger.debug("📋 \(name): \(description)")

             Task {
                 if let composedRepo = repository as? WeatherRepositoryComposed {
                     let health = await composedRepo.getHealthStatus()
                     logger.debug("   Health: \(health.description)")
                 }
             }
         }

         logger.debug("\n✨ Key Benefits:")
         logger.debug("• Generic base classes reduce code duplication")
         logger.debug("• Protocol composition enables flexible configurations")
         logger.debug("• Auto-configuration based on available services")
         logger.debug("• Elegant error handling with ServiceError")
         logger.debug("• Thread-safe caching with actor-based cache")
         logger.debug("• Type-safe mapping with generic protocol mapper")
     }
 }
*/
