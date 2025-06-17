//
//  DependencyContainerTests.swift
//  ExampleMVVMTests
//
//  Created by Claude on 17/6/25.
//

import XCTest
@testable import ExampleMVVM

class DependencyContainerTests: XCTestCase {
    var dependencyContainer: DependencyContainer!

    override func setUp() {
        super.setUp()
        dependencyContainer = DependencyContainer()
    }

    override func tearDown() {
        dependencyContainer = nil
        super.tearDown()
    }

    func testDependencyContainerInitialization() {
        XCTAssertNotNil(dependencyContainer.apiClient)
        XCTAssertNotNil(dependencyContainer.configuration)
        XCTAssertNotNil(dependencyContainer.jsonLoader)
        XCTAssertNotNil(dependencyContainer.weatherRepository)
        XCTAssertNotNil(dependencyContainer.fetchWeatherUseCase)
    }

    func testInitialDataSourceSetting() {
        XCTAssertTrue(dependencyContainer.useLocalData)
    }

    func testSwitchDataSource() {
        let initialValue = dependencyContainer.useLocalData
        dependencyContainer.switchDataSource()
        XCTAssertNotEqual(dependencyContainer.useLocalData, initialValue)
    }
}