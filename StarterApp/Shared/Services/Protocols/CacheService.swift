//
//  CacheService.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/17.
//


/// Protocol for caching services
protocol CacheService {
    associatedtype Key: Hashable
    associatedtype Value: Codable
    
    /// Get cached value
    func get(for key: Key) async throws -> Value?
    
    /// Set cached value
    func set(_ value: Value, for key: Key) async throws
    
    /// Remove cached value
    func remove(for key: Key) async throws
    
    /// Clear all cached values
    func clear() async throws
    
    /// Check if value is expired
    func isExpired(for key: Key) async -> Bool
}