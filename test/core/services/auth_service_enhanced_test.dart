import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:good_deeds_reminder/core/services/auth_service.dart';

void main() {
  group('AuthService Enhanced Error Handling', () {
    late AuthService authService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      authService = AuthService.instance;
    });

    group('AuthResult', () {
      test('should create successful AuthResult', () {
        // Arrange & Act
        final result = AuthResult(success: true);

        // Assert
        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
        expect(result.errorType, isNull);
        expect(result.isRetryable, isFalse);
      });

      test('should create failed AuthResult with error details', () {
        // Arrange & Act
        final result = AuthResult(
          success: false,
          errorMessage: 'Invalid credentials',
          errorType: AuthErrorType.authentication,
          isRetryable: false,
        );

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, equals('Invalid credentials'));
        expect(result.errorType, equals(AuthErrorType.authentication));
        expect(result.isRetryable, isFalse);
      });

      test('should have meaningful toString', () {
        // Arrange
        final result = AuthResult(
          success: false,
          errorMessage: 'Network error',
          errorType: AuthErrorType.network,
          isRetryable: true,
        );

        // Act
        final string = result.toString();

        // Assert
        expect(string, contains('AuthResult'));
        expect(string, contains('success: false'));
        expect(string, contains('Network error'));
        expect(string, contains('network'));
        expect(string, contains('isRetryable: true'));
      });
    });

    group('login validation', () {
      test('should return validation error for empty email', () async {
        // Act
        final result = await authService.login('', 'password123');

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('email'));
        expect(result.errorType, equals(AuthErrorType.validation));
        expect(result.isRetryable, isFalse);
      });

      test('should return validation error for short password', () async {
        // Act
        final result = await authService.login('test@example.com', '123');

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('6 characters'));
        expect(result.errorType, equals(AuthErrorType.validation));
        expect(result.isRetryable, isFalse);
      });
    });

    group('register validation', () {
      test('should return validation error for empty name', () async {
        // Act
        final result = await authService.register('', 'test@example.com', 'password123');

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('name'));
        expect(result.errorType, equals(AuthErrorType.validation));
        expect(result.isRetryable, isFalse);
      });

      test('should return validation error for empty email', () async {
        // Act
        final result = await authService.register('John Doe', '', 'password123');

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('email'));
        expect(result.errorType, equals(AuthErrorType.validation));
        expect(result.isRetryable, isFalse);
      });

      test('should return validation error for short password', () async {
        // Act
        final result = await authService.register('John Doe', 'test@example.com', '123');

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('6 characters'));
        expect(result.errorType, equals(AuthErrorType.validation));
        expect(result.isRetryable, isFalse);
      });
    });

    group('continueAsGuest', () {
      test('should return successful result', () async {
        // Act
        final result = await authService.continueAsGuest();

        // Assert
        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
        expect(authService.isGuestMode, isTrue);
        expect(authService.isLoggedIn, isTrue);
      });
    });
  });

  group('AuthErrorType', () {
    test('should have all expected error types', () {
      // Assert
      expect(AuthErrorType.values, contains(AuthErrorType.validation));
      expect(AuthErrorType.values, contains(AuthErrorType.authentication));
      expect(AuthErrorType.values, contains(AuthErrorType.network));
      expect(AuthErrorType.values, contains(AuthErrorType.service));
      expect(AuthErrorType.values, contains(AuthErrorType.unknown));
    });
  });
}