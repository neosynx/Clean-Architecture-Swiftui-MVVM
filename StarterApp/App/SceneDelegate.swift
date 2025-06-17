//
//  SceneDelegate.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import SwiftUI

@Observable
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?
    var scenePhase: ScenePhase = .active
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        print("🌟 Scene will connect")
        
        // Handle any URLs if the app was launched from a URL
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        }
        
        // Handle any shortcut items if the app was launched from a shortcut
        if let shortcutItem = connectionOptions.shortcutItem {
            handleShortcutItem(shortcutItem)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        print("💫 Scene did disconnect")
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("⚡ Scene became active")
        scenePhase = .active
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        print("😪 Scene will resign active")
        scenePhase = .inactive
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("🌅 Scene will enter foreground")
        scenePhase = .active
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("🌃 Scene entered background")
        scenePhase = .background
        
        // Save user data if needed
        saveApplicationData()
    }
    
    // MARK: - URL Handling
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleURL(url)
    }
    
    private func handleURL(_ url: URL) {
        print("🔗 Handling URL: \(url)")
        
        // Parse and handle deep links
        switch url.scheme {
        case "examplemvvm":
            handleDeepLink(url)
        case "https", "http":
            handleWebLink(url)
        default:
            print("⚠️ Unknown URL scheme: \(url.scheme ?? "none")")
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        print("📱 Handling deep link: \(url.absoluteString)")
        
        // Example: examplemvvm://weather/london
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        
        switch pathComponents.first {
        case "weather":
            if pathComponents.count > 1 {
                let city = pathComponents[1]
                print("🌤️ Deep link to weather for city: \(city)")
                // Handle navigation to weather for specific city
            }
        default:
            print("⚠️ Unknown deep link path: \(url.path)")
        }
    }
    
    private func handleWebLink(_ url: URL) {
        print("🌐 Handling web link: \(url.absoluteString)")
        // Handle universal links
    }
    
    // MARK: - Shortcuts
    
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let success = handleShortcutItem(shortcutItem)
        completionHandler(success)
    }
    
    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        print("⚡ Handling shortcut: \(shortcutItem.type)")
        
        switch shortcutItem.type {
        case "com.example.weather.current":
            print("🌤️ Quick action: Show current weather")
            return true
        case "com.example.weather.forecast":
            print("📅 Quick action: Show forecast")
            return true
        default:
            return false
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveApplicationData() {
        print("💾 Saving application data...")
        // Implement data saving logic
        // This is where you would persist user data, cache, etc.
    }
}

// MARK: - Scene Phase Extensions

extension SceneDelegate {
    var isActive: Bool {
        scenePhase == .active
    }
    
    var isInBackground: Bool {
        scenePhase == .background
    }
    
    var isInactive: Bool {
        scenePhase == .inactive
    }
}