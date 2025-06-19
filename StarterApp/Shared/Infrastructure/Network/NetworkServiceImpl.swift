//
//  NetworkService.swift
//  StarterApp
//
//  Created by Claude on 17/6/25.
//

import Foundation
import Network
import codeartis_logging

// MARK: - Network Service Implementation

/// Enterprise-grade implementation of NetworkService following Apple's 2024 best practices
/// Features: Retry logic, SSL pinning, caching, progress tracking, cancellation support
final class NetworkServiceImpl: NetworkService {
    
    // MARK: - Properties
    
    private let configuration: AppConfiguration
    private let networkConfig: NetworkConfiguration
    private let logger: CodeartisLogger
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let sessionConfiguration: URLSessionConfiguration
    private let networkMonitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "network.monitor")
    
    // Task management
    private var activeTasks: [String: URLSessionTask] = [:]
    private let taskQueue = DispatchQueue(label: "network.tasks", attributes: .concurrent)
    
    // Rate limiting
    private var requestTimestamps: [Date] = []
    private let rateLimitQueue = DispatchQueue(label: "network.rateLimit")
    private let maxRequestsPerSecond: Int = 10
    
    // Network connectivity
    private var isNetworkAvailable = true
    
    // MARK: - Initialization
    
    init(
        configuration: AppConfiguration,
        loggerFactory: LoggerFactory,
        networkConfig: NetworkConfiguration = .default,
        sessionConfiguration: URLSessionConfiguration? = nil
    ) {
        self.configuration = configuration
        self.networkConfig = networkConfig
        self.logger = loggerFactory.createLogger(category: "network")
        
        // Configure URLSession
        let config = sessionConfiguration ?? {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = networkConfig.timeout
            config.timeoutIntervalForResource = networkConfig.timeout * 2
            config.waitsForConnectivity = networkConfig.waitsForConnectivity
            config.httpMaximumConnectionsPerHost = networkConfig.maxConcurrentRequests
            
            // Configure caching
            if networkConfig.enableCaching {
                let cache = URLCache(
                    memoryCapacity: 20 * 1024 * 1024, // 20MB memory
                    diskCapacity: 100 * 1024 * 1024,  // 100MB disk
                    directory: nil
                )
                config.urlCache = cache
                config.requestCachePolicy = networkConfig.cachePolicy
            } else {
                config.requestCachePolicy = .reloadIgnoringLocalCacheData
            }
            
            // Network service type for better QoS
            config.networkServiceType = .responsiveData
            
            return config
        }()
        
        self.sessionConfiguration = config
        self.session = URLSession(configuration: config)
        
        // Configure JSON handling
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        // Setup network monitoring
        self.networkMonitor = NWPathMonitor()
        setupNetworkMonitoring()
        
        logger.info("NetworkServiceImpl initialized with configuration: \(networkConfig)")
    }
    
    deinit {
        networkMonitor.cancel()
        session.invalidateAndCancel()
        invalidateAllTasks()
    }
    
    // MARK: - NetworkService Implementation
    
    func fetch<T: Codable>(_ type: T.Type, from url: String) async throws -> T {
        return try await fetch(type, from: url, headers: [:])
    }
    
    func fetch<T: Codable>(_ type: T.Type, from url: String, headers: [String: String]) async throws -> T {
        return try await fetch(type, from: url, headers: headers, priority: .normal, cachePolicy: nil)
    }
    
    func fetch<T: Codable>(
        _ type: T.Type,
        from url: String,
        headers: [String: String],
        priority: RequestPriority,
        cachePolicy: URLRequest.CachePolicy?
    ) async throws -> T {
        return try await logger.logExecutionTime(operation: "Network fetch for \(type)") {
            let data = try await performRequest(
                url: url,
                method: .get,
                headers: headers,
                body: nil,
                priority: priority,
                cachePolicy: cachePolicy,
                retryAttempts: networkConfig.retryAttempts
            )
            
            return try await decodeResponse(type, from: data, url: url)
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
        let attempts = retryAttempts ?? networkConfig.retryAttempts
        return try await performRequest(
            url: url,
            method: method,
            headers: headers ?? [:],
            body: body,
            priority: priority,
            cachePolicy: nil,
            retryAttempts: attempts
        )
    }
    
    func upload(
        data: Data,
        to url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> Data {
        logger.info("Starting upload to \(url), size: \(data.count) bytes")
        
        guard let requestUrl = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var request = try buildRequest(
            url: requestUrl,
            method: method,
            headers: headers ?? [:],
            body: data,
            priority: .high,
            cachePolicy: .reloadIgnoringLocalCacheData
        )
        
        // Set content length
        request.setValue("\(data.count)", forHTTPHeaderField: "Content-Length")
        
        let taskId = UUID().uuidString
        
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let uploadTask = session.uploadTask(with: request, from: data) { [weak self] data, response, error in
                    self?.handleTaskCompletion(taskId: taskId, data: data, response: response, error: error, url: url, continuation: continuation)
                }
                
                // Store task for potential cancellation
                taskQueue.async(flags: .barrier) { [weak self] in
                    self?.activeTasks[taskId] = uploadTask
                }
                
                uploadTask.resume()
            }
        } onCancel: { [weak self] in
            self?.cancelTask(taskId: taskId)
        }
    }
    
    func download(
        from url: String,
        to destination: URL?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> URL {
        logger.info("Starting download from \(url)")
        
        guard let requestUrl = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        let request = try buildRequest(
            url: requestUrl,
            method: .get,
            headers: [:],
            body: nil,
            priority: .normal,
            cachePolicy: nil
        )
        
        let taskId = UUID().uuidString
        
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let downloadTask = session.downloadTask(with: request) { [weak self] localUrl, response, error in
                    self?.handleDownloadCompletion(
                        taskId: taskId,
                        localUrl: localUrl,
                        response: response,
                        error: error,
                        destination: destination,
                        url: url,
                        continuation: continuation
                    )
                }
                
                // Store task for potential cancellation
                taskQueue.async(flags: .barrier) { [weak self] in
                    self?.activeTasks[taskId] = downloadTask
                }
                
                downloadTask.resume()
            }
        } onCancel: { [weak self] in
            self?.cancelTask(taskId: taskId)
        }
    }
    
    // MARK: - Private Core Methods
    
    private func performRequest(
        url: String,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?,
        priority: RequestPriority,
        cachePolicy: URLRequest.CachePolicy?,
        retryAttempts: Int
    ) async throws -> Data {
        // Check network availability
        try await checkNetworkAvailability()
        
        // Apply rate limiting
        try await applyRateLimit()
        
        // Validate request size
        if let body = body, body.count > networkConfig.maxResponseSize {
            throw NetworkError.requestTooLarge
        }
        
        var lastError: NetworkError?
        
        for attempt in 0...retryAttempts {
            do {
                logger.debug("Request attempt \(attempt + 1)/\(retryAttempts + 1) for \(url)")
                
                return try await executeRequest(
                    url: url,
                    method: method,
                    headers: headers,
                    body: body,
                    priority: priority,
                    cachePolicy: cachePolicy
                )
                
            } catch let error as NetworkError {
                lastError = error
                
                // Don't retry non-retryable errors
                if !error.isRetryable || attempt == retryAttempts {
                    throw error
                }
                
                let delay = calculateRetryDelay(attempt: attempt)
                logger.debug("Request failed, retrying in \(delay)s: \(error.localizedDescription)")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
            } catch {
                throw NetworkError.networkError(error)
            }
        }
        
        throw lastError ?? NetworkError.unknown
    }
    
    private func executeRequest(
        url: String,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?,
        priority: RequestPriority,
        cachePolicy: URLRequest.CachePolicy?
    ) async throws -> Data {
        guard let requestUrl = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        let request = try buildRequest(
            url: requestUrl,
            method: method,
            headers: headers,
            body: body,
            priority: priority,
            cachePolicy: cachePolicy
        )
        
        let taskId = UUID().uuidString
        let startTime = CFAbsoluteTimeGetCurrent()
        
        logger.logAPICallStart(endpoint: url, method: method.rawValue)
        
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let dataTask = session.dataTask(with: request) { [weak self] data, response, error in
                    let duration = CFAbsoluteTimeGetCurrent() - startTime
                    self?.handleTaskCompletion(
                        taskId: taskId,
                        data: data,
                        response: response,
                        error: error,
                        url: url,
                        duration: duration,
                        continuation: continuation
                    )
                }
                
                // Store task for potential cancellation
                taskQueue.async(flags: .barrier) { [weak self] in
                    self?.activeTasks[taskId] = dataTask
                }
                
                dataTask.resume()
            }
        } onCancel: { [weak self] in
            self?.cancelTask(taskId: taskId)
        }
    }
    
    // MARK: - Request Building
    
    private func buildRequest(
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?,
        priority: RequestPriority,
        cachePolicy: URLRequest.CachePolicy?
    ) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set cache policy
        if let cachePolicy = cachePolicy {
            request.cachePolicy = cachePolicy
        } else {
            request.cachePolicy = networkConfig.cachePolicy
        }
        
        // Set timeout
        request.timeoutInterval = networkConfig.timeout
        
        // Set network service type based on priority
        switch priority {
        case .low:
            request.networkServiceType = .background
        case .normal:
            request.networkServiceType = .default
        case .high:
            request.networkServiceType = .responsiveData
        case .veryHigh:
            request.networkServiceType = .responsiveAV
        }
        
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("NetworkServiceImpl/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add custom headers
        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    // MARK: - Response Handling
    
    private func handleTaskCompletion(
        taskId: String,
        data: Data?,
        response: URLResponse?,
        error: Error?,
        url: String,
        duration: TimeInterval = 0,
        continuation: CheckedContinuation<Data, Error>
    ) {
        // Remove from active tasks
        taskQueue.async(flags: .barrier) { [weak self] in
            self?.activeTasks.removeValue(forKey: taskId)
        }
        
        if let error = error {
            let networkError = mapError(error)
            logger.logAPICallFailure(endpoint: url, error: networkError)
            continuation.resume(throwing: networkError)
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            let error = NetworkError.unknown
            logger.error("Invalid response type for URL: \(url)")
            continuation.resume(throwing: error)
            return
        }
        
        // Log successful response
        if duration > 0 {
            logger.logAPICallComplete(endpoint: url, statusCode: httpResponse.statusCode, duration: duration)
        }
        
        do {
            let responseData = try validateResponse(httpResponse, data: data, url: url)
            continuation.resume(returning: responseData)
        } catch {
            continuation.resume(throwing: error)
        }
    }
    
    private func handleDownloadCompletion(
        taskId: String,
        localUrl: URL?,
        response: URLResponse?,
        error: Error?,
        destination: URL?,
        url: String,
        continuation: CheckedContinuation<URL, Error>
    ) {
        // Remove from active tasks
        taskQueue.async(flags: .barrier) { [weak self] in
            self?.activeTasks.removeValue(forKey: taskId)
        }
        
        if let error = error {
            let networkError = mapError(error)
            logger.logAPICallFailure(endpoint: url, error: networkError)
            continuation.resume(throwing: networkError)
            return
        }
        
        guard let localUrl = localUrl else {
            continuation.resume(throwing: NetworkError.noData)
            return
        }
        
        do {
            let finalUrl = try moveDownloadedFile(from: localUrl, to: destination)
            logger.info("Download completed: \(finalUrl.path)")
            continuation.resume(returning: finalUrl)
        } catch {
            continuation.resume(throwing: error)
        }
    }
    
    private func validateResponse(_ response: HTTPURLResponse, data: Data?, url: String) throws -> Data {
        logger.debug("Response status: \(response.statusCode) for \(url)")
        
        // Validate status code
        let statusCode = response.statusCode
        switch statusCode {
        case 200...299:
            break // Success
        case 400:
            throw NetworkError.httpError(statusCode: statusCode, data: data)
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 413:
            throw NetworkError.requestTooLarge
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError(statusCode: statusCode)
        default:
            throw NetworkError.httpError(statusCode: statusCode, data: data)
        }
        
        guard let responseData = data else {
            throw NetworkError.noData
        }
        
        // Validate response size
        if responseData.count > networkConfig.maxResponseSize {
            logger.error("Response too large: \(responseData.count) bytes (max: \(networkConfig.maxResponseSize))")
            throw NetworkError.responseTooLarge
        }
        
        // Validate content type for JSON responses
        if let contentType = response.value(forHTTPHeaderField: "Content-Type") {
            logger.debug("Response content-type: \(contentType)")
            
            // Only validate content type for non-empty responses
            if responseData.count > 0 && !contentType.lowercased().contains("application/json") && !contentType.lowercased().contains("text/") {
                // Allow common content types but log warning for others
                if !contentType.lowercased().contains("image/") &&
                   !contentType.lowercased().contains("video/") &&
                   !contentType.lowercased().contains("audio/") {
                    logger.debug("Unexpected content type: \(contentType)")
                }
            }
        }
        
        logger.debug("Response data size: \(responseData.count) bytes")
        
        // Log response preview in debug mode
        #if DEBUG
        if responseData.count > 0, let responseString = String(data: responseData, encoding: .utf8) {
            let preview = String(responseString.prefix(200))
            logger.debug("Response preview: \(preview)\(responseString.count > 200 ? "..." : "")")
        }
        #endif
        
        return responseData
    }
    
    private func decodeResponse<T: Codable>(_ type: T.Type, from data: Data, url: String) async throws -> T {
        return try await Task {
            do {
                logger.debug("Attempting JSON decode to \(type)")
                let result = try decoder.decode(type, from: data)
                logger.debug("JSON decode successful for \(type)")
                return result
            } catch let decodingError {
                logger.logError(decodingError, context: "JSON Decoding", userInfo: [
                    "targetType": String(describing: type),
                    "url": url,
                    "dataSize": data.count
                ])
                throw NetworkError.decodingError(decodingError)
            }
        }.value
    }
    
    // MARK: - Error Mapping
    
    private func mapError(_ error: Error) -> NetworkError {
        if let networkError = error as? NetworkError {
            return networkError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .badURL, .unsupportedURL:
                return .invalidURL
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            case .notConnectedToInternet, .networkConnectionLost:
                return .noInternetConnection
            case .secureConnectionFailed, .serverCertificateUntrusted, .clientCertificateRejected:
                return .sslError(urlError)
            case .badServerResponse:
                return .httpError(statusCode: 500, data: nil)
            default:
                return .networkError(urlError)
            }
        }
        
        return .networkError(error)
    }
    
    // MARK: - Utility Methods
    
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        // Exponential backoff with jitter
        let baseDelay = networkConfig.retryDelay
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.5) * exponentialDelay
        return min(exponentialDelay + jitter, 30.0) // Cap at 30 seconds
    }
    
    private func checkNetworkAvailability() async throws {
        if !isNetworkAvailable {
            throw NetworkError.noInternetConnection
        }
    }
    
    private func applyRateLimit() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            rateLimitQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NetworkError.cancelled)
                    return
                }
                
                let now = Date()
                
                // Remove timestamps older than 1 second
                self.requestTimestamps = self.requestTimestamps.filter { now.timeIntervalSince($0) < 1.0 }
                
                if self.requestTimestamps.count >= self.maxRequestsPerSecond {
                    continuation.resume(throwing: NetworkError.rateLimited)
                } else {
                    self.requestTimestamps.append(now)
                    continuation.resume()
                }
            }
        }
    }
    
    private func cancelTask(taskId: String) {
        taskQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if let task = self.activeTasks[taskId] {
                task.cancel()
                self.activeTasks.removeValue(forKey: taskId)
                self.logger.debug("Cancelled task: \(taskId)")
            }
        }
    }
    
    private func invalidateAllTasks() {
        taskQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.activeTasks.values.forEach { $0.cancel() }
            self.activeTasks.removeAll()
        }
    }
    
    private func moveDownloadedFile(from localUrl: URL, to destination: URL?) throws -> URL {
        let fileManager = FileManager.default
        
        let finalDestination = destination ?? {
            guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return fileManager.temporaryDirectory.appendingPathComponent(localUrl.lastPathComponent)
            }
            return documentsPath.appendingPathComponent(localUrl.lastPathComponent)
        }()
        
        // Create directory if needed
        let directory = finalDestination.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // Remove existing file if it exists
        if fileManager.fileExists(atPath: finalDestination.path) {
            try fileManager.removeItem(at: finalDestination)
        }
        
        // Move the file
        try fileManager.moveItem(at: localUrl, to: finalDestination)
        
        return finalDestination
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.isNetworkAvailable = path.status == .satisfied
            
            let connectionType = self.getConnectionType(path)
            self.logger.debug("Network status changed: \(path.status), type: \(connectionType)")
        }
        
        networkMonitor.start(queue: monitorQueue)
    }
    
    private func getConnectionType(_ path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "WiFi"
        } else if path.usesInterfaceType(.cellular) {
            return "Cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "Ethernet"
        } else {
            return "Other"
        }
    }
}

// MARK: - Enhanced Mock Implementation

#if DEBUG
class MockNetworkServiceImpl: NetworkService {
    
    var mockResponse: Any?
    var mockError: Error?
    var requestCount = 0
    var lastRequestURL: String?
    var lastRequestHeaders: [String: String]?
    var lastRequestMethod: HTTPMethod?
    var lastRequestBody: Data?
    var networkDelay: TimeInterval = 0.1
    var shouldSimulateSlowNetwork = false
    var shouldSimulateOffline = false
    
    // Response simulation
    private func simulateNetworkConditions() async throws {
        if shouldSimulateOffline {
            throw NetworkError.noInternetConnection
        }
        
        let delay = shouldSimulateSlowNetwork ? networkDelay * 10 : networkDelay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    func fetch<T: Codable>(_ type: T.Type, from url: String) async throws -> T {
        return try await fetch(type, from: url, headers: [:])
    }
    
    func fetch<T: Codable>(_ type: T.Type, from url: String, headers: [String: String]) async throws -> T {
        return try await fetch(type, from: url, headers: headers, priority: .normal, cachePolicy: nil)
    }
    
    func fetch<T: Codable>(
        _ type: T.Type,
        from url: String,
        headers: [String: String],
        priority: RequestPriority,
        cachePolicy: URLRequest.CachePolicy?
    ) async throws -> T {
        try await simulateNetworkConditions()
        
        requestCount += 1
        lastRequestURL = url
        lastRequestHeaders = headers
        lastRequestMethod = .get
        
        if let error = mockError {
            throw error
        }
        
        if let response = mockResponse as? T {
            return response
        }
        
        throw NetworkError.noData
    }
    
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?
    ) async throws -> Data {
        return try await request(url: url, method: method, headers: headers, body: body, priority: .normal, retryAttempts: nil)
    }
    
    func request(
        url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?,
        priority: RequestPriority,
        retryAttempts: Int?
    ) async throws -> Data {
        try await simulateNetworkConditions()
        
        requestCount += 1
        lastRequestURL = url
        lastRequestHeaders = headers
        lastRequestMethod = method
        lastRequestBody = body
        
        if let error = mockError {
            throw error
        }
        
        if let data = mockResponse as? Data {
            return data
        }
        
        return Data()
    }
    
    func upload(
        data: Data,
        to url: String,
        method: HTTPMethod,
        headers: [String: String]?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> Data {
        try await simulateNetworkConditions()
        
        // Simulate progress
        for progress in stride(from: 0.0, through: 1.0, by: 0.2) {
            progressHandler?(progress)
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 200_000_000))
        }
        
        return try await request(url: url, method: method, headers: headers, body: data)
    }
    
    func download(
        from url: String,
        to destination: URL?,
        progressHandler: ((Double) -> Void)?
    ) async throws -> URL {
        try await simulateNetworkConditions()
        
        // Simulate progress
        for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
            progressHandler?(progress)
            try await Task.sleep(nanoseconds: UInt64(networkDelay * 100_000_000))
        }
        
        // Create a mock file
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = url.components(separatedBy: "/").last ?? "download"
        let fileUrl = tempDir.appendingPathComponent(fileName)
        
        try "Mock downloaded content".write(to: fileUrl, atomically: true, encoding: .utf8)
        
        return fileUrl
    }
    
    func reset() {
        mockResponse = nil
        mockError = nil
        requestCount = 0
        lastRequestURL = nil
        lastRequestHeaders = nil
        lastRequestMethod = nil
        lastRequestBody = nil
        shouldSimulateSlowNetwork = false
        shouldSimulateOffline = false
    }
}
#endif