//
//  WeatherApiDTO.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - API Response DTOs (Codable for External API)

public struct ForecastApiDTO: Codable {
    public let city: CityApiDTO
    public let list: [WeatherApiDTO]
    public let cnt: Int?
    public let cod: String?
    public let message: Int?
    
    enum CodingKeys: String, CodingKey {
        case city, list, cnt, cod, message
    }
}

public struct CityApiDTO: Codable {
    public let id: Int?
    public let name: String
    public let coord: CoordinateApiDTO?
    public let country: String
    public let population: Int?
    public let timezone: Int?
    public let sunrise: Int?
    public let sunset: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, coord, country, population, timezone, sunrise, sunset
    }
}

public struct CoordinateApiDTO: Codable {
    public let lat: Double
    public let lon: Double
}

public struct WeatherApiDTO: Codable {
    public let dt: Int
    public let main: TemperatureApiDTO
    public let weather: [WeatherDataApiDTO]
    public let clouds: CloudsApiDTO?
    public let wind: WindApiDTO?
    public let visibility: Int?
    public let pop: Double?
    public let rain: RainApiDTO?
    public let snow: SnowApiDTO?
    public let sys: SysApiDTO?
    public let dt_txt: String?
    
    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind, visibility, pop, rain, snow, sys, dt_txt
    }
}

public struct TemperatureApiDTO: Codable {
    public let temp: Double
    public let feels_like: Double?
    public let temp_min: Double?
    public let temp_max: Double?
    public let pressure: Int?
    public let sea_level: Int?
    public let grnd_level: Int?
    public let humidity: Int?
    public let temp_kf: Double?
    
    enum CodingKeys: String, CodingKey {
        case temp, feels_like, temp_min, temp_max, pressure, sea_level, grnd_level, humidity, temp_kf
    }
}

public struct WeatherDataApiDTO: Codable {
    public let id: Int
    public let main: String
    public let description: String
    public let icon: String
    
    enum CodingKeys: String, CodingKey {
        case id, main, description, icon
    }
}

public struct CloudsApiDTO: Codable {
    public let all: Int
}

public struct WindApiDTO: Codable {
    public let speed: Double
    public let deg: Int?
    public let gust: Double?
}

public struct RainApiDTO: Codable {
    public let oneHour: Double?
    public let threeHour: Double?
    
    enum CodingKeys: String, CodingKey {
        case oneHour = "1h"
        case threeHour = "3h"
    }
}

public struct SnowApiDTO: Codable {
    public let oneHour: Double?
    public let threeHour: Double?
    
    enum CodingKeys: String, CodingKey {
        case oneHour = "1h"
        case threeHour = "3h"
    }
}

public struct SysApiDTO: Codable {
    public let pod: String?
}