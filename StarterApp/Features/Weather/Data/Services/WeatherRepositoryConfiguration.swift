//
//  WeatherRepositoryConfiguration.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Weather Repository Configuration

/// Configuration object for WeatherRepository settings
/// Externalizes hardcoded values and makes them configurable
struct WeatherRepositoryConfiguration {
    
    // MARK: - Cache Configuration
    
    /// Cache-specific settings
    struct CacheConfiguration {
        let countLimit: Int
        let totalCostLimit: Int
        let expirationInterval: TimeInterval
        
        static let `default` = CacheConfiguration(
            countLimit: 50,
            totalCostLimit: 20 * 1024 * 1024, // 20MB
            expirationInterval: 3600 // 1 hour
        )
        
        static let minimal = CacheConfiguration(
            countLimit: 10,
            totalCostLimit: 5 * 1024 * 1024, // 5MB
            expirationInterval: 1800 // 30 minutes
        )
        
        static let aggressive = CacheConfiguration(
            countLimit: 100,
            totalCostLimit: 50 * 1024 * 1024, // 50MB
            expirationInterval: 7200 // 2 hours
        )
    }
    
    // MARK: - Strategy Configuration
    
    /// Data access strategy settings
    struct StrategyConfiguration {
        let type: WeatherDataAccessStrategyType
        let enableFallbacks: Bool
        let maxRetryAttempts: Int
        let retryDelay: TimeInterval
        
        static let `default` = StrategyConfiguration(
            type: .cacheFirst,
            enableFallbacks: true,
            maxRetryAttempts: 3,
            retryDelay: 2.0
        )
        
        static let development = StrategyConfiguration(
            type: .networkFirst,
            enableFallbacks: true,
            maxRetryAttempts: 1,
            retryDelay: 1.0
        )
        
        static let production = StrategyConfiguration(
            type: .cacheFirst,
            enableFallbacks: true,
            maxRetryAttempts: 5,
            retryDelay: 3.0
        )
    }
    
    // MARK: - Main Configuration
    
    let cache: CacheConfiguration
    let strategy: StrategyConfiguration
    let enableHealthMonitoring: Bool
    let enableMigrationSupport: Bool
    
    // MARK: - Presets
    
    static let `default` = WeatherRepositoryConfiguration(
        cache: .default,
        strategy: .default,
        enableHealthMonitoring: true,
        enableMigrationSupport: true
    )
    
    static let development = WeatherRepositoryConfiguration(
        cache: .minimal,
        strategy: .development,
        enableHealthMonitoring: true,
        enableMigrationSupport: true
    )
    
    static let production = WeatherRepositoryConfiguration(
        cache: .aggressive,
        strategy: .production,
        enableHealthMonitoring: true,
        enableMigrationSupport: false
    )
    
    static let testing = WeatherRepositoryConfiguration(
        cache: CacheConfiguration(
            countLimit: 5,
            totalCostLimit: 1024 * 1024, // 1MB
            expirationInterval: 300 // 5 minutes
        ),
        strategy: StrategyConfiguration(
            type: .cacheFirst,
            enableFallbacks: false,
            maxRetryAttempts: 1,
            retryDelay: 0.1
        ),
        enableHealthMonitoring: false,
        enableMigrationSupport: false
    )
}