//
//  AppLifecycleManager.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import SwiftUI
import Combine

@Observable
class AppLifecycleManager {
    var isAppActive = true
    var isNetworkAvailable = true
    var backgroundTasksActive = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
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
        print("🟢 AppLifecycleManager: App became active")
        // Refresh data, resume timers, etc.
        refreshAppData()
    }
    
    private func handleAppWillResignActive() {
        print("🟡 AppLifecycleManager: App will resign active")
        // Pause timers, save user input, etc.
        pauseActiveOperations()
    }
    
    private func handleAppDidEnterBackground() {
        print("🔴 AppLifecycleManager: App entered background")
        backgroundTasksActive = true
        // Save important data, stop location updates, etc.
        saveUserData()
        startBackgroundTasks()
    }
    
    private func handleAppWillEnterForeground() {
        print("🟢 AppLifecycleManager: App will enter foreground")
        backgroundTasksActive = false
        // Restore UI, refresh data, etc.
        resumeFromBackground()
    }
    
    // MARK: - App State Management
    
    private func refreshAppData() {
        // Refresh weather data, user settings, etc.
        print("🔄 Refreshing app data...")
    }
    
    private func pauseActiveOperations() {
        // Pause any active operations
        print("⏸️ Pausing active operations...")
    }
    
    private func saveUserData() {
        // Save any unsaved user data
        print("💾 Saving user data...")
    }
    
    private func startBackgroundTasks() {
        // Start any necessary background tasks
        print("🌙 Starting background tasks...")
    }
    
    private func resumeFromBackground() {
        // Resume operations when coming back from background
        print("☀️ Resuming from background...")
        refreshAppData()
    }
    
    // MARK: - Network Management
    
    func updateNetworkStatus(_ isAvailable: Bool) {
        isNetworkAvailable = isAvailable
        print("🌐 Network status changed: \(isAvailable ? "Available" : "Unavailable")")
        
        if isAvailable {
            handleNetworkRestored()
        } else {
            handleNetworkLost()
        }
    }
    
    private func handleNetworkRestored() {
        print("✅ Network restored - syncing data...")
        // Sync pending data, retry failed requests, etc.
    }
    
    private func handleNetworkLost() {
        print("❌ Network lost - enabling offline mode...")
        // Enable offline mode, cache data, etc.
    }
    
    // MARK: - Memory Management
    
    func handleMemoryWarning() {
        print("⚠️ Memory warning received - cleaning up...")
        // Clear caches, release non-essential resources, etc.
        clearCaches()
    }
    
    private func clearCaches() {
        print("🧹 Clearing caches and temporary data...")
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