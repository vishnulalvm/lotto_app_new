# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter lottery results application following Clean Architecture with BLoC state management. The app supports multiple languages (English, Malayalam, Hindi, Tamil) and includes features for lottery result checking, barcode scanning, scratch cards, and prize claiming.

## Development Commands

### Essential Commands
```bash
# Install dependencies
flutter pub get

# Run the app (use this for development)
flutter run

# Analyze code (run this before committing)
flutter analyze

# Run tests
flutter test

# Build for production
flutter build apk              # Android APK
flutter build appbundle       # Android App Bundle for Play Store
flutter build ios             # iOS build

# Generate app icons after changes
flutter pub run flutter_launcher_icons:main
```

### Code Quality
- The project uses `flutter_lints` for code analysis
- Always run `flutter analyze` before committing changes
- Follow standard Flutter/Dart conventions as enforced by the linter

## Architecture

### Clean Architecture Structure
```
lib/
├── core/               # Shared utilities, constants, widgets
├── data/              # API services, models, data sources
├── domain/            # Use cases, business logic
├── presentation/      # BLoCs, pages, UI components
└── routes/           # GoRouter navigation configuration
```

### State Management
- **BLoC Pattern**: All state management uses `flutter_bloc`
- **Key BLoCs**: AuthBloc, HomeScreenResultsBloc, ThemeBloc, LotteryResultDetailsBloc, TicketCheckBloc
- **Dependency Injection**: Manual injection in main.dart using MultiBlocProvider

### Navigation
- **GoRouter**: Declarative routing with authentication guards
- **Authentication Flow**: App requires login before accessing main features
- Routes automatically redirect based on login status

### API Integration
- **HTTP Client**: Uses `http` package for API communication
- **API Structure**: Services organized by feature in `lib/data/api_services/`
- **Models**: Located in `lib/data/models/` with JSON serialization

### Internationalization
- **Package**: `easy_localization`
- **Languages**: English (default), Malayalam, Hindi, Tamil
- **Translations**: JSON files in `assets/translations/`
- **Usage**: Access via `context.tr('key')` or `'key'.tr()`

### Key Features
- **Authentication**: Phone number-based login/signup
- **Lottery Results**: Home screen with results display and details
- **Barcode Scanner**: QR/barcode scanning using `mobile_scanner`
- **Scratch Cards**: Interactive scratch functionality using `scratcher`
- **Theme Support**: Light/dark theme switching
- **Local Storage**: `shared_preferences` for user data persistence

## Caching System

### Overview
The app implements a comprehensive caching system using Hive database for offline functionality and improved performance.

### Cache Strategy
- **Cache-First**: Always try to load from cache first, then fetch from network
- **Background Refresh**: When cached data is available, show it immediately and refresh in background
- **Offline Fallback**: Show cached data when network is unavailable
- **Expiration**: Cache expires after 24 hours by default

### Dependencies
```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
connectivity_plus: ^6.1.0
path_provider: ^2.1.4
build_runner: ^2.4.13  # dev dependency
hive_generator: ^2.0.1  # dev dependency
```

### Key Components

#### Cache Models
- `CachedHomeScreenModel`: Hive-annotated model for home screen data
- `CachedHomeScreenResultModel`: Individual lottery result cache model
- Generated adapters via `build_runner` for type-safe serialization

#### Services
- `HiveService`: Database initialization and box management
- `CacheManager`: Automatic cleanup, size management, and maintenance
- `ConnectivityService`: Network status monitoring for offline detection

#### Repositories
- `HomeScreenCacheRepository`: Interface for cache operations
- `HomeScreenCacheRepositoryImpl`: Implementation with error handling
- Enhanced `HomeScreenResultsRepository`: Combines API and cache with intelligent strategy

### Cache Configuration
```dart
// Cache limits
Max Size: 50MB
Max Age: 7 days  
Cleanup Interval: 1 hour
Cache Expiry: 24 hours
Fresh Data Window: 30 minutes
```

### Code Generation
Run when cache models change:
```bash
flutter packages pub run build_runner build
```

### Error Handling
Custom exceptions for cache operations:
- `CacheReadException`: Failed to read from cache
- `CacheWriteException`: Failed to write to cache  
- `CacheCorruptedException`: Cache data is corrupted
- `CacheStorageFullException`: Insufficient storage space

### UI Indicators
- **Offline Badge**: Shows in app bar when device is offline
- **Data Source Indicators**: Shows whether data is live, cached, or hybrid
- **Cache Age**: Displays how old cached data is
- **Error Banners**: Shows connection errors with retry options

### Usage Examples

#### In BLoC
```dart
// Load with cache-first strategy
final result = await _useCase.execute();

// Force refresh (skip cache)
final result = await _useCase.execute(forceRefresh: true);

// Get cache information
final cacheInfo = await _useCase.getCacheInfo();
```

#### Cache Management
```dart
// Clear all cache
await _useCase.clearCache();

// Get cache statistics
final stats = CacheManager.getCacheStats();

// Perform maintenance
await CacheManager.performMaintenance();
```

## Development Workflow

1. **Authentication Required**: Most features require user authentication
2. **Cache-First Loading**: UI loads cached data immediately, then refreshes from network
3. **Offline Support**: App functions with cached data when offline
4. **Feature-Based Organization**: Code organized by app features rather than technical layers
5. **BLoC Events**: UI interactions trigger BLoC events, never direct state mutations
6. **Clean Architecture**: Maintain separation between data, domain, and presentation layers

## Important Files

- `lib/main.dart`: App entry point with BLoC providers and cache initialization
- `lib/data/services/hive_service.dart`: Hive database setup and management
- `lib/data/services/cache_manager.dart`: Cache maintenance and cleanup
- `lib/data/services/connectivity_service.dart`: Network status monitoring
- `lib/data/models/home_screen/cached_home_screen_model.dart`: Cache data models
- `lib/data/repositories/cache/`: Cache repository implementations
- `lib/core/errors/cache_exceptions.dart`: Cache-specific error types
- `lib/routes/app_router.dart`: GoRouter configuration with route definitions
- `lib/core/constants/`: API endpoints, colors, strings, and other constants
- `lib/core/helpers/`: Utility functions including responsive design helpers
- `lib/core/widgets/`: Reusable UI components used across the app

## Testing

The project structure supports unit, widget, and integration testing. Test files should mirror the lib structure in the test directory. Cache functionality includes dedicated tests for:
- Cache repository operations
- Model serialization/deserialization  
- Cache expiration logic
- Error handling scenarios