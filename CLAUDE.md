# CLAUDE.md - Radiance iOS Project Guidelines

## Project Context
This is a reference architecture native iOS app built with SwiftUI targeting iOS 17.0+.

## Tech Stack
- **Framework**: SwiftUI + SwiftData + Combine
- **Language**: Swift 5.9+
- **Architecture**: MVVM with @Observable
- **Target**: iOS 17.0+

🚀 Latest Best Practices for SwiftUI EnvironmentObject (2024-2025)
1. Modern Approach: Observation Framework vs EnvironmentObject
Key Change in iOS 17+: Apple introduced the Observation framework, offering a cleaner syntax and significant performance improvements
Traditional EnvironmentObject (Still Valid):
swift// Old approach - Still works
class UserSettings: ObservableObject {
    @Published var username = "Guest"
    @Published var isLoggedIn = false
}

@main
struct MyApp: App {
    @StateObject private var settings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var settings: UserSettings
    
    var body: some View {
        Text("Hello, \(settings.username)")
    }
}
New Observation Framework Approach (iOS 17+):
swift// Modern approach using @Observable
@Observable
class UserSettings {
    var username = "Guest"
    var isLoggedIn = false
}

@main
struct MyApp: App {
    @State private var settings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settings)  // Note: .environment() not .environmentObject()
        }
    }
}

struct ContentView: View {
    @Environment(UserSettings.self) var settings
    
    var body: some View {
        Text("Hello, \(settings.username)")
    }
}
2. Key Advantages of Modern @Environment + @Observable
Performance Benefits:

Views that do not actively use the environment state properties are no longer re-evaluated, further optimizing SwiftUI's rendering process
More granular, property-level reactivity with Observable instances

Safety Improvements:

EnvironmentValue is designed to be safer and more reliable because it requires a default value for every environment value SwiftUI - How to pass EnvironmentObject into View Model
Easy to inject multiple observable instances of the same type, which is hard to achieve with EnvironmentObject SwiftUI - How to pass EnvironmentObject into View Model

3. Best Practices for EnvironmentObject Usage
When to Use EnvironmentObject:

When your view structure is complex and has multiple layers of nesting
For sharing data across many places in your app without manual dependency injection swiftui - What's the purpose of .environmentObject() view operator vs @EnvironmentObject? - Stack Overflow
Only when data sharing across multiple layers is necessary What’s the difference between @ObservedObject, @State, and @EnvironmentObject? - a free SwiftUI by Example tutorial

When NOT to Use EnvironmentObject:

For tightly coupled views, consider @State or @Binding What’s the difference between @ObservedObject, @State, and @EnvironmentObject? - a free SwiftUI by Example tutorial
For simple data that only needs to be passed one level down

4. Proper Injection Patterns
Root Level Injection:
swift@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
Conditional Injection for Different View Hierarchies:
Sheet presentations require explicit injection since they create different view hierarchies
swiftstruct RootView: View {
    @EnvironmentObject var settings: Settings
    @State private var showingSheet = false
    
    var body: some View {
        VStack {
            ChildView() // Inherits environment object automatically
            
            Button("Show Sheet") {
                showingSheet.toggle()
            }
        }
        .sheet(isPresented: $showingSheet) {
            SheetView()
                .environmentObject(settings) // Must explicitly inject
        }
    }
}
5. Selective Declaration Pattern
Best Practice: You only need to declare @EnvironmentObject in views that really need to access the ViewModel, not in every intermediate layer
swiftstruct MiddleView: View {
    // No @EnvironmentObject declaration needed if not used
    var body: some View {
        VStack {
            SomeStaticContent()
            ChildThatNeedsEnvironment() // This child can declare @EnvironmentObject
        }
    }
}

struct ChildThatNeedsEnvironment: View {
    @EnvironmentObject var appState: AppState // Only declare where needed
    
    var body: some View {
        Text("Current state: \(appState.currentValue)")
    }
}
6. Passing EnvironmentObject to ViewModels
Method 1: Parameter Injection (Recommended)
swiftstruct MyView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        VStack {
            Button("Sign In") {
                viewModel.signIn(with: auth) // Pass as parameter
            }
        }
    }
}

class MyViewModel: ObservableObject {
    func signIn(with auth: AuthService) {
        // Use auth service here
    }
}
Method 2: Setup Pattern
swiftstruct MyView: View {
    @EnvironmentObject var settings: UserSettings
    @StateObject private var viewModel = MyViewModel()
    
    var body: some View {
        VStack {
            // UI content
        }
        .onAppear {
            viewModel.setup(settings)
        }
    }
}
7. Multiple Environment Objects
Type-Based Matching:
Environment objects are matched based on the object type
swift@main
struct MyApp: App {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var appTheme = AppTheme()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSettings)
                .environmentObject(appTheme) // Multiple objects
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var theme: AppTheme
    
    var body: some View {
        Text("Hello")
            .foregroundColor(theme.primaryColor)
    }
}
8. Modern Alternative Using @Environment with Custom Keys
Advanced Pattern for iOS 17+:
swiftextension EnvironmentValues {
    @Entry var store: AppStore = AppStore()
    @Entry var userStore: UserStore = UserStore()
    @Entry var themeStore: ThemeStore = ThemeStore()
}

@Observable
class AppStore {
    var isLoading = false
}

struct ContentView: View {
    @Environment(\.store) var store
    @Environment(\.userStore) var userStore
    
    var body: some View {
        Text("Loading: \(store.isLoading)")
    }
}
9. Testing Considerations
Always Provide Environment Objects in Previews:
swiftstruct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UserSettings()) // Required for preview
    }
}
10. Migration Strategy
For new iOS 17+ projects: Use @Observable + @Environment
For existing projects: EnvironmentObject is still fully supported and works well
Hybrid approach: You can combine EnvironmentValue with the Observation framework for seamless integration
Key Takeaways

Performance: Modern @Observable provides better performance with granular updates
Safety: @Environment is safer with required default values
Flexibility: Environment can hold reference types, functions, factory methods, and protocol-constrained objects SwiftUI - How to pass EnvironmentObject into View Model
Selective Usage: Only declare @EnvironmentObject where actually needed
Testing: Always provide environment objects in previews to avoid crashes

The choice between EnvironmentObject and the modern Environment approach depends on your deployment target and architectural preferences, but both are valid and well-supported patterns in current SwiftUI development.