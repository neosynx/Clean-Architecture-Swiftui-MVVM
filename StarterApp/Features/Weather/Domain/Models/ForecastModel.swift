//
//  ForecastModel.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/17.
//
import Foundation

public struct ForecastModel: Equatable {
    public let city: CityModel
    public let weatherItems: [WeatherModel]
    public let lastUpdated: Date
    
    public init(city: CityModel, weatherItems: [WeatherModel], lastUpdated: Date = Date()) {
        self.city = city
        self.weatherItems = weatherItems
        self.lastUpdated = lastUpdated
    }
}

