//
//  WeatherService.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import Foundation

class WeatherService {
    private let networkService: NetworkService
    private let jsonLoader: JSONLoader
    private let configuration: AppConfiguration
    private let useLocalData: Bool
    
    init(networkService: NetworkService, useLocalData: Bool = false) {
        self.networkService = networkService
        self.jsonLoader = JSONLoader()
        self.configuration = AppConfiguration()
        self.useLocalData = useLocalData
    }
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        if useLocalData {
            return try await fetchLocalWeather()
        } else {
            return try await fetchRemoteWeather(for: city)
        }
    }
    
    private func fetchRemoteWeather(for city: String) async throws -> ForecastModel {
        let apiKey = configuration.apiKey
        let url = "\(configuration.baseURL)?q=\(city)&appid=\(apiKey)&units=metric"
        
        return try await networkService.fetch(ForecastModel.self, from: url)
    }
    
    private func fetchLocalWeather() async throws -> ForecastModel {
        guard let data = jsonLoader.loadJSON(filename: configuration.localWeatherDataFilename) else {
            throw WeatherServiceError.noLocalData
        }
        
        return try JSONDecoder().decode(ForecastModel.self, from: data)
    }
}

enum WeatherServiceError: Error {
    case noLocalData
    case invalidURL
    
    var localizedDescription: String {
        switch self {
        case .noLocalData:
            return "Unable to load local weather data"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}
