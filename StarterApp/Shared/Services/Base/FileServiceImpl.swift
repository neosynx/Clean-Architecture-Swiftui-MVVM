//
//  GenericFileService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Generic File Service

/// Generic base class for file data services
class FileServiceImpl<Key: Hashable, Value: Codable>: FileDataService {
    typealias Key = Key
    typealias Value = Value
    
    // MARK: - Properties
    
     let directoryName: String
     let fileExtension: String
     let fileManager = FileManager.default
     let encoder: JSONEncoder
     let decoder: JSONDecoder
     let logger: AppLogger
    
    // MARK: - Initialization
    
    init(
        directoryName: String,
        fileExtension: String = "json",
        logger: AppLogger
    ) {
        self.directoryName = directoryName
        self.fileExtension = fileExtension
        self.logger = logger
        
        self.encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        Task {
            try? await ensureDirectoryExists()
        }
    }
    
    // MARK: - FileDataService Protocol
    
    func fetch(for key: Key) async throws -> Value {
        let url = getFileURL(for: key)
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw ServiceError.notFound
        }
        
        do {
            let data = try Data(contentsOf: url)
            let value = try decoder.decode(Value.self, from: data)
            return value
        } catch {
            throw ServiceError.fileCorrupted
        }
    }
    
    func exists(for key: Key) async -> Bool {
        let url = getFileURL(for: key)
        return fileManager.fileExists(atPath: url.path)
    }
    
    func getAllKeys() async throws -> [Key] {
        let directoryURL = getDirectoryURL()
        
        guard fileManager.fileExists(atPath: directoryURL.path) else {
            return []
        }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            
            let keys = fileURLs.compactMap { url -> Key? in
                let filename = url.deletingPathExtension().lastPathComponent
                return keyFromFilename(filename)
            }
            
            return keys
        } catch {
            throw ServiceError.serviceUnavailable
        }
    }
    
    // MARK: - File Operations
    
    /// Save value to file (available for subclasses)
    func save(_ value: Value, for key: Key) async throws {
        logger.debug("📁 FileService.save starting for key: \(key)")
        
        do {
            logger.debug("📁 FileService.save: Ensuring directory exists...")
            try await ensureDirectoryExists()
            logger.debug("📁 FileService.save: Directory check successful")
            
            let url = getFileURL(for: key)
            logger.debug("📁 FileService.save: Target file URL: \(url)")
            
            logger.debug("📁 FileService.save: Encoding value to JSON...")
            let data = try encoder.encode(value)
            logger.debug("📁 FileService.save: JSON encoding successful, data size: \(data.count) bytes")
            
            logger.debug("📁 FileService.save: Writing data to file...")
            try data.write(to: url, options: [.atomic])
            logger.debug("📁 FileService.save: File write successful")
            
        } catch {
            logger.error("📁 FileService.save: Error occurred:")
            logger.error("   🏷️ Error type: \(type(of: error))")
            logger.error("   📝 Error: \(error.localizedDescription)")
            logger.error("   🔍 Full error: \(error)")
            throw ServiceError.serviceUnavailable
        }
    }
    
    /// Delete file for key (available for subclasses)
    func delete(for key: Key) async throws {
        let url = getFileURL(for: key)
        
        guard fileManager.fileExists(atPath: url.path) else {
            return // File doesn't exist, consider it deleted
        }
        
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw ServiceError.serviceUnavailable
        }
    }
    
    // MARK: - File Path Management (Override in subclasses)
    
    /// Override this method in subclasses for custom filename generation
    func filenameFromKey(_ key: Key) -> String {
        return String(describing: key)
    }
    
    /// Override this method in subclasses for custom key reconstruction
    func keyFromFilename(_ filename: String) -> Key? {
        return filename as? Key
    }
    
    // MARK: - Private Methods
    
    private func getDirectoryURL() -> URL {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            // Fallback to temporary directory if documents directory is not available
            return fileManager.temporaryDirectory.appendingPathComponent(directoryName)
        }
        return documentsURL.appendingPathComponent(directoryName)
    }
    
    private func getFileURL(for key: Key) -> URL {
        let directoryURL = getDirectoryURL()
        let filename = filenameFromKey(key)
        return directoryURL.appendingPathComponent(filename).appendingPathExtension(fileExtension)
    }
    
    private func ensureDirectoryExists() async throws {
        let directoryURL = getDirectoryURL()
        logger.debug("📁 FileService.ensureDirectoryExists: Target directory: \(directoryURL)")
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            logger.debug("📁 FileService.ensureDirectoryExists: Directory doesn't exist, creating...")
            do {
                try fileManager.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                logger.debug("📁 FileService.ensureDirectoryExists: Directory created successfully")
            } catch {
                logger.error("📁 FileService.ensureDirectoryExists: Failed to create directory:")
                logger.error("   🏷️ Error type: \(type(of: error))")
                logger.error("   📝 Error: \(error.localizedDescription)")
                logger.error("   🔍 Full error: \(error)")
                throw ServiceError.serviceUnavailable
            }
        } else {
            logger.debug("📁 FileService.ensureDirectoryExists: Directory already exists")
        }
    }
}

// MARK: - Mock File Service Implementation for Testing

#if DEBUG
/// Mock implementation of FileDataService for testing purposes
final class MockFileService<Key: Hashable, Value: Codable>: FileDataService {
    typealias Key = Key
    typealias Value = Value
    
    // MARK: - Mock Storage
    
    private var storage: [Key: Value] = [:]
    private var shouldFailOperations = false
    private let logger: AppLogger?
    
    // MARK: - Call Tracking
    
    private(set) var fetchCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var deleteCallCount = 0
    private(set) var existsCallCount = 0
    private(set) var getAllKeysCallCount = 0
    
    private(set) var lastFetchedKey: Key?
    private(set) var lastSavedKey: Key?
    private(set) var lastSavedValue: Value?
    private(set) var lastDeletedKey: Key?
    
    // MARK: - Initialization
    
    init(logger: AppLogger? = nil) {
        self.logger = logger
    }
    
    // MARK: - FileDataService Protocol Implementation
    
    func fetch(for key: Key) async throws -> Value {
        fetchCallCount += 1
        lastFetchedKey = key
        
        logger?.debug("📁 MockFileService.fetch called for key: \(key)")
        
        if shouldFailOperations {
            throw ServiceError.serviceUnavailable
        }
        
        guard let value = storage[key] else {
            logger?.debug("📁 MockFileService.fetch: Key not found: \(key)")
            throw ServiceError.notFound
        }
        
        logger?.debug("📁 MockFileService.fetch: Returning value for key: \(key)")
        return value
    }
    
    func exists(for key: Key) async -> Bool {
        existsCallCount += 1
        
        logger?.debug("📁 MockFileService.exists called for key: \(key)")
        
        let exists = storage[key] != nil
        logger?.debug("📁 MockFileService.exists: Key \(key) exists: \(exists)")
        return exists
    }
    
    func getAllKeys() async throws -> [Key] {
        getAllKeysCallCount += 1
        
        logger?.debug("📁 MockFileService.getAllKeys called")
        
        if shouldFailOperations {
            throw ServiceError.serviceUnavailable
        }
        
        let keys = Array(storage.keys)
        logger?.debug("📁 MockFileService.getAllKeys: Returning \(keys.count) keys")
        return keys
    }
    
    // MARK: - Additional Mock Methods (Public for Testing)
    
    /// Save a value for a key (public for mock control)
    func save(_ value: Value, for key: Key) async throws {
        saveCallCount += 1
        lastSavedKey = key
        lastSavedValue = value
        
        logger?.debug("📁 MockFileService.save called for key: \(key)")
        
        if shouldFailOperations {
            throw ServiceError.serviceUnavailable
        }
        
        storage[key] = value
        logger?.debug("📁 MockFileService.save: Saved value for key: \(key)")
    }
    
    /// Delete a value for a key (public for mock control)
    func delete(for key: Key) async throws {
        deleteCallCount += 1
        lastDeletedKey = key
        
        logger?.debug("📁 MockFileService.delete called for key: \(key)")
        
        if shouldFailOperations {
            throw ServiceError.serviceUnavailable
        }
        
        storage.removeValue(forKey: key)
        logger?.debug("📁 MockFileService.delete: Deleted value for key: \(key)")
    }
    
    // MARK: - Mock Control Methods
    
    /// Configure the mock to fail operations
    func setShouldFailOperations(_ shouldFail: Bool) {
        shouldFailOperations = shouldFail
        logger?.debug("📁 MockFileService: Set shouldFailOperations to \(shouldFail)")
    }
    
    /// Set mock data for a specific key
    func setMockData(_ value: Value, for key: Key) {
        storage[key] = value
        logger?.debug("📁 MockFileService: Set mock data for key: \(key)")
    }
    
    /// Remove mock data for a specific key
    func removeMockData(for key: Key) {
        storage.removeValue(forKey: key)
        logger?.debug("📁 MockFileService: Removed mock data for key: \(key)")
    }
    
    /// Clear all mock data
    func clearAllMockData() {
        storage.removeAll()
        logger?.debug("📁 MockFileService: Cleared all mock data")
    }
    
    /// Reset all mock state including call counts
    func reset() {
        storage.removeAll()
        shouldFailOperations = false
        
        fetchCallCount = 0
        saveCallCount = 0
        deleteCallCount = 0
        existsCallCount = 0
        getAllKeysCallCount = 0
        
        lastFetchedKey = nil
        lastSavedKey = nil
        lastSavedValue = nil
        lastDeletedKey = nil
        
        logger?.debug("📁 MockFileService: Reset all state")
    }
    
    // MARK: - Test Helpers
    
    /// Get the current storage state (for testing)
    var currentStorage: [Key: Value] {
        return storage
    }
    
    /// Get total call count across all operations
    var totalCallCount: Int {
        return fetchCallCount + saveCallCount + deleteCallCount + existsCallCount + getAllKeysCallCount
    }
    
    /// Check if a specific key was accessed
    func wasKeyAccessed(_ key: Key) -> Bool {
        return lastFetchedKey == key || lastSavedKey == key || lastDeletedKey == key
    }
    
    /// Get number of items in storage
    var storageCount: Int {
        return storage.count
    }
}
#endif
