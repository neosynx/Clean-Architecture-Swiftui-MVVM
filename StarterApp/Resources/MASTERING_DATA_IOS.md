# Mastering Data in iOS 17+: A Comprehensive Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Modern Async/Await Networking](#modern-asyncawait-networking)
3. [SwiftData: The Future of iOS Persistence](#swiftdata-the-future-of-ios-persistence)
4. [Secure Storage Solutions](#secure-storage-solutions)
5. [In-Memory Caching with NSCache](#in-memory-caching-with-nscache)
6. [Test Data Management](#test-data-management)
7. [Architecture Best Practices](#architecture-best-practices)
8. [Performance Optimization](#performance-optimization)
9. [Migration Strategies](#migration-strategies)

## Introduction

This guide establishes the best practices for data handling in iOS 17+ applications, focusing on modern Apple technologies and Clean Architecture principles. Our approach prioritizes SwiftData for persistence, NSCache for performance, and secure storage for sensitive data.

### Key Principles
- **Database-First**: All persistent data uses SwiftData (no file storage)
- **Performance**: NSCache provides lightning-fast in-memory access
- **Security**: Sensitive data stored in Keychain, preferences in UserDefaults
- **Testing**: JSON files used exclusively for mock data and testing
- **Clean Architecture**: Strict separation between domain models and DTOs

## Modern Async/Await Networking

### NetworkService Implementation

Our `NetworkService` provides a robust, async/await-based networking layer with enterprise features:

```swift
// Basic usage
let weather = try await networkService.fetch(WeatherApiDTO.self, from: url)

// Advanced usage with retry and caching
let data = try await networkService.fetch(
    WeatherApiDTO.self,
    from: url,
    headers: ["API-Key": apiKey],
    priority: .high,
    cachePolicy: .returnCacheDataElseLoad
)
```

### Key Features
- **Automatic Retry Logic**: Exponential backoff with jitter
- **Request Prioritization**: From `.low` to `.veryHigh`
- **Progress Tracking**: For uploads and downloads
- **Cancellation Support**: Task-based cancellation
- **Rate Limiting**: Prevents API throttling
- **Network Monitoring**: Automatic offline detection

### Error Handling

```swift
do {
    let data = try await networkService.fetch(WeatherApiDTO.self, from: url)
} catch {
    switch error {
    case NetworkError.noInternetConnection:
        // Show offline UI
    case NetworkError.rateLimited:
        // Handle rate limiting
    case NetworkError.decodingError(let decodingError):
        // Log decoding issues
    default:
        // Generic error handling
    }
}
```

## SwiftData: The Future of iOS Persistence

### Why SwiftData for iOS 17+

SwiftData is Apple's modern persistence framework that replaces Core Data for new projects:
- **Declarative Models**: Using `@Model` macro
- **Type Safety**: Compile-time query validation
- **SwiftUI Integration**: Seamless with `@Query`
- **Automatic Migrations**: Schema evolution handled automatically
- **Actor-Based**: Thread-safe by design

### SwiftData in Clean Architecture

In our Clean Architecture, SwiftData models are **DTOs in the Data Layer**:

```swift
// Data/DTOs/WeatherSwiftDataDTO.swift
import SwiftData

@Model
final class WeatherSwiftDataDTO {
    var id: UUID
    var cityName: String
    var temperature: Double
    var humidity: Int
    var weatherDescription: String
    var lastUpdated: Date
    
    init(cityName: String, temperature: Double, humidity: Int, weatherDescription: String) {
        self.id = UUID()
        self.cityName = cityName
        self.temperature = temperature
        self.humidity = humidity
        self.weatherDescription = weatherDescription
        self.lastUpdated = Date()
    }
}
```

### SwiftData Container Setup

```swift
// Infrastructure/Persistence/SwiftDataContainer.swift
import SwiftData

actor SwiftDataContainer {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init() throws {
        let schema = Schema([
            WeatherSwiftDataDTO.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        self.modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        self.modelContext = ModelContext(modelContainer)
        self.modelContext.autosaveEnabled = true
    }
    
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) async throws -> [T] {
        try modelContext.fetch(descriptor)
    }
    
    func insert<T: PersistentModel>(_ model: T) async throws {
        modelContext.insert(model)
        try modelContext.save()
    }
    
    func delete<T: PersistentModel>(_ model: T) async throws {
        modelContext.delete(model)
        try modelContext.save()
    }
}
```

### Repository Integration

The repository handles all SwiftData operations and mapping:

```swift
final class WeatherRepositoryImpl: WeatherRepository {
    private let swiftDataContainer: SwiftDataContainer
    private let domainCache = NSCache<NSString, ForecastModel>()
    private let mapper: WeatherProtocolMapper
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        // Check memory cache first
        if let cached = domainCache.object(forKey: city as NSString) {
            return cached
        }
        
        // Query SwiftData
        let descriptor = FetchDescriptor<WeatherSwiftDataDTO>(
            predicate: #Predicate { $0.cityName == city },
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        
        let results = try await swiftDataContainer.fetch(descriptor)
        
        if let dto = results.first {
            let domainModel = mapper.mapToDomain(dto)
            domainCache.setObject(domainModel, forKey: city as NSString)
            return domainModel
        }
        
        // Fallback to network if not found
        return try await fetchFromNetwork(city)
    }
}
```

## Secure Storage Solutions

### Storage Decision Matrix

| Data Type | Storage Solution | Encryption | Use Case |
|-----------|-----------------|------------|----------|
| API Keys | Keychain | Yes (Hardware) | Authentication tokens |
| User Preferences | UserDefaults | No | Settings, units |
| Sensitive User Data | Keychain | Yes | Passwords, tokens |
| App Configuration | UserDefaults | No | Feature flags |
| Large Data Sets | SwiftData | FileVault | Weather history |

### Keychain Service Implementation

```swift
// Infrastructure/Security/KeychainService.swift
import Security

actor KeychainService {
    private let service: String
    
    init(service: String = Bundle.main.bundleIdentifier ?? "com.app.default") {
        self.service = service
    }
    
    func save(_ data: Data, for key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func load(key: String) async throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.itemNotFound
        }
        
        return data
    }
}
```

### UserDefaults Wrapper

```swift
// Infrastructure/Security/UserDefaultsService.swift
@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get { UserDefaults.standard.object(forKey: key) as? T ?? defaultValue }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}

// Usage in app settings
struct AppSettings {
    @UserDefault(key: "temperatureUnit", defaultValue: "celsius")
    static var temperatureUnit: String
    
    @UserDefault(key: "enableNotifications", defaultValue: true)
    static var enableNotifications: Bool
    
    @UserDefault(key: "savedCities", defaultValue: [])
    static var savedCities: [String]
}
```

## In-Memory Caching with NSCache

### Why NSCache?

NSCache is Apple's recommended solution for in-memory caching:
- **Automatic Memory Management**: Responds to memory pressure
- **Thread-Safe**: No additional synchronization needed
- **Key-Value Storage**: Similar API to Dictionary
- **Eviction Policies**: Automatic under memory pressure

### NSCache Service Implementation

```swift
// Services/Base/NSCacheServiceImpl.swift
import Foundation

final class NSCacheServiceImpl<Key: Hashable, Value: AnyObject>: CacheService {
    private let cache = NSCache<NSString, Value>()
    private let keyTransformer: (Key) -> NSString
    
    init(
        countLimit: Int = 100,
        totalCostLimit: Int = 50 * 1024 * 1024, // 50MB
        keyTransformer: @escaping (Key) -> NSString = { NSString(string: "\($0)") }
    ) {
        self.keyTransformer = keyTransformer
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
        cache.evictsObjectsWithDiscardedContent = true
    }
    
    func get(for key: Key) async throws -> Value? {
        cache.object(forKey: keyTransformer(key))
    }
    
    func set(_ value: Value, for key: Key) async throws {
        cache.setObject(value, forKey: keyTransformer(key))
    }
    
    func remove(for key: Key) async throws {
        cache.removeObject(forKey: keyTransformer(key))
    }
    
    func clear() async throws {
        cache.removeAllObjects()
    }
    
    func isExpired(for key: Key) async -> Bool {
        // NSCache doesn't track expiration, always return false
        false
    }
}
```

### Repository with Two-Level Caching

```swift
final class WeatherRepositoryImpl: WeatherRepository {
    // NSCache for domain models (fast access)
    private let domainCache = NSCache<NSString, ForecastModelWrapper>()
    // SwiftData for persistence
    private let swiftDataContainer: SwiftDataContainer
    
    init(swiftDataContainer: SwiftDataContainer) {
        self.swiftDataContainer = swiftDataContainer
        setupCache()
    }
    
    private func setupCache() {
        domainCache.countLimit = 50
        domainCache.totalCostLimit = 10 * 1024 * 1024 // 10MB
    }
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        // Level 1: Memory cache (fastest)
        if let wrapper = domainCache.object(forKey: city as NSString) {
            return wrapper.model
        }
        
        // Level 2: SwiftData (persistent)
        if let persisted = try await fetchFromSwiftData(city) {
            // Populate cache
            let wrapper = ForecastModelWrapper(model: persisted)
            domainCache.setObject(wrapper, forKey: city as NSString)
            return persisted
        }
        
        // Level 3: Network (slowest)
        return try await fetchFromNetwork(city)
    }
}

// Wrapper for reference type requirement
final class ForecastModelWrapper {
    let model: ForecastModel
    init(model: ForecastModel) {
        self.model = model
    }
}
```

## Test Data Management

### Mock Data Strategy

Test data is loaded from JSON files, never from production storage:

```swift
// Infrastructure/Testing/MockDataLoader.swift
final class MockDataLoader {
    enum MockScenario: String {
        case success = "weather_success"
        case error = "weather_error"
        case offline = "weather_offline"
        case empty = "weather_empty"
    }
    
    func loadMockResponse<T: Decodable>(
        _ type: T.Type,
        scenario: MockScenario
    ) throws -> T {
        guard let url = Bundle.main.url(
            forResource: scenario.rawValue,
            withExtension: "json"
        ) else {
            throw MockError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(type, from: data)
    }
}
```

### Mock Network Service

```swift
// Infrastructure/Testing/MockNetworkService.swift
final class MockNetworkService: NetworkService {
    private let mockLoader = MockDataLoader()
    var scenario: MockDataLoader.MockScenario = .success
    var delay: TimeInterval = 0.5
    
    func fetch<T: Codable>(_ type: T.Type, from url: String) async throws -> T {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        // Return mock data based on scenario
        switch scenario {
        case .success:
            return try mockLoader.loadMockResponse(type, scenario: scenario)
        case .error:
            throw NetworkError.httpError(statusCode: 500, data: nil)
        case .offline:
            throw NetworkError.noInternetConnection
        case .empty:
            throw NetworkError.noData
        }
    }
}
```

## Architecture Best Practices

### 1. Clean Architecture Boundaries

```swift
// ✅ CORRECT: Domain models only in UI/Store/Repository
class WeatherStore: ObservableObject {
    @Published var forecasts: [ForecastModel] = [] // Domain Model
    private let repository: WeatherRepository
}

// ❌ WRONG: SwiftData models in Store
class WeatherStore: ObservableObject {
    @Published var forecasts: [WeatherSwiftDataDTO] = [] // Don't do this!
}
```

### 2. DTO Mapping Pattern

```swift
extension WeatherProtocolMapper {
    func mapToDomain(_ dto: WeatherSwiftDataDTO) -> ForecastModel {
        ForecastModel(
            city: CityModel(
                id: Int(dto.id.uuidString.hashValue),
                name: dto.cityName
            ),
            weather: WeatherModel(
                temperature: TemperatureModel(
                    current: dto.temperature,
                    min: dto.temperature - 5,
                    max: dto.temperature + 5
                ),
                humidity: dto.humidity,
                condition: WeatherConditionModel(
                    main: dto.weatherDescription,
                    description: dto.weatherDescription,
                    icon: "default"
                )
            ),
            timestamp: dto.lastUpdated
        )
    }
    
    func mapToSwiftDataDTO(_ domain: ForecastModel) -> WeatherSwiftDataDTO {
        WeatherSwiftDataDTO(
            cityName: domain.city.name,
            temperature: domain.weather.temperature.current,
            humidity: domain.weather.humidity,
            weatherDescription: domain.weather.condition.main
        )
    }
}
```

### 3. Dependency Injection

```swift
// App/AppContainer.swift
final class AppContainer {
    lazy var swiftDataContainer: SwiftDataContainer = {
        try! SwiftDataContainer()
    }()
    
    lazy var keychainService: KeychainService = {
        KeychainService()
    }()
    
    lazy var weatherRepository: WeatherRepository = {
        WeatherRepositoryImpl(
            swiftDataContainer: swiftDataContainer,
            networkService: networkService,
            keychainService: keychainService,
            logger: logger
        )
    }()
    
    lazy var weatherStore: WeatherStore = {
        WeatherStore(repository: weatherRepository)
    }()
}
```

## Performance Optimization

### 1. Cache Warming

```swift
extension WeatherStore {
    func warmCache() async {
        guard !hasWarmedCache else { return }
        
        do {
            let cities = try await repository.getAllSavedCities()
            await withTaskGroup(of: Void.self) { group in
                for city in cities.prefix(5) { // Limit concurrent fetches
                    group.addTask {
                        _ = try? await self.repository.fetchWeather(for: city)
                    }
                }
            }
            hasWarmedCache = true
        } catch {
            logger.error("Cache warming failed: \(error)")
        }
    }
}
```

### 2. Background Refresh

```swift
extension WeatherRepositoryImpl {
    func refreshInBackground() async {
        await withTaskGroup(of: Void.self) { group in
            let cities = try? await getAllSavedCities()
            
            for city in cities ?? [] {
                group.addTask { [weak self] in
                    guard let self else { return }
                    
                    // Refresh if data is older than 1 hour
                    if let cached = try? await self.getCachedWeather(for: city),
                       cached.timestamp.timeIntervalSinceNow < -3600 {
                        _ = try? await self.refreshWeather(for: city)
                    }
                }
            }
        }
    }
}
```

### 3. Memory Management

```swift
class WeatherStore: ObservableObject {
    func handleMemoryWarning() {
        // Clear non-essential data
        if forecasts.count > 10 {
            forecasts = Array(forecasts.prefix(5))
        }
        
        // Repository will handle cache clearing
        Task {
            try? await repository.clearCache()
        }
    }
}
```

## Migration Strategies

### From Core Data to SwiftData

```swift
// 1. Create SwiftData models matching Core Data entities
@Model
final class WeatherSwiftDataDTO {
    // Properties matching Core Data entity
}

// 2. Migration service
actor DataMigrationService {
    func migrateFromCoreData() async throws {
        let coreDataStack = CoreDataStack()
        let swiftDataContainer = try SwiftDataContainer()
        
        // Fetch all Core Data entities
        let fetchRequest = NSFetchRequest<WeatherEntity>(entityName: "WeatherEntity")
        let entities = try coreDataStack.context.fetch(fetchRequest)
        
        // Convert and save to SwiftData
        for entity in entities {
            let swiftDataModel = WeatherSwiftDataDTO(
                cityName: entity.cityName ?? "",
                temperature: entity.temperature,
                // ... map other properties
            )
            try await swiftDataContainer.insert(swiftDataModel)
        }
        
        // Mark migration complete
        UserDefaults.standard.set(true, forKey: "HasMigratedToSwiftData")
    }
}
```

### From File Storage to SwiftData

```swift
// Clean up file-based storage after migration
func cleanupFileStorage() async throws {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let weatherDirectory = documentsURL.appendingPathComponent("Weather")
    
    if fileManager.fileExists(atPath: weatherDirectory.path) {
        try fileManager.removeItem(at: weatherDirectory)
    }
}
```

## Conclusion

This architecture provides a robust, performant, and secure data layer for iOS 17+ applications:

- **SwiftData** for modern persistence with type safety
- **NSCache** for lightning-fast in-memory access
- **Keychain** for secure credential storage
- **Clean Architecture** maintaining clear boundaries
- **Test-friendly** with comprehensive mocking support

By following these patterns, your iOS applications will be scalable, maintainable, and aligned with Apple's latest best practices.