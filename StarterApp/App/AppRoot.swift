//
//  ExampleMVVMApp.swift
//  ExampleMVVM
//
//  Created by MacBook Air M1 on 19/6/24.
//

import SwiftUI

@main
struct AppRoot: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var container = AppContainer()
    @State private var sceneDelegate = SceneDelegate()
    @State private var lifecycleManager = AppLifecycleManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(appDelegate)
                .environment(sceneDelegate)
                .environment(lifecycleManager)
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    lifecycleManager.handleMemoryWarning()
                }
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("✅ App is now active")
            lifecycleManager.isAppActive = true
        case .inactive:
            print("⏸️ App is now inactive")
            lifecycleManager.isAppActive = false
        case .background:
            print("📱 App is now in background")
            lifecycleManager.isAppActive = false
        @unknown default:
            print("❓ Unknown scene phase")
        }
    }
}


