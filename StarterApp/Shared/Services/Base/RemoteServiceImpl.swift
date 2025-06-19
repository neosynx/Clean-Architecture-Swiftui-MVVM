//
//  GenericRemoteService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation
import codeartis_logging

// MARK: - Generic Remote Service

/// Generic base class for remote data services
class RemoteServiceImpl<Key: Hashable, Value: Codable>: RemoteDataService {
    typealias Key = Key
    typealias Value = Value
    
    // MARK: - Properties
    
     let networkService: NetworkService
     let baseURL: String
     let headers: [String: String]
     let logger: CodeartisLogger
    
    // MARK: - Initialization
    
    init(
        networkService: NetworkService,
        baseURL: String,
        headers: [String: String] = [:],
        logger: CodeartisLogger
    ) {
        self.networkService = networkService
        self.baseURL = baseURL
        self.headers = headers
        self.logger = logger
    }
    
    // MARK: - RemoteDataService Protocol
    
    func fetch(for key: Key) async throws -> Value {
        guard await isAvailable() else {
            throw ServiceError.networkUnavailable
        }
        
        let url = buildURL(for: key)
        
        do {
            logger.debug("fetch \(Value.self), url: \(url)")
            return try await networkService.fetch(Value.self, from: url)
        } catch {
            throw ServiceError.notFound
        }
    }
    
    func isAvailable() async -> Bool {
        logger.debug("🔍 RemoteService.isAvailable checking network connectivity...")
        
        // Basic network connectivity check
        guard let url = URL(string: "https://www.google.com") else {
            logger.error("   ❌ Failed to create Google URL for connectivity check")
            return false
        }
        
        do {
            logger.debug("   📡 Testing connectivity to google.com...")
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                let isAvailable = httpResponse.statusCode == 200
                logger.debug("   📊 Google.com status: \(httpResponse.statusCode)")
                logger.debug("   🌐 Network available: \(isAvailable)")
                return isAvailable
            } else {
                logger.critical("   ⚠️ Non-HTTP response from google.com")
                return false
            }
        } catch {
            logger.error("   ❌ Connectivity check failed:")
            logger.error("      🏷️ Error type: \(type(of: error))")
            logger.error("      📝 Error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - URL Building (Override in subclasses)
    
    /// Override this method in subclasses to build specific URLs
    func buildURL(for key: Key) -> String {
        return "\(baseURL)/\(key)"
    }
    
    /// Override this method in subclasses to add specific headers
    func buildHeaders(for key: Key) -> [String: String] {
        return headers
    }
}
