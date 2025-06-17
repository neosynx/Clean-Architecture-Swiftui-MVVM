//
//  LoggingConfiguration.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Log Level

enum LogLevel: String, CaseIterable, Comparable {
    case debug = "debug"
    case info = "info"
    case notice = "notice"
    case error = "error"
    case fault = "fault"
    case critical = "critical"
    
    var emoji: String {
        switch self {
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .notice: return "📋"
        case .error: return "❌"
        case .fault: return "💥"
        case .critical: return "🚨"
        }
    }
    
    var priority: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .notice: return 2
        case .error: return 3
        case .fault: return 4
        case .critical: return 5
        }
    }
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.priority < rhs.priority
    }
}

// MARK: - Environment

enum LoggingEnvironment: String, CaseIterable {
    case debug = "Debug"
    case staging = "Staging" 
    case production = "Production"
    
    var isProduction: Bool {
        return self == .production
    }
    
    var isDebug: Bool {
        return self == .debug
    }
}

// MARK: - Log Format

enum LogFormat {
    case minimal        // Just emoji and message
    case standard       // Emoji, level, and message
    case detailed       // Full format with timestamp, file, line, function
}

// MARK: - Logging Configuration

struct LoggingConfiguration {
    
    // MARK: - Properties
    
    let environment: LoggingEnvironment
    let minimumLevel: LogLevel
    let format: LogFormat
    let enableConsoleOutput: Bool
    let enableFileLogging: Bool
    let consoleFallback: Bool
    let subsystem: String
    
    // MARK: - Initialization
    
    init(
        environment: LoggingEnvironment,
        minimumLevel: LogLevel,
        format: LogFormat = .standard,
        enableConsoleOutput: Bool = true,
        enableFileLogging: Bool = false,
        consoleFallback: Bool = false,
        subsystem: String = Bundle.main.bundleIdentifier ?? "com.starterapp"
    ) {
        self.environment = environment
        self.minimumLevel = minimumLevel
        self.format = format
        self.enableConsoleOutput = enableConsoleOutput
        self.enableFileLogging = enableFileLogging
        self.consoleFallback = consoleFallback
        self.subsystem = subsystem
    }
    
    // MARK: - Helper Methods
    
    func shouldLog(_ level: LogLevel) -> Bool {
        return level >= minimumLevel && enableConsoleOutput
    }
    
    // MARK: - Predefined Configurations
    
    static let `default`: LoggingConfiguration = {
        let environment = currentEnvironment()
        return configuration(for: environment)
    }()
    
    static func configuration(for environment: LoggingEnvironment) -> LoggingConfiguration {
        // Check for environment variable override
        let envLogLevel = ProcessInfo.processInfo.environment["STARTERAPP_LOG_LEVEL"]
        // Only enable console fallback when explicitly requested, not automatically in debug
        let shouldEnableConsoleFallback = envLogLevel?.lowercased() == "console"
        
        switch environment {
        case .debug:
            return LoggingConfiguration(
                environment: environment,
                minimumLevel: .debug,
                format: .detailed,
                enableConsoleOutput: true,
                enableFileLogging: true,
                consoleFallback: shouldEnableConsoleFallback
            )
            
        case .staging:
            return LoggingConfiguration(
                environment: environment,
                minimumLevel: .info,
                format: .standard,
                enableConsoleOutput: true,
                enableFileLogging: true,
                consoleFallback: shouldEnableConsoleFallback
            )
            
        case .production:
            return LoggingConfiguration(
                environment: environment,
                minimumLevel: .error,
                format: .minimal,
                enableConsoleOutput: false,
                enableFileLogging: true,
                consoleFallback: false
            )
        }
    }
    
    // MARK: - Environment Detection
    
    private static func currentEnvironment() -> LoggingEnvironment {
        #if DEBUG
        return .debug
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

// MARK: - Category Definitions

struct LogCategory {
    static let app = "App"
    static let ui = "UI"
    static let network = "Network"
    static let data = "Data"
    static let repository = "Repository"
    static let service = "Service"
    static let cache = "Cache"
    static let storage = "Storage"
    static let authentication = "Auth"
    static let analytics = "Analytics"
    static let performance = "Performance"
    static let security = "Security"
}

// MARK: - Logging Profiles

extension LoggingConfiguration {
    
    /// Debug console profile for immediate Xcode visibility
    static let debugConsole = LoggingConfiguration(
        environment: .debug,
        minimumLevel: .debug,
        format: .detailed,
        enableConsoleOutput: true,
        enableFileLogging: false,
        consoleFallback: true
    )
    
    /// Development profile with verbose logging
    static let development = LoggingConfiguration(
        environment: .debug,
        minimumLevel: .debug,
        format: .detailed,
        enableConsoleOutput: true,
        enableFileLogging: true,
        consoleFallback: true
    )
    
    /// Testing profile with reduced noise
    static let testing = LoggingConfiguration(
        environment: .debug,
        minimumLevel: .info,
        format: .standard,
        enableConsoleOutput: true,
        enableFileLogging: false
    )
    
    /// Release profile with minimal logging
    static let release = LoggingConfiguration(
        environment: .production,
        minimumLevel: .error,
        format: .minimal,
        enableConsoleOutput: false,
        enableFileLogging: true
    )
    
    /// Network debugging profile
    static let networkDebugging = LoggingConfiguration(
        environment: .debug,
        minimumLevel: .debug,
        format: .detailed,
        enableConsoleOutput: true,
        enableFileLogging: true
    )
    
    /// Performance monitoring profile
    static let performance = LoggingConfiguration(
        environment: .staging,
        minimumLevel: .notice,
        format: .standard,
        enableConsoleOutput: true,
        enableFileLogging: true
    )
}

// MARK: - Custom Configuration Builder

class LoggingConfigurationBuilder {
    private var environment: LoggingEnvironment = .debug
    private var minimumLevel: LogLevel = .info
    private var format: LogFormat = .standard
    private var enableConsoleOutput: Bool = true
    private var enableFileLogging: Bool = false
    private var consoleFallback: Bool = false
    private var subsystem: String = Bundle.main.bundleIdentifier ?? "com.starterapp"
    
    func environment(_ environment: LoggingEnvironment) -> LoggingConfigurationBuilder {
        self.environment = environment
        return self
    }
    
    func minimumLevel(_ level: LogLevel) -> LoggingConfigurationBuilder {
        self.minimumLevel = level
        return self
    }
    
    func format(_ format: LogFormat) -> LoggingConfigurationBuilder {
        self.format = format
        return self
    }
    
    func consoleOutput(_ enabled: Bool) -> LoggingConfigurationBuilder {
        self.enableConsoleOutput = enabled
        return self
    }
    
    func fileLogging(_ enabled: Bool) -> LoggingConfigurationBuilder {
        self.enableFileLogging = enabled
        return self
    }
    
    func consoleFallback(_ enabled: Bool) -> LoggingConfigurationBuilder {
        self.consoleFallback = enabled
        return self
    }
    
    func subsystem(_ subsystem: String) -> LoggingConfigurationBuilder {
        self.subsystem = subsystem
        return self
    }
    
    func build() -> LoggingConfiguration {
        return LoggingConfiguration(
            environment: environment,
            minimumLevel: minimumLevel,
            format: format,
            enableConsoleOutput: enableConsoleOutput,
            enableFileLogging: enableFileLogging,
            consoleFallback: consoleFallback,
            subsystem: subsystem
        )
    }
}

// MARK: - Usage Examples in Comments

/*
 Usage Examples:
 
 // Use default configuration based on build configuration
 let logger = AppLogger(subsystem: "com.starterapp", category: "Network")
 
 // Use predefined profile
 let devLogger = AppLogger(subsystem: "com.starterapp", category: "UI", configuration: .development)
 
 // Create custom configuration
 let customConfig = LoggingConfigurationBuilder()
     .environment(.staging)
     .minimumLevel(.notice)
     .format(.detailed)
     .consoleOutput(true)
     .fileLogging(true)
     .build()
 
 let customLogger = AppLogger(subsystem: "com.starterapp", category: "Data", configuration: customConfig)
 */