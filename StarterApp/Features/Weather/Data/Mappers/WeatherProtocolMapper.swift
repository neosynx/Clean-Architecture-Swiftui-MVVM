//
//  WeatherProtocolMapper.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Weather Protocol Mapper

/// Weather-specific protocol mapper implementation
/// Extended to support SwiftData DTOs for modern iOS 17+ persistence
final class WeatherProtocolMapper: ProtocolMapperImpl<ForecastModel, ForecastApiDTO>, ProtocolMapper {
    typealias DomainModel = ForecastModel
    typealias RemoteDTO = ForecastApiDTO
    typealias DataEntity = WeatherEntity
    
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
    
    // MARK: - SwiftData DTO Mapping
    
    /// Convert SwiftData DTO to Domain Model
    func mapToDomain(_ dto: WeatherEntity) -> ForecastModel {
        let city = CityModel(
            name: dto.cityName,
            country: dto.country
        )
        
        let temperature = TemperatureModel(
            current: dto.temperatureCurrent,
            min: dto.temperatureMin,
            max: dto.temperatureMax,
            feelsLike: dto.temperatureFeelsLike
        )
        
        let weatherType = mapWeatherType(dto.weatherMain)
        let condition = WeatherConditionModel(
            type: weatherType,
            iconCode: dto.weatherIcon
        )
        
        let weather = WeatherModel(
            dateTime: dto.dataTimestamp,
            temperature: temperature,
            condition: condition,
            description: dto.weatherDescription
        )
        
        return ForecastModel(
            city: city,
            weatherItems: [weather], // Single weather item from current data
            lastUpdated: dto.lastUpdated
        )
    }
    
    /// Convert Domain Model to SwiftData DTO
    func mapToSwiftDataEntity(_ model: ForecastModel) -> WeatherEntity {
        // Use the first weather item or create a default
        let weather = model.weatherItems.first ?? createDefaultWeather()
        
        return WeatherEntity(
            cityId: generateCityId(from: model.city.name),
            cityName: model.city.name,
            country: model.city.country,
            timezone: 0, // Default, could be enhanced
            temperatureCurrent: weather.temperature.current,
            temperatureMin: weather.temperature.min ?? 0.0,
            temperatureMax: weather.temperature.max ?? 0.0,
            temperatureFeelsLike: weather.temperature.feelsLike ?? 0.0,
            weatherMain: weather.condition.type.rawValue.capitalized,
            weatherDescription: weather.description,
            weatherIcon: weather.condition.iconCode ?? "01d",
            pressure: 1013, // Default atmospheric pressure
            humidity: 50, // Default humidity
            visibility: 10000, // Default visibility in meters
            windSpeed: 0.0, // Default wind speed
            windDegree: nil,
            windGust: nil,
            cloudiness: 0, // Default cloudiness
            dataTimestamp: weather.dateTime,
            sunriseTime: nil, // Could be enhanced
            sunsetTime: nil, // Could be enhanced
            dataSource: "domain_mapping"
        )
    }
    
    /// Convert API DTO to SwiftData DTO (for direct persistence)
    func mapApiToSwiftDataDTO(_ apiDTO: ForecastApiDTO) -> [WeatherEntity] {
        return apiDTO.list.compactMap { weatherApi in
            guard let firstWeather = weatherApi.weather.first else { 
                // Return default weather data instead of nil
                return WeatherEntity(
                    cityId: apiDTO.city.id ?? 0,
                    cityName: apiDTO.city.name,
                    country: apiDTO.city.country,
                    timezone: apiDTO.city.timezone ?? 0,
                    temperatureCurrent: 0.0,
                    temperatureMin: 0.0,
                    temperatureMax: 0.0,
                    temperatureFeelsLike: 0.0,
                    weatherMain: "Unknown",
                    weatherDescription: "No weather data",
                    weatherIcon: "01d",
                    pressure: 1013,
                    humidity: 50,
                    visibility: 10000,
                    windSpeed: 0.0,
                    windDegree: nil,
                    windGust: nil,
                    cloudiness: 0,
                    dataTimestamp: Date(timeIntervalSince1970: TimeInterval(weatherApi.dt)),
                    sunriseTime: nil,
                    sunsetTime: nil,
                    dataSource: "api_fallback"
                )
            }
            
            return WeatherEntity(
                cityId: apiDTO.city.id ?? 0,
                cityName: apiDTO.city.name,
                country: apiDTO.city.country,
                timezone: apiDTO.city.timezone ?? 0,
                temperatureCurrent: weatherApi.main.temp,
                temperatureMin: weatherApi.main.temp_min ?? 0.0,
                temperatureMax: weatherApi.main.temp_max ?? 0.0,
                temperatureFeelsLike: weatherApi.main.feels_like ?? 0.0,
                weatherMain: firstWeather.main,
                weatherDescription: firstWeather.description,
                weatherIcon: firstWeather.icon,
                pressure: weatherApi.main.pressure ?? 1013,
                humidity: weatherApi.main.humidity ?? 50,
                visibility: weatherApi.visibility ?? 10000,
                windSpeed: weatherApi.wind?.speed ?? 0.0,
                windDegree: weatherApi.wind?.deg,
                windGust: weatherApi.wind?.gust,
                cloudiness: weatherApi.clouds?.all ?? 0,
                dataTimestamp: Date(timeIntervalSince1970: TimeInterval(weatherApi.dt)),
                sunriseTime: nil, // Not available in current API DTO
                sunsetTime: nil, // Not available in current API DTO
                dataSource: "api"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDefaultWeather() -> WeatherModel {
        WeatherModel(
            dateTime: Date(),
            temperature: TemperatureModel(
                current: 20.0,
                min: 15.0,
                max: 25.0,
                feelsLike: 22.0
            ),
            condition: WeatherConditionModel(
                type: .unknown,
                iconCode: "01d"
            ),
            description: "No weather data available"
        )
    }
    
    private func generateCityId(from cityName: String) -> Int {
        // Simple hash-based ID generation
        // In production, you'd want proper city IDs from the API
        abs(cityName.hashValue) % 10_000_000
    }
    
    // MARK: - Batch Mapping
    
    /// Convert multiple SwiftData DTOs to a single Domain Model (for forecast data)
    func mapToDomain(_ dtos: [WeatherEntity]) -> ForecastModel? {
        guard let firstDTO = dtos.first else { return nil }
        
        let city = CityModel(
            name: firstDTO.cityName,
            country: firstDTO.country
        )
        
        let weatherItems = dtos.map { dto in
            let temperature = TemperatureModel(
                current: dto.temperatureCurrent,
                min: dto.temperatureMin,
                max: dto.temperatureMax,
                feelsLike: dto.temperatureFeelsLike
            )
            
            let weatherType = mapWeatherType(dto.weatherMain)
            let condition = WeatherConditionModel(
                type: weatherType,
                iconCode: dto.weatherIcon
            )
            
            return WeatherModel(
                dateTime: dto.dataTimestamp,
                temperature: temperature,
                condition: condition,
                description: dto.weatherDescription
            )
        }
        
        let lastUpdated = dtos.compactMap { $0.lastUpdated }.max() ?? Date()
        
        return ForecastModel(
            city: city,
            weatherItems: weatherItems,
            lastUpdated: lastUpdated
        )
    }
}
