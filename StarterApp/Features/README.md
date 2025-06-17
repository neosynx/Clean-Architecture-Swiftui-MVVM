# Feature-Based Architecture Guide

## Overview

This project uses a **Feature-Based Clean Architecture** where each feature is organized as a self-contained module with its own layers.

## Feature Structure

Each feature follows this structure:

```
Features/
└── FeatureName/
    ├── FeatureNameModule.swift       # Feature module definition
    ├── Presentation/
    │   ├── Views/                    # SwiftUI Views
    │   └── ViewModels/               # ViewModels
    ├── Domain/
    │   ├── UseCases/                 # Business logic
    │   └── Entities/                 # Domain models
    └── Data/
        ├── Repositories/             # Repository implementations
        └── DataSources/              # Data source implementations
```

## Adding a New Feature

### 1. Create Feature Structure

```bash
mkdir -p Features/NewFeature/{Presentation/{Views,ViewModels},Domain/{UseCases,Entities},Data/{Repositories,DataSources}}
```

### 2. Create Feature Module

Create `NewFeatureModule.swift`:

```swift
import SwiftUI

// MARK: - Feature Dependencies
struct NewFeatureDependencies {
    // Define your feature's dependencies
}

// MARK: - Feature Module
struct NewFeatureModule: FeatureModule {
    typealias RootView = NewFeatureView
    typealias Dependencies = NewFeatureDependencies
    
    static var identifier: String { "newfeature" }
    
    static func createRootView(dependencies: Dependencies) -> NewFeatureView {
        NewFeatureView()
    }
    
    static func registerDependencies(in container: DependencyContainer) {
        // Register feature-specific dependencies
        print("🎯 NewFeature dependencies registered")
    }
}
```

### 3. Add Feature Destination

Update `FeatureDestination` enum in `FeatureModule.swift`:

```swift
enum FeatureDestination: String, CaseIterable {
    case weather = "weather"
    case newfeature = "newfeature"  // Add this line
    // ... existing cases
    
    var title: String {
        switch self {
        case .newfeature: return "New Feature"
        // ... existing cases
        }
    }
    
    var icon: String {
        switch self {
        case .newfeature: return "star"
        // ... existing cases  
        }
    }
}
```

### 4. Register Feature

Update `DependencyContainer.swift`:

```swift
private func registerFeatures() {
    featureRegistry.register(WeatherFeatureModule.self)
    featureRegistry.register(NewFeatureModule.self)  // Add this line
    
    WeatherFeatureModule.registerDependencies(in: self)
    NewFeatureModule.registerDependencies(in: self)  // Add this line
}
```

### 5. Add to Main App

Update `MainAppView.swift`:

```swift
TabView(selection: $selectedTab) {
    // ... existing tabs
    
    NewFeatureView()
        .tabItem {
            Label(FeatureDestination.newfeature.title, 
                  systemImage: FeatureDestination.newfeature.icon)
        }
        .tag(FeatureDestination.newfeature)
}
```

## Best Practices

### 1. Feature Independence
- Each feature should be self-contained
- Avoid direct dependencies between features
- Use shared components from `Shared/` folder

### 2. Clean Architecture Layers
- **Presentation**: UI components and ViewModels
- **Domain**: Business logic and entities
- **Data**: Repository implementations and data sources

### 3. Dependency Injection
- Define feature dependencies clearly
- Use the DependencyContainer for shared services
- Keep feature-specific dependencies isolated

### 4. Shared Components
- Place reusable UI components in `Shared/UI/Components/`
- Put common business logic in `Shared/Domain/`
- Infrastructure services go in `Shared/Infrastructure/`

## Example Features

### Weather Feature
The Weather feature demonstrates:
- ✅ Complete Clean Architecture implementation
- ✅ Feature module pattern
- ✅ Coordinator pattern for navigation
- ✅ Integration with shared infrastructure

### Placeholder Features
- **Forecast**: 7-day weather forecasts
- **Location**: Location management
- **Settings**: App configuration

## Testing Strategy

Each feature should have its own test suite:

```
ExampleMVVMTests/
└── Features/
    └── FeatureName/
        ├── Presentation/
        ├── Domain/
        └── Data/
```

## Benefits

✅ **Scalability**: Easy to add new features  
✅ **Team Collaboration**: Multiple teams can work on different features  
✅ **Maintainability**: Related code is co-located  
✅ **Testability**: Feature-specific test isolation  
✅ **Modularity**: Features can become separate Swift Packages  
✅ **Code Reuse**: Shared components prevent duplication