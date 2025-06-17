//
//  LoggerFactory.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation


// MARK: - Logger Factory Implementation

final class LoggerFactoryImpl: LoggerFactory {
    
    // MARK: - Shared Instance
    
    /// Shared logger factory instance using default configuration
    static let shared: LoggerFactoryImpl = {
        let subsystem = Bundle.main.bundleIdentifier ?? "com.starterapp.default"
        return LoggerFactoryImpl(subsystem: subsystem)
    }()
    
    // MARK: - Properties
    
    private let defaultConfiguration: LoggingConfiguration
    private let subsystem: String
    
    // MARK: - Initialization
    
    init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.starterapp",
        configuration: LoggingConfiguration = .default
    ) {
        self.subsystem = subsystem
        self.defaultConfiguration = configuration
    }
    
    // MARK: - Factory Methods
    
    func createLogger(category: String) -> AppLogger {
        return createLogger(category: category, configuration: defaultConfiguration)
    }
    
    func createLogger(category: String, configuration: LoggingConfiguration) -> AppLogger {
        return AppLoggerImpl(subsystem: subsystem, category: category, configuration: configuration)
    }
    
    // MARK: - Convenience Methods for Common Categories
    
    func createAppLogger() -> AppLogger {
        return createLogger(category: LogCategory.app)
    }
    
    func createUILogger() -> AppLogger {
        return createLogger(category: LogCategory.ui)
    }
    
    func createNetworkLogger() -> AppLogger {
        return createLogger(category: LogCategory.network)
    }
    
    func createDataLogger() -> AppLogger {
        return createLogger(category: LogCategory.data)
    }
    
    func createRepositoryLogger() -> AppLogger {
        return createLogger(category: LogCategory.repository)
    }
    
    func createServiceLogger() -> AppLogger {
        return createLogger(category: LogCategory.service)
    }
    
    func createCacheLogger() -> AppLogger {
        return createLogger(category: LogCategory.cache)
    }
    
    func createStorageLogger() -> AppLogger {
        return createLogger(category: LogCategory.storage)
    }
    
    func createPerformanceLogger() -> AppLogger {
        return createLogger(category: LogCategory.performance)
    }
    
    func createSecurityLogger() -> AppLogger {
        return createLogger(category: LogCategory.security)
    }
}

// MARK: - Environment Specific Factories

extension LoggerFactory {
    
    /// Factory for development environment with verbose logging
    static func development(subsystem: String = Bundle.main.bundleIdentifier ?? "com.starterapp") -> LoggerFactory {
        return LoggerFactoryImpl(subsystem: subsystem, configuration: .development)
    }
    
    /// Factory for testing environment with reduced logging
    static func testing(subsystem: String = Bundle.main.bundleIdentifier ?? "com.starterapp") -> LoggerFactory {
        return LoggerFactoryImpl(subsystem: subsystem, configuration: .testing)
    }
    
    /// Factory for production environment with minimal logging
    static func production(subsystem: String = Bundle.main.bundleIdentifier ?? "com.starterapp") -> LoggerFactory {
        return LoggerFactoryImpl(subsystem: subsystem, configuration: .release)
    }
    
    /// Factory for network debugging
    static func networkDebugging(subsystem: String = Bundle.main.bundleIdentifier ?? "com.starterapp") -> LoggerFactory {
        return LoggerFactoryImpl(subsystem: subsystem, configuration: .networkDebugging)
    }
}


// MARK: - Feature-Specific Logger Factories

extension LoggerFactory {
    
    /// Create logger for Weather feature
    func createWeatherLogger() -> AppLogger {
        return createLogger(category: "Weather")
    }
    
    /// Create logger for Settings feature
    func createSettingsLogger() -> AppLogger {
        return createLogger(category: "Settings")
    }
    
    /// Create logger for a specific feature
    func createFeatureLogger(feature: String) -> AppLogger {
        return createLogger(category: feature)
    }
}

// MARK: - Performance Monitoring

extension LoggerFactory {
    
    /// Create logger specifically for performance monitoring
    func createPerformanceLogger(for component: String) -> AppLogger {
        let category = "\(LogCategory.performance).\(component)"
        return createLogger(category: category, configuration: .performance)
    }
    
    /// Create logger for memory monitoring
    func createMemoryLogger() -> AppLogger {
        return createLogger(category: "Memory", configuration: .performance)
    }
    
    /// Create logger for network performance
    func createNetworkPerformanceLogger() -> AppLogger {
        return createLogger(category: "NetworkPerformance", configuration: .networkDebugging)
    }
}

// MARK: - Mock Factory for Testing

#if DEBUG
final class MockLoggerFactory: LoggerFactory {
    
    private var loggers: [String: MockAppLogger] = [:]
    
    func createLogger(category: String) -> AppLogger {
        return createLogger(category: category, configuration: .testing)
    }
    
    func createLogger(category: String, configuration: LoggingConfiguration) -> AppLogger {
        if let existingLogger = loggers[category] {
            return existingLogger
        }
        
        let mockLogger = MockAppLogger(category: category)
        loggers[category] = mockLogger
        return mockLogger
    }
    
    func getLogger(for category: String) -> MockAppLogger? {
        return loggers[category]
    }
    
    func clearLogs() {
        loggers.values.forEach { $0.clearLogs() }
    }
}

final class MockAppLogger: AppLogger {
    
    struct LogEntry {
        let level: LogLevel
        let message: String
        let file: String
        let function: String
        let line: Int
        let timestamp: Date
    }
    
    private(set) var logs: [LogEntry] = []
    let category: String
    
    init(category: String) {
        self.category = category
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logs.append(LogEntry(level: .debug, message: message, file: file, function: function, line: line, timestamp: Date()))
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logs.append(LogEntry(level: .info, message: message, file: file, function: function, line: line, timestamp: Date()))
    }
    
    func notice(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logs.append(LogEntry(level: .notice, message: message, file: file, function: function, line: line, timestamp: Date()))
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logs.append(LogEntry(level: .error, message: message, file: file, function: function, line: line, timestamp: Date()))
    }
    
    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logs.append(LogEntry(level: .fault, message: message, file: file, function: function, line: line, timestamp: Date()))
    }
    
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        logs.append(LogEntry(level: .critical, message: message, file: file, function: function, line: line, timestamp: Date()))
    }
    
    func clearLogs() {
        logs.removeAll()
    }
    
    func logCount(for level: LogLevel) -> Int {
        return logs.filter { $0.level == level }.count
    }
    
    func containsMessage(_ message: String) -> Bool {
        return logs.contains { $0.message.contains(message) }
    }
}
#endif
