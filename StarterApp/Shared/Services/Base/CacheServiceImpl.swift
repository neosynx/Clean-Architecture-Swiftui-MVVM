//
//  GenericCacheService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Generic Cache Service

/// Generic actor-based cache service for thread-safe caching
actor CacheServiceImpl<Key: Hashable, Value: Codable>: CacheService {
    
    // MARK: - Cache Entry
    
    private struct CacheEntry {
        let value: Value
        let timestamp: Date
        let expirationDate: Date
        
        var isExpired: Bool {
            Date() > expirationDate
        }
    }
    
    // MARK: - Properties
    
    private var cache: [Key: CacheEntry] = [:]
    private let expirationInterval: TimeInterval
    private let maxEntries: Int
    
    // MARK: - Initialization
    
    init(
        expirationInterval: TimeInterval = 600, // 10 minutes default
        maxEntries: Int = 100
    ) {
        self.expirationInterval = expirationInterval
        self.maxEntries = maxEntries
    }
    
    // MARK: - CacheService Protocol
    
    func get(for key: Key) async throws -> Value? {
        guard let entry = cache[key] else {
            return nil
        }
        
        if entry.isExpired {
            cache.removeValue(forKey: key)
            throw ServiceError.cacheExpired
        }
        
        return entry.value
    }
    
    func set(_ value: Value, for key: Key) async throws {
        let expirationDate = Date().addingTimeInterval(expirationInterval)
        
        let entry = CacheEntry(
            value: value,
            timestamp: Date(),
            expirationDate: expirationDate
        )
        
        // Evict oldest entry if at capacity
        if cache.count >= maxEntries {
            await evictOldestEntry()
        }
        
        cache[key] = entry
    }
    
    func remove(for key: Key) async throws {
        cache.removeValue(forKey: key)
    }
    
    func clear() async throws {
        cache.removeAll()
    }
    
    func isExpired(for key: Key) async -> Bool {
        guard let entry = cache[key] else {
            return true
        }
        return entry.isExpired
    }
    
    // MARK: - Cache Management
    
    /// Clean expired entries from cache
    func cleanExpiredEntries() async {
        let expiredKeys = cache.compactMap { key, entry in
            entry.isExpired ? key : nil
        }
        
        for key in expiredKeys {
            cache.removeValue(forKey: key)
        }
    }
    
    /// Get cache statistics
    func getStatistics() async -> CacheStatistics {
        let validEntries = cache.values.filter { !$0.isExpired }
        let timestamps = validEntries.map { $0.timestamp }
        
        return CacheStatistics(
            entryCount: validEntries.count,
            memoryUsage: estimateMemoryUsage(),
            oldestEntry: timestamps.min(),
            newestEntry: timestamps.max()
        )
    }
    
    // MARK: - Private Methods
    
    private func evictOldestEntry() async {
        guard let oldestKey = cache.min(by: { $0.value.timestamp < $1.value.timestamp })?.key else {
            return
        }
        cache.removeValue(forKey: oldestKey)
    }
    
    private func estimateMemoryUsage() -> Int {
        // Rough estimation - in production you might want more accurate calculation
        return cache.count * 1024 // Assume ~1KB per cached entry
    }
}

// MARK: - Cache Statistics

struct CacheStatistics {
    let entryCount: Int
    let memoryUsage: Int
    let oldestEntry: Date?
    let newestEntry: Date?
    
    var formattedMemoryUsage: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(memoryUsage))
    }
}
