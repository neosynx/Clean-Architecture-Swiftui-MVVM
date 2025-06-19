//
//  WeatherFileService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Protocol

/// Protocol for weather file service operations
/// Provides a unified interface for file-based weather data storage
protocol WeatherFileService {
    
    /// Fetch weather data from file storage
    /// - Parameter city: The city name to fetch weather for
    /// - Returns: Weather data from file storage
    /// - Throws: ServiceError for various failure scenarios
    func fetch(for city: String) async throws -> WeatherApiDTO
    
    /// Save weather forecast to file
    /// - Parameters:
    ///   - forecast: The weather forecast to save
    ///   - city: The city name to save forecast for
    /// - Throws: ServiceError if save operation fails
    func saveForecast(_ forecast: WeatherApiDTO, for city: String) async throws
    
    /// Delete weather forecast file
    /// - Parameter city: The city name to delete forecast for
    /// - Throws: ServiceError if delete operation fails
    func deleteForecast(for city: String) async throws
    
    /// Clear all weather files
    /// - Throws: ServiceError if clear operation fails
    func clearAllForecasts() async throws
    
    /// Get all available city keys
    /// - Returns: Array of city names that have stored weather data
    /// - Throws: ServiceError if operation fails
    func getAllKeys() async throws -> [String]
    
    /// Check if weather data exists for a city
    /// - Parameter city: The city name to check
    /// - Returns: True if data exists, false otherwise
    func exists(for city: String) async throws -> Bool
}

// MARK: - Implementation

/// Weather-specific file service implementation
final class WeatherFileServiceImpl: FileServiceImpl<String, WeatherApiDTO>, WeatherFileService {
    
    // MARK: - Initialization
    
    init(logger: AppLogger) {
        super.init(
            directoryName: "Weather",
            fileExtension: "json",
            logger: logger
        )
    }
    
    // MARK: - Filename Handling Override
    
    override func filenameFromKey(_ city: String) -> String {
        // Normalize city name for safe filename
        let normalizedCity = city.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "_")
        
        // Replace unsafe characters with underscores
        let safeCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let safeName = normalizedCity.components(separatedBy: safeCharacterSet.inverted).joined(separator: "_")
        
        // Ensure filename isn't too long
        let maxLength = 100
        if safeName.count > maxLength {
            let truncated = String(safeName.prefix(maxLength))
            let hash = abs(city.hashValue)
            return "\(truncated)_\(hash)"
        }
        
        return safeName
    }
    
    override func keyFromFilename(_ filename: String) -> String? {
        // Convert filename back to city name
        return filename.replacingOccurrences(of: "_", with: " ").capitalized
    }
    
    // MARK: - Public Save Method
    
    /// Save weather forecast to file
    func saveForecast(_ forecast: WeatherApiDTO, for city: String) async throws {
        try await save(forecast, for: city)
    }
    
    /// Delete weather forecast file
    func deleteForecast(for city: String) async throws {
        try await delete(for: city)
    }
    
    /// Clear all weather files
    func clearAllForecasts() async throws {
        let cities = try await getAllKeys()
        for city in cities {
            try await delete(for: city)
        }
    }
}
