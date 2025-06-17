//
//  WeatherModel.swift
//  StarterApp
//
//  Created by MacBook Air M1 on 19/6/24.
//

import Foundation

// MARK: - Pure Domain Models (No Codable, No External Dependencies)

public struct WeatherModel: Equatable {
    public let dateTime: Date
    public let temperature: TemperatureModel
    public let condition: WeatherConditionModel
    public let description: String

    public init(dateTime: Date, temperature: TemperatureModel, condition: WeatherConditionModel, description: String) {
        self.dateTime = dateTime
        self.temperature = temperature
        self.condition = condition
        self.description = description
    }
}

public enum WeatherType: String, CaseIterable {
    case sunny = "Clear"
    case cloudy = "Clouds"
    case rainy = "Rain"
    case snowy = "Snow"
    case stormy = "Thunderstorm"
    case foggy = "Fog"
    case unknown = "Unknown"

    public var displayName: String {
        switch self {
        case .sunny: return "Sunny"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        case .snowy: return "Snowy"
        case .stormy: return "Stormy"
        case .foggy: return "Foggy"
        case .unknown: return "Unknown"
        }
    }

    public var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        case .snowy: return "❄️"
        case .stormy: return "⛈️"
        case .foggy: return "🌫️"
        case .unknown: return "❓"
        }
    }
}
