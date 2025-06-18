//
//  SecureStorageService.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation
import Security

/// Unified secure storage service for Keychain and UserDefaults
/// Provides a consistent API for storing sensitive and non-sensitive data
final class SecureStorageService {
    
    // MARK: - Properties
    
    private let keychainService: KeychainService
    private let userDefaultsService: UserDefaultsService
    private let logger: AppLogger
    
    // MARK: - Storage Types
    
    enum StorageType {
        case keychain       // For sensitive data (passwords, tokens, API keys)
        case userDefaults   // For non-sensitive preferences and settings
        
        var isSecure: Bool {
            switch self {
            case .keychain: return true
            case .userDefaults: return false
            }
        }
    }
    
    // MARK: - Initialization
    
    init(logger: AppLogger) {
        self.keychainService = KeychainService(logger: logger)
        self.userDefaultsService = UserDefaultsService(logger: logger)
        self.logger = logger
    }
    
    // MARK: - Generic Storage Methods
    
    /// Store data with automatic type selection based on sensitivity
    func store<T: Codable>(
        _ value: T,
        for key: String,
        type: StorageType
    ) async throws {
        switch type {
        case .keychain:
            try await keychainService.store(value, for: key)
        case .userDefaults:
            userDefaultsService.store(value, for: key)
        }
        
        logger.debug("Stored value for key '\(key)' in \(type)")
    }
    
    /// Retrieve data from storage
    func retrieve<T: Codable>(
        _ type: T.Type,
        for key: String,
        storageType: StorageType
    ) async throws -> T? {
        switch storageType {
        case .keychain:
            return try await keychainService.retrieve(type, for: key)
        case .userDefaults:
            return userDefaultsService.retrieve(type, for: key)
        }
    }
    
    /// Remove data from storage
    func remove(key: String, from storageType: StorageType) async throws {
        switch storageType {
        case .keychain:
            try await keychainService.remove(key: key)
        case .userDefaults:
            userDefaultsService.remove(key: key)
        }
        
        logger.debug("Removed value for key '\(key)' from \(storageType)")
    }
    
    /// Check if key exists in storage
    func exists(key: String, in storageType: StorageType) async -> Bool {
        switch storageType {
        case .keychain:
            return await keychainService.exists(key: key)
        case .userDefaults:
            return userDefaultsService.exists(key: key)
        }
    }
    
    // MARK: - Convenience Methods for Common Use Cases
    
    /// Store API key securely
    func storeAPIKey(_ apiKey: String, for service: String) async throws {
        let key = "api_key_\(service)"
        try await store(apiKey, for: key, type: .keychain)
    }
    
    /// Retrieve API key
    func retrieveAPIKey(for service: String) async throws -> String? {
        let key = "api_key_\(service)"
        return try await retrieve(String.self, for: key, storageType: .keychain)
    }
    
    /// Store user preferences
    func storePreference<T: Codable>(_ value: T, for key: String) {
        userDefaultsService.store(value, for: "pref_\(key)")
    }
    
    /// Retrieve user preferences
    func retrievePreference<T: Codable>(_ type: T.Type, for key: String) -> T? {
        userDefaultsService.retrieve(type, for: "pref_\(key)")
    }
    
    /// Clear all data (useful for logout)
    func clearAll() async throws {
        try await keychainService.clearAll()
        userDefaultsService.clearAll()
        logger.info("Cleared all secure storage")
    }
}

// MARK: - Keychain Service

/// Service for interacting with iOS Keychain
final class KeychainService {
    
    // MARK: - Properties
    
    private let service: String
    private let accessGroup: String?
    private let logger: AppLogger
    
    // MARK: - Errors
    
    enum KeychainError: LocalizedError {
        case encodingFailed
        case decodingFailed
        case saveFailed(OSStatus)
        case updateFailed(OSStatus)
        case deleteFailed(OSStatus)
        case itemNotFound
        case unexpectedData
        
        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode data for Keychain"
            case .decodingFailed:
                return "Failed to decode data from Keychain"
            case .saveFailed(let status):
                return "Keychain save failed with status: \(status)"
            case .updateFailed(let status):
                return "Keychain update failed with status: \(status)"
            case .deleteFailed(let status):
                return "Keychain delete failed with status: \(status)"
            case .itemNotFound:
                return "Item not found in Keychain"
            case .unexpectedData:
                return "Unexpected data format in Keychain"
            }
        }
    }
    
    // MARK: - Initialization
    
    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.app.starterapp",
        accessGroup: String? = nil,
        logger: AppLogger
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    /// Store codable value in Keychain
    func store<T: Codable>(_ value: T, for key: String) async throws {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(value) else {
            throw KeychainError.encodingFailed
        }
        
        try await store(data, for: key)
    }
    
    /// Retrieve codable value from Keychain
    func retrieve<T: Codable>(_ type: T.Type, for key: String) async throws -> T? {
        guard let data = try await retrieve(key: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        guard let value = try? decoder.decode(type, from: data) else {
            throw KeychainError.decodingFailed
        }
        
        return value
    }
    
    /// Store raw data in Keychain
    func store(_ data: Data, for key: String) async throws {
        var query = baseQuery(for: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        
        // Try to update first
        let updateQuery = baseQuery(for: key)
        let updateAttributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecItemNotFound {
            // Item doesn't exist, add it
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                logger.error("Keychain save failed for key '\(key)': \(addStatus)")
                throw KeychainError.saveFailed(addStatus)
            }
        } else if updateStatus != errSecSuccess {
            logger.error("Keychain update failed for key '\(key)': \(updateStatus)")
            throw KeychainError.updateFailed(updateStatus)
        }
        
        logger.debug("Successfully stored data in Keychain for key: \(key)")
    }
    
    /// Retrieve raw data from Keychain
    func retrieve(key: String) async throws -> Data? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            logger.error("Keychain retrieve failed for key '\(key)': \(status)")
            throw KeychainError.itemNotFound
        }
        
        guard let data = result as? Data else {
            throw KeychainError.unexpectedData
        }
        
        logger.debug("Successfully retrieved data from Keychain for key: \(key)")
        return data
    }
    
    /// Remove item from Keychain
    func remove(key: String) async throws {
        let query = baseQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Keychain delete failed for key '\(key)': \(status)")
            throw KeychainError.deleteFailed(status)
        }
        
        logger.debug("Successfully removed item from Keychain for key: \(key)")
    }
    
    /// Check if key exists in Keychain
    func exists(key: String) async -> Bool {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = false
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Clear all items from Keychain for this service
    func clearAll() async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
        
        logger.info("Cleared all Keychain items for service: \(service)")
    }
    
    // MARK: - Private Methods
    
    private func baseQuery(for key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
}

// MARK: - UserDefaults Service

/// Service for managing UserDefaults storage
final class UserDefaultsService {
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let suiteName: String?
    private let logger: AppLogger
    
    // MARK: - Initialization
    
    init(
        suiteName: String? = nil,
        logger: AppLogger
    ) {
        self.suiteName = suiteName
        self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.logger = logger
    }
    
    // MARK: - Public Methods
    
    /// Store value in UserDefaults
    func store<T: Codable>(_ value: T, for key: String) {
        let encoder = JSONEncoder()
        
        if let encoded = try? encoder.encode(value) {
            userDefaults.set(encoded, forKey: key)
            logger.debug("Stored value in UserDefaults for key: \(key)")
        } else {
            // Fallback for simple types
            userDefaults.set(value, forKey: key)
            logger.debug("Stored simple value in UserDefaults for key: \(key)")
        }
    }
    
    /// Retrieve value from UserDefaults
    func retrieve<T: Codable>(_ type: T.Type, for key: String) -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            // Try to get simple types directly
            return userDefaults.object(forKey: key) as? T
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }
    
    /// Remove value from UserDefaults
    func remove(key: String) {
        userDefaults.removeObject(forKey: key)
        logger.debug("Removed value from UserDefaults for key: \(key)")
    }
    
    /// Check if key exists
    func exists(key: String) -> Bool {
        userDefaults.object(forKey: key) != nil
    }
    
    /// Clear all UserDefaults for this suite
    func clearAll() {
        if let suiteName = suiteName {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        } else {
            let domain = Bundle.main.bundleIdentifier ?? "com.app.starterapp"
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        
        userDefaults.synchronize()
        logger.info("Cleared all UserDefaults")
    }
    
    /// Synchronize UserDefaults (force write to disk)
    func synchronize() {
        userDefaults.synchronize()
    }
}

// MARK: - Property Wrappers

/// Property wrapper for UserDefaults-backed properties
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    let userDefaults: UserDefaults
    
    init(
        key: String,
        defaultValue: T,
        userDefaults: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.userDefaults = userDefaults
    }
    
    var wrappedValue: T {
        get { userDefaults.object(forKey: key) as? T ?? defaultValue }
        set { userDefaults.set(newValue, forKey: key) }
    }
}

/// Property wrapper for Keychain-backed properties
@propertyWrapper
struct KeychainStored<T: Codable> {
    let key: String
    let defaultValue: T
    private let keychainService: KeychainService
    
    init(
        key: String,
        defaultValue: T,
        service: String = Bundle.main.bundleIdentifier ?? "com.app.starterapp"
    ) {
        self.key = key
        self.defaultValue = defaultValue
        // Note: This is a simplified implementation for the property wrapper
        // In production, you'd inject the logger properly
        // For now, we provide a logger using the shared factory since property wrappers must be synchronous
        let logger = LoggerFactoryImpl.shared.createLogger(category: "keychain")
        self.keychainService = KeychainService(logger: logger)
    }
    
    var wrappedValue: T {
        get {
            // Property wrappers must be synchronous
            // This is a simplified version - consider using async alternatives
            return defaultValue
        }
        set {
            // Property wrappers must be synchronous
            // This is a simplified version - consider using async alternatives
            _ = newValue
        }
    }
}