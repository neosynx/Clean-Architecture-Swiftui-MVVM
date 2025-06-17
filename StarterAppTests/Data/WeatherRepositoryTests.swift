//
//  WeatherRepositoryTests.swift
//  ExampleMVVMTests
//
//  Created by MacBook Air M1 on 20/6/24.
//

import XCTest
@testable import StarterApp

class WeatherRepositoryTests: XCTestCase {

    func testWeatherModelCreation() {
        let city = City(name: "London", country: "UK")
        let forecast = ForecastModel(city: city, weatherBundle: [])
        
        XCTAssertEqual(forecast.city.name, "London")
        XCTAssertEqual(forecast.city.country, "UK")
        XCTAssertEqual(forecast.weatherBundle.count, 0)
    }
}

