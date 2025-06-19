//
//  AppLifecycleManager.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import SwiftUI
import Combine
import codeartis_logging

// MARK: - App Lifecycle Manager Protocol

/// Protocol for managing application lifecycle events and state
/// This abstraction allows for easy testing and different implementations
protocol AppLifecycleManagerProtocol: Observable {
    /// Current app active state
    var isAppActive: Bool { get }
    
    /// Current network availability state
    var isNetworkAvailable: Bool { get }
    
    /// Background tasks active state
    var backgroundTasksActive: Bool { get }
    
    /// Update network status
    /// - Parameter isAvailable: Whether network is currently available
    func updateNetworkStatus(_ isAvailable: Bool)
    
    /// Handle memory warning
    func handleMemoryWarning()
    
    /// Check if background tasks can be performed
    var canPerformBackgroundTasks: Bool { get }
    
    /// Check if data should be refreshed
    var shouldRefreshData: Bool { get }
    
    /// Check if app is in optimal state
    var isInOptimalState: Bool { get }
}

// MARK: - App Lifecycle Manager Implementation

@Observable
class AppLifecycleManager: AppLifecycleManagerProtocol {
    var isAppActive = true
    var isNetworkAvailable = true
    var backgroundTasksActive = false
    
    private var cancellables = Set<AnyCancellable>()
    private let logger: CodeartisLogger
    
    init(logger: CodeartisLogger) {
        self.logger = logger
        logger.info("AppLifecycleManager initialized")
        setupLifecycleObservers()
    }
    
    private func setupLifecycleObservers() {
        // Listen to app lifecycle notifications
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { _ in
                self.isAppActive = true
                self.handleAppBecameActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { _ in
                self.isAppActive = false
                self.handleAppWillResignActive()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { _ in
                self.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in
                self.handleAppWillEnterForeground()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Lifecycle Handlers
    
    private func handleAppBecameActive() {
        logger.logAppLifecycle(.becameActive)
        // Refresh data, resume timers, etc.
        refreshAppData()
    }
    
    private func handleAppWillResignActive() {
        logger.logAppLifecycle(.willResignActive)
        // Pause timers, save user input, etc.
        pauseActiveOperations()
    }
    
    private func handleAppDidEnterBackground() {
        logger.logAppLifecycle(.enteredBackground)
        backgroundTasksActive = true
        // Save important data, stop location updates, etc.
        saveUserData()
        startBackgroundTasks()
    }
    
    private func handleAppWillEnterForeground() {
        logger.logAppLifecycle(.willEnterForeground)
        backgroundTasksActive = false
        // Restore UI, refresh data, etc.
        resumeFromBackground()
    }
    
    // MARK: - App State Management
    
    private func refreshAppData() {
        // Refresh weather data, user settings, etc.
        logger.info("Refreshing app data...")
    }
    
    private func pauseActiveOperations() {
        // Pause any active operations
        logger.info("Pausing active operations...")
    }
    
    private func saveUserData() {
        // Save any unsaved user data
        logger.info("Saving user data...")
    }
    
    private func startBackgroundTasks() {
        // Start any necessary background tasks
        logger.info("Starting background tasks...")
    }
    
    private func resumeFromBackground() {
        // Resume operations when coming back from background
        logger.info("Resuming from background...")
        refreshAppData()
    }
    
    // MARK: - Network Management
    
    func updateNetworkStatus(_ isAvailable: Bool) {
        isNetworkAvailable = isAvailable
        logger.info("Network status changed: \(isAvailable ? "Available" : "Unavailable")")
        
        if isAvailable {
            handleNetworkRestored()
        } else {
            handleNetworkLost()
        }
    }
    
    private func handleNetworkRestored() {
        logger.info("Network restored - syncing data...")
        // Sync pending data, retry failed requests, etc.
    }
    
    private func handleNetworkLost() {
        logger.notice("Network lost - enabling offline mode...")
        // Enable offline mode, cache data, etc.
    }
    
    // MARK: - Memory Management
    
    func handleMemoryWarning() {
        logger.notice("Memory warning received - cleaning up...")
        // Clear caches, release non-essential resources, etc.
        clearCaches()
    }
    
    private func clearCaches() {
        logger.info("Clearing caches and temporary data...")
        // Implement cache clearing logic
    }
}

// MARK: - Convenience Properties

extension AppLifecycleManager {
    var canPerformBackgroundTasks: Bool {
        backgroundTasksActive && !isAppActive
    }
    
    var shouldRefreshData: Bool {
        isAppActive && isNetworkAvailable
    }
    
    var isInOptimalState: Bool {
        isAppActive && isNetworkAvailable && !backgroundTasksActive
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
@Observable
final class MockAppLifecycleManager: AppLifecycleManagerProtocol {
    
    var isAppActive = true
    var isNetworkAvailable = true
    var backgroundTasksActive = false
    
    private(set) var networkStatusUpdates: [Bool] = []
    private(set) var memoryWarningCount = 0
    
    // MARK: - Mock Control Methods
    
    /// Simulate app becoming active
    func simulateAppBecameActive() {
        isAppActive = true
    }
    
    /// Simulate app going inactive
    func simulateAppWillResignActive() {
        isAppActive = false
    }
    
    /// Simulate app entering background
    func simulateAppDidEnterBackground() {
        isAppActive = false
        backgroundTasksActive = true
    }
    
    /// Simulate app entering foreground
    func simulateAppWillEnterForeground() {
        isAppActive = true
        backgroundTasksActive = false
    }
    
    /// Reset all mock state
    func reset() {
        isAppActive = true
        isNetworkAvailable = true
        backgroundTasksActive = false
        networkStatusUpdates.removeAll()
        memoryWarningCount = 0
    }
    
    // MARK: - Protocol Implementation
    
    func updateNetworkStatus(_ isAvailable: Bool) {
        isNetworkAvailable = isAvailable
        networkStatusUpdates.append(isAvailable)
    }
    
    func handleMemoryWarning() {
        memoryWarningCount += 1
    }
    
    var canPerformBackgroundTasks: Bool {
        backgroundTasksActive && !isAppActive
    }
    
    var shouldRefreshData: Bool {
        isAppActive && isNetworkAvailable
    }
    
    var isInOptimalState: Bool {
        isAppActive && isNetworkAvailable && !backgroundTasksActive
    }
    
    // MARK: - Test Helpers
    
    /// Check if network status was updated with specific value
    func wasNetworkStatusUpdated(to status: Bool) -> Bool {
        return networkStatusUpdates.contains(status)
    }
    
    /// Get number of network status updates
    var networkStatusUpdateCount: Int {
        return networkStatusUpdates.count
    }
}
#endif
