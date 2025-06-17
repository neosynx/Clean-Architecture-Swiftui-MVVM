//
//  RemoteDataService.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/17.
//


// MARK: - Remote Data Service Protocol

/// Protocol for services that fetch data from remote sources
protocol RemoteDataService: DataService {
    /// Check if remote service is available
    func isAvailable() async -> Bool
}
