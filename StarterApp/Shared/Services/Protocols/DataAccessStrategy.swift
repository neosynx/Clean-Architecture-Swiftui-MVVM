//
//  DataAccessStrategy.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Legacy Protocol (Deprecated)

/// Legacy protocol - use specific WeatherDataAccessStrategy instead
/// This exists only for build compatibility
@available(*, deprecated, message: "Use WeatherDataAccessStrategy instead")
protocol DataAccessStrategy {
    // Empty - deprecated protocol for build compatibility only
}

// MARK: - Legacy Strategy Types (Deprecated)

/// Legacy strategy types - use WeatherDataAccessStrategyType instead
@available(*, deprecated, message: "Use WeatherDataAccessStrategyType instead")
enum DataAccessStrategyType: String, CaseIterable {
    case cacheFirst = "cache_first"
    case persistenceFirst = "persistence_first"
    case networkFirst = "network_first"
    
    var description: String {
        switch self {
        case .cacheFirst:
            return "Cache → Persistence → Network"
        case .persistenceFirst:
            return "Persistence → Cache → Network"
        case .networkFirst:
            return "Network → Cache → Persistence"
        }
    }
}

// MARK: - Legacy Strategy Configuration (Deprecated)

/// Legacy configuration - not used in new implementation
@available(*, deprecated, message: "Strategy configuration is now handled by individual implementations")
struct DataAccessStrategyConfig {
    let type: DataAccessStrategyType
    let cacheExpirationInterval: TimeInterval
    let enableFallbacks: Bool
    let maxRetryAttempts: Int
    
    static let `default` = DataAccessStrategyConfig(
        type: .cacheFirst,
        cacheExpirationInterval: 3600,
        enableFallbacks: true,
        maxRetryAttempts: 3
    )
}