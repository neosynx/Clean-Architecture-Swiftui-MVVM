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
    var savedCities: [String] = []
    var dataSource: DataSourceType = .remote
    
    // MARK: - Dependencies
    private let weatherRepository: WeatherRepository
    
    // MARK: - Data Source Configuration
    enum DataSourceType: String, CaseIterable {
        case remote = "Remote API"
        case local = "Local Storage"
        case cache = "Memory Cache"
        case offline = "Offline Mode"
        
        var description: String {
            return self.rawValue
        }
    }
    
    // MARK: - Initialization
    init(weatherRepository: WeatherRepository) {
        self.weatherRepository = weatherRepository
        Task {
            await loadSavedCities()
        }
    }
    
    // MARK: - Weather Operations
    @MainActor
    func fetchWeather(for city: String, forceRefresh: Bool = false) async {
        guard !city.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        selectedCity = city
        
        do {
            let result = try await performFetch(for: city, forceRefresh: forceRefresh)
            forecast = result
        } catch {
            errorMessage = error.localizedDescription
            forecast = nil
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshWeather() async {
        guard !selectedCity.isEmpty else { return }
        await fetchWeather(for: selectedCity, forceRefresh: true)
    }
    
    @MainActor
    func saveCurrentWeather() async {
        guard let forecast = forecast else { return }
        
        do {
            try await weatherRepository.saveWeather(forecast)
            await loadSavedCities()
        } catch {
            errorMessage = "Failed to save weather: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func deleteWeather(for city: String) async {
        do {
            try await weatherRepository.deleteWeather(for: city)
            await loadSavedCities()
            
            // Clear current forecast if it's for the deleted city
            if selectedCity.lowercased() == city.lowercased() {
                clearWeather()
            }
        } catch {
            errorMessage = "Failed to delete weather: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func loadSavedCities() async {
        do {
            savedCities = try await weatherRepository.getAllSavedCities()
        } catch {
            print("Failed to load saved cities: \(error)")
        }
    }
    
    @MainActor
    func clearCache() async {
        do {
            try await weatherRepository.clearCache()
        } catch {
            errorMessage = "Failed to clear cache: \(error.localizedDescription)"
        }
    }
    
    func clearWeather() {
        forecast = nil
        errorMessage = nil
        selectedCity = ""
    }
    
    // MARK: - Data Source Strategy
    func switchDataSource(to newSource: DataSourceType) {
        dataSource = newSource
    }
    
    // MARK: - Private Methods
    private func performFetch(for city: String, forceRefresh: Bool) async throws -> ForecastModel {
        switch dataSource {
        case .remote:
            if forceRefresh {
                return try await weatherRepository.refreshWeather(for: city)
            } else {
                return try await weatherRepository.fetchWeather(for: city)
            }
            
        case .local:
            if let localWeather = try await weatherRepository.getCachedWeather(for: city) {
                return localWeather
            } else {
                // Fallback to remote if no local data
                return try await weatherRepository.fetchWeather(for: city)
            }
            
        case .cache:
            if let cachedWeather = try await weatherRepository.getCachedWeather(for: city) {
                return cachedWeather
            } else {
                // Fallback to remote if no cached data
                return try await weatherRepository.fetchWeather(for: city)
            }
            
        case .offline:
            return try await weatherRepository.getWeatherWithFallback(for: city)
        }
    }
}
