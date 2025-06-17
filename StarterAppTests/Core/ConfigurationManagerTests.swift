//
//  ConfigurationManagerTests.swift
//  ExampleMVVMTests
//
//  Created by MacBook Air M1 on 20/6/24.
//

import XCTest
@testable import StarterApp

class ConfigurationManagerTests: XCTestCase {
    func testAppConfigurationLoadsValues() {
        let configuration = AppConfiguration()
        
        XCTAssertNotNil(configuration.baseURL)
        XCTAssertNotNil(configuration.apiKey)
        XCTAssertEqual(configuration.baseURL, "https://api.openweathermap.org/data/2.5/forecast")
        XCTAssertEqual(configuration.apiKey, "c8bea7fd8fb47ad823162954a2965e4b")
        XCTAssertEqual(configuration.localWeatherDataFilename, "weather_data")
    }
}
