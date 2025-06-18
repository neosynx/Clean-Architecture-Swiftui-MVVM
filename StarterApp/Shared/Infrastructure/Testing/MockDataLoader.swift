//
//  MockDataLoader.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

/// Service for loading mock data from JSON files for testing and development
/// This replaces network calls during testing and provides consistent test scenarios
final class MockDataLoader {
    
    // MARK: - Mock Scenarios
    
    enum MockScenario: String, CaseIterable {
        case weatherSuccess = "weather_success"
        case weatherError = "weather_error"
        case weatherEmpty = "weather_empty"
        case weatherPartial = "weather_partial"
        case networkTimeout = "network_timeout"
        case serverError = "server_error"
        case invalidData = "invalid_data"
        case offline = "offline"
        
        var fileName: String {
            rawValue
        }
        
        var description: String {
            switch self {
            case .weatherSuccess:
                return "Successful weather response with full data"
            case .weatherError:
                return "Weather API error response"
            case .weatherEmpty:
                return "Empty weather response"
            case .weatherPartial:
                return "Partial weather data (missing fields)"
            case .networkTimeout:
                return "Network timeout simulation"
            case .serverError:
                return "Server error (500) simulation"
            case .invalidData:
                return "Invalid JSON response"
            case .offline:
                return "Offline mode simulation"
            }
        }
    }
    
    // MARK: - Properties
    
    private let bundle: Bundle
    private let logger: AppLogger?
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    init(
        bundle: Bundle = .main,
        logger: AppLogger? = nil
    ) {
        self.bundle = bundle
        self.logger = logger
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Loading Methods
    
    /// Load mock response for a specific scenario
    func loadMockResponse<T: Decodable>(
        _ type: T.Type,
        scenario: MockScenario
    ) throws -> T {
        logger?.debug("Loading mock response for scenario: \(scenario.rawValue)")
        
        guard let url = bundle.url(
            forResource: scenario.fileName,
            withExtension: "json"
        ) else {
            logger?.error("Mock file not found: \(scenario.fileName).json")
            throw MockDataError.fileNotFound(scenario.fileName)
        }
        
        do {
            let data = try Data(contentsOf: url)
            let response = try decoder.decode(type, from: data)
            logger?.debug("Successfully loaded mock response: \(scenario.fileName)")
            return response
        } catch {
            logger?.error("Failed to decode mock data: \(error)")
            throw MockDataError.decodingFailed(error)
        }
    }
    
    /// Load mock response with custom file name
    func loadMockResponse<T: Decodable>(
        _ type: T.Type,
        fileName: String
    ) throws -> T {
        logger?.debug("Loading mock response from file: \(fileName)")
        
        guard let url = bundle.url(
            forResource: fileName,
            withExtension: "json"
        ) else {
            logger?.error("Mock file not found: \(fileName).json")
            throw MockDataError.fileNotFound(fileName)
        }
        
        do {
            let data = try Data(contentsOf: url)
            let response = try decoder.decode(type, from: data)
            logger?.debug("Successfully loaded mock response: \(fileName)")
            return response
        } catch {
            logger?.error("Failed to decode mock data: \(error)")
            throw MockDataError.decodingFailed(error)
        }
    }
    
    /// Load raw JSON data
    func loadRawData(scenario: MockScenario) throws -> Data {
        guard let url = bundle.url(
            forResource: scenario.fileName,
            withExtension: "json"
        ) else {
            throw MockDataError.fileNotFound(scenario.fileName)
        }
        
        return try Data(contentsOf: url)
    }
    
    /// Load JSON as dictionary
    func loadJSONDictionary(scenario: MockScenario) throws -> [String: Any] {
        let data = try loadRawData(scenario: scenario)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MockDataError.invalidFormat
        }
        
        return json
    }
    
    // MARK: - Request/Response Pairs
    
    /// Load request/response pair for API testing
    func loadRequestResponsePair(
        scenario: MockScenario
    ) throws -> RequestResponsePair {
        let fileName = "\(scenario.fileName)_pair"
        
        guard let url = bundle.url(
            forResource: fileName,
            withExtension: "json"
        ) else {
            throw MockDataError.fileNotFound(fileName)
        }
        
        let data = try Data(contentsOf: url)
        return try decoder.decode(RequestResponsePair.self, from: data)
    }
    
    // MARK: - Scenario Management
    
    /// Get all available scenarios
    func getAllScenarios() -> [MockScenario] {
        MockScenario.allCases.filter { scenarioExists($0) }
    }
    
    /// Check if scenario file exists
    func scenarioExists(_ scenario: MockScenario) -> Bool {
        bundle.url(forResource: scenario.fileName, withExtension: "json") != nil
    }
    
    /// Get scenario metadata
    func getScenarioMetadata() -> [ScenarioMetadata] {
        MockScenario.allCases.map { scenario in
            ScenarioMetadata(
                scenario: scenario,
                exists: scenarioExists(scenario),
                description: scenario.description
            )
        }
    }
}

// MARK: - Errors

enum MockDataError: LocalizedError {
    case fileNotFound(String)
    case decodingFailed(Error)
    case invalidFormat
    case scenarioNotSupported(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let fileName):
            return "Mock data file not found: \(fileName).json"
        case .decodingFailed(let error):
            return "Failed to decode mock data: \(error.localizedDescription)"
        case .invalidFormat:
            return "Invalid mock data format"
        case .scenarioNotSupported(let scenario):
            return "Mock scenario not supported: \(scenario)"
        }
    }
}

// MARK: - Supporting Types

/// Request/Response pair for API mocking
struct RequestResponsePair: Codable {
    let request: MockRequest
    let response: MockResponse
    let metadata: PairMetadata?
}

struct MockRequest: Codable {
    let url: String
    let method: String
    let headers: [String: String]?
    let body: String?
}

struct MockResponse: Codable {
    let statusCode: Int
    let headers: [String: String]?
    let body: String
    let delay: TimeInterval?
}

struct PairMetadata: Codable {
    let scenario: String
    let description: String
    let version: String
    let created: Date
}

/// Scenario metadata
struct ScenarioMetadata {
    let scenario: MockDataLoader.MockScenario
    let exists: Bool
    let description: String
}

// MARK: - Mock Response Builder

/// Helper for building mock responses in tests
final class MockResponseBuilder {
    private var statusCode: Int = 200
    private var headers: [String: String] = [:]
    private var body: String = ""
    private var delay: TimeInterval = 0.1
    
    func withStatusCode(_ code: Int) -> MockResponseBuilder {
        self.statusCode = code
        return self
    }
    
    func withHeader(_ key: String, value: String) -> MockResponseBuilder {
        self.headers[key] = value
        return self
    }
    
    func withBody(_ body: String) -> MockResponseBuilder {
        self.body = body
        return self
    }
    
    func withDelay(_ delay: TimeInterval) -> MockResponseBuilder {
        self.delay = delay
        return self
    }
    
    func build() -> MockResponse {
        MockResponse(
            statusCode: statusCode,
            headers: headers.isEmpty ? nil : headers,
            body: body,
            delay: delay
        )
    }
}

// MARK: - Test Data Generators

extension MockDataLoader {
    /// Generate mock weather data programmatically
    static func generateWeatherMockData(
        cityName: String = "London",
        temperature: Double = 20.0
    ) -> [String: Any] {
        [
            "city": [
                "id": 2643743,
                "name": cityName,
                "country": "GB",
                "timezone": 0
            ],
            "weather": [
                "temperature": [
                    "current": temperature,
                    "min": temperature - 5,
                    "max": temperature + 5,
                    "feelsLike": temperature + 2
                ],
                "condition": [
                    "main": "Clear",
                    "description": "clear sky",
                    "icon": "01d"
                ],
                "pressure": 1013,
                "humidity": 65,
                "visibility": 10000,
                "wind": [
                    "speed": 3.5,
                    "degree": 180
                ],
                "cloudiness": 0,
                "dataTime": ISO8601DateFormatter().string(from: Date()),
                "sys": [
                    "sunrise": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                    "sunset": ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600))
                ]
            ]
        ]
    }
}

// MARK: - Testing Extensions

#if DEBUG
extension MockDataLoader {
    /// Convenience method for testing
    static func test() -> MockDataLoader {
        MockDataLoader(logger: nil)
    }
    
    /// Create mock data loader with custom bundle (for unit tests)
    static func withBundle(_ bundle: Bundle) -> MockDataLoader {
        MockDataLoader(bundle: bundle)
    }
}
#endif