//
//  WeatherDomainErrors.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

// MARK: - Weather Domain Errors

/// Comprehensive error types for weather domain operations
/// Replaces generic ServiceError with domain-specific errors
enum WeatherDomainError: Error, LocalizedError, Equatable {
    
    // MARK: - Data Not Found Errors
    case cityNotFound(String)
    case noWeatherData(String)
    case cacheEmpty
    case persistenceEmpty
    
    // MARK: - Data Quality Errors
    case invalidWeatherData(String)
    case corruptedForecast(String)
    case outdatedData(String, age: TimeInterval)
    case incompleteData(String, missing: [String])
    
    // MARK: - Network Errors
    case networkUnavailable
    case apiKeyInvalid
    case apiRateLimitExceeded
    case apiServiceUnavailable
    case networkTimeout
    
    // MARK: - Storage Errors
    case cacheWriteFailure(String)
    case cacheReadFailure(String)
    case persistenceWriteFailure(String)
    case persistenceReadFailure(String)
    case storageQuotaExceeded
    
    // MARK: - Configuration Errors
    case invalidConfiguration(String)
    case missingDependency(String)
    case strategyUnavailable(WeatherDataAccessStrategyType)
    
    // MARK: - Security Errors
    case unauthorizedAccess
    case encryptionFailure
    case dataIntegrityViolation
    
    // MARK: - Localized Error Descriptions
    
    var errorDescription: String? {
        switch self {
        // Data Not Found
        case .cityNotFound(let city):
            return "Weather data not found for '\(city)'"
        case .noWeatherData(let city):
            return "No weather data available for '\(city)'"
        case .cacheEmpty:
            return "Weather cache is empty"
        case .persistenceEmpty:
            return "No weather data stored locally"
            
        // Data Quality
        case .invalidWeatherData(let reason):
            return "Invalid weather data: \(reason)"
        case .corruptedForecast(let city):
            return "Weather forecast data for '\(city)' is corrupted"
        case .outdatedData(let city, let age):
            return "Weather data for '\(city)' is outdated (age: \(Int(age/3600))h)"
        case .incompleteData(let city, let missing):
            return "Incomplete weather data for '\(city)'. Missing: \(missing.joined(separator: ", "))"
            
        // Network
        case .networkUnavailable:
            return "Network connection unavailable"
        case .apiKeyInvalid:
            return "Weather API key is invalid or expired"
        case .apiRateLimitExceeded:
            return "Weather API rate limit exceeded"
        case .apiServiceUnavailable:
            return "Weather service is currently unavailable"
        case .networkTimeout:
            return "Network request timed out"
            
        // Storage
        case .cacheWriteFailure(let reason):
            return "Failed to write to weather cache: \(reason)"
        case .cacheReadFailure(let reason):
            return "Failed to read from weather cache: \(reason)"
        case .persistenceWriteFailure(let reason):
            return "Failed to save weather data: \(reason)"
        case .persistenceReadFailure(let reason):
            return "Failed to load weather data: \(reason)"
        case .storageQuotaExceeded:
            return "Storage quota exceeded for weather data"
            
        // Configuration
        case .invalidConfiguration(let details):
            return "Invalid weather repository configuration: \(details)"
        case .missingDependency(let dependency):
            return "Missing required dependency: \(dependency)"
        case .strategyUnavailable(let strategy):
            return "Data access strategy '\(strategy.rawValue)' is not available"
            
        // Security
        case .unauthorizedAccess:
            return "Unauthorized access to weather data"
        case .encryptionFailure:
            return "Failed to encrypt/decrypt weather data"
        case .dataIntegrityViolation:
            return "Weather data integrity check failed"
        }
    }
    
    // MARK: - Error Categories
    
    /// Categorizes errors for different handling strategies
    var category: ErrorCategory {
        switch self {
        case .cityNotFound, .noWeatherData, .cacheEmpty, .persistenceEmpty:
            return .dataNotFound
        case .invalidWeatherData, .corruptedForecast, .outdatedData, .incompleteData:
            return .dataQuality
        case .networkUnavailable, .apiKeyInvalid, .apiRateLimitExceeded, .apiServiceUnavailable, .networkTimeout:
            return .network
        case .cacheWriteFailure, .cacheReadFailure, .persistenceWriteFailure, .persistenceReadFailure, .storageQuotaExceeded:
            return .storage
        case .invalidConfiguration, .missingDependency, .strategyUnavailable:
            return .configuration
        case .unauthorizedAccess, .encryptionFailure, .dataIntegrityViolation:
            return .security
        }
    }
    
    /// Error severity for logging and user experience
    var severity: ErrorSeverity {
        switch self {
        case .cityNotFound, .noWeatherData, .cacheEmpty, .persistenceEmpty:
            return .low
        case .invalidWeatherData, .corruptedForecast, .outdatedData, .incompleteData:
            return .medium
        case .networkUnavailable, .networkTimeout:
            return .medium
        case .apiKeyInvalid, .apiRateLimitExceeded, .apiServiceUnavailable:
            return .high
        case .cacheWriteFailure, .cacheReadFailure, .persistenceWriteFailure, .persistenceReadFailure:
            return .medium
        case .storageQuotaExceeded:
            return .high
        case .invalidConfiguration, .missingDependency, .strategyUnavailable:
            return .critical
        case .unauthorizedAccess, .encryptionFailure, .dataIntegrityViolation:
            return .critical
        }
    }
    
    /// Whether the error is recoverable
    var isRecoverable: Bool {
        switch category {
        case .dataNotFound, .network:
            return true
        case .dataQuality, .storage:
            return true
        case .configuration, .security:
            return false
        }
    }
}

// MARK: - Error Supporting Types

enum ErrorCategory {
    case dataNotFound
    case dataQuality
    case network
    case storage
    case configuration
    case security
}

enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
}

// MARK: - Result Extensions

extension Result where Failure == WeatherDomainError {
    /// Convenience initializer for common error scenarios
    static func cityNotFound(_ city: String) -> Result<Success, WeatherDomainError> {
        .failure(.cityNotFound(city))
    }
    
    static func networkUnavailable() -> Result<Success, WeatherDomainError> {
        .failure(.networkUnavailable)
    }
    
    static func invalidData(_ reason: String) -> Result<Success, WeatherDomainError> {
        .failure(.invalidWeatherData(reason))
    }
}