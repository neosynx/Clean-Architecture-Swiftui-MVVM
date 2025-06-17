//
//  FileDataService.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/17.
//


// MARK: - File Data Service Protocol

/// Protocol for services that load data from files
protocol FileDataService: DataService {
    /// Check if data exists for key
    func exists(for key: Key) async -> Bool
    
    /// Get all available keys
    func getAllKeys() async throws -> [Key]
}