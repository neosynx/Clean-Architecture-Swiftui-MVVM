//
//  WeatherDomainMapper.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Domain Mappers (DTO -> Domain Models)

public struct WeatherDomainMapper {
    
    // MARK: - API DTO to Domain
    
    public static func mapToDomain(_ dto: ForecastApiDTO) -> ForecastModel {
        let city = CityModel(
            name: dto.city.name,
            country: dto.city.country
        )
        
        let weatherItems = dto.list.map { mapToDomain($0) }
        
        return ForecastModel(
            city: city,
            weatherItems: weatherItems,
            lastUpdated: Date()
        )
    }
    
    public static func mapToDomain(_ dto: WeatherApiDTO) -> WeatherModel {
        let dateTime = Date(timeIntervalSince1970: TimeInterval(dto.dt))
        
        let temperature = TemperatureModel(
            current: dto.main.temp,
            min: dto.main.temp_min,
            max: dto.main.temp_max,
            feelsLike: dto.main.feels_like
        )
        
        let weatherType = mapWeatherType(dto.weather.first?.main ?? "Unknown")
        let condition = WeatherConditionModel(
            type: weatherType,
            iconCode: dto.weather.first?.icon
        )
        
        let description = dto.weather.first?.description ?? "No description"
        
        return WeatherModel(
            dateTime: dateTime,
            temperature: temperature,
            condition: condition,
            description: description
        )
    }
    
    // MARK: - File DTO to Domain
    
    public static func mapToDomain(_ dto: ForecastFileDTO) -> ForecastModel {
        let city = CityModel(
            name: dto.cityName,
            country: dto.country
        )
        
        let weatherItems = dto.weatherItems.compactMap { mapToDomain($0) }
        
        let lastUpdated = ISO8601DateFormatter().date(from: dto.lastUpdated) ?? Date()
        
        return ForecastModel(
            city: city,
            weatherItems: weatherItems,
            lastUpdated: lastUpdated
        )
    }
    
    public static func mapToDomain(_ dto: WeatherFileDTO) -> WeatherModel? {
        guard let dateTime = ISO8601DateFormatter().date(from: dto.dateTime) else {
            return nil
        }
        
        let temperature = TemperatureModel(
            current: dto.temperature.current,
            min: dto.temperature.min,
            max: dto.temperature.max,
            feelsLike: dto.temperature.feelsLike
        )
        
        let weatherType = mapWeatherType(dto.condition.type)
        let condition = WeatherConditionModel(
            type: weatherType,
            iconCode: dto.condition.iconCode
        )
        
        return WeatherModel(
            dateTime: dateTime,
            temperature: temperature,
            condition: condition,
            description: dto.description
        )
    }
    
    // MARK: - Domain to File DTO
    
    public static func mapToFileDTO(_ forecast: ForecastModel) -> ForecastFileDTO {
        let weatherItems = forecast.weatherItems.map { mapToFileDTO($0) }
        let lastUpdatedString = ISO8601DateFormatter().string(from: forecast.lastUpdated)
        
        return ForecastFileDTO(
            cityName: forecast.city.name,
            country: forecast.city.country,
            weatherItems: weatherItems,
            lastUpdated: lastUpdatedString
        )
    }
    
    public static func mapToFileDTO(_ weather: WeatherModel) -> WeatherFileDTO {
        let dateTimeString = ISO8601DateFormatter().string(from: weather.dateTime)
        
        let temperatureDTO = TemperatureFileDTO(
            current: weather.temperature.current,
            min: weather.temperature.min,
            max: weather.temperature.max,
            feelsLike: weather.temperature.feelsLike
        )
        
        let conditionDTO = WeatherConditionFileDTO(
            type: weather.condition.type.rawValue,
            iconCode: weather.condition.iconCode
        )
        
        return WeatherFileDTO(
            dateTime: dateTimeString,
            temperature: temperatureDTO,
            condition: conditionDTO,
            description: weather.description
        )
    }
    
    // MARK: - Helper Methods
    
    private static func mapWeatherType(_ apiType: String) -> WeatherType {
        switch apiType.lowercased() {
        case "clear": return .sunny
        case "clouds": return .cloudy
        case "rain", "drizzle": return .rainy
        case "snow": return .snowy
        case "thunderstorm": return .stormy
        case "mist", "fog", "haze": return .foggy
        default: return .unknown
        }
    }
}
