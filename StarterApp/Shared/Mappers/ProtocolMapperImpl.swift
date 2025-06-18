//
//  GenericProtocolMapper.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Generic Protocol Mapper

/// Base generic protocol mapper with common functionality
class ProtocolMapperImpl<DomainModel, RemoteDTO: Codable> {
    typealias DomainModelType = DomainModel
    typealias RemoteDTOType = RemoteDTO

    // MARK: - Protocol Requirements (Override in subclasses)
    
    func mapToDomain(_ dto: RemoteDTO) -> DomainModel {
        fatalError("mapToDomain(RemoteDTO) must be overridden in subclass")
    }
    
    // MARK: - Common Utilities
    
    /// Utility for date formatting
    let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()
    
    /// Utility for safe string conversion
    func safeString(_ value: String?) -> String {
        return value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    /// Utility for safe double conversion
     func safeDouble(_ value: Double?) -> Double {
        return value ?? 0.0
    }
    
    /// Utility for safe date parsing
     func safeDate(from string: String?) -> Date {
        guard let string = string,
              let date = iso8601Formatter.date(from: string) else {
            return Date()
        }
        return date
    }
    
    /// Utility for date to string conversion
     func dateString(from date: Date) -> String {
        return iso8601Formatter.string(from: date)
    }
}

// MARK: - Mapper Error

enum MapperError: Error, LocalizedError {
    case invalidData
    case missingRequiredField(String)
    case conversionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "Invalid data provided for mapping"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .conversionFailed(let details):
            return "Data conversion failed: \(details)"
        }
    }
}
