//
//  Extension+Logger.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - AppLogger Convenience Extensions

extension AppLogger {
    
    // MARK: - Performance Monitoring
    
    /// Log the execution time of a block of code
    func logExecutionTime<T>(operation: String, file: String = #file, function: String = #function, line: Int = #line, _ block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            info("⏱️ \(operation) completed in \(String(format: "%.3f", timeElapsed))s", file: file, function: function, line: line)
        }
        return try block()
    }
    
    /// Log the execution time of an async block of code
    func logExecutionTime<T>(operation: String, file: String = #file, function: String = #function, line: Int = #line, _ block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            info("⏱️ \(operation) completed in \(String(format: "%.3f", timeElapsed))s", file: file, function: function, line: line)
        }
        return try await block()
    }
    
    // MARK: - Lifecycle Logging
    
    /// Log view lifecycle events
    func logViewLifecycle(_ event: ViewLifecycleEvent, view: String, file: String = #file, function: String = #function, line: Int = #line) {
        debug("📱 \(view) - \(event.rawValue)", file: file, function: function, line: line)
    }
    
    /// Log app lifecycle events
    func logAppLifecycle(_ event: AppLifecycleEvent, file: String = #file, function: String = #function, line: Int = #line) {
        info("🔄 App \(event.rawValue)", file: file, function: function, line: line)
    }
    
    // MARK: - User Action Logging
    
    /// Log user interactions
    func logUserAction(_ action: String, details: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        let detailsString = details.isEmpty ? "" : " - Details: \(details)"
        info("👤 User Action: \(action)\(detailsString)", file: file, function: function, line: line)
    }
    
    /// Log user navigation
    func logNavigation(from: String, to: String, file: String = #file, function: String = #function, line: Int = #line) {
        info("🧭 Navigation: \(from) → \(to)", file: file, function: function, line: line)
    }
    
    // MARK: - Data Operations
    
    /// Log data operations (CRUD)
    func logDataOperation(_ operation: DataOperation, entity: String, identifier: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let idString = identifier.map { " (ID: \($0))" } ?? ""
        info("💾 \(operation.rawValue) \(entity)\(idString)", file: file, function: function, line: line)
    }
    
    /// Log cache operations
    func logCacheOperation(_ operation: CacheOperation, key: String, hit: Bool? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var message = "🗄️ Cache \(operation.rawValue): \(key)"
        if let hit = hit {
            message += hit ? " [HIT]" : " [MISS]"
        }
        debug(message, file: file, function: function, line: line)
    }
    
    // MARK: - Network Logging Helpers
    
    /// Log API call start
    func logAPICallStart(endpoint: String, method: String, file: String = #file, function: String = #function, line: Int = #line) {
        info("🌐 Starting API call: \(method) \(endpoint)", file: file, function: function, line: line)
    }
    
    /// Log API call completion
    func logAPICallComplete(endpoint: String, statusCode: Int, duration: TimeInterval, file: String = #file, function: String = #function, line: Int = #line) {
        let statusEmoji = statusCode < 300 ? "✅" : statusCode < 500 ? "⚠️" : "❌"
        info("\(statusEmoji) API call completed: \(endpoint) [\(statusCode)] (\(String(format: "%.2f", duration))s)", file: file, function: function, line: line)
    }
    
    /// Log API call failure
    func logAPICallFailure(endpoint: String, error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        self.error("❌ API call failed: \(endpoint) - \(error.localizedDescription)", file: file, function: function, line: line)
    }
    
    // MARK: - Memory and Resource Logging
    
    /// Log memory usage
    func logMemoryUsage(file: String = #file, function: String = #function, line: Int = #line) {
        var memoryInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &memoryInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let memoryMB = Double(memoryInfo.resident_size) / 1024.0 / 1024.0
            info("🧠 Memory usage: \(String(format: "%.1f", memoryMB)) MB", file: file, function: function, line: line)
        }
    }
    
    // MARK: - Error Context Logging
    
    /// Log error with additional context
    func logError(_ error: Error, context: String, userInfo: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        var message = "❌ Error in \(context): \(error.localizedDescription)"
        
        if !userInfo.isEmpty {
            message += " - Context: \(userInfo)"
        }
        
        if let nsError = error as NSError? {
            message += " (Domain: \(nsError.domain), Code: \(nsError.code))"
        }
        
        self.error(message, file: file, function: function, line: line)
    }
    
    /// Log warning with context
    func logWarning(_ message: String, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        let contextString = context.isEmpty ? "" : " [\(context)]"
        notice("⚠️ Warning\(contextString): \(message)", file: file, function: function, line: line)
    }
}

// MARK: - Lifecycle Events

enum ViewLifecycleEvent: String {
    case appeared = "appeared"
    case disappeared = "disappeared"
    case loaded = "loaded"
    case unloaded = "unloaded"
}

enum AppLifecycleEvent: String {
    case launched = "launched"
    case becameActive = "became active"
    case willResignActive = "will resign active"
    case enteredBackground = "entered background"
    case willEnterForeground = "will enter foreground"
    case willTerminate = "will terminate"
}

// MARK: - Data Operations

enum DataOperation: String {
    case create = "CREATE"
    case read = "READ"
    case update = "UPDATE"
    case delete = "DELETE"
    case sync = "SYNC"
    case migrate = "MIGRATE"
}

enum CacheOperation: String {
    case get = "GET"
    case set = "SET"
    case remove = "REMOVE"
    case clear = "CLEAR"
    case expire = "EXPIRE"
}

// MARK: - Result Logging

extension AppLogger {
    
    /// Log the result of an operation
    func logResult<T, E: Error>(_ result: Result<T, E>, operation: String, file: String = #file, function: String = #function, line: Int = #line) {
        switch result {
        case .success:
            info("✅ \(operation) succeeded", file: file, function: function, line: line)
        case .failure(let error):
            self.error("❌ \(operation) failed: \(error.localizedDescription)", file: file, function: function, line: line)
        }
    }
    
    /// Log optional values
    func logOptional<T>(_ value: T?, context: String, file: String = #file, function: String = #function, line: Int = #line) {
        if value != nil {
            debug("✅ \(context): Value present", file: file, function: function, line: line)
        } else {
            debug("❌ \(context): Value is nil", file: file, function: function, line: line)
        }
    }
}

// MARK: - Conditional Logging

extension AppLogger {
    
    /// Log only in debug builds
    func debugOnly(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        debug(message, file: file, function: function, line: line)
        #endif
    }
    
    /// Log with condition
    func logIf(_ condition: Bool, level: LogLevel = .info, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard condition else { return }
        
        switch level {
        case .debug:
            debug(message, file: file, function: function, line: line)
        case .info:
            info(message, file: file, function: function, line: line)
        case .notice:
            notice(message, file: file, function: function, line: line)
        case .error:
            error(message, file: file, function: function, line: line)
        case .fault:
            fault(message, file: file, function: function, line: line)
        case .critical:
            critical(message, file: file, function: function, line: line)
        }
    }
}

// MARK: - Structured Logging

extension AppLogger {
    
    /// Log structured data
    func logStructured(
        event: String,
        category: String = "General",
        properties: [String: Any] = [:],
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let propertiesString = properties.isEmpty ? "" : " Properties: \(properties)"
        let message = "📊 [\(category)] \(event)\(propertiesString)"
        
        switch level {
        case .debug:
            debug(message, file: file, function: function, line: line)
        case .info:
            info(message, file: file, function: function, line: line)
        case .notice:
            notice(message, file: file, function: function, line: line)
        case .error:
            error(message, file: file, function: function, line: line)
        case .fault:
            fault(message, file: file, function: function, line: line)
        case .critical:
            critical(message, file: file, function: function, line: line)
        }
    }
}

// MARK: - Performance Profiling

extension AppLogger {
    
    /// Create a performance profiler
    func createProfiler(operation: String, file: String = #file, function: String = #function, line: Int = #line) -> PerformanceProfiler {
        return PerformanceProfiler(logger: self, operation: operation, file: file, function: function, line: line)
    }
}

// MARK: - Performance Profiler

class PerformanceProfiler {
    private let logger: AppLogger
    private let operation: String
    private let startTime: CFAbsoluteTime
    private var checkpoints: [(String, CFAbsoluteTime)] = []
    
    init(logger: AppLogger, operation: String, file: String = #file, function: String = #function, line: Int = #line) {
        self.logger = logger
        self.operation = operation
        self.startTime = CFAbsoluteTimeGetCurrent()
        logger.debug("🚀 Started profiling: \(operation)", file: file, function: function, line: line)
    }
    
    func checkpoint(_ name: String, file: String = #file, function: String = #function, line: Int = #line) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        checkpoints.append((name, currentTime))
        let elapsed = currentTime - startTime
        logger.debug("📍 \(operation) checkpoint '\(name)' at \(String(format: "%.3f", elapsed))s", file: file, function: function, line: line)
    }
    
    func finish(file: String = #file, function: String = #function, line: Int = #line) {
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("🏁 \(operation) completed in \(String(format: "%.3f", totalTime))s", file: file, function: function, line: line)
        
        if !checkpoints.isEmpty {
            logger.debug("📊 \(operation) checkpoint summary:", file: file, function: function, line: line)
            var previousTime = startTime
            for (name, time) in checkpoints {
                let stepTime = time - previousTime
                let totalTime = time - startTime
                logger.debug("  • \(name): +\(String(format: "%.3f", stepTime))s (total: \(String(format: "%.3f", totalTime))s)", file: file, function: function, line: line)
                previousTime = time
            }
        }
    }
}

// MARK: - Import Helper

/*
 Usage Examples:
 
 let logger = LoggerFactory.shared.createAppLogger()
 
 // Performance monitoring
 let result = logger.logExecutionTime(operation: "Data Processing") {
     // Your code here
     return processData()
 }
 
 // User action logging
 logger.logUserAction("Button Tapped", details: ["button": "save", "screen": "settings"])
 
 // Navigation logging
 logger.logNavigation(from: "Settings", to: "Profile")
 
 // API logging
 logger.logAPICallStart(endpoint: "/api/weather", method: "GET")
 // ... make API call ...
 logger.logAPICallComplete(endpoint: "/api/weather", statusCode: 200, duration: 0.5)
 
 // Performance profiling
 let profiler = logger.createProfiler(operation: "Data Sync")
 // ... do some work ...
 profiler.checkpoint("Data Fetched")
 // ... do more work ...
 profiler.checkpoint("Data Processed")
 // ... finish work ...
 profiler.finish()
 
 // Conditional logging
 logger.logIf(shouldLogDebugInfo, level: .debug, message: "Debug information")
 
 // Structured logging
 logger.logStructured(
     event: "User Login",
     category: "Authentication",
     properties: ["method": "email", "success": true]
 )
 */
