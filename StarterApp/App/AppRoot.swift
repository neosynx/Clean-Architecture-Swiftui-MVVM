//
//  ExampleMVVMApp.swift
//  ExampleMVVM
//
//  Created by MacBook Air M1 on 19/6/24.
//

import SwiftUI
import FactoryKit

@main
struct AppRoot: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var container = AppContainerImpl()
    @State private var sceneDelegate = SceneDelegate()
    @State private var lifecycleManager: AppLifecycleManager
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        let appContainer = AppContainerImpl()
        let logger = appContainer.loggerFactory.createAppLogger()
        _container = State(initialValue: appContainer)
        _lifecycleManager = State(initialValue: AppLifecycleManager(logger: logger))
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .environment(appDelegate)
                .environment(sceneDelegate)
                .environment(lifecycleManager)
                // Factory-created stores via environment (constructor-injected, shared)
                .environment(Container.shared.weatherStore())
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                    lifecycleManager.handleMemoryWarning()
                }
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        let logger = container.loggerFactory.createAppLogger()
        
        switch phase {
        case .active:
            logger.info("App scene is now active", file: #file, function: #function, line: #line)
            lifecycleManager.isAppActive = true
        case .inactive:
            logger.info("App scene is now inactive", file: #file, function: #function, line: #line)
            lifecycleManager.isAppActive = false
        case .background:
            logger.info("App scene is now in background", file: #file, function: #function, line: #line)
            lifecycleManager.isAppActive = false
        @unknown default:
            logger.notice("Unknown scene phase detected", file: #file, function: #function, line: #line)
        }
    }
}


