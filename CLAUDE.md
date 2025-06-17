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