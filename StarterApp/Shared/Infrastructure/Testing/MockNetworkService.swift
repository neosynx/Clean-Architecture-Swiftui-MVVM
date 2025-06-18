//
//  MockNetworkService.swift
//  StarterApp
//
//  Created by Claude on 18/6/25.
//

import Foundation

/// Mock implementation of NetworkService for testing and development
/// Loads responses from JSON files instead of making real network calls
final class MockNetworkService: NetworkService {
    
    // MARK: - Properties
    
    private let mockDataLoader: MockDataLoader
    private let logger: AppLogger?
    
    // Test configuration
    var currentScenario: MockDataLoader.MockScenario = .weatherSuccess
    var networkDelay: TimeInterval = 0.5
    var shouldSimulateSlowNetwork = false
    var shouldSimulateOffline = false
    var shouldSimulateTimeout = false
    var failureRate: Double = 0.0 // 0.0 = never fail, 1.0 = always fail
    
    // Request tracking for verification
    var requestCount = 0
    var lastRequestURL: String?
    var lastRequestHeaders: [String: String]?
    var lastRequestMethod: HTTPMethod?
    var lastRequestBody: Data?
    
    // MARK: - Initialization
    
    init(
        bundle: Bundle = .main,
        logger: AppLogger? = nil
    ) {
        self.mockDataLoader = MockDataLoader(bundle: bundle, logger: logger)
        self.logger = logger
    }
    
    // MARK: - NetworkService Implementation
    
    func fetch<T: Codable>(_ type: T.Type, from url: String) async throws -> T {
        return try await fetch(type, from: url, headers: [:])
    }
    
    func fetch<T: Codable>(_ type: T.Type, from url: String, headers: [String: String]) async throws -> T {
        return try await fetch(
            type,
            from: url,
            headers: headers,
            priority: .normal,
            cachePolicy: nil
        )
    }
    
    func fetch<T: Codable>(
        _ type: T.Type,
        from url: String,
        headers: [String: String],
        priority: RequestPriority,
        cachePolicy: URLRequest.CachePolicy?
    ) async throws -> T {
        // Track request
        trackRequest(url: url, method: .get, headers: headers, body: nil)
        
        // Simulate network conditions
        try await simulateNetworkConditions()
        
        // Check for simulated failures
        try checkForSimulatedFailures()
        
        // Load mock response based on URL and scenario
        let scenario = determineScenario(for: url)
        
        do {
            let response = try mockDataLoader.loadMockResponse(type, scenario: scenario)
            logger?.debug("Mock fetch successful for \(type) from \(url)")
            return response
        } catch {
            logger?.error("Mock fetch failed: \(error)")
            throw NetworkError.decodingError(error)
        }
    }
    
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?
    ) async throws -> Data {
        return try await request(
            url: url,
            method: method,
            headers: headers,
            body: body,
            priority: .normal,
            retryAttempts: nil
        )
    }
    
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        priority: RequestPriority,
        retryAttempts: Int?
    ) async throws -> Data {
        // Track request
        trackRequest(url: url, method: method, headers: headers ?? [:], body: body)
        
        // Simulate network conditions
        try await simulateNetworkConditions()
        
        // Check for simulated failures
        try checkForSimulatedFailures()
        
        // Determine scenario and load raw data
        let scenario = determineScenario(for: url)
        
        do {
            let data = try mockDataLoader.loadRawData(scenario: scenario)
            logger?.debug("Mock request successful for \(method.rawValue) \(url)")
            return data
        } catch {
            logger?.error("Mock request failed: \(error)")
            throw NetworkError.networkError(error)
        }
    }
    
    func upload(
        data: Data,
        to url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> Data {
        // Track request
        trackRequest(url: url, method: method, headers: headers ?? [:], body: data)
        
        // Simulate upload progress
        await simulateUploadProgress(progressHandler: progressHandler)
        
        // Simulate network conditions
        try await simulateNetworkConditions()
        
        // Return mock success response
        let successResponse = """
        {
            "success": true,
            "message": "Upload completed successfully",
            "size": \(data.count)
        }
        """
        
        guard let responseData = successResponse.data(using: .utf8) else {
            throw NetworkError.unknown
        }
        
        return responseData
    }
    
    func download(
        from url: String,
        to destination: URL?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> URL {
        // Track request
        trackRequest(url: url, method: .get, headers: [:], body: nil)
        
        // Simulate download progress
        await simulateDownloadProgress(progressHandler: progressHandler)
        
        // Simulate network conditions
        try await simulateNetworkConditions()
        
        // Create mock downloaded file
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let fileName = url.components(separatedBy: "/").last ?? "mock_download"
        let fileUrl = tempDir.appendingPathComponent(fileName)
        
        let mockContent = "Mock downloaded content from \(url)"
        try mockContent.write(to: fileUrl, atomically: true, encoding: .utf8)
        
        // Move to destination if specified
        if let destination = destination {
            let finalUrl = destination
            if fileManager.fileExists(atPath: finalUrl.path) {
                try fileManager.removeItem(at: finalUrl)
            }
            try fileManager.moveItem(at: fileUrl, to: finalUrl)
            return finalUrl
        }
        
        return fileUrl
    }
    
    // MARK: - Test Configuration
    
    /// Configure the mock service for a specific test scenario
    func configure(
        scenario: MockDataLoader.MockScenario,
        delay: TimeInterval = 0.1,
        slowNetwork: Bool = false,
        offline: Bool = false,
        timeout: Bool = false,
        failureRate: Double = 0.0
    ) {
        self.currentScenario = scenario
        self.networkDelay = delay
        self.shouldSimulateSlowNetwork = slowNetwork
        self.shouldSimulateOffline = offline
        self.shouldSimulateTimeout = timeout
        self.failureRate = max(0.0, min(1.0, failureRate))
        
        logger?.debug("MockNetworkService configured: scenario=\(scenario.rawValue), delay=\(delay)s")
    }
    
    /// Reset all tracking and configuration
    func reset() {
        currentScenario = .weatherSuccess
        networkDelay = 0.1
        shouldSimulateSlowNetwork = false
        shouldSimulateOffline = false
        shouldSimulateTimeout = false
        failureRate = 0.0
        
        requestCount = 0
        lastRequestURL = nil
        lastRequestHeaders = nil
        lastRequestMethod = nil
        lastRequestBody = nil
        
        logger?.debug("MockNetworkService reset to defaults")
    }
    
    // MARK: - Private Methods
    
    private func trackRequest(
        url: String,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?
    ) {
        requestCount += 1
        lastRequestURL = url
        lastRequestHeaders = headers
        lastRequestMethod = method
        lastRequestBody = body
        
        logger?.debug("Tracked mock request: \(method.rawValue) \(url)")
    }
    
    private func simulateNetworkConditions() async throws {
        if shouldSimulateOffline {
            throw NetworkError.noInternetConnection
        }
        
        if shouldSimulateTimeout {
            throw NetworkError.timeout
        }
        
        // Simulate network delay
        let actualDelay = shouldSimulateSlowNetwork ? networkDelay * 5 : networkDelay
        try await Task.sleep(nanoseconds: UInt64(actualDelay * 1_000_000_000))
    }
    
    private func checkForSimulatedFailures() throws {
        // Random failure simulation
        if failureRate > 0 && Double.random(in: 0...1) < failureRate {
            throw NetworkError.networkError(URLError(.networkConnectionLost))
        }
    }
    
    private func determineScenario(for url: String) -> MockDataLoader.MockScenario {
        // You can customize this to return different scenarios based on URL
        // For example, different endpoints could return different scenarios
        
        if url.contains("error") {
            return .weatherError
        } else if url.contains("empty") {
            return .weatherEmpty
        } else if shouldSimulateOffline {
            return .offline
        } else {
            return currentScenario
        }
    }
    
    private func simulateUploadProgress(progressHandler: ((Double) -> Void)?) async {
        guard let progressHandler = progressHandler else { return }
        
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            progressHandler(progress)
            try? await Task.sleep(nanoseconds: UInt64(networkDelay * 100_000_000)) // 1/10 of delay
        }
    }
    
    private func simulateDownloadProgress(progressHandler: ((Double) -> Void)?) async {
        guard let progressHandler = progressHandler else { return }
        
        for progress in stride(from: 0.0, through: 1.0, by: 0.2) {
            progressHandler(progress)
            try? await Task.sleep(nanoseconds: UInt64(networkDelay * 200_000_000)) // 1/5 of delay
        }
    }
}

// MARK: - Test Verification

extension MockNetworkService {
    /// Verify that a request was made with expected parameters
    func verifyRequest(
        url: String? = nil,
        method: HTTPMethod? = nil,
        headerKey: String? = nil,
        headerValue: String? = nil
    ) -> Bool {
        if let expectedURL = url, lastRequestURL != expectedURL {
            return false
        }
        
        if let expectedMethod = method, lastRequestMethod != expectedMethod {
            return false
        }
        
        if let headerKey = headerKey, let headerValue = headerValue {
            return lastRequestHeaders?[headerKey] == headerValue
        }
        
        return true
    }
    
    /// Get request statistics for testing
    func getRequestStats() -> RequestStats {
        RequestStats(
            totalRequests: requestCount,
            lastURL: lastRequestURL,
            lastMethod: lastRequestMethod?.rawValue,
            lastHeaders: lastRequestHeaders
        )
    }
}

struct RequestStats {
    let totalRequests: Int
    let lastURL: String?
    let lastMethod: String?
    let lastHeaders: [String: String]?
}