//
//  JSONLoader.swift
//  StarterApp
//
//  Created by MacBook Air M1 on 20/6/24.
//

import Foundation

// MARK: - JSON Loader Protocol

/// Protocol for loading JSON data from various sources
/// This abstraction allows for different implementations and easy testing
protocol JSONLoaderProtocol {
    /// Load JSON data from a file in the bundle
    /// - Parameters:
    ///   - filename: The name of the JSON file (without extension)
    ///   - logger: Optional logger for error reporting
    /// - Returns: The JSON data if successful, nil otherwise
    func loadJSON(filename: String, logger: AppLogger?) -> Data?
}

// MARK: - Default Implementation

extension JSONLoaderProtocol {
    /// Convenience method without logger parameter
    func loadJSON(filename: String) -> Data? {
        return loadJSON(filename: filename, logger: nil)
    }
}

// MARK: - Bundle JSON Loader Implementation

/// Implementation that loads JSON files from the app bundle
final class JSONLoader: JSONLoaderProtocol {
    
    func loadJSON(filename: String, logger: AppLogger? = nil) -> Data? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            let message = "JSON file '\(filename).json' not found in bundle"
            if let logger = logger {
                logger.error(message)
            } else {
                print(message)
            }
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let message = "Successfully loaded JSON file: \(filename).json (\(data.count) bytes)"
            if let logger = logger {
                logger.debug(message)
            }
            return data
        } catch {
            let message = "Error loading JSON file '\(filename).json': \(error.localizedDescription)"
            if let logger = logger {
                logger.error(message)
            } else {
                print(message)
            }
            return nil
        }
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
/// Mock implementation for testing purposes
final class MockJSONLoader: JSONLoaderProtocol {
    
    private var mockData: [String: Data] = [:]
    private var shouldFailLoading = false
    private(set) var loadedFiles: [String] = []
    
    /// Set mock data for a specific filename
    func setMockData(_ data: Data, for filename: String) {
        mockData[filename] = data
    }
    
    /// Set mock JSON object for a specific filename
    func setMockJSON<T: Codable>(_ object: T, for filename: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(object)
        setMockData(data, for: filename)
    }
    
    /// Configure the mock to fail loading
    func setShouldFailLoading(_ shouldFail: Bool) {
        shouldFailLoading = shouldFail
    }
    
    /// Reset all mock state
    func reset() {
        mockData.removeAll()
        shouldFailLoading = false
        loadedFiles.removeAll()
    }
    
    func loadJSON(filename: String, logger: AppLogger?) -> Data? {
        loadedFiles.append(filename)
        
        if shouldFailLoading {
            let message = "Mock loader configured to fail for: \(filename)"
            logger?.error(message)
            return nil
        }
        
        guard let data = mockData[filename] else {
            let message = "Mock data not found for: \(filename)"
            logger?.error(message)
            return nil
        }
        
        logger?.debug("Mock loader returning data for: \(filename) (\(data.count) bytes)")
        return data
    }
    
    /// Check if a file was loaded
    func wasFileLoaded(_ filename: String) -> Bool {
        return loadedFiles.contains(filename)
    }
    
    /// Get count of how many times a file was loaded
    func loadCount(for filename: String) -> Int {
        return loadedFiles.filter { $0 == filename }.count
    }
}
#endif


