import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../lib/core/services/auth_service.dart';
import '../../../lib/core/services/supabase_service.dart';

void main() {
  group('AuthService Integration Tests', () {
    late AuthService authService;

    setUp(() async {
      // Initialize SharedPreferences with mock
      SharedPreferences.setMockInitialValues({});
      
      // Get AuthService instance
      authService = AuthService.instance;
      
      // Initialize the service
      await authService.initialize();
    });

    tearDown(() async {
      // Clean up after each test
      await authService.logout();
    });

    group('Guest Mode', () {
      test('should allow continuing as guest', () async {
        // Act
        await authService.continueAsGuest();

        // Assert
        expect(authService.isLoggedIn, true);
        expect(authService.isGuestMode, true);
        expect(authService.userName, 'Guest User');
        expect(authService.userEmail, 'guest@example.com');
        expect(authService.needsAuthentication, false);
      });

      test('should maintain guest mode after initialization', () async {
        // Arrange
        await authService.continueAsGuest();
        
        // Act - reinitialize to simulate app restart
        await authService.initialize();

        // Assert
        expect(authService.isLoggedIn, true);
        expect(authService.isGuestMode, true);
        expect(authService.userName, 'Guest User');
      });
    });

    group('Local Authentication Fallback', () {
      test('should login with valid credentials using fallback', () async {
        // Act
        final result = await authService.login('test@example.com', 'password123');

        // Assert
        expect(result, true);
        expect(authService.isLoggedIn, true);
        expect(authService.isGuestMode, false);
        expect(authService.userEmail, 'test@example.com');
        expect(authService.isSupabaseUser, false);
      });

      test('should register new user using fallback', () async {
        // Act
        final result = await authService.register('Test User', 'test@example.com', 'password123');

        // Assert
        expect(result, true);
        expect(authService.isLoggedIn, true);
        expect(authService.isGuestMode, false);
        expect(authService.userName, 'Test User');
        expect(authService.userEmail, 'test@example.com');
        expect(authService.isSupabaseUser, false);
      });

      test('should reject invalid login credentials', () async {
        // Act
        final result = await authService.login('invalid@example.com', '123');

        // Assert
        expect(result, false);
        expect(authService.isLoggedIn, false);
        expect(authService.needsAuthentication, true);
      });

      test('should reject invalid registration data', () async {
        // Act
        final result = await authService.register('', 'invalid-email', '123');

        // Assert
        expect(result, false);
        expect(authService.isLoggedIn, false);
        expect(authService.needsAuthentication, true);
      });
    });

    group('Profile Management', () {
      test('should update user profile locally', () async {
        // Arrange
        await authService.login('test@example.com', 'password123');

        // Act
        final result = await authService.updateProfile('Updated Name', 'updated@example.com');

        // Assert
        expect(result, true);
        expect(authService.userName, 'Updated Name');
        expect(authService.userEmail, 'updated@example.com');
      });

      test('should not update profile when not logged in', () async {
        // Act
        final result = await authService.updateProfile('Test Name', 'test@example.com');

        // Assert
        expect(result, false);
      });
    });

    group('Session Management', () {
      test('should logout and clear all data', () async {
        // Arrange
        await authService.login('test@example.com', 'password123');
        expect(authService.isLoggedIn, true);

        // Act
        await authService.logout();

        // Assert
        expect(authService.isLoggedIn, false);
        expect(authService.isGuestMode, false);
        expect(authService.currentUser, null);
        expect(authService.needsAuthentication, true);
      });

      test('should have valid session for local users', () async {
        // Arrange
        await authService.login('test@example.com', 'password123');

        // Act & Assert
        expect(authService.hasValidSession, true);
      });

      test('should have valid session for guest users', () async {
        // Arrange
        await authService.continueAsGuest();

        // Act & Assert
        expect(authService.hasValidSession, true);
      });
    });

    group('Data Persistence', () {
      test('should persist login state across initialization', () async {
        // Arrange
        await authService.login('test@example.com', 'password123');
        final originalUserName = authService.userName;

        // Act - simulate app restart
        await authService.initialize();

        // Assert
        expect(authService.isLoggedIn, true);
        expect(authService.userName, originalUserName);
        expect(authService.userEmail, 'test@example.com');
      });

      test('should persist guest state across initialization', () async {
        // Arrange
        await authService.continueAsGuest();

        // Act - simulate app restart
        await authService.initialize();

        // Assert
        expect(authService.isLoggedIn, true);
        expect(authService.isGuestMode, true);
        expect(authService.userName, 'Guest User');
      });
    });

    group('Helper Methods', () {
      test('should identify non-Supabase users correctly', () async {
        // Arrange
        await authService.login('test@example.com', 'password123');

        // Act & Assert
        expect(authService.isSupabaseUser, false);
        expect(authService.supabaseUser, null);
      });

      test('should refresh auth state for local users', () async {
        // Arrange
        await authService.login('test@example.com', 'password123');

        // Act
        await authService.refreshAuthState();

        // Assert - should remain logged in for local users
        expect(authService.isLoggedIn, true);
      });
    });
  });
}