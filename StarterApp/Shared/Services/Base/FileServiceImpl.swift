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
    
    // MARK: - Initialization
    
    init(
        directoryName: String,
        fileExtension: String = "json"
    ) {
        self.directoryName = directoryName
        self.fileExtension = fileExtension
        
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
        print("📁 FileService.save starting for key: \(key)")
        
        do {
            print("📁 FileService.save: Ensuring directory exists...")
            try await ensureDirectoryExists()
            print("📁 FileService.save: Directory check successful")
            
            let url = getFileURL(for: key)
            print("📁 FileService.save: Target file URL: \(url)")
            
            print("📁 FileService.save: Encoding value to JSON...")
            let data = try encoder.encode(value)
            print("📁 FileService.save: JSON encoding successful, data size: \(data.count) bytes")
            
            print("📁 FileService.save: Writing data to file...")
            try data.write(to: url, options: [.atomic])
            print("📁 FileService.save: File write successful")
            
        } catch {
            print("📁 FileService.save: Error occurred:")
            print("   🏷️ Error type: \(type(of: error))")
            print("   📝 Error: \(error.localizedDescription)")
            print("   🔍 Full error: \(error)")
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
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent(directoryName)
    }
    
    private func getFileURL(for key: Key) -> URL {
        let directoryURL = getDirectoryURL()
        let filename = filenameFromKey(key)
        return directoryURL.appendingPathComponent(filename).appendingPathExtension(fileExtension)
    }
    
    private func ensureDirectoryExists() async throws {
        let directoryURL = getDirectoryURL()
        print("📁 FileService.ensureDirectoryExists: Target directory: \(directoryURL)")
        
        if !fileManager.fileExists(atPath: directoryURL.path) {
            print("📁 FileService.ensureDirectoryExists: Directory doesn't exist, creating...")
            do {
                try fileManager.createDirectory(
                    at: directoryURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                print("📁 FileService.ensureDirectoryExists: Directory created successfully")
            } catch {
                print("📁 FileService.ensureDirectoryExists: Failed to create directory:")
                print("   🏷️ Error type: \(type(of: error))")
                print("   📝 Error: \(error.localizedDescription)")
                print("   🔍 Full error: \(error)")
                throw ServiceError.serviceUnavailable
            }
        } else {
            print("📁 FileService.ensureDirectoryExists: Directory already exists")
        }
    }
}
