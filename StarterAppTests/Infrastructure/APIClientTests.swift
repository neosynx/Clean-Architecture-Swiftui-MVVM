//
//  APIClientTests.swift
//  ExampleMVVMTests
//
//  Created by MacBook Air M1 on 20/6/24.
//

import XCTest
@testable import StarterApp

class APIClientTests: XCTestCase {
    var apiClient: APIClient!

    override func setUp() {
        super.setUp()
        apiClient = APIClient()
    }

    override func tearDown() {
        apiClient = nil
        super.tearDown()
    }

    func testAPIClientInitialization() {
        XCTAssertNotNil(apiClient)
    }
}

