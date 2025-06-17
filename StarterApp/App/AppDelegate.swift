//
//  AppDelegate.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import UIKit
import UserNotifications

@Observable
class AppDelegate: NSObject, UIApplicationDelegate {
    var isNetworkAvailable = true
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        print("🚀 App launched successfully")
        
        // Configure app-wide settings
        configureAppearance()
        setupNetworkMonitoring()
        requestNotificationPermissions()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("📱 App became active")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("😴 App will resign active")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("🌙 App entered background")
        startBackgroundTask()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("☀️ App will enter foreground")
        endBackgroundTask()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        print("💥 App will terminate")
    }
    
    // MARK: - Configuration
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
    
    private func setupNetworkMonitoring() {
        // In a real app, you would set up network monitoring here
        // For example, using Network framework
        print("🌐 Network monitoring configured")
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permissions granted")
                } else {
                    print("❌ Notification permissions denied")
                }
            }
        }
    }
    
    // MARK: - Background Tasks
    
    private func startBackgroundTask() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
        }
    }
}

// MARK: - Push Notifications

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle foreground notifications
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        print("📱 Notification tapped: \(response.notification.request.identifier)")
        completionHandler()
    }
}

// MARK: - Remote Notifications

extension AppDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("📱 Device Token: \(token)")
        
        // Send token to your server
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error)")
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("📱 Received remote notification")
        // Handle background fetch
        completionHandler(.newData)
    }
}

// MARK: - URL Handling

extension AppDelegate {
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        print("🔗 Opening URL: \(url)")
        // Handle deep links
        return true
    }
}