//
//  DataService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Base Data Service Protocol

/// Base protocol for all data services
protocol DataService {
    associatedtype Key: Hashable
    associatedtype Value: Codable
    
    /// Fetch data for the given key
    func fetch(for key: Key) async throws -> Value
}


// MARK: - Service Errors

enum ServiceError: Error, LocalizedError {
    case notFound
    case networkUnavailable
    case fileCorrupted
    case cacheExpired
    case invalidData
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Data not found"
        case .networkUnavailable:
            return "Network service unavailable"
        case .fileCorrupted:
            return "File data is corrupted"
        case .cacheExpired:
            return "Cached data has expired"
        case .invalidData:
            return "Invalid data format"
        case .serviceUnavailable:
            return "Service is currently unavailable"
        }
    }
}
