//
//  WeatherStore.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import Foundation

@Observable
class WeatherStore {
    // MARK: - State
    var forecast: ForecastModel?
    var isLoading = false
    var errorMessage: String?
    var selectedCity = ""
    
    // MARK: - Dependencies
    private let weatherService: WeatherService
    
    // MARK: - Initialization
    init(weatherService: WeatherService) {
        self.weatherService = weatherService
    }
    
    // MARK: - Actions
    @MainActor
    func fetchWeather(for city: String) async {
        guard !city.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        selectedCity = city
        
        do {
            forecast = try await weatherService.fetchWeather(for: city)
        } catch {
            errorMessage = error.localizedDescription
            forecast = nil
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshWeather() async {
        guard !selectedCity.isEmpty else { return }
        await fetchWeather(for: selectedCity)
    }
    
    func clearWeather() {
        forecast = nil
        errorMessage = nil
        selectedCity = ""
    }
}
