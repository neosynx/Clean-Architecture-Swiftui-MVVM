//
//  WeatherFileDTO.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - File Storage DTOs (Simplified for Local Storage)

public struct ForecastFileDTO: Codable {
    public let cityName: String
    public let country: String
    public let weatherItems: [WeatherFileDTO]
    public let lastUpdated: String // ISO date string
    public let version: String
    
    public init(cityName: String, country: String, weatherItems: [WeatherFileDTO], lastUpdated: String, version: String = "1.0") {
        self.cityName = cityName
        self.country = country
        self.weatherItems = weatherItems
        self.lastUpdated = lastUpdated
        self.version = version
    }
}

public struct WeatherFileDTO: Codable {
    public let dateTime: String // ISO date string
    public let temperature: TemperatureFileDTO
    public let condition: WeatherConditionFileDTO
    public let description: String
    
    public init(dateTime: String, temperature: TemperatureFileDTO, condition: WeatherConditionFileDTO, description: String) {
        self.dateTime = dateTime
        self.temperature = temperature
        self.condition = condition
        self.description = description
    }
}

public struct TemperatureFileDTO: Codable {
    public let current: Double
    public let min: Double?
    public let max: Double?
    public let feelsLike: Double?
    public let unit: String // "celsius" or "fahrenheit"
    
    public init(current: Double, min: Double? = nil, max: Double? = nil, feelsLike: Double? = nil, unit: String = "celsius") {
        self.current = current
        self.min = min
        self.max = max
        self.feelsLike = feelsLike
        self.unit = unit
    }
}

public struct WeatherConditionFileDTO: Codable {
    public let type: String
    public let iconCode: String?
    
    public init(type: String, iconCode: String? = nil) {
        self.type = type
        self.iconCode = iconCode
    }
}