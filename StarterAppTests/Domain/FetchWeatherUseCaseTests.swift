//
//  FetchWeatherUseCaseTests.swift
//  ExampleMVVMTests
//
//  Created by MacBook Air M1 on 20/6/24.
//

import XCTest
@testable import StarterApp

class FetchWeatherUseCaseTests: XCTestCase {

    func testWeatherDataModel() {
        let weatherData = WeatherDataModel(name: "Clear")
        XCTAssertEqual(weatherData.name, "Clear")
        
        let weatherType = WeatherType(rawValue: "Clear")
        XCTAssertEqual(weatherType, .sunny)
    }
}

