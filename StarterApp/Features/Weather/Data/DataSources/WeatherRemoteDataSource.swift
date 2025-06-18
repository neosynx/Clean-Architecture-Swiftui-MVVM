//
//  WeatherRemoteDataSource.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//


/// Weather-specific remote data source - bridges to generic protocol
protocol WeatherRemoteDataSource: RemoteDataSource where Key == String, Model == ForecastModel {
    /// Fetch weather data from remote source
    func fetch(for city: String) async throws -> ForecastModel
    
    /// Check if remote service is available
    var isAvailable: Bool { get }
}
