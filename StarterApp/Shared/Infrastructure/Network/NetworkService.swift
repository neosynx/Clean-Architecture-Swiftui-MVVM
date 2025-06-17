//
//  NetworkServiceProtocol.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation
import Network

// MARK: - Network Configuration

struct NetworkConfiguration {
    let timeout: TimeInterval
    let retryAttempts: Int
    let retryDelay: TimeInterval
    let maxConcurrentRequests: Int
    let enableCaching: Bool
    let cachePolicy: URLRequest.CachePolicy
    let maxResponseSize: Int
    let waitsForConnectivity: Bool
    
    static let `default` = NetworkConfiguration(
        timeout: 30.0,
        retryAttempts: 3,
        retryDelay: 1.0,
        maxConcurrentRequests: 10,
        enableCaching: true,
        cachePolicy: .returnCacheDataElseLoad,
        maxResponseSize: 50 * 1024 * 1024, // 50MB
        waitsForConnectivity: true
    )
    
    static let fast = NetworkConfiguration(
        timeout: 10.0,
        retryAttempts: 1,
        retryDelay: 0.5,
        maxConcurrentRequests: 20,
        enableCaching: false,
        cachePolicy: .reloadIgnoringLocalCacheData,
        maxResponseSize: 10 * 1024 * 1024, // 10MB
        waitsForConnectivity: false
    )
}

// MARK: - Request Priority

enum RequestPriority: Float {
    case low = 0.25
    case normal = 0.5
    case high = 0.75
    case veryHigh = 1.0
}

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
    
    /// Fetches and decodes data with advanced options
    /// - Parameters:
    ///   - type: The type to decode the response into
    ///   - url: The URL string to fetch from
    ///   - headers: Additional HTTP headers
    ///   - priority: Request priority
    ///   - cachePolicy: Cache policy override
    /// - Returns: The decoded object of type T
    /// - Throws: NetworkError if the request fails
    func fetch<T: Codable>(
        _ type: T.Type,
        from url: String,
        headers: [String: String],
        priority: RequestPriority,
        cachePolicy: URLRequest.CachePolicy?
    ) async throws -> T
    
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
    
    /// Performs a request with retry logic and cancellation support
    /// - Parameters:
    ///   - url: The URL string
    ///   - method: HTTP method
    ///   - headers: HTTP headers
    ///   - body: Request body data
    ///   - priority: Request priority
    ///   - retryAttempts: Number of retry attempts (nil uses default)
    /// - Returns: Raw data response
    /// - Throws: NetworkError if the request fails
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        priority: RequestPriority,
        retryAttempts: Int?
    ) async throws -> Data
    
    /// Uploads data with progress tracking
    /// - Parameters:
    ///   - data: Data to upload
    ///   - url: Upload URL
    ///   - method: HTTP method
    ///   - headers: HTTP headers
    ///   - progressHandler: Progress callback
    /// - Returns: Server response data
    /// - Throws: NetworkError if upload fails
    func upload(
        data: Data,
        to url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> Data
    
    /// Downloads data with progress tracking
    /// - Parameters:
    ///   - url: Download URL
    ///   - destination: Local file URL
    ///   - progressHandler: Progress callback
    /// - Returns: Downloaded file URL
    /// - Throws: NetworkError if download fails
    func download(
        from url: String,
        to destination: URL?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> URL
}

// MARK: - Default Implementation

extension NetworkService {
    
    /// Convenience method for fetch without custom headers
    func fetch<T: Codable>(_ type: T.Type, from url: String) async throws -> T {
        return try await fetch(type, from: url, headers: [:])
    }
    
    /// Default implementation for advanced fetch
    func fetch<T: Codable>(
        _ type: T.Type,
        from url: String,
        headers: [String: String],
        priority: RequestPriority,
        cachePolicy: URLRequest.CachePolicy?
    ) async throws -> T {
        return try await fetch(type, from: url, headers: headers)
    }
    
    /// Default implementation for advanced request
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        priority: RequestPriority,
        retryAttempts: Int?
    ) async throws -> Data {
        return try await request(url: url, method: method, headers: headers, body: body)
    }
    
    /// Default implementation for upload
    func upload(
        data: Data,
        to url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> Data {
        return try await request(url: url, method: method, headers: headers, body: data)
    }
    
    /// Default implementation for download
    func download(
        from url: String,
        to destination: URL?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> URL {
        let data = try await request(url: url, method: .get, headers: nil, body: nil)
        
        let fileManager = FileManager.default
        let finalDestination = destination ?? {
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = url.components(separatedBy: "/").last ?? "download"
            return documentsPath.appendingPathComponent(fileName)
        }()
        
        try data.write(to: finalDestination)
        return finalDestination
    }
}

// MARK: - Network Errors

enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case networkError(Error)
    case httpError(statusCode: Int, data: Data?)
    case timeout
    case cancelled
    case unauthorized
    case forbidden
    case notFound
    case serverError(statusCode: Int)
    case noInternetConnection
    case sslError(Error)
    case requestTooLarge
    case responseTooLarge
    case invalidContentType(expected: String, received: String?)
    case rateLimited
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
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .unauthorized:
            return "Unauthorized access - invalid credentials"
        case .forbidden:
            return "Access forbidden - insufficient permissions"
        case .notFound:
            return "Resource not found"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .noInternetConnection:
            return "No internet connection available"
        case .sslError(let error):
            return "SSL/TLS error: \(error.localizedDescription)"
        case .requestTooLarge:
            return "Request payload too large"
        case .responseTooLarge:
            return "Response payload too large"
        case .invalidContentType(let expected, let received):
            return "Invalid content type. Expected: \(expected), received: \(received ?? "none")"
        case .rateLimited:
            return "Rate limit exceeded - too many requests"
        case .unknown:
            return "An unknown error occurred"
        }
    }
    
    var errorCode: Int {
        switch self {
        case .invalidURL: return 1001
        case .noData: return 1002
        case .decodingError: return 1003
        case .networkError: return 1004
        case .httpError(let statusCode, _): return statusCode
        case .timeout: return 1005
        case .cancelled: return 1006
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .serverError(let statusCode): return statusCode
        case .noInternetConnection: return 1007
        case .sslError: return 1008
        case .requestTooLarge: return 413
        case .responseTooLarge: return 1009
        case .invalidContentType: return 1010
        case .rateLimited: return 429
        case .unknown: return 1000
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .timeout, .noInternetConnection, .serverError, .rateLimited:
            return true
        case .networkError(let error):
            if let urlError = error as? URLError {
                return urlError.code == .timedOut || urlError.code == .networkConnectionLost
            }
            return false
        default:
            return false
        }
    }
}
