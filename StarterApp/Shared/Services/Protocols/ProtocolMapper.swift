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
    associatedtype FileDTO: Codable
    
    /// Map remote DTO to domain model
    func mapToDomain(_ dto: RemoteDTO) -> DomainModel
    
    /// Map file DTO to domain model
    func mapToDomain(_ dto: FileDTO) -> DomainModel
    
    /// Map domain model to file DTO
    func mapToFileDTO(_ model: DomainModel) -> FileDTO
}