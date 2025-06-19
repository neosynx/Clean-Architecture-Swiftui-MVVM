//
//  SettingsView.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppContainerImpl.self) private var container
    
    var body: some View {
        NavigationView {
            Form {
                Section("Data Source") {
                    Toggle("Use Local Data", isOn: Binding(
                        get: { container.useLocalData },
                        set: { _ in container.switchDataSource() }
                    ))
                }
                
                Section("Environment") {
                    HStack {
                        Text("Current Environment")
                        Spacer()
                        Text(container.environment.displayName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Architecture")
                        Spacer()
                        Text("MV Pattern")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

extension AppEnvironment {
    var displayName: String {
        switch self {
        case .development: return "Development"
        case .staging: return "Staging"
        case .production: return "Production"
        }
    }
}