import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:good_deeds_reminder/core/utils/backend_error_handler.dart';

void main() {
  group('BackendErrorHandler', () {
    late BackendErrorHandler errorHandler;

    setUp(() {
      errorHandler = BackendErrorHandler.instance;
    });

    group('handleSupabaseOperation', () {
      test('should return result on successful operation', () async {
        // Arrange
        const expectedResult = 'success';
        
        // Act
        final result = await errorHandler.handleSupabaseOperation(
          () async => expectedResult,
          'testOperation',
          enableRetry: false,
        );

        // Assert
        expect(result, equals(expectedResult));
      });

      test('should return fallback value when operation fails and fallback provided', () async {
        // Arrange
        const fallbackValue = 'fallback';
        
        // Act
        final result = await errorHandler.handleSupabaseOperation(
          () async => throw Exception('Test error'),
          'testOperation',
          enableRetry: false,
          fallbackValue: fallbackValue,
        );

        // Assert
        expect(result, equals(fallbackValue));
      });

      test('should throw BackendException when operation fails without fallback', () async {
        // Arrange & Act & Assert
        expect(
          () => errorHandler.handleSupabaseOperation(
            () async => throw Exception('Test error'),
            'testOperation',
            enableRetry: false,
          ),
          throwsA(isA<BackendException>()),
        );
      });

      test('should retry retryable operations', () async {
        // Arrange
        int attemptCount = 0;
        const expectedResult = 'success';
        
        // Act
        final result = await errorHandler.handleSupabaseOperation(
          () async {
            attemptCount++;
            if (attemptCount < 3) {
              throw AuthException('network error');
            }
            return expectedResult;
          },
          'testOperation',
          maxRetries: 3,
        );

        // Assert
        expect(result, equals(expectedResult));
        expect(attemptCount, equals(3));
      });

      test('should not retry non-retryable operations', () async {
        // Arrange
        int attemptCount = 0;
        
        // Act & Assert
        expect(
          () => errorHandler.handleSupabaseOperation(
            () async {
              attemptCount++;
              throw AuthException('invalid login credentials');
            },
            'testOperation',
            maxRetries: 3,
          ),
          throwsA(isA<BackendException>()),
        );
        
        expect(attemptCount, equals(1));
      });
    });

    group('retry behavior through handleSupabaseOperation', () {
      test('should retry network AuthException', () async {
        // Arrange
        int attemptCount = 0;
        
        // Act & Assert
        await expectLater(
          () => errorHandler.handleSupabaseOperation(
            () async {
              attemptCount++;
              throw AuthException('network error');
            },
            'testOperation',
            maxRetries: 2,
          ),
          throwsA(isA<BackendException>()),
        );
        
        expect(attemptCount, greaterThan(1)); // Should have retried
      });

      test('should not retry credential AuthException', () async {
        // Arrange
        int attemptCount = 0;
        
        // Act & Assert
        await expectLater(
          () => errorHandler.handleSupabaseOperation(
            () async {
              attemptCount++;
              throw AuthException('invalid login credentials');
            },
            'testOperation',
            maxRetries: 2,
          ),
          throwsA(isA<BackendException>()),
        );
        
        expect(attemptCount, equals(1)); // Should not have retried
      });

      test('should not retry ArgumentError', () async {
        // Arrange
        int attemptCount = 0;
        
        // Act & Assert
        await expectLater(
          () => errorHandler.handleSupabaseOperation(
            () async {
              attemptCount++;
              throw ArgumentError('Invalid argument');
            },
            'testOperation',
            maxRetries: 2,
          ),
          throwsA(isA<BackendException>()),
        );
        
        expect(attemptCount, equals(1)); // Should not have retried
      });
    });

    group('error message creation through handleSupabaseOperation', () {
      test('should create authentication BackendException for AuthException', () async {
        // Act & Assert
        await expectLater(
          () => errorHandler.handleSupabaseOperation(
            () async => throw AuthException('invalid login credentials'),
            'signIn',
            enableRetry: false,
          ),
          throwsA(
            predicate<BackendException>((e) =>
              e.errorType == BackendErrorType.authentication &&
              e.userMessage.contains('Invalid email or password') &&
              !e.isRetryable
            ),
          ),
        );
      });

      test('should create validation BackendException for weak password', () async {
        // Act & Assert
        await expectLater(
          () => errorHandler.handleSupabaseOperation(
            () async => throw AuthException('weak password'),
            'signUp',
            enableRetry: false,
          ),
          throwsA(
            predicate<BackendException>((e) =>
              e.errorType == BackendErrorType.validation &&
              e.userMessage.contains('Password is too weak') &&
              !e.isRetryable
            ),
          ),
        );
      });

      test('should create database BackendException for PostgrestException', () async {
        // Act & Assert
        await expectLater(
          () => errorHandler.handleSupabaseOperation(
            () async => throw PostgrestException(
              message: 'duplicate key value violates unique constraint',
              code: '23505',
            ),
            'insert',
            enableRetry: false,
          ),
          throwsA(
            predicate<BackendException>((e) =>
              e.errorType == BackendErrorType.validation &&
              e.userMessage.contains('already exists') &&
              !e.isRetryable
            ),
          ),
        );
      });

      test('should create network BackendException for timeout', () async {
        // Act & Assert
        await expectLater(
          () => errorHandler.handleSupabaseOperation(
            () async => throw TimeoutException('Operation timed out', Duration(seconds: 30)),
            'operation',
            enableRetry: false,
          ),
          throwsA(
            predicate<BackendException>((e) =>
              e.errorType == BackendErrorType.timeout &&
              e.userMessage.contains('timed out') &&
              e.isRetryable
            ),
          ),
        );
      });
    });

    group('getUserFriendlyMessage', () {
      test('should return user-friendly message for AuthException', () {
        // Arrange
        final error = AuthException('invalid login credentials');
        
        // Act
        final message = BackendErrorHandler.getUserFriendlyMessage(error);
        
        // Assert
        expect(message, contains('Invalid email or password'));
      });

      test('should return user-friendly message for PostgrestException', () {
        // Arrange
        final error = PostgrestException(
          message: 'duplicate key value',
          code: '23505',
        );
        
        // Act
        final message = BackendErrorHandler.getUserFriendlyMessage(error);
        
        // Assert
        expect(message, contains('already exists'));
      });

      test('should return generic message for unknown error', () {
        // Arrange
        final error = Exception('Unknown error');
        
        // Act
        final message = BackendErrorHandler.getUserFriendlyMessage(error);
        
        // Assert
        expect(message, equals('An unexpected error occurred. Please try again.'));
      });
    });

    group('isRetryable', () {
      test('should return true for retryable BackendException', () {
        // Arrange
        final error = BackendException(
          originalError: Exception('test'),
          operationName: 'test',
          errorType: BackendErrorType.network,
          userMessage: 'Network error',
          technicalMessage: 'Network error',
          isRetryable: true,
        );
        
        // Act
        final retryable = BackendErrorHandler.isRetryable(error);
        
        // Assert
        expect(retryable, isTrue);
      });

      test('should return false for non-retryable BackendException', () {
        // Arrange
        final error = BackendException(
          originalError: Exception('test'),
          operationName: 'test',
          errorType: BackendErrorType.authentication,
          userMessage: 'Auth error',
          technicalMessage: 'Auth error',
          isRetryable: false,
        );
        
        // Act
        final retryable = BackendErrorHandler.isRetryable(error);
        
        // Assert
        expect(retryable, isFalse);
      });
    });
  });

  group('BackendException', () {
    test('should create BackendException with all properties', () {
      // Arrange
      final originalError = Exception('Original error');
      const operationName = 'testOperation';
      const errorType = BackendErrorType.authentication;
      const userMessage = 'User friendly message';
      const technicalMessage = 'Technical message';
      const isRetryable = false;

      // Act
      final exception = BackendException(
        originalError: originalError,
        operationName: operationName,
        errorType: errorType,
        userMessage: userMessage,
        technicalMessage: technicalMessage,
        isRetryable: isRetryable,
      );

      // Assert
      expect(exception.originalError, equals(originalError));
      expect(exception.operationName, equals(operationName));
      expect(exception.errorType, equals(errorType));
      expect(exception.userMessage, equals(userMessage));
      expect(exception.technicalMessage, equals(technicalMessage));
      expect(exception.isRetryable, equals(isRetryable));
    });

    test('should have meaningful toString', () {
      // Arrange
      final exception = BackendException(
        originalError: Exception('test'),
        operationName: 'signIn',
        errorType: BackendErrorType.authentication,
        userMessage: 'Invalid credentials',
        technicalMessage: 'Auth failed',
        isRetryable: false,
      );

      // Act
      final string = exception.toString();

      // Assert
      expect(string, contains('BackendException'));
      expect(string, contains('Invalid credentials'));
      expect(string, contains('signIn'));
      expect(string, contains('authentication'));
    });
  });
}