# CLAUDE.md - StarterApp iOS Clean Architecture Guidelines

## Project Context
This is a reference Clean Architecture iOS app built with SwiftUI targeting iOS 17.0+, implementing modern patterns with Repository Pattern and DTO separation for maintainable, testable, and scalable code.

## Tech Stack
- **Framework**: SwiftUI + CoreData + Combine
- **Language**: Swift 5.9+
- **Architecture**: Clean Architecture + MVVM with @Observable
- **Data Layer**: Repository Pattern with DTO Mapping
- **Concurrency**: Swift async/await + Actors
- **Target**: iOS 17.0+

## 🏗️ Clean Architecture Overview

### Core Principle: Dependency Inversion
**Critical Rule**: Views and Stores only reference Domain Models. All other layers use DTOs and mappers.

```
┌─────────────────────────────────────────────┐
│                UI Layer                     │
│  ┌─────────────┐    ┌─────────────────────┐ │
│  │   Views     │◄──►│ Stores (@Observable)│ │
│  │  SwiftUI    │    │ Domain Models Only  │ │
│  └─────────────┘    └─────────────────────┘ │
└─────────────────────┬───────────────────────┘
                      │ Domain Models
┌─────────────────────▼───────────────────────┐
│               Domain Layer                  │
│  ┌─────────────┐    ┌─────────────────────┐ │
│  │   Models    │    │ Repository Protocol │ │
│  │ Pure Domain │    │ Business Logic      │ │
│  └─────────────┘    └─────────────────────┘ │
└─────────────────────┬───────────────────────┘
                      │ Repository Interface
┌─────────────────────▼───────────────────────┐
│                Data Layer                   │
│  ┌─────────────┐    ┌─────────────────────┐ │
│  │     DTOs    │◄──►│ Repository Impl     │ │
│  │  API/File   │    │   + Mappers         │ │
│  └─────────────┘    └─────────────────────┘ │
│  ┌─────────────┐    ┌─────────────────────┐ │
│  │ DataSources │    │     CoreData        │ │
│  │Remote/Local │    │  File Storage       │ │
│  └─────────────┘    └─────────────────────┘ │
└─────────────────────────────────────────────┘
```

## 📁 Project Structure

```
StarterApp/
├── App/                          # App lifecycle & DI container
│   ├── AppRoot.swift             # App entry point
│   ├── AppContainer.swift        # Dependency injection factory
│   ├── AppDelegate.swift         # App delegate
│   └── SceneDelegate.swift       # Scene lifecycle
├── Features/
│   └── Weather/
│       ├── UI/                   # SwiftUI Views
│       │   ├── WeatherView.swift
│       │   └── WeatherRowView.swift
│       ├── Stores/               # @Observable State Management
│       │   └── WeatherStore.swift
│       ├── Domain/
│       │   └── Models/           # Pure Domain Models (No Codable)
│       │       ├── ForecastModel.swift
│       │       ├── WeatherModel.swift
│       │       ├── CityModel.swift
│       │       ├── TemperatureModel.swift
│       │       └── WeatherConditionModel.swift
│       └── Data/
│           ├── DTOs/             # Data Transfer Objects (Codable)
│           │   ├── WeatherApiDTO.swift
│           │   └── WeatherFileDTO.swift
│           ├── Mappers/          # DTO ↔ Domain Model converters
│           │   └── WeatherDomainMapper.swift
│           ├── Repositories/     # Repository implementations
│           │   ├── WeatherRepository.swift
│           │   └── WeatherRepositoryImpl.swift
│           ├── DataSources/      # Remote/Local/Cache data sources
│           │   ├── WeatherDataSource.swift
│           │   ├── WeatherRemoteDataSourceImpl.swift
│           │   ├── WeatherFileDataSourceImpl.swift
│           │   └── WeatherMemoryCacheDataSource.swift
│           └── CoreData/         # Core Data models
│               └── WeatherDataModel.xcdatamodeld
├── Shared/
│   ├── Infrastructure/           # Network, Storage utilities
│   │   ├── Network/
│   │   │   ├── APIClient.swift
│   │   │   ├── HTTPMethod.swift
│   │   │   └── WeatherAPIConfiguration.swift
│   │   └── Storage/
│   │       └── JSONLoader.swift
│   ├── Extensions/               # Utility extensions
│   │   └── Extension+Date.swift
│   └── UI/                       # Reusable UI components
│       └── Components/
│           └── LoadingView.swift
└── Resources/                    # Assets, JSON files
    ├── Assets.xcassets
    └── weather_data.json
```

## 🎯 Domain Layer Implementation

### Pure Domain Models (No External Dependencies)

```swift
// ✅ CORRECT: Pure domain model
public struct ForecastModel: Equatable {
    public let city: CityModel
    public let weatherItems: [WeatherModel]
    public let lastUpdated: Date
    
    public init(city: CityModel, weatherItems: [WeatherModel], lastUpdated: Date = Date()) {
        self.city = city
        self.weatherItems = weatherItems
        self.lastUpdated = lastUpdated
    }
}

public struct WeatherModel: Equatable {
    public let dateTime: Date
    public let temperature: TemperatureModel
    public let condition: WeatherConditionModel
    public let description: String
    
    // Pure domain logic, no Codable
}

public enum WeatherType: String, CaseIterable {
    case sunny = "Clear"
    case cloudy = "Clouds"
    case rainy = "Rain"
    
    public var displayName: String {
        switch self {
        case .sunny: return "Sunny"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        }
    }
    
    public var emoji: String {
        switch self {
        case .sunny: return "☀️"
        case .cloudy: return "☁️"
        case .rainy: return "🌧️"
        }
    }
}
```

## 📦 DTO Pattern Implementation

### Dual DTO Strategy

```swift
// API DTO - Maps directly to external API structure
public struct ForecastApiDTO: Codable {
    public let city: CityApiDTO
    public let list: [WeatherApiDTO]
    public let cnt: Int?
    public let cod: String?
    // API-specific properties
}

public struct WeatherApiDTO: Codable {
    public let dt: Int                    // Unix timestamp
    public let main: TemperatureApiDTO
    public let weather: [WeatherDataApiDTO]
    public let clouds: CloudsApiDTO?
    public let wind: WindApiDTO?
    
    enum CodingKeys: String, CodingKey {
        case dt, main, weather, clouds, wind
    }
}

// File DTO - Optimized for local storage
public struct ForecastFileDTO: Codable {
    public let cityName: String
    public let country: String
    public let weatherItems: [WeatherFileDTO]
    public let lastUpdated: String       // ISO date string
    public let version: String           // For data migration
    
    public init(cityName: String, country: String, weatherItems: [WeatherFileDTO], lastUpdated: String, version: String = "1.0") {
        self.cityName = cityName
        self.country = country
        self.weatherItems = weatherItems
        self.lastUpdated = lastUpdated
        self.version = version
    }
}

public struct WeatherFileDTO: Codable {
    public let dateTime: String          // ISO date string
    public let temperature: TemperatureFileDTO
    public let condition: WeatherConditionFileDTO
    public let description: String
}
```

## 🔄 Mapper Pattern

### Bidirectional Domain Mappers

```swift
public struct WeatherDomainMapper {
    
    // MARK: - API DTO → Domain Model
    public static func mapToDomain(_ dto: ForecastApiDTO) -> ForecastModel {
        let city = CityModel(name: dto.city.name, country: dto.city.country)
        let weatherItems = dto.list.map { mapToDomain($0) }
        
        return ForecastModel(
            city: city,
            weatherItems: weatherItems,
            lastUpdated: Date()
        )
    }
    
    public static func mapToDomain(_ dto: WeatherApiDTO) -> WeatherModel {
        let dateTime = Date(timeIntervalSince1970: TimeInterval(dto.dt))
        
        let temperature = TemperatureModel(
            current: dto.main.temp,
            min: dto.main.temp_min,
            max: dto.main.temp_max,
            feelsLike: dto.main.feels_like
        )
        
        let weatherType = mapWeatherType(dto.weather.first?.main ?? "Unknown")
        let condition = WeatherConditionModel(
            type: weatherType,
            iconCode: dto.weather.first?.icon
        )
        
        return WeatherModel(
            dateTime: dateTime,
            temperature: temperature,
            condition: condition,
            description: dto.weather.first?.description ?? "No description"
        )
    }
    
    // MARK: - File DTO → Domain Model
    public static func mapToDomain(_ dto: ForecastFileDTO) -> ForecastModel {
        let city = CityModel(name: dto.cityName, country: dto.country)
        let weatherItems = dto.weatherItems.compactMap { mapToDomain($0) }
        let lastUpdated = ISO8601DateFormatter().date(from: dto.lastUpdated) ?? Date()
        
        return ForecastModel(
            city: city,
            weatherItems: weatherItems,
            lastUpdated: lastUpdated
        )
    }
    
    // MARK: - Domain Model → File DTO
    public static func mapToFileDTO(_ forecast: ForecastModel) -> ForecastFileDTO {
        let weatherItems = forecast.weatherItems.map { mapToFileDTO($0) }
        let lastUpdatedString = ISO8601DateFormatter().string(from: forecast.lastUpdated)
        
        return ForecastFileDTO(
            cityName: forecast.city.name,
            country: forecast.city.country,
            weatherItems: weatherItems,
            lastUpdated: lastUpdatedString
        )
    }
    
    // MARK: - Helper Methods
    private static func mapWeatherType(_ apiType: String) -> WeatherType {
        switch apiType.lowercased() {
        case "clear": return .sunny
        case "clouds": return .cloudy
        case "rain", "drizzle": return .rainy
        case "snow": return .snowy
        case "thunderstorm": return .stormy
        case "mist", "fog", "haze": return .foggy
        default: return .unknown
        }
    }
}
```

## 🏛️ Repository Pattern with Strategy

### Repository Protocol (Domain Boundary)

```swift
protocol WeatherRepository {
    func fetchWeather(for city: String) async throws -> ForecastModel
    func saveWeather(_ forecast: ForecastModel) async throws
    func deleteWeather(for city: String) async throws
    func getAllSavedCities() async throws -> [String]
    func getCachedWeather(for city: String) async throws -> ForecastModel?
    func clearCache() async throws
    func refreshWeather(for city: String) async throws -> ForecastModel
    func getWeatherWithFallback(for city: String) async throws -> ForecastModel
}
```

### Repository Implementation with Intelligent Strategies

```swift
class WeatherRepositoryImpl: WeatherRepository {
    private let remoteDataSource: WeatherRemoteDataSource    // Returns ForecastApiDTO
    private let localDataSource: WeatherLocalDataSource      // Returns ForecastFileDTO
    private let cacheDataSource: WeatherCacheDataSource      // Returns ForecastFileDTO
    private let configuration: RepositoryConfiguration
    
    struct RepositoryConfiguration {
        let useCache: Bool
        let useLocalStorage: Bool
        let cacheFirstStrategy: Bool
        let offlineFallback: Bool
        
        static let `default` = RepositoryConfiguration(
            useCache: true,
            useLocalStorage: true,
            cacheFirstStrategy: true,
            offlineFallback: true
        )
    }
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        // Strategy 1: Check cache first if enabled
        if configuration.useCache && configuration.cacheFirstStrategy {
            if let cachedForecast = try await getCachedWeather(for: city) {
                return cachedForecast
            }
        }
        
        // Strategy 2: Try remote API
        do {
            let forecastApiDTO = try await remoteDataSource.fetchWeather(for: city)
            let forecast = WeatherDomainMapper.mapToDomain(forecastApiDTO)  // DTO → Domain
            
            // Convert to File DTO for storage
            let forecastFileDTO = WeatherDomainMapper.mapToFileDTO(forecast)  // Domain → DTO
            
            // Cache and save locally
            if configuration.useCache {
                try await cacheDataSource.cacheWeather(forecastFileDTO)
            }
            
            if configuration.useLocalStorage {
                try await localDataSource.saveWeather(forecastFileDTO)
            }
            
            return forecast  // Return Domain Model
        } catch {
            // Strategy 3: Fallback to local storage
            if configuration.offlineFallback && configuration.useLocalStorage {
                if let localForecastDTO = try await localDataSource.fetchWeather(for: city) {
                    return WeatherDomainMapper.mapToDomain(localForecastDTO)  // DTO → Domain
                }
            }
            
            throw error
        }
    }
    
    func getCachedWeather(for city: String) async throws -> ForecastModel? {
        guard configuration.useCache else { return nil }
        
        if let cachedDTO = try await cacheDataSource.getCachedWeather(for: city) {
            return WeatherDomainMapper.mapToDomain(cachedDTO)  // DTO → Domain
        }
        return nil
    }
}
```

## 🗄️ Data Source Architecture

### Protocol Segregation

```swift
// Remote Data Source - Works with API DTOs
protocol WeatherRemoteDataSource {
    func fetchWeather(for city: String) async throws -> ForecastApiDTO
}

// Local Data Source - Works with File DTOs
protocol WeatherLocalDataSource {
    func fetchWeather(for city: String) async throws -> ForecastFileDTO?
    func saveWeather(_ forecast: ForecastFileDTO) async throws
    func deleteWeather(for city: String) async throws
    func getAllSavedCities() async throws -> [String]
    func clearAll() async throws
}

// Cache Data Source - Works with File DTOs
protocol WeatherCacheDataSource {
    func getCachedWeather(for city: String) async throws -> ForecastFileDTO?
    func cacheWeather(_ forecast: ForecastFileDTO) async throws
    func clearCache() async throws
    func isExpired(for city: String) async -> Bool
}
```

### Actor-Based Thread-Safe Cache Implementation

```swift
class WeatherMemoryCacheDataSource: WeatherCacheDataSource {
    private actor CacheActor {
        private var cache: [String: CachedWeather] = [:]
        private let cacheExpirationTime: TimeInterval
        
        init(cacheExpirationTime: TimeInterval = 300) { // 5 minutes default
            self.cacheExpirationTime = cacheExpirationTime
        }
        
        func get(for city: String) -> CachedWeather? {
            return cache[city.lowercased()]
        }
        
        func set(_ forecast: ForecastFileDTO, for city: String) {
            cache[city.lowercased()] = CachedWeather(
                forecast: forecast,
                timestamp: Date()
            )
        }
        
        func isExpired(for city: String) -> Bool {
            guard let cachedWeather = cache[city.lowercased()] else {
                return true
            }
            
            let timeElapsed = Date().timeIntervalSince(cachedWeather.timestamp)
            return timeElapsed > cacheExpirationTime
        }
        
        func cleanExpiredEntries() {
            let now = Date()
            cache = cache.filter { _, cachedWeather in
                let timeElapsed = now.timeIntervalSince(cachedWeather.timestamp)
                return timeElapsed <= cacheExpirationTime
            }
        }
    }
    
    private struct CachedWeather {
        let forecast: ForecastFileDTO
        let timestamp: Date
    }
    
    private let cacheActor: CacheActor
    
    func getCachedWeather(for city: String) async throws -> ForecastFileDTO? {
        let cachedWeather = await cacheActor.get(for: city)
        
        guard let cachedWeather = cachedWeather else {
            return nil
        }
        
        let isExpired = await cacheActor.isExpired(for: city)
        if isExpired {
            await cacheActor.cleanExpiredEntries()
            return nil
        }
        
        return cachedWeather.forecast
    }
    
    func cacheWeather(_ forecast: ForecastFileDTO) async throws {
        await cacheActor.set(forecast, for: forecast.cityName)
    }
}
```

## 🏪 Modern Store Pattern with @Observable

### State Management for iOS 17+

```swift
@Observable
class WeatherStore {
    // MARK: - State (Domain Models Only)
    var forecast: ForecastModel?
    var isLoading = false
    var errorMessage: String?
    var selectedCity = ""
    var savedCities: [String] = []
    var dataSource: DataSourceType = .remote
    
    // MARK: - Dependencies
    private let weatherRepository: WeatherRepository
    
    // MARK: - Data Source Configuration
    enum DataSourceType: String, CaseIterable {
        case remote = "Remote API"
        case local = "Local Storage"
        case cache = "Memory Cache"
        case offline = "Offline Mode"
    }
    
    init(weatherRepository: WeatherRepository) {
        self.weatherRepository = weatherRepository
        Task {
            await loadSavedCities()
        }
    }
    
    // MARK: - Weather Operations
    @MainActor
    func fetchWeather(for city: String, forceRefresh: Bool = false) async {
        guard !city.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        selectedCity = city
        
        do {
            let result = try await performFetch(for: city, forceRefresh: forceRefresh)
            forecast = result  // Always Domain Model
        } catch {
            errorMessage = error.localizedDescription
            forecast = nil
        }
        
        isLoading = false
    }
    
    @MainActor
    func saveCurrentWeather() async {
        guard let forecast = forecast else { return }
        
        do {
            try await weatherRepository.saveWeather(forecast)  // Pass Domain Model
            await loadSavedCities()
        } catch {
            errorMessage = "Failed to save weather: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    private func performFetch(for city: String, forceRefresh: Bool) async throws -> ForecastModel {
        switch dataSource {
        case .remote:
            if forceRefresh {
                return try await weatherRepository.refreshWeather(for: city)
            } else {
                return try await weatherRepository.fetchWeather(for: city)
            }
            
        case .local:
            if let localWeather = try await weatherRepository.getCachedWeather(for: city) {
                return localWeather
            } else {
                // Fallback to remote if no local data
                return try await weatherRepository.fetchWeather(for: city)
            }
            
        case .cache:
            if let cachedWeather = try await weatherRepository.getCachedWeather(for: city) {
                return cachedWeather
            } else {
                // Fallback to remote if no cached data
                return try await weatherRepository.fetchWeather(for: city)
            }
            
        case .offline:
            return try await weatherRepository.getWeatherWithFallback(for: city)
        }
    }
}
```

## 🎨 UI Layer Integration

### Modern SwiftUI Patterns

```swift
struct WeatherView: View {
    @Environment(WeatherStore.self) private var weatherStore
    @State private var cityName = ""
    
    var body: some View {
        NavigationView {
            VStack {
                searchSection
                weatherContent
            }
            .navigationTitle("Weather")
            .task {
                if weatherStore.forecast == nil {
                    await loadDefaultWeather()
                }
            }
        }
    }
    
    @ViewBuilder
    private var weatherContent: some View {
        if weatherStore.isLoading {
            LoadingView()
        } else if let forecast = weatherStore.forecast { // ForecastModel
            WeatherList(forecast: forecast)
        } else if let errorMessage = weatherStore.errorMessage {
            VStack {
                Text("Error")
                    .font(.headline)
                Text(errorMessage)
                    .foregroundColor(.red)
                Button("Retry") {
                    Task {
                        await weatherStore.refreshWeather()
                    }
                }
                .padding()
            }
        } else {
            VStack {
                Image(systemName: "cloud.sun")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text("No weather data")
                    .font(.headline)
                Text("Search for a city to get started")
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
    
    private func searchWeather() async {
        await weatherStore.fetchWeather(for: cityName)
    }
}

struct WeatherList: View {
    let forecast: ForecastModel  // Domain Model
    
    var body: some View {
        List {
            Section(header: Text(forecast.city.name)) {
                ForEach(forecast.weatherItems, id: \.dateTime) { weather in  // WeatherModel
                    WeatherRowView(weather: weather)
                }
            }
        }
    }
}

struct WeatherRowView: View {
    let weather: WeatherModel  // Domain Model
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Date: \(weather.dateTime, formatter: DateFormatter.shortDate)")
            Text("Temperature: \(weather.temperature.current)°C")
            Text("Condition: \(weather.condition.type.displayName)")
        }
        .padding()
    }
}
```

## 🏭 Dependency Injection

### Factory Pattern with AppContainer

```swift
class AppContainer {
    // MARK: - Lazy Properties
    private lazy var apiClient = APIClient()
    private lazy var configurationManager = ConfigurationManager()
    private lazy var jsonLoader = JSONLoader()
    
    // MARK: - Factory Methods
    func makeWeatherStore() -> WeatherStore {
        return WeatherStore(weatherRepository: makeWeatherRepository())
    }
    
    private func makeWeatherRepository() -> WeatherRepository {
        return WeatherRepositoryImpl(
            remoteDataSource: makeRemoteDataSource(),
            localDataSource: makeLocalDataSource(),
            cacheDataSource: makeCacheDataSource(),
            configuration: .default
        )
    }
    
    private func makeRemoteDataSource() -> WeatherRemoteDataSource {
        return WeatherRemoteDataSourceImpl(
            networkService: apiClient,
            configuration: configurationManager
        )
    }
    
    private func makeLocalDataSource() -> WeatherLocalDataSource {
        return WeatherFileDataSourceImpl(
            fileManager: .default,
            jsonLoader: jsonLoader
        )
    }
    
    private func makeCacheDataSource() -> WeatherCacheDataSource {
        return WeatherMemoryCacheDataSource(cacheExpirationTime: 300) // 5 minutes
    }
}

// Environment injection
@main
struct AppRoot: App {
    @State private var container = AppContainer()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)  // Inject container
        }
    }
}

struct RootView: View {
    @Environment(AppContainer.self) private var container
    @State private var weatherStore: WeatherStore?
    
    var body: some View {
        if let weatherStore = weatherStore {
            WeatherView()
                .environment(weatherStore)  // Inject store
        } else {
            LoadingView()
        }
    }
    .task {
        weatherStore = container.makeWeatherStore()  // Factory creation
    }
}
```

## 🧪 Testing Strategy

### Repository Testing with Mocks

```swift
class MockWeatherRepository: WeatherRepository {
    var fetchWeatherCalled = false
    var saveWeatherCalled = false
    var mockForecast: ForecastModel?
    var mockError: Error?
    
    func fetchWeather(for city: String) async throws -> ForecastModel {
        fetchWeatherCalled = true
        
        if let error = mockError {
            throw error
        }
        
        return mockForecast ?? ForecastModel(
            city: CityModel(name: city, country: "Test"),
            weatherItems: [],
            lastUpdated: Date()
        )
    }
    
    func saveWeather(_ forecast: ForecastModel) async throws {
        saveWeatherCalled = true
        
        if let error = mockError {
            throw error
        }
    }
    
    // Implement other methods...
}

class WeatherStoreTests: XCTestCase {
    var store: WeatherStore!
    var mockRepository: MockWeatherRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockWeatherRepository()
        store = WeatherStore(weatherRepository: mockRepository)
    }
    
    func testFetchWeatherSuccess() async {
        // Given
        let expectedCity = "London"
        
        // When
        await store.fetchWeather(for: expectedCity)
        
        // Then
        XCTAssertTrue(mockRepository.fetchWeatherCalled)
        XCTAssertNotNil(store.forecast)
        XCTAssertEqual(store.forecast?.city.name, expectedCity)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.errorMessage)
    }
    
    func testFetchWeatherError() async {
        // Given
        mockRepository.mockError = WeatherRepositoryError.networkError(NSError(domain: "test", code: 1))
        
        // When
        await store.fetchWeather(for: "London")
        
        // Then
        XCTAssertTrue(mockRepository.fetchWeatherCalled)
        XCTAssertNil(store.forecast)
        XCTAssertFalse(store.isLoading)
        XCTAssertNotNil(store.errorMessage)
    }
}
```

### DTO Mapping Tests

```swift
class WeatherDomainMapperTests: XCTestCase {
    
    func testMapApiDTOToDomain() {
        // Given
        let apiDTO = ForecastApiDTO(
            city: CityApiDTO(name: "London", country: "UK"),
            list: [
                WeatherApiDTO(
                    dt: 1640995200,  // 2022-01-01 00:00:00 UTC
                    main: TemperatureApiDTO(temp: 15.5, temp_min: 10.0, temp_max: 20.0, feels_like: 16.0),
                    weather: [WeatherDataApiDTO(main: "Clear", description: "clear sky", icon: "01d")]
                )
            ]
        )
        
        // When
        let domainModel = WeatherDomainMapper.mapToDomain(apiDTO)
        
        // Then
        XCTAssertEqual(domainModel.city.name, "London")
        XCTAssertEqual(domainModel.city.country, "UK")
        XCTAssertEqual(domainModel.weatherItems.count, 1)
        
        let weather = domainModel.weatherItems.first!
        XCTAssertEqual(weather.temperature.current, 15.5)
        XCTAssertEqual(weather.condition.type, .sunny)
        XCTAssertEqual(weather.description, "clear sky")
    }
    
    func testMapDomainToFileDTO() {
        // Given
        let domainModel = ForecastModel(
            city: CityModel(name: "London", country: "UK"),
            weatherItems: [
                WeatherModel(
                    dateTime: Date(timeIntervalSince1970: 1640995200),
                    temperature: TemperatureModel(current: 15.5, min: 10.0, max: 20.0, feelsLike: 16.0),
                    condition: WeatherConditionModel(type: .sunny, iconCode: "01d"),
                    description: "clear sky"
                )
            ],
            lastUpdated: Date()
        )
        
        // When
        let fileDTO = WeatherDomainMapper.mapToFileDTO(domainModel)
        
        // Then
        XCTAssertEqual(fileDTO.cityName, "London")
        XCTAssertEqual(fileDTO.country, "UK")
        XCTAssertEqual(fileDTO.weatherItems.count, 1)
        XCTAssertEqual(fileDTO.version, "1.0")
        
        let weatherDTO = fileDTO.weatherItems.first!
        XCTAssertEqual(weatherDTO.temperature.current, 15.5)
        XCTAssertEqual(weatherDTO.condition.type, "Clear")
        XCTAssertEqual(weatherDTO.description, "clear sky")
    }
}
```

## 🎯 Key Architecture Benefits

1. **Separation of Concerns**: Domain models completely isolated from data persistence
2. **Testability**: Protocol-based design enables easy mocking and testing
3. **Flexibility**: Multiple data sources with configurable strategies
4. **Scalability**: Feature-based organization supports team scaling
5. **Modern Swift**: Leverages latest Swift concurrency and SwiftUI patterns
6. **Offline-First**: Robust caching and local storage with intelligent fallbacks
7. **Type Safety**: Strong typing throughout all layers with compile-time guarantees
8. **Performance**: Actor-based concurrency for thread-safe operations
9. **Maintainability**: Clear boundaries and single responsibility principle
10. **Future-Proof**: Easy to extend with new features and data sources

## 📋 Development Rules

### ✅ DO:
- Views and Stores only reference Domain Models
- Use DTOs for all external data (API, files, databases)
- Map between DTOs and Domain Models in Repository layer
- Keep Domain Models pure (no Codable, no external dependencies)
- Use @Observable for iOS 17+ state management
- Implement Repository pattern for data abstraction
- Use Actors for thread-safe shared state
- Follow protocol segregation for data sources
- Write comprehensive tests for mappers and repositories

### ❌ DON'T:
- Reference DTOs in Views or Stores
- Put Codable on Domain Models
- Skip the mapping layer
- Mix API concerns with business logic
- Use @ObservableObject for new iOS 17+ code
- Create god objects or massive view controllers
- Ignore error handling and edge cases
- Skip unit tests for business logic

## 🔧 Build & Run Commands
- **Build**: `xcodebuild -scheme StarterApp -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64' build`
- **Test**: `xcodebuild test -scheme StarterApp -destination 'platform=iOS Simulator,name=iPhone 16,arch=arm64'`
- **Clean**: `xcodebuild clean -scheme StarterApp`

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.

## 🚀 Data Flow Summary

```
UI Layer (Views) 
    ↓ @Environment injection
Store Layer (@Observable) ──→ Domain Models Only
    ↓ Repository protocol
Repository Implementation ──→ DTO Mapping Logic
    ↓ DataSource protocols  
Multiple Data Sources ──→ DTOs (API/File/Cache)
    ↓ Mappers
Domain Models ←──── Pure Swift Types
```

This architecture ensures **maintainable, testable, and scalable iOS applications** with clear separation of concerns and modern Swift patterns.