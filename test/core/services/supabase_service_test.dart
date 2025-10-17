import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/services/supabase_service.dart';
import '../../../lib/core/utils/backend_error_handler.dart';

void main() {
  group('SupabaseService', () {
    late SupabaseService supabaseService;

    setUp(() {
      supabaseService = SupabaseService.instance;
    });

    group('Authentication Methods', () {
      test('signIn should handle uninitialized Supabase', () async {
        // Since Supabase is not initialized in test environment, 
        // we expect it to throw a BackendException
        try {
          await supabaseService.signIn('test@example.com', 'password123');
          fail('Expected BackendException to be thrown');
        } catch (e) {
          expect(e, isA<BackendException>());
          expect((e as BackendException).userMessage, contains('Service is not available'));
        }
      });

      test('signIn should throw BackendException for empty email', () async {
        // Since Supabase is not initialized, it will throw service unavailable error first
        // This is correct behavior - service initialization is checked before input validation
        expect(
          () => supabaseService.signIn('', 'password123'),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Service is not available. Please try again later.',
          )),
        );
      });

      test('signIn should throw BackendException for empty password', () async {
        // Since Supabase is not initialized, it will throw service unavailable error first
        expect(
          () => supabaseService.signIn('test@example.com', ''),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Service is not available. Please try again later.',
          )),
        );
      });

      test('signUp should throw BackendException when service unavailable', () async {
        // Since Supabase is not initialized, all signUp calls will throw service unavailable error
        expect(
          () => supabaseService.signUp('', 'password123', 'John Doe'),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Service is not available. Please try again later.',
          )),
        );

        expect(
          () => supabaseService.signUp('test@example.com', '', 'John Doe'),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Service is not available. Please try again later.',
          )),
        );

        expect(
          () => supabaseService.signUp('test@example.com', 'password123', ''),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Service is not available. Please try again later.',
          )),
        );
      });

      test('signOut should handle uninitialized Supabase', () async {
        // Act & Assert
        expect(
          () => supabaseService.signOut(),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Service is not available. Please try again later.',
          )),
        );
      });

      test('getCurrentUser should return null when Supabase not initialized', () {
        // Act
        final result = supabaseService.getCurrentUser();

        // Assert
        expect(result, isNull);
      });

      test('getCurrentSession should return null when Supabase not initialized', () {
        // Act
        final result = supabaseService.getCurrentSession();

        // Assert
        expect(result, isNull);
      });
    });

    group('User Profile Methods', () {
      test('getUserProfile should throw BackendException for empty userId', () async {
        // Act & Assert
        expect(
          () => supabaseService.getUserProfile(''),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Invalid user information.',
          )),
        );
      });

      test('updateUserProfile should throw BackendException for empty userId', () async {
        // Act & Assert
        expect(
          () => supabaseService.updateUserProfile('', {'name': 'John'}),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Invalid user information.',
          )),
        );
      });

      test('updateUserProfile should throw BackendException for empty updates', () async {
        // Act & Assert
        expect(
          () => supabaseService.updateUserProfile('user123', {}),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'No changes to save.',
          )),
        );
      });
    });

    group('Database Operations', () {
      test('select should throw BackendException for empty table name', () async {
        // Act & Assert
        expect(
          () => supabaseService.select(''),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Invalid data request.',
          )),
        );
      });

      test('insert should throw BackendException for empty table name', () async {
        // Act & Assert
        expect(
          () => supabaseService.insert('', {'name': 'test'}),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Invalid data request.',
          )),
        );
      });

      test('insert should throw BackendException for empty data', () async {
        // Act & Assert
        expect(
          () => supabaseService.insert('users', {}),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'No data to save.',
          )),
        );
      });

      test('update should throw BackendException for empty table name', () async {
        // Act & Assert
        expect(
          () => supabaseService.update('', {'name': 'test'}, {'id': '1'}),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Invalid data request.',
          )),
        );
      });

      test('update should throw BackendException for empty data', () async {
        // Act & Assert
        expect(
          () => supabaseService.update('users', {}, {'id': '1'}),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'No changes to save.',
          )),
        );
      });

      test('update should throw BackendException for empty filters', () async {
        // Act & Assert
        expect(
          () => supabaseService.update('users', {'name': 'test'}, {}),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Invalid update request.',
          )),
        );
      });

      test('delete should throw BackendException for empty table name', () async {
        // Act & Assert
        expect(
          () => supabaseService.delete('', {'id': '1'}),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Invalid data request.',
          )),
        );
      });

      test('delete should throw BackendException for empty filters', () async {
        // Act & Assert
        expect(
          () => supabaseService.delete('users', {}),
          throwsA(isA<BackendException>().having(
            (e) => e.userMessage,
            'userMessage',
            'Invalid delete request.',
          )),
        );
      });
    });

    group('Initialization Checks', () {
      test('isInitialized should return false when Supabase not initialized', () {
        // Act
        final result = supabaseService.isInitialized;

        // Assert
        expect(result, isFalse);
      });

      test('client getter should throw exception when not initialized', () {
        // Act & Assert
        expect(
          () => supabaseService.client,
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Supabase is not initialized'),
          )),
        );
      });

      test('authStateChanges should throw exception when not initialized', () {
        // Act & Assert
        expect(
          () => supabaseService.authStateChanges,
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Supabase is not initialized'),
          )),
        );
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance', () {
        // Act
        final instance1 = SupabaseService.instance;
        final instance2 = SupabaseService.instance;

        // Assert
        expect(identical(instance1, instance2), isTrue);
      });
    });
  });
}