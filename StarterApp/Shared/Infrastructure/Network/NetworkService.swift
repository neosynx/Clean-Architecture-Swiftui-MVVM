//
//  NetworkServiceProtocol.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Network Service Protocol

/// Protocol defining the contract for network services
/// This abstraction allows for different implementations and easy testing
protocol NetworkService {
    
    /// Fetches and decodes data from a URL
    /// - Parameters:
    ///   - type: The type to decode the response into
    ///   - url: The URL string to fetch from
    /// - Returns: The decoded object of type T
    /// - Throws: NetworkError if the request fails
    func fetch<T: Codable>(_ type: T.Type, from url: String) async throws -> T
    
    /// Fetches and decodes data from a URL with custom headers
    /// - Parameters:
    ///   - type: The type to decode the response into
    ///   - url: The URL string to fetch from
    ///   - headers: Additional HTTP headers
    /// - Returns: The decoded object of type T
    /// - Throws: NetworkError if the request fails
    func fetch<T: Codable>(_ type: T.Type, from url: String, headers: [String: String]) async throws -> T
    
    /// Performs a data request with full customization
    /// - Parameters:
    ///   - url: The URL string
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - headers: HTTP headers
    ///   - body: Request body data
    /// - Returns: Raw data response
    /// - Throws: NetworkError if the request fails
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?
    ) async throws -> Data
}

// MARK: - Default Implementation

extension NetworkService {
    
    /// Convenience method for fetch without custom headers
    func fetch<T: Codable>(_ type: T.Type, from url: String) async throws -> T {
        return try await fetch(type, from: url, headers: [:])
    }
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case httpError(statusCode: Int)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL format"
        case .noData:
            return "No data received from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
