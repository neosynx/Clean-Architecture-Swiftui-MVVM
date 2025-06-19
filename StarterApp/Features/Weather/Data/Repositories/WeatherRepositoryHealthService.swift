//
//  WeatherRepositoryHealthService.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation
import codeartis_logging

// MARK: - Weather Repository Health Service

/// Dedicated service for monitoring weather repository health
/// Extracted from repository to follow Single Responsibility Principle
protocol WeatherRepositoryHealthService {
    /// Get comprehensive health report for weather repository
    func getHealthReport() async -> WeatherRepositoryHealthReport
    
    /// Check if repository is healthy
    func isHealthy() async -> Bool
    
    /// Get detailed diagnostics for troubleshooting
    func getDiagnostics() async -> WeatherRepositoryDiagnostics
}

// MARK: - Health Report Models

/// Comprehensive health report for weather repository
struct WeatherRepositoryHealthReport {
    let cache: DataSourceHealth
    let persistence: DataSourceHealth
    let remote: DataSourceHealth
    let overall: OverallHealth
    let timestamp: Date
    
    init(cache: DataSourceHealth, persistence: DataSourceHealth, remote: DataSourceHealth) {
        self.cache = cache
        self.persistence = persistence
        self.remote = remote
        self.overall = OverallHealth(cache: cache, persistence: persistence, remote: remote)
        self.timestamp = Date()
    }
}

/// Health status for individual data sources
struct DataSourceHealth {
    let isHealthy: Bool
    let responseTime: TimeInterval?
    let lastError: WeatherDomainError?
    let entriesCount: Int
    let lastUpdated: Date?
    let additionalInfo: [String: Any]
    
    init(
        isHealthy: Bool,
        responseTime: TimeInterval? = nil,
        lastError: WeatherDomainError? = nil,
        entriesCount: Int = 0,
        lastUpdated: Date? = nil,
        additionalInfo: [String: Any] = [:]
    ) {
        self.isHealthy = isHealthy
        self.responseTime = responseTime
        self.lastError = lastError
        self.entriesCount = entriesCount
        self.lastUpdated = lastUpdated
        self.additionalInfo = additionalInfo
    }
}

/// Overall health status combining all data sources
struct OverallHealth {
    let status: HealthStatus
    let score: Double // 0.0 to 1.0
    let criticalIssues: [String]
    let warnings: [String]
    
    init(cache: DataSourceHealth, persistence: DataSourceHealth, remote: DataSourceHealth) {
        var score = 0.0
        var criticalIssues: [String] = []
        var warnings: [String] = []
        
        // Cache health contributes 30% to overall score
        if cache.isHealthy {
            score += 0.3
        } else {
            if let error = cache.lastError, error.severity == .critical {
                criticalIssues.append("Cache: \(error.localizedDescription ?? "Unknown error")")
            } else {
                warnings.append("Cache: \(cache.lastError?.localizedDescription ?? "Unhealthy")")
            }
        }
        
        // Persistence health contributes 50% to overall score
        if persistence.isHealthy {
            score += 0.5
        } else {
            if let error = persistence.lastError, error.severity == .critical {
                criticalIssues.append("Persistence: \(error.localizedDescription ?? "Unknown error")")
            } else {
                warnings.append("Persistence: \(persistence.lastError?.localizedDescription ?? "Unhealthy")")
            }
        }
        
        // Remote health contributes 20% to overall score
        if remote.isHealthy {
            score += 0.2
        } else {
            if let error = remote.lastError, error.severity == .critical {
                criticalIssues.append("Remote: \(error.localizedDescription ?? "Unknown error")")
            } else {
                warnings.append("Remote: \(remote.lastError?.localizedDescription ?? "Unhealthy")")
            }
        }
        
        // Determine status based on score and issues
        let status: HealthStatus
        if !criticalIssues.isEmpty {
            status = .critical
        } else if score < 0.5 {
            status = .degraded
        } else if !warnings.isEmpty {
            status = .warning
        } else {
            status = .healthy
        }
        
        self.status = status
        self.score = score
        self.criticalIssues = criticalIssues
        self.warnings = warnings
    }
}

enum HealthStatus: String, CaseIterable {
    case healthy = "healthy"
    case warning = "warning"
    case degraded = "degraded"
    case critical = "critical"
    
    var emoji: String {
        switch self {
        case .healthy: return "✅"
        case .warning: return "⚠️"
        case .degraded: return "🔶"
        case .critical: return "🚨"
        }
    }
}

/// Detailed diagnostics for troubleshooting
struct WeatherRepositoryDiagnostics {
    let configuration: WeatherRepositoryConfiguration
    let strategyType: WeatherDataAccessStrategyType
    let recentErrors: [TimestampedError]
    let performanceMetrics: PerformanceMetrics
    let storageInfo: StorageInfo
}

struct TimestampedError {
    let error: WeatherDomainError
    let timestamp: Date
    let source: String
}

struct PerformanceMetrics {
    let averageResponseTime: TimeInterval
    let cacheHitRate: Double
    let persistenceHitRate: Double
    let networkRequestCount: Int
    let errorRate: Double
}

struct StorageInfo {
    let cacheSize: Int
    let persistenceSize: Int
    let totalStorageUsed: Int
    let availableStorage: Int
}

// MARK: - Implementation

final class WeatherRepositoryHealthServiceImpl: WeatherRepositoryHealthService {
    
    // MARK: - Properties
    
    private let cacheDataSource: WeatherCacheDataSource
    private let persistenceDataSource: WeatherPersistenceDataSource
    private let remoteDataSource: WeatherRemoteDataSource?
    private let logger: CodeartisLogger
    private let configuration: WeatherRepositoryConfiguration
    
    // Health tracking
    private var recentErrors: [TimestampedError] = []
    private let maxRecentErrors = 50
    private let metricsLock = NSLock()
    
    // MARK: - Initialization
    
    init(
        cacheDataSource: WeatherCacheDataSource,
        persistenceDataSource: WeatherPersistenceDataSource,
        remoteDataSource: WeatherRemoteDataSource?,
        configuration: WeatherRepositoryConfiguration,
        logger: CodeartisLogger
    ) {
        self.cacheDataSource = cacheDataSource
        self.persistenceDataSource = persistenceDataSource
        self.remoteDataSource = remoteDataSource
        self.configuration = configuration
        self.logger = logger
    }
    
    // MARK: - Health Service Implementation
    
    func getHealthReport() async -> WeatherRepositoryHealthReport {
        logger.debug("🏥 Generating weather repository health report")
        
        async let cacheHealth = checkCacheHealth()
        async let persistenceHealth = checkPersistenceHealth()
        async let remoteHealth = checkRemoteHealth()
        
        let report = WeatherRepositoryHealthReport(
            cache: await cacheHealth,
            persistence: await persistenceHealth,
            remote: await remoteHealth
        )
        
        logger.debug("🏥 Health report generated: \(report.overall.status.rawValue)")
        return report
    }
    
    func isHealthy() async -> Bool {
        let report = await getHealthReport()
        return report.overall.status == .healthy || report.overall.status == .warning
    }
    
    func getDiagnostics() async -> WeatherRepositoryDiagnostics {
        // This is a simplified implementation
        // In production, you'd collect actual metrics
        return WeatherRepositoryDiagnostics(
            configuration: configuration,
            strategyType: configuration.strategy.type,
            recentErrors: Array(recentErrors.suffix(20)),
            performanceMetrics: PerformanceMetrics(
                averageResponseTime: 0.1,
                cacheHitRate: 0.8,
                persistenceHitRate: 0.6,
                networkRequestCount: 10,
                errorRate: 0.05
            ),
            storageInfo: StorageInfo(
                cacheSize: 1024,
                persistenceSize: 2048,
                totalStorageUsed: 3072,
                availableStorage: 100000
            )
        )
    }
    
    // MARK: - Private Health Checks
    
    private func checkCacheHealth() async -> DataSourceHealth {
        let startTime = Date()
        
        do {
            // Try to get cache statistics
            if let cacheImpl = cacheDataSource as? WeatherCacheDataSourceImpl {
                let stats = await cacheImpl.getStatistics()
                let responseTime = Date().timeIntervalSince(startTime)
                
                return DataSourceHealth(
                    isHealthy: true,
                    responseTime: responseTime,
                    entriesCount: stats.entryCount,
                    lastUpdated: Date(),
                    additionalInfo: [
                        "totalCount": stats.totalCount,
                        "expiredCount": stats.expiredCount,
                        "countLimit": stats.countLimit
                    ]
                )
            } else {
                // Generic cache health check
                _ = try await cacheDataSource.get(for: "health_check")
                let responseTime = Date().timeIntervalSince(startTime)
                
                return DataSourceHealth(
                    isHealthy: true,
                    responseTime: responseTime
                )
            }
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            let domainError = WeatherDomainError.cacheReadFailure(error.localizedDescription)
            
            recordError(domainError, source: "cache")
            
            return DataSourceHealth(
                isHealthy: false,
                responseTime: responseTime,
                lastError: domainError
            )
        }
    }
    
    private func checkPersistenceHealth() async -> DataSourceHealth {
        let startTime = Date()
        
        do {
            let cities = try await persistenceDataSource.getAllSavedCities()
            let responseTime = Date().timeIntervalSince(startTime)
            
            return DataSourceHealth(
                isHealthy: true,
                responseTime: responseTime,
                entriesCount: cities.count,
                lastUpdated: Date()
            )
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            let domainError = WeatherDomainError.persistenceReadFailure(error.localizedDescription)
            
            recordError(domainError, source: "persistence")
            
            return DataSourceHealth(
                isHealthy: false,
                responseTime: responseTime,
                lastError: domainError
            )
        }
    }
    
    private func checkRemoteHealth() async -> DataSourceHealth {
        guard let remote = remoteDataSource else {
            return DataSourceHealth(
                isHealthy: false,
                lastError: WeatherDomainError.missingDependency("remote data source")
            )
        }
        
        let isAvailable = remote.isAvailable
        
        return DataSourceHealth(
            isHealthy: isAvailable,
            lastError: isAvailable ? nil : WeatherDomainError.networkUnavailable
        )
    }
    
    // MARK: - Error Tracking
    
    private func recordError(_ error: WeatherDomainError, source: String) {
        metricsLock.lock()
        defer { metricsLock.unlock() }
        
        let timestampedError = TimestampedError(
            error: error,
            timestamp: Date(),
            source: source
        )
        
        recentErrors.append(timestampedError)
        
        // Keep only recent errors
        if recentErrors.count > maxRecentErrors {
            recentErrors = Array(recentErrors.suffix(maxRecentErrors))
        }
    }
}

// MARK: - Health Report Extensions

extension WeatherRepositoryHealthReport: CustomStringConvertible {
    var description: String {
        """
        Weather Repository Health Report (\(timestamp)):
        Overall: \(overall.status.emoji) \(overall.status.rawValue.capitalized) (Score: \(String(format: "%.1f", overall.score * 100))%)
        
        Data Sources:
        - Cache: \(cache.isHealthy ? "✅" : "❌") (\(cache.entriesCount) entries)
        - Persistence: \(persistence.isHealthy ? "✅" : "❌") (\(persistence.entriesCount) entries)
        - Remote: \(remote.isHealthy ? "✅" : "❌")
        
        Issues:
        \(overall.criticalIssues.isEmpty ? "- No critical issues" : overall.criticalIssues.map { "🚨 \($0)" }.joined(separator: "\n"))
        \(overall.warnings.isEmpty ? "- No warnings" : overall.warnings.map { "⚠️ \($0)" }.joined(separator: "\n"))
        """
    }
}