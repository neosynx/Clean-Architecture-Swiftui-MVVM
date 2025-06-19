//
//  ContentView.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import SwiftUI

struct RootView: View {
    @Environment(AppContainerImpl.self) private var container
    @State private var weatherStore: WeatherStore?
    
    var body: some View {
        TabView {
            if let weatherStore = weatherStore {
                WeatherView()
                    .environment(weatherStore)
                    .tabItem {
                        Label("Weather", systemImage: "cloud.sun")
                    }
            } else {
                ProgressView("Loading...")
                    .tabItem {
                        Label("Weather", systemImage: "cloud.sun")
                    }
            }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .task {
            if weatherStore == nil {
                weatherStore = container.makeWeatherStore()
            }
        }
    }
}
