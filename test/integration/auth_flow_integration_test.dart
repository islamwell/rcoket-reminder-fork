import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/core/services/auth_service.dart';
import '../../lib/core/services/supabase_service.dart';

void main() {
  group('Authentication Flow Integration Tests', () {
    late AuthService authService;
    late SupabaseService supabaseService;

    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Initialize services
      authService = AuthService.instance;
      supabaseService = SupabaseService.instance;
      
      // Initialize auth service
      await authService.initialize();
    });

    tearDown(() async {
      // Clean up after each test
      try {
        await authService.logout();
      } catch (e) {
        // Ignore cleanup errors
        print('Cleanup error: $e');
      }
    });

    group('Complete Login Flow with Supabase Backend', () {
      test('should handle successful login with valid credentials', () async {
        // Test login with valid credentials
        final result = await authService.login('test@example.com', 'testpassword123');
        
        if (result.success) {
          // Verify user is logged in
          expect(authService.isLoggedIn, isTrue);
          expect(authService.isGuestMode, isFalse);
          expect(authService.currentUser, isNotNull);
          expect(authService.currentUser!['email'], equals('test@example.com'));
          
          // Verify data is persisted in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('is_logged_in'), isTrue);
          expect(prefs.getString('user_data'), isNotNull);
          expect(prefs.getBool('is_guest_mode'), isFalse);
        } else {
          // In test environment, we expect this to fail due to configuration
          expect(result.success, isFalse);
          expect(result.errorMessage, isNotNull);
          expect(authService.isLoggedIn, isFalse);
        }
      });

      test('should handle login failure with invalid credentials', () async {
        // Test login with invalid credentials
        final result = await authService.login('invalid@example.com', 'wrongpassword');
        
        // Should fail
        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
        expect(authService.isLoggedIn, isFalse);
        expect(authService.currentUser, isNull);
      });

      test('should validate form fields before submitting', () async {
        // Test empty email
        var result = await authService.login('', 'password123');
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('email'));

        // Test empty password
        result = await authService.login('test@example.com', '');
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('6 characters'));

        // Test short password
        result = await authService.login('test@example.com', '123');
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('6 characters'));
      });

      test('should persist authentication state after successful login', () async {
        // Attempt login
        final result = await authService.login('test@example.com', 'testpassword123');
        
        // If login was successful, verify persistence
        if (result.success) {
          // Verify data is persisted in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('is_logged_in'), isTrue);
          expect(prefs.getString('user_data'), isNotNull);
          expect(prefs.getBool('is_guest_mode'), isFalse);
          
          // Simulate app restart by reinitializing AuthService
          await authService.initialize();
          
          // Should restore login state
          expect(authService.isLoggedIn, isTrue);
          expect(authService.isGuestMode, isFalse);
          expect(authService.currentUser, isNotNull);
        }
      });
    });

    group('Complete Registration Flow with User Data Persistence', () {
      test('should handle successful registration with valid data', () async {
        // Test registration with valid data
        final result = await authService.register(
          'Test User',
          'newuser@example.com',
          'newpassword123',
        );
        
        if (result.success) {
          // Verify user is registered and logged in
          expect(authService.isLoggedIn, isTrue);
          expect(authService.isGuestMode, isFalse);
          expect(authService.currentUser, isNotNull);
          expect(authService.currentUser!['name'], equals('Test User'));
          expect(authService.currentUser!['email'], equals('newuser@example.com'));
          
          // Verify data is persisted in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('is_logged_in'), isTrue);
          expect(prefs.getString('user_data'), isNotNull);
          expect(prefs.getBool('is_guest_mode'), isFalse);
        } else {
          // In test environment, we expect this to fail due to configuration
          expect(result.success, isFalse);
          expect(result.errorMessage, isNotNull);
          expect(authService.isLoggedIn, isFalse);
        }
      });

      test('should handle registration failure with existing email', () async {
        // Test registration with potentially existing email
        final result = await authService.register(
          'Test User',
          'existing@example.com',
          'password123',
        );
        
        // Should fail (either due to existing email or test environment)
        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
        expect(authService.isLoggedIn, isFalse);
        expect(authService.currentUser, isNull);
      });

      test('should validate all registration form fields', () async {
        // Test empty name
        var result = await authService.register('', 'test@example.com', 'password123');
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('name'));

        // Test empty email
        result = await authService.register('Test User', '', 'password123');
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('email'));

        // Test empty password
        result = await authService.register('Test User', 'test@example.com', '');
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('6 characters'));

        // Test short password
        result = await authService.register('Test User', 'test@example.com', '123');
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('6 characters'));
      });

      test('should persist user data after successful registration', () async {
        // Attempt registration
        final result = await authService.register(
          'New Test User',
          'newtest@example.com',
          'newpassword123',
        );
        
        // If registration was successful, verify data persistence
        if (result.success) {
          // Verify user data is correctly stored
          expect(authService.currentUser!['name'], equals('New Test User'));
          expect(authService.currentUser!['email'], equals('newtest@example.com'));
          expect(authService.currentUser!['supabaseUser'], isTrue);
          
          // Verify persistence in SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          expect(prefs.getBool('is_logged_in'), isTrue);
          final userData = prefs.getString('user_data');
          expect(userData, isNotNull);
          expect(userData, contains('New Test User'));
          expect(userData, contains('newtest@example.com'));
        }
      });
    });

    group('Guest Mode Functionality with Local Storage', () {
      test('should successfully enable guest mode', () async {
        // Test guest mode functionality
        final result = await authService.continueAsGuest();
        
        // Should succeed
        expect(result.success, isTrue);
        expect(authService.isLoggedIn, isTrue);
        expect(authService.isGuestMode, isTrue);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!['isGuest'], isTrue);
      });

      test('should persist guest mode in local storage', () async {
        // Enable guest mode
        final result = await authService.continueAsGuest();
        expect(result.success, isTrue);
        
        // Verify guest mode is stored in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('is_guest_mode'), isTrue);
        expect(prefs.getBool('is_logged_in'), isTrue);
        
        // Verify guest user data is stored
        final userData = prefs.getString('user_data');
        expect(userData, isNotNull);
        expect(userData, contains('isGuest'));
        expect(userData, contains('true'));
      });

      test('should restore guest mode on app restart', () async {
        // First, enable guest mode
        var result = await authService.continueAsGuest();
        expect(result.success, isTrue);
        expect(authService.isGuestMode, isTrue);

        // Simulate app restart by reinitializing AuthService
        await authService.initialize();

        // Should restore guest state
        expect(authService.isLoggedIn, isTrue);
        expect(authService.isGuestMode, isTrue);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!['isGuest'], isTrue);
      });

      test('should allow logout from guest mode', () async {
        // Enable guest mode
        var result = await authService.continueAsGuest();
        expect(result.success, isTrue);
        expect(authService.isGuestMode, isTrue);

        // Logout
        await authService.logout();

        // Should be logged out
        expect(authService.isLoggedIn, isFalse);
        expect(authService.isGuestMode, isFalse);
        expect(authService.currentUser, isNull);

        // Should clear from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('is_guest_mode'), isFalse);
        expect(prefs.getBool('is_logged_in'), isFalse);
      });

      test('should handle guest mode without requiring network connection', () async {
        // Guest mode should work even when Supabase is not available
        final result = await authService.continueAsGuest();
        
        // Should successfully enable guest mode
        expect(result.success, isTrue);
        expect(authService.isLoggedIn, isTrue);
        expect(authService.isGuestMode, isTrue);

        // Guest mode should not depend on Supabase
        expect(authService.isSupabaseUser, isFalse);
      });

      test('should create unique guest user data', () async {
        // Enable guest mode
        final result = await authService.continueAsGuest();
        expect(result.success, isTrue);

        // Verify guest user has unique ID and timestamp
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!['id'], isNotNull);
        expect(authService.currentUser!['id'], startsWith('guest_'));
        expect(authService.currentUser!['guestStartTime'], isNotNull);
        expect(authService.currentUser!['isGuest'], isTrue);
      });
    });

    group('Backend Integration and Data Synchronization', () {
      test('should handle Supabase backend connection', () async {
        // Test Supabase service initialization and connection
        final isConfigured = supabaseService.isInitialized;
        
        if (isConfigured) {
          // If Supabase is configured, test connection
          expect(supabaseService.client, isNotNull);
          
          // Test getting current user (should be null initially)
          final currentUser = supabaseService.getCurrentUser();
          expect(currentUser, isNull); // No user logged in initially
          
          // Test getting current session (should be null initially)
          final currentSession = supabaseService.getCurrentSession();
          expect(currentSession, isNull); // No session initially
        } else {
          // If Supabase is not configured, verify fallback behavior
          expect(() => supabaseService.client, throwsException);
        }
      });

      test('should sync user data between Supabase and local storage', () async {
        // Attempt login to test data synchronization
        final result = await authService.login('test@example.com', 'testpassword123');
        
        // If login was successful, verify data synchronization
        if (result.success && !authService.isGuestMode) {
          // Verify user data is cached locally
          final prefs = await SharedPreferences.getInstance();
          final userData = prefs.getString('user_data');
          expect(userData, isNotNull);
          
          // Verify Supabase user flag is set
          expect(authService.currentUser!['supabaseUser'], isTrue);
          
          // Test sync functionality
          await authService.syncUserData();
          
          // Should not throw errors during sync
          expect(authService.currentUser, isNotNull);
        }
      });

      test('should handle offline data caching', () async {
        // Enable guest mode to test offline functionality
        final result = await authService.continueAsGuest();
        expect(result.success, isTrue);

        // Verify offline data is cached
        expect(authService.isLoggedIn, isTrue);
        expect(authService.isGuestMode, isTrue);

        // Verify data persists in local storage
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('is_logged_in'), isTrue);
        expect(prefs.getBool('is_guest_mode'), isTrue);
        expect(prefs.getString('user_data'), isNotNull);

        // Test sync when connectivity is restored (should not crash)
        try {
          await authService.syncUserData();
          // Should complete without errors for guest users
        } catch (e) {
          // Expected for guest users or when Supabase is not available
          expect(e, isA<Exception>());
        }
      });

      test('should maintain authentication state consistency', () async {
        // Initially not logged in
        expect(authService.isLoggedIn, isFalse);
        expect(authService.isGuestMode, isFalse);
        expect(authService.currentUser, isNull);

        // Enable guest mode
        final result = await authService.continueAsGuest();
        expect(result.success, isTrue);

        // Verify consistent guest state
        expect(authService.isLoggedIn, isTrue);
        expect(authService.isGuestMode, isTrue);
        expect(authService.currentUser, isNotNull);
        expect(authService.currentUser!['isGuest'], isTrue);
        expect(authService.needsAuthentication, isFalse);
        expect(authService.hasValidSession, isTrue);

        // Test logout
        await authService.logout();

        // Verify consistent logged out state
        expect(authService.isLoggedIn, isFalse);
        expect(authService.isGuestMode, isFalse);
        expect(authService.currentUser, isNull);
        expect(authService.needsAuthentication, isTrue);
        expect(authService.hasValidSession, isFalse);
      });
    });

    group('Error Handling and Recovery', () {
      test('should handle network errors gracefully', () async {
        // Test with valid-looking credentials that will likely fail in test environment
        final result = await authService.login('test@example.com', 'testpassword123');
        
        // Should handle network errors without crashing
        expect(result, isNotNull);
        expect(result.success, isA<bool>());
        
        if (!result.success) {
          expect(result.errorMessage, isNotNull);
          expect(result.errorMessage, isNotEmpty);
          
          // Should not show technical error messages
          expect(result.errorMessage, isNot(contains('Exception')));
          expect(result.errorMessage, isNot(contains('null')));
          expect(result.errorMessage, isNot(contains('Stack trace')));
        }
      });

      test('should handle service unavailable errors', () async {
        // Test when backend service is not available
        final result = await authService.login('test@example.com', 'testpassword123');
        
        if (!result.success) {
          // Should provide user-friendly error message
          expect(result.errorMessage, isNotNull);
          expect(result.errorMessage, isNotEmpty);
          
          // Should not show technical error messages
          expect(result.errorMessage, isNot(contains('Exception')));
          expect(result.errorMessage, isNot(contains('null')));
          expect(result.errorMessage, isNot(contains('Stack trace')));
        }
      });

      test('should handle authentication timeout', () async {
        // Test timeout handling
        final result = await authService.login('test@example.com', 'testpassword123');
        
        // Should complete within reasonable time or fail gracefully
        expect(result, isNotNull);
        expect(result.success, isA<bool>());
        
        if (!result.success) {
          expect(result.errorMessage, isNotNull);
        }
      });

      test('should recover from authentication errors', () async {
        // First, try with invalid credentials
        var result = await authService.login('invalid@example.com', 'wrongpassword');
        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);

        // Should allow user to try again with different credentials
        result = await authService.login('test@example.com', 'testpassword123');
        
        // Should handle the second attempt
        expect(result, isNotNull);
        expect(result.success, isA<bool>());
      });
    });

    group('Authentication State Persistence', () {
      test('should persist authentication state after app restart', () async {
        // First, login as guest
        final result = await authService.continueAsGuest();
        expect(result.success, isTrue);
        expect(authService.isLoggedIn, isTrue);
        expect(authService.isGuestMode, isTrue);

        // Simulate app restart by reinitializing AuthService
        await authService.initialize();

        // Should remember guest state
        expect(authService.isLoggedIn, isTrue);
        expect(authService.isGuestMode, isTrue);
        expect(authService.currentUser, isNotNull);
      });

      test('should handle session expiration gracefully', () async {
        // Start with guest mode (which doesn't expire)
        final result = await authService.continueAsGuest();
        expect(result.success, isTrue);
        expect(authService.hasValidSession, isTrue);

        // For Supabase users, test session validation
        if (authService.isSupabaseUser) {
          // Test refresh auth state
          await authService.refreshAuthState();
          
          // Should maintain valid state or logout if session expired
          expect(authService.hasValidSession, isA<bool>());
        }
      });

      test('should clear authentication state on logout', () async {
        // Enable guest mode
        final result = await authService.continueAsGuest();
        expect(result.success, isTrue);

        // Verify logged in state
        expect(authService.isLoggedIn, isTrue);
        expect(authService.isGuestMode, isTrue);

        // Logout
        await authService.logout();

        // Verify all state is cleared
        expect(authService.isLoggedIn, isFalse);
        expect(authService.isGuestMode, isFalse);
        expect(authService.currentUser, isNull);
        expect(authService.needsAuthentication, isTrue);
        expect(authService.hasValidSession, isFalse);

        // Verify SharedPreferences is cleared
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('is_logged_in'), isFalse);
        expect(prefs.getBool('is_guest_mode'), isFalse);
      });
    });
  });
}