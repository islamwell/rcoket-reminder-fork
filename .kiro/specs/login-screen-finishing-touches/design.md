# Design Document

## Overview

This design outlines the implementation of login screen finishing touches, including UI restructuring, Supabase backend integration, sample data removal, icon replacement, and scrolling Islamic quotes. The solution maintains the existing authentication flow while enhancing the user experience and implementing persistent data storage.

## Architecture

### Current Architecture
- Flutter app with presentation layer separation
- Local authentication service using SharedPreferences
- SVG-based icon system with Material Design
- Gradient-based UI with animation support

### Enhanced Architecture
- **Backend Layer**: Supabase integration with Flutter SDK
- **Service Layer**: Enhanced AuthService with Supabase client
- **Data Layer**: Persistent storage through Supabase with local caching
- **Presentation Layer**: Updated LoginScreen with restructured UI components
- **Configuration Layer**: Environment-based configuration with Firebase config file

## Components and Interfaces

### 1. UI Component Restructuring

#### Login Screen Layout Changes
```dart
// New top row structure
Row(
  children: [
    Expanded(child: GuestButton()),  // Moved from bottom
    SizedBox(width: 8),
    Expanded(child: SignUpButton()), // Existing
  ]
)
// Bottom login button remains unchanged
```

#### Scrolling Quote Widget
```dart
class ScrollingQuoteWidget extends StatefulWidget {
  final List<String> quotes;
  final Duration scrollDuration;
  final Duration displayDuration;
}
```

#### Icon Display Component
```dart
// Updated icon widget to use custom SVG with PNG fallback
Widget _buildLogo() {
  return Container(
    child: SvgPicture.asset(
      'assets/images/img_app_logo.svg',
      width: 120,
      height: 120,
      placeholderBuilder: (context) => Image.asset(
        'assets/images/reminder app icon.png',
        width: 120,
        height: 120,
      ),
    ),
  );
}
```

### 2. Backend Integration Components

#### Supabase Service Layer
```dart
class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;
  
  Future<AuthResponse> signIn(String email, String password);
  Future<AuthResponse> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<User?> getCurrentUser();
}
```

#### Enhanced Auth Service
```dart
class AuthService {
  final SupabaseService _supabaseService;
  
  Future<bool> login(String email, String password);
  Future<bool> register(String name, String email, String password);
  Future<void> continueAsGuest();
  Future<void> syncUserData();
}
```

### 3. Configuration Management

#### Environment Configuration
```dart
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  
  static bool get useSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
```

#### Firebase Configuration File
```json
// firebase_config.json (for future use)
{
  "apiKey": "your-api-key",
  "authDomain": "your-project.firebaseapp.com",
  "projectId": "your-project-id",
  "storageBucket": "your-project.appspot.com",
  "messagingSenderId": "123456789",
  "appId": "your-app-id"
}
```

## Data Models

### User Model Enhancement
```dart
class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isGuest;
  final Map<String, dynamic>? metadata;
  
  // Supabase integration methods
  factory User.fromSupabase(Map<String, dynamic> data);
  Map<String, dynamic> toSupabase();
}
```

### Authentication State Model
```dart
class AuthState {
  final bool isAuthenticated;
  final bool isGuest;
  final User? user;
  final AuthStatus status;
  
  enum AuthStatus { initial, loading, authenticated, unauthenticated, error }
}
```

## Error Handling

### Backend Connection Handling
```dart
class BackendErrorHandler {
  static Future<T> handleSupabaseOperation<T>(
    Future<T> Function() operation,
    T fallbackValue,
  ) async {
    try {
      return await operation();
    } on PostgrestException catch (e) {
      // Handle Supabase-specific errors
      _logError('Supabase error: ${e.message}');
      return fallbackValue;
    } on AuthException catch (e) {
      // Handle authentication errors
      _logError('Auth error: ${e.message}');
      rethrow;
    } catch (e) {
      // Handle general errors
      _logError('Unexpected error: $e');
      return fallbackValue;
    }
  }
}
```

### Offline Handling
```dart
class OfflineDataManager {
  static Future<void> cacheUserData(User user);
  static Future<User?> getCachedUserData();
  static Future<void> syncWhenOnline();
}
```

## Testing Strategy

### Unit Tests
- **AuthService Tests**: Mock Supabase responses for login/register/guest flows
- **UI Component Tests**: Test quote scrolling animation and button positioning
- **Configuration Tests**: Verify environment variable loading and fallback behavior

### Integration Tests
- **Authentication Flow**: End-to-end login/register/guest user journeys
- **Backend Integration**: Supabase connection and data persistence
- **UI Integration**: Complete login screen interaction flows

### Widget Tests
- **ScrollingQuoteWidget**: Animation timing and text transitions
- **LoginScreen Layout**: Button positioning and responsive behavior
- **Icon Display**: Custom icon loading and display verification

## Implementation Phases

### Phase 1: UI Restructuring
1. Move Guest button to top row next to Sign Up
2. Replace app icon with custom SVG asset (img_app_logo.svg) with PNG fallback
3. Implement scrolling quotes widget
4. Update text content with Islamic quotes

### Phase 2: Backend Integration
1. Add Supabase dependencies to pubspec.yaml
2. Create environment configuration system
3. Implement SupabaseService with authentication methods
4. Update AuthService to use Supabase backend

### Phase 3: Data Migration
1. Remove all hardcoded sample data
2. Implement data migration utilities
3. Update services to use persistent storage
4. Add offline caching mechanisms

### Phase 4: Configuration & Fallback
1. Create Firebase configuration file
2. Implement configuration switching logic
3. Add environment variable validation
4. Document configuration setup process

## Security Considerations

### Authentication Security
- Use Supabase Row Level Security (RLS) policies
- Implement proper session management
- Secure storage of authentication tokens
- Input validation for all user inputs

### Data Protection
- Encrypt sensitive data in local storage
- Implement proper logout cleanup
- Use secure HTTP connections only
- Validate all backend responses

## Performance Optimizations

### UI Performance
- Optimize quote scrolling animations using AnimationController
- Implement proper widget disposal to prevent memory leaks
- Use const constructors where possible
- Minimize rebuild cycles during authentication state changes

### Backend Performance
- Implement connection pooling for Supabase client
- Cache user data locally to reduce API calls
- Use pagination for large data sets
- Implement retry logic with exponential backoff

## Accessibility Features

### Screen Reader Support
- Proper semantic labels for all interactive elements
- Announce quote changes to screen readers
- Accessible button descriptions
- Focus management during authentication flows

### Visual Accessibility
- Maintain sufficient color contrast ratios
- Support system font scaling
- Provide visual feedback for all user actions
- Ensure touch targets meet minimum size requirements