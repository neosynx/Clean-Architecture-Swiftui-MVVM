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
        let weatherRepository = makeWeatherRepository()
        return WeatherStore(weatherRepository: weatherRepository)
    }
    
    // MARK: - Repository Factories
    private func makeWeatherRepository() -> WeatherRepository {
        // Create services based on availability and environment
        let remoteService = createWeatherRemoteService()
        let fileService = createWeatherFileService()
        let cacheService = createWeatherCacheService()
        
        // Choose strategy based on environment and preferences
        let strategy: WeatherRepositoryImpl.DataStrategy = .cacheFirst
        
        return WeatherRepositoryImpl(
            remoteService: remoteService,
            fileService: fileService,
            cacheService: cacheService,
            strategy: strategy,
            enableFallback: true
        )
    }
    
    private func createWeatherRemoteService() -> WeatherRemoteService? {
        // Only create remote service if not in local-only mode
        guard !useLocalData else { return nil }
        
        return WeatherRemoteService(
            networkService: networkService,
            configuration: configuration
        )
    }
    
    private func createWeatherFileService() -> WeatherFileService? {
        // Always create file service for local storage
        return WeatherFileService()
    }
    
    private func createWeatherCacheService() -> CacheServiceImpl<String, ForecastFileDTO> {
        // Cache configuration based on environment
        let expirationInterval: TimeInterval = environment == .development ? 300 : 600 // 5 min dev, 10 min prod
        let maxEntries = environment == .development ? 20 : 50
        
        return CacheServiceImpl<String, ForecastFileDTO>(
            expirationInterval: expirationInterval,
            maxEntries: maxEntries
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
        print("🌐 NetworkService.fetch starting...")
        print("   📍 URL: \(url)")
        print("   🎯 Target Type: \(type)")
        
        guard let url = URL(string: url) else {
            print("   ❌ Invalid URL format: \(url)")
            throw NetworkError.invalidURL
        }
        print("   ✅ URL validation passed")
        
        do {
            print("   📡 Making URLSession request...")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Log response details
            if let httpResponse = response as? HTTPURLResponse {
                print("   📊 HTTP Status: \(httpResponse.statusCode)")
                print("   📋 Response Headers: \(httpResponse.allHeaderFields)")
                
                // Check for non-200 status codes
                if !(200...299).contains(httpResponse.statusCode) {
                    print("   ⚠️ Non-success status code: \(httpResponse.statusCode)")
                }
            }
            
            print("   📦 Response data size: \(data.count) bytes")
            
            // Log raw response for debugging (first 500 chars)
            if let responseString = String(data: data, encoding: .utf8) {
                let preview = String(responseString.prefix(500))
                print("   📄 Response preview: \(preview)")
                if responseString.count > 500 {
                    print("   📄 ... (truncated, full size: \(responseString.count) chars)")
                }
            } else {
                print("   ⚠️ Could not convert response data to string")
            }
            
            // Attempt JSON decoding
            print("   🔄 Attempting JSON decode to \(type)...")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let result = try decoder.decode(type, from: data)
            print("   ✅ JSON decode successful")
            return result
            
        } catch let decodingError as DecodingError {
            print("   ❌ JSON Decoding Error:")
            switch decodingError {
            case .dataCorrupted(let context):
                print("      💥 Data corrupted: \(context.debugDescription)")
                print("      🗂️ Coding path: \(context.codingPath)")
            case .keyNotFound(let key, let context):
                print("      🔑 Key not found: \(key.stringValue)")
                print("      📍 Context: \(context.debugDescription)")
                print("      🗂️ Coding path: \(context.codingPath)")
            case .typeMismatch(let type, let context):
                print("      🔀 Type mismatch for type: \(type)")
                print("      📍 Context: \(context.debugDescription)")
                print("      🗂️ Coding path: \(context.codingPath)")
            case .valueNotFound(let type, let context):
                print("      🚫 Value not found for type: \(type)")
                print("      📍 Context: \(context.debugDescription)")
                print("      🗂️ Coding path: \(context.codingPath)")
            @unknown default:
                print("      ❓ Unknown decoding error: \(decodingError)")
            }
            throw NetworkError.noData
            
        } catch let urlError as URLError {
            print("   ❌ URL Error:")
            print("      📟 Code: \(urlError.code.rawValue)")
            print("      📝 Description: \(urlError.localizedDescription)")
            print("      🌐 Failed URL: \(urlError.failureURLString ?? "nil")")
            
            switch urlError.code {
            case .notConnectedToInternet:
                print("      🚫 No internet connection")
            case .timedOut:
                print("      ⏰ Request timed out")
            case .cannotFindHost:
                print("      🏠 Cannot find host")
            case .cannotConnectToHost:
                print("      🔌 Cannot connect to host")
            case .networkConnectionLost:
                print("      📡 Network connection lost")
            case .dnsLookupFailed:
                print("      🔍 DNS lookup failed")
            case .httpTooManyRedirects:
                print("      🔄 Too many redirects")
            case .resourceUnavailable:
                print("      📭 Resource unavailable")
            case .badURL:
                print("      🚫 Bad URL")
            default:
                print("      ❓ Other URL error: \(urlError.localizedDescription)")
            }
            throw NetworkError.noData
            
        } catch {
            print("   ❌ Unexpected Error:")
            print("      📝 Description: \(error.localizedDescription)")
            print("      🔍 Full error: \(error)")
            throw NetworkError.noData
        }
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
