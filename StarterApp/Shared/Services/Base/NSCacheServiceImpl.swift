//
//  NSCacheServiceImpl.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation
import codeartis_logging

// MARK: - Cache Service Protocol

/// Generic protocol for cache services
/// Provides a common interface for different cache implementations
protocol CacheServiceProtocol<Key, Value> {
    associatedtype Key: Hashable
    associatedtype Value
    
    /// Get cached value for key
    /// - Parameter key: The cache key
    /// - Returns: The cached value if exists and not expired, nil otherwise
    func get(for key: Key) async -> Value?
    
    /// Set value in cache for key
    /// - Parameters:
    ///   - value: The value to cache
    ///   - key: The cache key
    func set(_ value: Value, for key: Key)
    
    /// Remove cached value for key
    /// - Parameter key: The cache key
    func remove(for key: Key)
    
    /// Clear all cached values
    func clear()
    
    /// Check if cache entry is expired
    /// - Parameter key: The cache key
    /// - Returns: true if expired or not found, false if valid
    func isExpired(for key: Key) -> Bool
    
    /// Get all cached keys
    /// - Returns: Set of all currently cached keys
    func getAllKeys() -> Set<Key>
    
    /// Get cache statistics
    /// - Returns: Statistics about the cache state
    func getStatistics() -> SimpleCacheStatistics
    
    /// Clean expired entries from cache
    func cleanExpiredEntries()
}

/// NSCache-based implementation for optimal memory management
/// Apple's recommended solution for in-memory caching with automatic eviction
final class NSCacheServiceImpl<Key: Hashable, Value: AnyObject>: NSObject, CacheServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let cache = NSCache<NSString, CacheEntry>()
    private let keyTransformer: (Key) -> NSString
    private let logger: CodeartisLogger?
    private let expirationInterval: TimeInterval
    
    // Serial queue for thread-safe operations on metadata
    private let metadataQueue = DispatchQueue(label: "nscache.metadata", attributes: .concurrent)
    private var keyTracker = Set<Key>()
    
    // MARK: - Cache Entry Wrapper
    
    private final class CacheEntry {
        let value: Value
        let timestamp: Date
        let expirationDate: Date
        
        init(value: Value, expirationInterval: TimeInterval) {
            self.value = value
            self.timestamp = Date()
            self.expirationDate = Date().addingTimeInterval(expirationInterval)
        }
        
        var isExpired: Bool {
            Date() > expirationDate
        }
    }
    
    // MARK: - Initialization
    
    init(
        countLimit: Int = 100,
        totalCostLimit: Int = 50 * 1024 * 1024, // 50MB default
        expirationInterval: TimeInterval = 3600, // 1 hour default
        keyTransformer: @escaping (Key) -> NSString = { NSString(string: "\($0)") },
        logger: CodeartisLogger? = nil
    ) {
        self.keyTransformer = keyTransformer
        self.logger = logger
        self.expirationInterval = expirationInterval
        
        super.init()
        
        // Configure NSCache
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
        cache.evictsObjectsWithDiscardedContent = true
        cache.name = "NSCacheService.\(String(describing: Key.self)).\(String(describing: Value.self))"
        
        // Note: Not setting delegate due to generic class limitations
        
        logger?.debug("NSCache initialized: countLimit=\(countLimit), costLimit=\(totalCostLimit / 1024 / 1024)MB")
    }
    
    // MARK: - Public Methods
    
    func get(for key: Key) async -> Value? {
        let nsKey = keyTransformer(key)
        
        guard let entry = cache.object(forKey: nsKey) else {
            logger?.debug("Cache miss for key: \(key)")
            return nil
        }
        
        if entry.isExpired {
            logger?.debug("Cache entry expired for key: \(key)")
            cache.removeObject(forKey: nsKey)
            metadataQueue.async(flags: .barrier) {
                self.keyTracker.remove(key)
            }
            return nil
        }
        
        logger?.debug("Cache hit for key: \(key)")
        return entry.value
    }
    
    func set(_ value: Value, for key: Key) {
        let nsKey = keyTransformer(key)
        let entry = CacheEntry(value: value, expirationInterval: expirationInterval)
        
        // Calculate cost based on object size (approximate)
        let cost = MemoryLayout<Value>.stride
        
        cache.setObject(entry, forKey: nsKey, cost: cost)
        
        metadataQueue.async(flags: .barrier) {
            self.keyTracker.insert(key)
        }
        
        logger?.debug("Cached value for key: \(key), cost: \(cost) bytes")
    }
    
    func remove(for key: Key) {
        let nsKey = keyTransformer(key)
        cache.removeObject(forKey: nsKey)
        
        metadataQueue.async(flags: .barrier) {
            self.keyTracker.remove(key)
        }
        
        logger?.debug("Removed cache entry for key: \(key)")
    }
    
    func clear() {
        cache.removeAllObjects()
        
        metadataQueue.async(flags: .barrier) {
            self.keyTracker.removeAll()
        }
        
        logger?.debug("Cleared all cache entries")
    }
    
    func isExpired(for key: Key) -> Bool {
        let nsKey = keyTransformer(key)
        
        guard let entry = cache.object(forKey: nsKey) else {
            return true // Not in cache means expired
        }
        
        return entry.isExpired
    }
    
    // MARK: - Additional Methods
    
    /// Get all cached keys
    func getAllKeys() -> Set<Key> {
        metadataQueue.sync {
            keyTracker
        }
    }
    
    /// Get cache statistics
    func getStatistics() -> SimpleCacheStatistics {
        let keys = getAllKeys()
        var validCount = 0
        var expiredCount = 0
        
        for key in keys {
            if isExpired(for: key) {
                expiredCount += 1
            } else {
                validCount += 1
            }
        }
        
        return SimpleCacheStatistics(
            entryCount: validCount,
            expiredCount: expiredCount,
            totalCount: keys.count,
            countLimit: cache.countLimit,
            totalCostLimit: cache.totalCostLimit
        )
    }
    
    /// Clean expired entries
    func cleanExpiredEntries() {
        logger?.debug("Cleaning expired entries")
        
        let keys = getAllKeys()
        var removedCount = 0
        
        for key in keys {
            if isExpired(for: key) {
                remove(for: key)
                removedCount += 1
            }
        }
        
        logger?.debug("Removed \(removedCount) expired entries")
    }
}

// Note: NSCacheDelegate conformance not possible for generic classes

// MARK: - Cache Statistics

struct SimpleCacheStatistics {
    let entryCount: Int
    let expiredCount: Int
    let totalCount: Int
    let countLimit: Int
    let totalCostLimit: Int
    
    var usagePercentage: Double {
        guard countLimit > 0 else { return 0 }
        return Double(entryCount) / Double(countLimit) * 100
    }
    
    var description: String {
        """
        Cache Statistics:
        - Valid entries: \(entryCount)
        - Expired entries: \(expiredCount)
        - Total tracked: \(totalCount)
        - Count limit: \(countLimit)
        - Cost limit: \(totalCostLimit / 1024 / 1024)MB
        - Usage: \(String(format: "%.1f", usagePercentage))%
        """
    }
}

// MARK: - Specialized Cache for Domain Models

/// Specialized NSCache for domain models that need to be wrapped as reference types
final class DomainModelCache<Key: Hashable, Model> {
    
    // Wrapper to make value types work with NSCache
    private final class ModelWrapper {
        let model: Model
        init(model: Model) {
            self.model = model
        }
    }
    
    private let cache: NSCacheServiceImpl<Key, ModelWrapper>
    
    init(
        countLimit: Int = 100,
        totalCostLimit: Int = 50 * 1024 * 1024,
        expirationInterval: TimeInterval = 3600,
        logger: CodeartisLogger? = nil
    ) {
        self.cache = NSCacheServiceImpl(
            countLimit: countLimit,
            totalCostLimit: totalCostLimit,
            expirationInterval: expirationInterval,
            logger: logger
        )
    }
    
    func get(for key: Key) async -> Model? {
        guard let wrapper = await cache.get(for: key) else {
            return nil
        }
        return wrapper.model
    }
    
    func set(_ model: Model, for key: Key) async {
        let wrapper = ModelWrapper(model: model)
        cache.set(wrapper, for: key)
    }
    
    func remove(for key: Key) async {
        cache.remove(for: key)
    }
    
    func clear() async {
        cache.clear()
    }
    
    func isExpired(for key: Key) async -> Bool {
        cache.isExpired(for: key)
    }
    
    func getStatistics() async -> SimpleCacheStatistics {
        cache.getStatistics()
    }
}

// MARK: - Mock Cache Implementation for Testing

#if DEBUG
/// Mock cache implementation for testing purposes
final class MockCacheService<Key: Hashable, Value>: CacheServiceProtocol, @unchecked Sendable {
    
    private var storage: [Key: CacheItem] = [:]
    private let queue = DispatchQueue(label: "mock.cache", attributes: .concurrent)
    private let expirationInterval: TimeInterval
    
    private struct CacheItem {
        let value: Value
        let timestamp: Date
        let expirationDate: Date
        
        var isExpired: Bool {
            Date() > expirationDate
        }
    }
    
    private(set) var getCallCount = 0
    private(set) var setCallCount = 0
    private(set) var removeCallCount = 0
    private(set) var clearCallCount = 0
    
    init(expirationInterval: TimeInterval = 3600) {
        self.expirationInterval = expirationInterval
    }
    
    func get(for key: Key) async -> Value? {
        return queue.sync {
            getCallCount += 1
            
            guard let item = storage[key] else {
                return nil
            }
            
            if item.isExpired {
                storage.removeValue(forKey: key)
                return nil
            }
            
            return item.value
        }
    }
    
    func set(_ value: Value, for key: Key) {
        queue.async(flags: .barrier) {
            self.setCallCount += 1
            
            let item = CacheItem(
                value: value,
                timestamp: Date(),
                expirationDate: Date().addingTimeInterval(self.expirationInterval)
            )
            self.storage[key] = item
        }
    }
    
    func remove(for key: Key) {
        queue.async(flags: .barrier) {
            self.removeCallCount += 1
            self.storage.removeValue(forKey: key)
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.clearCallCount += 1
            self.storage.removeAll()
        }
    }
    
    func isExpired(for key: Key) -> Bool {
        return queue.sync {
            guard let item = storage[key] else {
                return true
            }
            return item.isExpired
        }
    }
    
    func getAllKeys() -> Set<Key> {
        return queue.sync {
            Set(storage.keys)
        }
    }
    
    func getStatistics() -> SimpleCacheStatistics {
        return queue.sync {
            let validCount = storage.values.filter { !$0.isExpired }.count
            let expiredCount = storage.values.filter { $0.isExpired }.count
            
            return SimpleCacheStatistics(
                entryCount: validCount,
                expiredCount: expiredCount,
                totalCount: storage.count,
                countLimit: 100,
                totalCostLimit: 50 * 1024 * 1024
            )
        }
    }
    
    func cleanExpiredEntries() {
        queue.async(flags: .barrier) {
            let expiredKeys = self.storage.compactMap { key, item in
                item.isExpired ? key : nil
            }
            
            for key in expiredKeys {
                self.storage.removeValue(forKey: key)
            }
        }
    }
    
    // MARK: - Test Helpers
    
    /// Reset all mock state
    func reset() {
        queue.async(flags: .barrier) {
            self.storage.removeAll()
            self.getCallCount = 0
            self.setCallCount = 0
            self.removeCallCount = 0
            self.clearCallCount = 0
        }
    }
    
    /// Check if key exists in cache (ignoring expiration)
    func hasKey(_ key: Key) -> Bool {
        return queue.sync {
            storage[key] != nil
        }
    }
    
    /// Get value without checking expiration (for testing)
    func getRawValue(for key: Key) -> Value? {
        return queue.sync {
            storage[key]?.value
        }
    }
    
    /// Set value with custom expiration date
    func setValue(_ value: Value, for key: Key, expiresAt date: Date) {
        queue.async(flags: .barrier) {
            let item = CacheItem(
                value: value,
                timestamp: Date(),
                expirationDate: date
            )
            self.storage[key] = item
        }
    }
}
#endif