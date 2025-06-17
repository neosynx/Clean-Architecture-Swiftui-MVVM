//
//  WeatherFileDataSourceImpl.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

class WeatherFileDataSourceImpl: WeatherLocalDataSource {
    private let fileManager: FileManager
    private let jsonLoader: JSONLoader
    private let documentsDirectory: URL
    
    init(fileManager: FileManager = .default, jsonLoader: JSONLoader = JSONLoader()) {
        self.fileManager = fileManager
        self.jsonLoader = jsonLoader
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func fetchWeather(for city: String) async throws -> ForecastModel? {
        let fileURL = getFileURL(for: city)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(ForecastModel.self, from: data)
        } catch {
            throw WeatherRepositoryError.invalidData
        }
    }
    
    func saveWeather(_ forecast: ForecastModel) async throws {
        let fileURL = getFileURL(for: forecast.city.name)
        
        do {
            let data = try JSONEncoder().encode(forecast)
            try data.write(to: fileURL)
        } catch {
            throw WeatherRepositoryError.storageError
        }
    }
    
    func deleteWeather(for city: String) async throws {
        let fileURL = getFileURL(for: city)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw WeatherRepositoryError.storageError
        }
    }
    
    func getAllSavedCities() async throws -> [String] {
        let weatherDirectory = documentsDirectory.appendingPathComponent("Weather")
        
        guard fileManager.fileExists(atPath: weatherDirectory.path) else {
            return []
        }
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: weatherDirectory.path)
            return files.compactMap { filename in
                guard filename.hasSuffix(".json") else { return nil }
                return String(filename.dropLast(5)) // Remove .json extension
            }
        } catch {
            throw WeatherRepositoryError.storageError
        }
    }
    
    func clearAll() async throws {
        let weatherDirectory = documentsDirectory.appendingPathComponent("Weather")
        
        guard fileManager.fileExists(atPath: weatherDirectory.path) else {
            return
        }
        
        do {
            try fileManager.removeItem(at: weatherDirectory)
        } catch {
            throw WeatherRepositoryError.storageError
        }
    }
    
    // MARK: - Private Methods
    
    private func getFileURL(for city: String) -> URL {
        let weatherDirectory = documentsDirectory.appendingPathComponent("Weather")
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: weatherDirectory.path) {
            try? fileManager.createDirectory(at: weatherDirectory, withIntermediateDirectories: true)
        }
        
        return weatherDirectory.appendingPathComponent("\(city).json")
    }
}