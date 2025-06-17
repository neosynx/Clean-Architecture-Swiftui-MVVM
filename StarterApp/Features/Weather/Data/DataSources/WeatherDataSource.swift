//
//  WeatherDataSource.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Remote Data Source Protocol

protocol WeatherRemoteDataSource {
    func fetchWeather(for city: String) async throws -> ForecastApiDTO
}

// MARK: - Local Data Source Protocol

protocol WeatherLocalDataSource {
    func fetchWeather(for city: String) async throws -> ForecastFileDTO?
    func saveWeather(_ forecast: ForecastFileDTO) async throws
    func deleteWeather(for city: String) async throws
    func getAllSavedCities() async throws -> [String]
    func clearAll() async throws
}

// MARK: - Cache Data Source Protocol

protocol WeatherCacheDataSource {
    func getCachedWeather(for city: String) async throws -> ForecastFileDTO?
    func cacheWeather(_ forecast: ForecastFileDTO) async throws
    func clearCache() async throws
    func isExpired(for city: String) async -> Bool
}