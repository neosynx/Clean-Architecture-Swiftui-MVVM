//
//  WeatherSwiftDataDTO.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation
import SwiftData

/// SwiftData model for persisting weather data
/// This is a DTO in the Data layer - never expose to UI or Stores
@Model
final class WeatherEntity {
    
    // MARK: - Properties
    
    /// Unique identifier
    @Attribute(.unique) var id: UUID
    
    /// City information
    var cityId: Int
    var cityName: String
    var country: String
    var timezone: Int
    
    /// Temperature data
    var temperatureCurrent: Double
    var temperatureMin: Double
    var temperatureMax: Double
    var temperatureFeelsLike: Double
    
    /// Weather conditions
    var weatherMain: String
    var weatherDescription: String
    var weatherIcon: String
    
    /// Atmospheric conditions
    var pressure: Int
    var humidity: Int
    var visibility: Int?
    
    /// Wind data
    var windSpeed: Double
    var windDegree: Int?
    var windGust: Double?
    
    /// Cloud coverage
    var cloudiness: Int
    
    /// Timestamps
    var dataTimestamp: Date
    var sunriseTime: Date?
    var sunsetTime: Date?
    
    /// Metadata
    var lastUpdated: Date
    var dataSource: String // "api" or "manual"
    
    // MARK: - Relationships
    
    /// Future: Could add relationships to hourly/daily forecasts
    // @Relationship(deleteRule: .cascade) var hourlyForecasts: [HourlyForecastDTO]?
    // @Relationship(deleteRule: .cascade) var dailyForecasts: [DailyForecastDTO]?
    
    // MARK: - Initialization
    
    init(
        cityId: Int,
        cityName: String,
        country: String = "",
        timezone: Int = 0,
        temperatureCurrent: Double,
        temperatureMin: Double,
        temperatureMax: Double,
        temperatureFeelsLike: Double,
        weatherMain: String,
        weatherDescription: String,
        weatherIcon: String,
        pressure: Int,
        humidity: Int,
        visibility: Int? = nil,
        windSpeed: Double,
        windDegree: Int? = nil,
        windGust: Double? = nil,
        cloudiness: Int,
        dataTimestamp: Date,
        sunriseTime: Date? = nil,
        sunsetTime: Date? = nil,
        dataSource: String = "api"
    ) {
        self.id = UUID()
        self.cityId = cityId
        self.cityName = cityName
        self.country = country
        self.timezone = timezone
        self.temperatureCurrent = temperatureCurrent
        self.temperatureMin = temperatureMin
        self.temperatureMax = temperatureMax
        self.temperatureFeelsLike = temperatureFeelsLike
        self.weatherMain = weatherMain
        self.weatherDescription = weatherDescription
        self.weatherIcon = weatherIcon
        self.pressure = pressure
        self.humidity = humidity
        self.visibility = visibility
        self.windSpeed = windSpeed
        self.windDegree = windDegree
        self.windGust = windGust
        self.cloudiness = cloudiness
        self.dataTimestamp = dataTimestamp
        self.sunriseTime = sunriseTime
        self.sunsetTime = sunsetTime
        self.lastUpdated = Date()
        self.dataSource = dataSource
    }
}

// MARK: - Convenience Methods

extension WeatherEntity {
    /// Check if the data is stale (older than 1 hour)
    var isStale: Bool {
        lastUpdated.timeIntervalSinceNow < -3600
    }
    
    /// Get a unique key for caching
    var cacheKey: String {
        cityName.lowercased().replacingOccurrences(of: " ", with: "_")
    }
    
    /// Create a copy with updated timestamp
    func refreshedCopy() -> WeatherEntity {
        let copy = WeatherEntity(
            cityId: cityId,
            cityName: cityName,
            country: country,
            timezone: timezone,
            temperatureCurrent: temperatureCurrent,
            temperatureMin: temperatureMin,
            temperatureMax: temperatureMax,
            temperatureFeelsLike: temperatureFeelsLike,
            weatherMain: weatherMain,
            weatherDescription: weatherDescription,
            weatherIcon: weatherIcon,
            pressure: pressure,
            humidity: humidity,
            visibility: visibility,
            windSpeed: windSpeed,
            windDegree: windDegree,
            windGust: windGust,
            cloudiness: cloudiness,
            dataTimestamp: dataTimestamp,
            sunriseTime: sunriseTime,
            sunsetTime: sunsetTime,
            dataSource: dataSource
        )
        copy.id = self.id // Preserve ID
        copy.lastUpdated = Date() // Update timestamp
        return copy
    }
}

// MARK: - Query Helpers

extension WeatherEntity {
    /// Predicate to find weather by city name
    static func predicate(forCity cityName: String) -> Predicate<WeatherEntity> {
        #Predicate<WeatherEntity> { weather in
            weather.cityName.localizedStandardContains(cityName)
        }
    }
    
    /// Predicate to find stale weather data
    static func staleDataPredicate(olderThan hours: Int = 1) -> Predicate<WeatherEntity> {
        let cutoffDate = Date().addingTimeInterval(-Double(hours) * 3600)
        return #Predicate<WeatherEntity> { weather in
            weather.lastUpdated < cutoffDate
        }
    }
    
    /// Sort descriptor for most recent first
    static var sortByLastUpdated: [SortDescriptor<WeatherEntity>] {
        [SortDescriptor(\.lastUpdated, order: .reverse)]
    }
}

// MARK: - Migration Support

// Note: File DTO mapping is handled in WeatherProtocolMapper
// to maintain clean architecture separation
