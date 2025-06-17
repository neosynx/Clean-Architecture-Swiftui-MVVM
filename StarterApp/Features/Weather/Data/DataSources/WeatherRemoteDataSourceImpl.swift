//
//  WeatherRemoteDataSourceImpl.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

class WeatherRemoteDataSourceImpl: WeatherRemoteDataSource {
    private let networkService: NetworkService
    private let configuration: AppConfiguration
    
    init(networkService: NetworkService, configuration: AppConfiguration) {
        self.networkService = networkService
        self.configuration = configuration
    }
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        let apiKey = configuration.apiKey
        let url = "\(configuration.baseURL)?q=\(city)&appid=\(apiKey)&units=metric"
        
        do {
            return try await networkService.fetch(ForecastModel.self, from: url)
        } catch {
            throw WeatherRepositoryError.networkError(error)
        }
    }
}