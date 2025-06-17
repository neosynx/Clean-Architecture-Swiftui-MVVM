//
//  WeatherViewModelTests.swift
//  ExampleMVVMTests
//
//  Created by MacBook Air M1 on 20/6/24.
//

import XCTest
@testable import StarterApp

class WeatherViewModelTests: XCTestCase {
    
    func testWeatherStoreInitialization() {
        let configuration = AppConfiguration()
        let networkService = NetworkService(configuration: configuration)
        let weatherService = WeatherService(networkService: networkService, useLocalData: true)
        let weatherStore = WeatherStore(weatherService: weatherService)
        
        XCTAssertNotNil(weatherStore)
    }
    
    func testAppContainerCreatesWeatherStore() {
        let appContainer = AppContainer()
        let weatherStore = appContainer.makeWeatherStore()
        
        XCTAssertNotNil(weatherStore)
    }
}

