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
    private let logger: AppLogger
    
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
    init(weatherRepository: WeatherRepository, logger: AppLogger) {
        self.weatherRepository = weatherRepository
        self.logger = logger
        logger.info("WeatherStore initialized")
        Task {
            await loadSavedCities()
        }
    }
    
    // MARK: - Weather Operations
    @MainActor
    func fetchWeather(for city: String, forceRefresh: Bool = false) async {
        guard !city.isEmpty else { 
            logger.debug("Fetch weather skipped: empty city name")
            return 
        }
        
        logger.logUserAction("Fetch Weather", details: ["city": city, "forceRefresh": forceRefresh])
        
        isLoading = true
        errorMessage = nil
        selectedCity = city
        
        do {
            let result = try await logger.logExecutionTime(operation: "Fetch weather for \(city)") {
                return try await performFetch(for: city, forceRefresh: forceRefresh)
            }
            forecast = result
            logger.info("Weather data loaded successfully for \(city)")
        } catch {
            logger.logError(error, context: "Weather fetch for \(city)")
            errorMessage = handleError(error)
            forecast = nil
        }
        
        isLoading = false
    }
    
    @MainActor
    func refreshWeather() async {
        guard !selectedCity.isEmpty else { 
            logger.debug("Refresh weather skipped: no city selected")
            return 
        }
        logger.logUserAction("Refresh Weather", details: ["city": selectedCity])
        await fetchWeather(for: selectedCity, forceRefresh: true)
    }
    
    @MainActor
    func saveCurrentWeather() async {
        guard let forecast = forecast else { 
            logger.debug("Save weather skipped: no forecast data")
            return 
        }
        
        logger.logUserAction("Save Weather", details: ["city": forecast.city.name])
        
        do {
            try await weatherRepository.saveWeather(forecast)
            logger.logDataOperation(.create, entity: "Weather", identifier: forecast.city.name)
            await loadSavedCities()
        } catch {
            logger.logError(error, context: "Save weather for \(forecast.city.name)")
            errorMessage = "Failed to save weather: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func deleteWeather(for city: String) async {
        logger.logUserAction("Delete Weather", details: ["city": city])
        
        do {
            try await weatherRepository.deleteWeather(for: city)
            logger.logDataOperation(.delete, entity: "Weather", identifier: city)
            await loadSavedCities()
            
            // Clear current forecast if it's for the deleted city
            if selectedCity.lowercased() == city.lowercased() {
                clearWeather()
                logger.debug("Cleared current forecast after deleting \(city)")
            }
        } catch {
            logger.logError(error, context: "Delete weather for \(city)")
            errorMessage = "Failed to delete weather: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func loadSavedCities() async {
        do {
            savedCities = try await weatherRepository.getAllSavedCities()
            logger.debug("Loaded \(savedCities.count) saved cities")
        } catch {
            logger.logError(error, context: "Load saved cities")
        }
    }
    
    @MainActor
    func clearCache() async {
        logger.logUserAction("Clear Cache")
        
        do {
            try await weatherRepository.clearCache()
            logger.logCacheOperation(.clear, key: "all")
        } catch {
            logger.logError(error, context: "Clear cache")
            errorMessage = "Failed to clear cache: \(error.localizedDescription)"
        }
    }
    
    func clearWeather() {
        logger.debug("Clearing weather data")
        forecast = nil
        errorMessage = nil
        selectedCity = ""
    }
    
    // MARK: - Data Source Strategy
    func switchDataSource(to newSource: DataSourceType) {
        let oldSource = dataSource
        dataSource = newSource
        logger.logUserAction("Switch Data Source", details: ["from": oldSource.rawValue, "to": newSource.rawValue])
    }
    
    // MARK: - Private Methods
    
    private func handleError(_ error: Error) -> String {
        if let serviceError = error as? ServiceError {
            switch serviceError {
            case .notFound:
                return "Weather data not found for this city"
            case .networkUnavailable:
                return "Network connection unavailable"
            case .fileCorrupted:
                return "Local weather data is corrupted"
            case .cacheExpired:
                return "Cached weather data has expired"
            case .invalidData:
                return "Invalid weather data received"
            case .serviceUnavailable:
                return "Weather service is temporarily unavailable"
            }
        } else {
            return error.localizedDescription
        }
    }
    
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
