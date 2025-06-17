//
//  Weather.swift
//  ExampleMVVM
//
//  Created by MacBook Air M1 on 19/6/24.
//

import Foundation

public struct ForecastModel: Codable, Equatable {
    
    // MARK: - Properties
    
    public var city: City
    public var weatherBundle: [WeatherModel]
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case city
        case weatherBundle = "list"
    }
}


public struct WeatherModel: Codable, Equatable {
    
    // MARK: - Properties
    
    public let dateTime: Double
    public let data: [WeatherDataModel]
    public let temperature: Temperature
    
    // MARK: - Convenience Properties
    
    public var type: WeatherType {
        guard let name = data.first?.name else { return .sunny }
        return WeatherType(rawValue: name) ?? .sunny
    }
    
    // MARK: - CodingKeys
    
    enum CodingKeys: String, CodingKey {
        case dateTime = "dt"
        case data = "weather"
        case temperature = "main"
    }
}

public struct WeatherDataModel: Codable, Equatable {
    
    // MARK: - Properties
    
    public let name: String
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case name = "main"
    }
}

public enum WeatherType: String {
    case sunny = "Clear"
    case cloudy = "Clouds"
    case rainy = "Rain"
}
