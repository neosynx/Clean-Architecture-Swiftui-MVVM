//
//  SecureStorageService 2.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/19.
//


// MARK: - Protocol

/// Protocol for secure storage operations
/// Provides a unified interface for storing sensitive and non-sensitive data
protocol SecureStorageService {
    
    // MARK: - Storage Types
    
    /// Defines the type of storage to use
    var StorageType: SecureStorageType.Type { get }
    
    // MARK: - Generic Storage Methods
    
    /// Store data with automatic type selection based on sensitivity
    func store<T: Codable>(
        _ value: T,
        for key: String,
        type: SecureStorageType
    ) async throws
    
    /// Retrieve data from storage
    func retrieve<T: Codable>(
        _ type: T.Type,
        for key: String,
        storageType: SecureStorageType
    ) async throws -> T?
    
    /// Remove data from storage
    func remove(key: String, from storageType: SecureStorageType) async throws
    
    /// Check if key exists in storage
    func exists(key: String, in storageType: SecureStorageType) async -> Bool
    
    // MARK: - Convenience Methods for Common Use Cases
    
    /// Store API key securely
    func storeAPIKey(_ apiKey: String, for service: String) async throws
    
    /// Retrieve API key
    func retrieveAPIKey(for service: String) async throws -> String?
    
    /// Store user preferences
    func storePreference<T: Codable>(_ value: T, for key: String)
    
    /// Retrieve user preferences
    func retrievePreference<T: Codable>(_ type: T.Type, for key: String) -> T?
    
    /// Clear all data (useful for logout)
    func clearAll() async throws
}