//
//  NetworkService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Network Service Implementation

/// Concrete implementation of NetworkServiceProtocol
/// Handles all network requests using URLSession with modern async/await
final class NetworkServiceImpl: NetworkService {
    
    // MARK: - Properties
    
    private let configuration: AppConfiguration
    private let logger: AppLogger
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    init(
        configuration: AppConfiguration,
        loggerFactory: LoggerFactoryImpl,
        session: URLSession = .shared
    ) {
        self.configuration = configuration
        self.logger = loggerFactory.createNetworkLogger()
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - NetworkServiceProtocol Implementation
    
    func fetch<T: Codable>(_ type: T.Type, from url: String, headers: [String: String]) async throws -> T {
        return try await logger.logExecutionTime(operation: "Network fetch for \(type)") {
            logger.logAPICallStart(endpoint: url, method: "GET")
            
            guard let requestUrl = URL(string: url) else {
                logger.error("Invalid URL format: \(url)")
                throw NetworkError.invalidURL
            }
            
            var request = URLRequest(url: requestUrl)
            headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
            
            let startTime = CFAbsoluteTimeGetCurrent()
            
            do {
                let (data, response) = try await session.data(for: request)
                let duration = CFAbsoluteTimeGetCurrent() - startTime
                
                try handleResponse(response, data: data, url: url, duration: duration)
                
                // Attempt JSON decoding
                logger.debug("Attempting JSON decode to \(type)")
                let result = try decoder.decode(type, from: data)
                logger.debug("JSON decode successful for \(type)")
                return result
                
            } catch let decodingError as DecodingError {
                logger.logAPICallFailure(endpoint: url, error: decodingError)
                logger.logError(decodingError, context: "JSON Decoding", userInfo: [
                    "targetType": String(describing: type),
                    "url": url
                ])
                throw NetworkError.decodingError(decodingError)
                
            } catch let urlError as URLError {
                logger.logAPICallFailure(endpoint: url, error: urlError)
                
                let errorContext = "URL Error: \(urlError.code.rawValue)"
                logger.logError(urlError, context: errorContext, userInfo: [
                    "failedURL": urlError.failureURLString ?? "unknown",
                    "code": urlError.code.rawValue
                ])
                
                throw NetworkError.networkError(urlError)
                
            } catch let networkError as NetworkError {
                // Re-throw NetworkError as-is
                throw networkError
                
            } catch {
                logger.logAPICallFailure(endpoint: url, error: error)
                logger.logError(error, context: "Network Request", userInfo: [
                    "url": url,
                    "targetType": String(describing: type)
                ])
                throw NetworkError.networkError(error)
            }
        }
    }
    
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?
    ) async throws -> Data {
        logger.logAPICallStart(endpoint: url, method: method.rawValue)
        
        guard let requestUrl = URL(string: url) else {
            logger.error("Invalid URL format: \(url)")
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let (data, response) = try await session.data(for: request)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            try handleResponse(response, data: data, url: url, duration: duration)
            
            return data
            
        } catch let urlError as URLError {
            logger.logAPICallFailure(endpoint: url, error: urlError)
            throw NetworkError.networkError(urlError)
            
        } catch let networkError as NetworkError {
            // Re-throw NetworkError as-is
            throw networkError
            
        } catch {
            logger.logAPICallFailure(endpoint: url, error: error)
            throw NetworkError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleResponse(_ response: URLResponse?, data: Data, url: String, duration: TimeInterval) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type for URL: \(url)")
            throw NetworkError.unknown
        }
        
        logger.logAPICallComplete(endpoint: url, statusCode: httpResponse.statusCode, duration: duration)
        logger.debug("Response data size: \(data.count) bytes")
        
        // Log response preview in debug mode only
        #if DEBUG
        if let responseString = String(data: data, encoding: .utf8) {
            let preview = String(responseString.prefix(200))
            logger.debug("Response preview: \(preview)\(responseString.count > 200 ? "..." : "")")
        }
        #endif
        
        // Check for HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("HTTP error status: \(httpResponse.statusCode)")
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Mock Implementation for Testing

#if DEBUG
class MockNetworkServiceImpl: NetworkService {
    
    var mockResponse: Any?
    var mockError: Error?
    var requestCount = 0
    var lastRequestURL: String?
    var lastRequestHeaders: [String: String]?
    
    func fetch<T: Codable>(_ type: T.Type, from url: String, headers: [String: String]) async throws -> T {
        requestCount += 1
        lastRequestURL = url
        lastRequestHeaders = headers
        
        if let error = mockError {
            throw error
        }
        
        if let response = mockResponse as? T {
            return response
        }
        
        throw NetworkError.noData
    }
    
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?
    ) async throws -> Data {
        requestCount += 1
        lastRequestURL = url
        lastRequestHeaders = headers
        
        if let error = mockError {
            throw error
        }
        
        if let data = mockResponse as? Data {
            return data
        }
        
        return Data()
    }
}
#endif
