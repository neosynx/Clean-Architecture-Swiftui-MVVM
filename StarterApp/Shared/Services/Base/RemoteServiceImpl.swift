//
//  GenericRemoteService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Generic Remote Service

/// Generic base class for remote data services
class RemoteServiceImpl<Key: Hashable, Value: Codable>: RemoteDataService {
    typealias Key = Key
    typealias Value = Value
    
    // MARK: - Properties
    
     let networkService: NetworkService
     let baseURL: String
     let headers: [String: String]
    
    // MARK: - Initialization
    
    init(
        networkService: NetworkService,
        baseURL: String,
        headers: [String: String] = [:]
    ) {
        self.networkService = networkService
        self.baseURL = baseURL
        self.headers = headers
    }
    
    // MARK: - RemoteDataService Protocol
    
    func fetch(for key: Key) async throws -> Value {
        guard await isAvailable() else {
            throw ServiceError.networkUnavailable
        }
        
        let url = buildURL(for: key)
        
        do {
            print("fetch \(Value.self), url: \(url)")
            return try await networkService.fetch(Value.self, from: url)
        } catch {
            throw ServiceError.notFound
        }
    }
    
    func isAvailable() async -> Bool {
        print("🔍 RemoteService.isAvailable checking network connectivity...")
        
        // Basic network connectivity check
        guard let url = URL(string: "https://www.google.com") else {
            print("   ❌ Failed to create Google URL for connectivity check")
            return false
        }
        
        do {
            print("   📡 Testing connectivity to google.com...")
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                let isAvailable = httpResponse.statusCode == 200
                print("   📊 Google.com status: \(httpResponse.statusCode)")
                print("   🌐 Network available: \(isAvailable)")
                return isAvailable
            } else {
                print("   ⚠️ Non-HTTP response from google.com")
                return false
            }
        } catch {
            print("   ❌ Connectivity check failed:")
            print("      🏷️ Error type: \(type(of: error))")
            print("      📝 Error: \(error.localizedDescription)")
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
