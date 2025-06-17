//
//  AppLogger.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation
import os.log



// MARK: - Logger Implementation

@available(iOS 14.0, *)
final class AppLoggerImpl: AppLogger {
    
    // MARK: - Properties
    
    private let logger: Logger
    private let configuration: LoggingConfiguration
    
    // MARK: - Initialization
    
    init(subsystem: String, category: String, configuration: LoggingConfiguration = .default) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.configuration = configuration
    }
    
    // MARK: - Logging Methods
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.debug) else { return }
        
        let formattedMessage = formatMessage(message, level: .debug, file: file, function: function, line: line)
        logger.debug("\(formattedMessage, privacy: .public)")
        
        // Also output to console for immediate Xcode visibility if enabled
        if configuration.consoleFallback {
            print(formattedMessage)
        }
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.info) else { return }
        
        let formattedMessage = formatMessage(message, level: .info, file: file, function: function, line: line)
        logger.info("\(formattedMessage, privacy: .public)")
        
        // Also output to console for immediate Xcode visibility if enabled
        if configuration.consoleFallback {
            print(formattedMessage)
        }
    }
    
    func notice(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.notice) else { return }
        
        let formattedMessage = formatMessage(message, level: .notice, file: file, function: function, line: line)
        logger.notice("\(formattedMessage, privacy: .public)")
        
        // Also output to console for immediate Xcode visibility if enabled
        if configuration.consoleFallback {
            print(formattedMessage)
        }
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.error) else { return }
        
        let formattedMessage = formatMessage(message, level: .error, file: file, function: function, line: line)
        logger.error("\(formattedMessage, privacy: .public)")
        
        // Also output to console for immediate Xcode visibility if enabled
        if configuration.consoleFallback {
            print(formattedMessage)
        }
    }
    
    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.fault) else { return }
        
        let formattedMessage = formatMessage(message, level: .fault, file: file, function: function, line: line)
        logger.fault("\(formattedMessage, privacy: .public)")
        
        // Also output to console for immediate Xcode visibility if enabled
        if configuration.consoleFallback {
            print(formattedMessage)
        }
    }
    
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.critical) else { return }
        
        let formattedMessage = formatMessage(message, level: .critical, file: file, function: function, line: line)
        logger.critical("\(formattedMessage, privacy: .public)")
        
        // Also output to console for immediate Xcode visibility if enabled
        if configuration.consoleFallback {
            print(formattedMessage)
        }
    }
    
    // MARK: - Private Methods
    
    private func formatMessage(_ message: String, level: LogLevel, file: String, function: String, line: Int) -> String {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        
        switch configuration.format {
        case .minimal:
            return "\(level.emoji) \(message)"
        case .standard:
            return "\(level.emoji) [\(level.rawValue.uppercased())] \(message)"
        case .detailed:
            return "\(timestamp) \(level.emoji) [\(level.rawValue.uppercased())] [\(fileName):\(line)] \(function) - \(message)"
        }
    }
}

// MARK: - Privacy-Aware Logging Extensions

//@available(iOS 14.0, *)
extension AppLoggerImpl {
    
    /// Log sensitive information with privacy protection
    func debugPrivate(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.debug) else { return }
        
        let formattedMessage = formatMessage(message, level: .debug, file: file, function: function, line: line)
        logger.debug("\(formattedMessage, privacy: .private)")
    }
    
    /// Log network requests with privacy handling
    func logNetworkRequest(url: String, method: String, headers: [String: String] = [:]) {
        guard configuration.shouldLog(.info) else { return }
        
        let sanitizedHeaders = sanitizeHeaders(headers)
        let message = "🌐 Network Request: \(method) \(url) Headers: \(sanitizedHeaders)"
        logger.info("\(message, privacy: .public)")
    }
    
    /// Log network responses with privacy handling
    func logNetworkResponse(url: String, statusCode: Int, responseTime: TimeInterval) {
        guard configuration.shouldLog(.info) else { return }
        
        let message = "🌐 Network Response: \(statusCode) \(url) (\(String(format: "%.2f", responseTime))s)"
        logger.info("\(message, privacy: .public)")
    }
    
    /// Log errors with context
    func logError(_ error: Error, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        let contextString = context.isEmpty ? "" : " Context: \(context)"
        let message = "❌ Error: \(error.localizedDescription)\(contextString)"
        self.error(message, file: file, function: function, line: line)
    }
    
    // MARK: - Private Helpers
    
    private func sanitizeHeaders(_ headers: [String: String]) -> [String: String] {
        let sensitiveKeys = Set(["authorization", "x-api-key", "cookie", "x-auth-token"])
        
        return headers.reduce(into: [:]) { result, element in
            let (key, value) = element
            result[key] = sensitiveKeys.contains(key.lowercased()) ? "***REDACTED***" : value
        }
    }
}

// MARK: - Fallback Logger for iOS < 14
/*
final class LegacyAppLogger: AppLoggerProtocol {
    
    private let configuration: LoggingConfiguration
    
    init(configuration: LoggingConfiguration = .default) {
        self.configuration = configuration
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.debug) else { return }
        logToConsole(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.info) else { return }
        logToConsole(message, level: .info, file: file, function: function, line: line)
    }
    
    func notice(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.notice) else { return }
        logToConsole(message, level: .notice, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.error) else { return }
        logToConsole(message, level: .error, file: file, function: function, line: line)
    }
    
    func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.fault) else { return }
        logToConsole(message, level: .fault, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard configuration.shouldLog(.critical) else { return }
        logToConsole(message, level: .critical, file: file, function: function, line: line)
    }
    
    private func logToConsole(_ message: String, level: LogLevel, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        
        let formattedMessage: String
        switch configuration.format {
        case .minimal:
            formattedMessage = "\(level.emoji) \(message)"
        case .standard:
            formattedMessage = "\(level.emoji) [\(level.rawValue.uppercased())] \(message)"
        case .detailed:
            formattedMessage = "\(timestamp) \(level.emoji) [\(level.rawValue.uppercased())] [\(fileName):\(line)] \(function) - \(message)"
        }
        
        print(formattedMessage)
    }
}*/
// MARK: - DateFormatter Extension

private extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
