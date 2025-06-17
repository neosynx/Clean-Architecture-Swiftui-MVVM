//
//  WeatherFileService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Weather File Service

/// Weather-specific file service implementation
final class WeatherFileService: FileServiceImpl<String, ForecastFileDTO> {
    
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
    func saveForecast(_ forecast: ForecastFileDTO, for city: String) async throws {
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
