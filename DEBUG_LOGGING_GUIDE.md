# Debug Logging Configuration Guide

This guide explains how to configure and view all application logs when running the StarterApp in debug mode.

## 🎯 Quick Setup for Debug Logging

### 1. Configure Xcode Scheme Environment Variables

1. In Xcode, select your scheme and click "Edit Scheme..."
2. Go to "Run" → "Arguments" → "Environment Variables"
3. Add these environment variables:

**For Console.app Only (Recommended):**
```
OS_ACTIVITY_MODE = enable
STARTERAPP_ENVIRONMENT = development
```

**For Dual Output (Xcode Console + Console.app):**
```
OS_ACTIVITY_MODE = enable
STARTERAPP_LOG_LEVEL = console
STARTERAPP_ENVIRONMENT = development
```

**What these do:**
- `OS_ACTIVITY_MODE=enable`: Enables os.Logger output visibility in Console.app
- `STARTERAPP_LOG_LEVEL=console`: Triggers console fallback mode for immediate Xcode visibility (causes duplicates)
- `STARTERAPP_ENVIRONMENT=development`: Forces development logging profile (shows ALL log levels)

### 2. View Logs in Multiple Ways

## 📱 Option 1: Xcode Console (Immediate Visibility)

When `STARTERAPP_LOG_LEVEL=debug` is set, all logs will appear in Xcode's debug console using `print()` alongside the structured os.Logger output.

**Advantages:**
- Immediate visibility during development
- No need to switch apps
- Familiar debug output

**Format example:**
```
2024-06-17 14:23:45.123 🌐 [INFO] [NetworkService.swift:45] fetch(url:) - Network Request: GET https://api.openweathermap.org/data/2.5/forecast
```

## 🖥️ Option 2: Console.app (Structured os.Logger)

For viewing the actual os.Logger structured output:

1. Open **Console.app** on your Mac
2. Connect your device or select your simulator from the left sidebar
3. Filter logs using these techniques:

### Filter by Subsystem
```
subsystem:com.starterapp
```

### Filter by Category
```
category:Weather
category:Network
category:Repository
```

### Filter by Log Level
```
level:debug
level:info
level:error
```

### Combine Filters
```
subsystem:com.starterapp AND category:Network
subsystem:com.starterapp AND level:debug
```

**Advantages:**
- Structured, searchable logs
- Rich metadata
- Professional logging format
- Persistent across app runs

## 🔧 Configuration Profiles

The app includes several pre-configured logging profiles:

### `.debugConsole` Profile
- **Use case**: Maximum visibility during development
- **Output**: Both Xcode console + os.Logger
- **Level**: All logs (debug and above)

```swift
// Automatically used when STARTERAPP_LOG_LEVEL=debug
let logger = loggerFactory.createLogger(category: "MyFeature")
```

### `.development` Profile
- **Use case**: Verbose logging with dual output
- **Output**: os.Logger + console fallback
- **Level**: Debug and above

### `.production` Profile
- **Use case**: Minimal logging for release builds
- **Output**: os.Logger only
- **Level**: Error and above

## 🏷️ Log Categories

The app uses categorized logging for easy filtering:

| Category | Purpose | Example Usage |
|----------|---------|---------------|
| `App` | Application lifecycle | App launch, background/foreground |
| `Network` | Network requests/responses | API calls, connectivity |
| `Weather` | Weather feature | Data fetching, processing |
| `Repository` | Data layer operations | Caching, fallbacks |
| `UI` | User interface | View lifecycle, user interactions |
| `Performance` | Performance monitoring | Execution time, memory |

## 📊 Log Levels and When to Use Them

| Level | Emoji | Purpose | Example |
|-------|-------|---------|---------|
| `debug` | 🐛 | Development info | Variable values, flow tracing |
| `info` | ℹ️ | General information | Feature usage, state changes |
| `notice` | 📋 | Important events | Configuration changes |
| `error` | ❌ | Error conditions | Network failures, parsing errors |
| `fault` | 💥 | System faults | Critical component failures |
| `critical` | 🚨 | Critical errors | App-breaking issues |

## 🚀 Recommended Development Workflow

### Step 1: Enable Debug Mode
Set environment variables in Xcode scheme:
```
OS_ACTIVITY_MODE = enable
STARTERAPP_ENVIRONMENT = development
```
*Add `STARTERAPP_LOG_LEVEL = console` only if you want dual output*

### Step 2: Run Your App
All logs will now appear in **both**:
- Xcode debug console (immediate)
- Console.app (structured)

### Step 3: Filter Logs as Needed
In Console.app, use filters like:
```
subsystem:com.starterapp AND category:Weather
```

### Step 4: Debug Specific Features
Use category-specific loggers:
```swift
let logger = loggerFactory.createWeatherLogger()
logger.debug("Fetching weather for city: \(cityName)")
```

## 🔍 Advanced Filtering Examples

### Network Debugging
```
subsystem:com.starterapp AND category:Network
```

### Error Investigation
```
subsystem:com.starterapp AND level:error
```

### Performance Analysis
```
subsystem:com.starterapp AND category:Performance
```

### Feature-Specific Debugging
```
subsystem:com.starterapp AND category:Weather AND level:debug
```

## 📱 Device vs Simulator

### Simulator
- Logs appear in Console.app under "Simulator" section
- Full os.Logger integration
- Console fallback works in Xcode

### Physical Device
- Device must be connected and trusted
- Logs appear under device name in Console.app
- May require developer mode enabled

## ⚠️ Important Notes

1. **Performance**: Console fallback adds minimal overhead but should be disabled in production
2. **Privacy**: os.Logger automatically handles sensitive data privacy
3. **Persistence**: os.Logger entries persist in the system log database
4. **Storage**: Console logs are automatically rotated by the system

## 🛠️ Troubleshooting

### "No logs appearing in Console.app"
- Check `OS_ACTIVITY_MODE=enable` is set
- Verify the correct subsystem filter: `subsystem:com.starterapp`
- Ensure device/simulator is selected in Console.app sidebar

### "No logs in Xcode console"
- Check `STARTERAPP_LOG_LEVEL=debug` is set
- Verify you're running a debug build
- Check that `consoleFallback` is enabled in LoggingConfiguration

### "Too many logs"
- Adjust log level: Use `info` instead of `debug`
- Filter by category in Console.app
- Use specific loggers for focused debugging

## 🎯 Best Practices

1. **Use appropriate log levels**: Don't use `debug` for production information
2. **Categorize your logs**: Use specific categories for different features
3. **Include context**: Add relevant data to log messages
4. **Filter strategically**: Use Console.app filters to focus on specific issues
5. **Clean up**: Remove excessive debug logging before release

## 📋 Example Debug Session

1. Set environment variables in Xcode scheme
2. Run app in simulator
3. Open Console.app
4. Filter: `subsystem:com.starterapp AND level:debug`
5. Trigger weather fetch in app
6. Watch logs in both Xcode console and Console.app
7. Use category filters to focus on specific components

This configuration gives you maximum visibility into your app's behavior during development while maintaining professional logging practices for production builds.