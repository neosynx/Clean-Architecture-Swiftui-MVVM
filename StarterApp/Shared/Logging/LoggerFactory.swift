//
//  LoggerFactoryProtocol.swift
//  StarterApp
//
//  Created by ryan arter on 2025/06/17.
//


// MARK: - Logger Factory Protocol

protocol LoggerFactory {
    func createLogger(category: String) -> AppLogger
    func createLogger(category: String, configuration: LoggingConfiguration) -> AppLogger
}
