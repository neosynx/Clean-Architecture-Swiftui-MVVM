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
    
    init(networkService: NetworkService, configuration: AppConfiguration, logger: AppLogger) {
        self.apiKey = configuration.apiKey
        
        super.init(
            networkService: networkService,
            baseURL: configuration.baseURL,
            headers: [
                "Accept": "application/json",
                "Content-Type": "application/json"
            ],
            logger: logger
        )
    }
    
    // MARK: - URL Building Override
    
    override func buildURL(for city: String) -> String {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        return "\(baseURL)?q=\(encodedCity)&appid=\(apiKey)&units=metric"
    }
    
    // MARK: - Enhanced Error Handling
    
    override func fetch(for city: String) async throws -> ForecastApiDTO {
        logger.debug("☁️ WeatherRemoteService.fetch starting for city: \(city)")
        
        do {
            let result = try await super.fetch(for: city)
            logger.debug("☁️ WeatherRemoteService.fetch completed successfully")
            return result
        } catch {
            logger.error("☁️ WeatherRemoteService.fetch caught error:")
            logger.error("   🏷️ Error type: \(type(of: error))")
            logger.error("   📝 Error description: \(error.localizedDescription)")
            logger.error("   🔍 Full error: \(error)")
            
            // Map generic service errors to weather-specific errors
            if let serviceError = error as? ServiceError {
                logger.debug("   🔄 Re-throwing ServiceError: \(serviceError)")
                throw serviceError
            } else if let networkError = error as? NetworkError {
                logger.debug("   🔄 Mapping NetworkError to ServiceError:")
                switch networkError {
                case .invalidURL:
                    logger.debug("      ➡️ invalidURL → invalidData")
                    throw ServiceError.invalidData
                case .noData:
                    logger.debug("      ➡️ noData → notFound")
                    throw ServiceError.notFound
                case .decodingError:
                    logger.debug("      ➡️ decodingError → invalidData")
                    throw ServiceError.invalidData
                case .networkError:
                    logger.debug("      ➡️ networkError → networkUnavailable")
                    throw ServiceError.networkUnavailable
                case .httpError(let statusCode):
                    logger.debug("      ➡️ httpError(\(statusCode)) → serviceUnavailable")
                    throw ServiceError.serviceUnavailable
                case .unknown:
                    logger.debug("      ➡️ unknown → serviceUnavailable")
                    throw ServiceError.serviceUnavailable
                }
            } else {
                logger.debug("   🔄 Unhandled error type, mapping to serviceUnavailable")
                throw ServiceError.serviceUnavailable
            }
        }
    }
}
