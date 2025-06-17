//
//  WeatherView.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import SwiftUI

struct WeatherView: View {
    @Environment(WeatherStore.self) private var weatherStore
    @State private var cityName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                searchSection
                weatherContent
            }
            .navigationTitle("Weather")
            .task {
                if weatherStore.forecast == nil {
                    await loadDefaultWeather()
                }
            }
        }
    }
    
    private var searchSection: some View {
        HStack {
            TextField("Enter city name", text: $cityName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Search") {
                Task {
                    await searchWeather()
                }
            }
            .disabled(cityName.isEmpty || weatherStore.isLoading)
        }
        .padding()
    }
    
    @ViewBuilder
    private var weatherContent: some View {
        if weatherStore.isLoading {
            LoadingView()
        } else if let forecast = weatherStore.forecast {
            WeatherList(forecast: forecast)
        } else if let errorMessage = weatherStore.errorMessage {
            ErrorView(error: errorMessage) {
                Task {
                    await weatherStore.refreshWeather()
                }
            }
        } else {
            EmptyStateView(
                title: "No weather data",
                subtitle: "Search for a city to get started",
                systemImage: "cloud.sun"
            )
        }
    }
    
    private func searchWeather() async {
        await weatherStore.fetchWeather(for: cityName)
    }
    
    private func loadDefaultWeather() async {
        await weatherStore.fetchWeather(for: "London")
    }
}

struct WeatherList: View {
    let forecast: ForecastModel
    
    var body: some View {
        List {
            Section(header: Text(forecast.city.name)) {
                ForEach(forecast.weatherBundle, id: \.dateTime) { weather in
                    WeatherRowView(weather: weather)
                }
            }
        }
    }
}

