//
//  WeatherProtocolMapper.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Weather Protocol Mapper

/// Weather-specific protocol mapper implementation
final class WeatherProtocolMapper: ProtocolMapperImpl<ForecastModel, ForecastApiDTO, ForecastFileDTO>, ProtocolMapper {
    typealias DomainModel = ForecastModel
    typealias RemoteDTO = ForecastApiDTO
    typealias FileDTO = ForecastFileDTO
    
    // MARK: - Remote DTO to Domain
    
    override func mapToDomain(_ dto: ForecastApiDTO) -> ForecastModel {
        let city = CityModel(
            name: safeString(dto.city.name),
            country: safeString(dto.city.country)
        )
        
        let weatherItems = dto.list.compactMap { mapWeatherToDomain($0) }
        
        return ForecastModel(
            city: city,
            weatherItems: weatherItems,
            lastUpdated: Date()
        )
    }
    
    // MARK: - File DTO to Domain
    
    override func mapToDomain(_ dto: ForecastFileDTO) -> ForecastModel {
        let city = CityModel(
            name: safeString(dto.cityName),
            country: safeString(dto.country)
        )
        
        let weatherItems = dto.weatherItems.compactMap { mapWeatherFileToDomain($0) }
        let lastUpdated = safeDate(from: dto.lastUpdated)
        
        return ForecastModel(
            city: city,
            weatherItems: weatherItems,
            lastUpdated: lastUpdated
        )
    }
    
    // MARK: - Domain to File DTO
    
    override func mapToFileDTO(_ model: ForecastModel) -> ForecastFileDTO {
        let weatherFileDTOs = model.weatherItems.map { mapWeatherToFileDTO($0) }
        let lastUpdatedString = dateString(from: model.lastUpdated)
        
        return ForecastFileDTO(
            cityName: model.city.name,
            country: model.city.country,
            weatherItems: weatherFileDTOs,
            lastUpdated: lastUpdatedString
        )
    }
    
    // MARK: - Private Mapping Methods
    
    private func mapWeatherToDomain(_ dto: WeatherApiDTO) -> WeatherModel? {
        let dateTime = Date(timeIntervalSince1970: TimeInterval(dto.dt))
        
        let temperature = TemperatureModel(
            current: safeDouble(dto.main.temp),
            min: dto.main.temp_min,
            max: dto.main.temp_max,
            feelsLike: dto.main.feels_like
        )
        
        let weatherType = mapWeatherType(dto.weather.first?.main ?? "Unknown")
        let condition = WeatherConditionModel(
            type: weatherType,
            iconCode: dto.weather.first?.icon
        )
        
        let description = safeString(dto.weather.first?.description)
        
        return WeatherModel(
            dateTime: dateTime,
            temperature: temperature,
            condition: condition,
            description: description
        )
    }
    
    private func mapWeatherFileToDomain(_ dto: WeatherFileDTO) -> WeatherModel? {
        let dateTime = safeDate(from: dto.dateTime)
        
        let temperature = TemperatureModel(
            current: safeDouble(dto.temperature.current),
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
            description: safeString(dto.description)
        )
    }
    
    private func mapWeatherToFileDTO(_ model: WeatherModel) -> WeatherFileDTO {
        let dateTimeString = dateString(from: model.dateTime)
        
        let temperatureDTO = TemperatureFileDTO(
            current: model.temperature.current,
            min: model.temperature.min,
            max: model.temperature.max,
            feelsLike: model.temperature.feelsLike,
            unit: "celsius"
        )
        
        let conditionDTO = WeatherConditionFileDTO(
            type: model.condition.type.rawValue,
            iconCode: model.condition.iconCode
        )
        
        return WeatherFileDTO(
            dateTime: dateTimeString,
            temperature: temperatureDTO,
            condition: conditionDTO,
            description: model.description
        )
    }
    
    private func mapWeatherType(_ apiType: String) -> WeatherType {
        switch apiType.lowercased() {
        case "clear":
            return .sunny
        case "clouds":
            return .cloudy
        case "rain", "drizzle":
            return .rainy
        case "snow":
            return .snowy
        case "thunderstorm":
            return .stormy
        case "mist", "fog", "haze":
            return .foggy
        default:
            return .unknown
        }
    }
}
