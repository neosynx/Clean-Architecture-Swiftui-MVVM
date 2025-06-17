//
//  AppContainer.swift
//  ExampleMVVM
//
//  Created by Claude on 17/6/25.
//

import Foundation

@Observable
class AppContainer {
    // MARK: - Configuration
    let configuration: AppConfiguration
    var environment: AppEnvironment = .production
    var useLocalData = false
    
    // MARK: - Core Services (Shared across features)
    private(set) var networkService: NetworkService
    private(set) var analyticsService: AnalyticsService
    
    // MARK: - Initialization
    init() {
        let env = AppEnvironment.production
        
        self.configuration = AppConfiguration()
        self.networkService = NetworkService(configuration: configuration)
        self.analyticsService = AnalyticsService(environment: env)
        self.environment = env
    }
    
    // MARK: - Store Factories (Feature-specific)
    func makeWeatherStore() -> WeatherStore {
        WeatherStore(
            weatherService: WeatherService(
                networkService: networkService,
                useLocalData: useLocalData
            )
        )
    }
    
    // MARK: - Environment Management
    func configureForEnvironment(_ env: AppEnvironment) {
        environment = env
    }
    
    // MARK: - Configuration
    func switchDataSource() {
        useLocalData.toggle()
        print("Switched to \(useLocalData ? "local" : "remote") data")
    }
}

enum AppEnvironment {
    case development, staging, production
}

// MARK: - Supporting Services
class NetworkService {
    private let configuration: AppConfiguration
    
    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }
    
    func fetch<T: Codable>(_ type: T.Type, from url: String) async throws -> T {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(type, from: data)
    }
}

class AnalyticsService {
    private let environment: AppEnvironment
    
    init(environment: AppEnvironment) {
        self.environment = environment
    }
    
    func track(_ event: String) {
        guard environment != .development else { return }
        print("📊 Analytics: \(event)")
    }
}

enum NetworkError: Error {
    case invalidURL
    case noData
}