//
//  WeatherRemoteService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Weather Remote Service

/// Weather-specific remote service implementation
final class WeatherRemoteService: RemoteServiceImpl<String, ForecastApiDTO> {
    
    // MARK: - Properties
    
    private let apiKey: String
    
    // MARK: - Initialization
    
    init(networkService: NetworkService, configuration: AppConfiguration) {
        self.apiKey = configuration.apiKey
        
        super.init(
            networkService: networkService,
            baseURL: configuration.baseURL,
            headers: [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ]
        )
    }
    
    // MARK: - URL Building Override
    
    override func buildURL(for city: String) -> String {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        return "\(baseURL)?q=\(encodedCity)&appid=\(apiKey)&units=metric"
    }
    
    // MARK: - Enhanced Error Handling
    
    override func fetch(for city: String) async throws -> ForecastApiDTO {
        print("☁️ WeatherRemoteService.fetch starting for city: \(city)")
        
        do {
            let result = try await super.fetch(for: city)
            print("☁️ WeatherRemoteService.fetch completed successfully")
            return result
        } catch {
            print("☁️ WeatherRemoteService.fetch caught error:")
            print("   🏷️ Error type: \(type(of: error))")
            print("   📝 Error description: \(error.localizedDescription)")
            print("   🔍 Full error: \(error)")
            
            // Map generic service errors to weather-specific errors
            if let serviceError = error as? ServiceError {
                print("   🔄 Re-throwing ServiceError: \(serviceError)")
                throw serviceError
            } else if let networkError = error as? NetworkError {
                print("   🔄 Mapping NetworkError to ServiceError:")
                switch networkError {
                case .invalidURL:
                    print("      ➡️ invalidURL → invalidData")
                    throw ServiceError.invalidData
                case .noData:
                    print("      ➡️ noData → notFound")
                    throw ServiceError.notFound
                }
            } else {
                print("   🔄 Unhandled error type, mapping to serviceUnavailable")
                throw ServiceError.serviceUnavailable
            }
        }
    }
}
