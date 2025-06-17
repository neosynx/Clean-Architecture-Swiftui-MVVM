//
//  AnalyticsServiceProtocol.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/17.
//


// MARK: - Analytics Service Protocol

protocol AnalyticsService {
    func track(_ event: String)
    func track(_ event: String, properties: [String: Any])
    func setUser(id: String)
    func clearUser()
}
