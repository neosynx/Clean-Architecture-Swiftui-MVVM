//
//  WeatherDataSource.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation

// MARK: - Remote Data Source Protocol

protocol WeatherRemoteDataSource {
    func fetchWeather(for city: String) async throws -> ForecastModel
}

// MARK: - Local Data Source Protocol

protocol WeatherLocalDataSource {
    func fetchWeather(for city: String) async throws -> ForecastModel?
    func saveWeather(_ forecast: ForecastModel) async throws
    func deleteWeather(for city: String) async throws
    func getAllSavedCities() async throws -> [String]
    func clearAll() async throws
}

// MARK: - Cache Data Source Protocol

protocol WeatherCacheDataSource {
    func getCachedWeather(for city: String) async throws -> ForecastModel?
    func cacheWeather(_ forecast: ForecastModel) async throws
    func clearCache() async throws
    func isExpired(for city: String) async -> Bool
}