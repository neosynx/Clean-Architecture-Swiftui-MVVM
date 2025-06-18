//
//  for.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/17.
//


// MARK: - Protocol Mapper

/// Generic protocol for mapping between different data representations
protocol ProtocolMapper {
    associatedtype DomainModel
    associatedtype RemoteDTO: Codable

    /// Map remote DTO to domain model
    func mapToDomain(_ dto: RemoteDTO) -> DomainModel
    
   
}
