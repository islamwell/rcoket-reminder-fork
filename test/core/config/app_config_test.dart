import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    group('Supabase Configuration', () {
      test('should have valid Supabase URL', () {
        // Act & Assert
        expect(AppConfig.supabaseUrl, isNotEmpty);
        expect(AppConfig.supabaseUrl, startsWith('https://'));
        expect(AppConfig.supabaseUrl, contains('supabase.co'));
      });

      test('should have valid Supabase anonymous key', () {
        // Act & Assert
        expect(AppConfig.supabaseAnonKey, isNotEmpty);
        expect(AppConfig.supabaseAnonKey.length, greaterThan(100)); // JWT tokens are typically long
      });

      test('isSupabaseConfigured should return true when both URL and key are present', () {
        // Act & Assert
        expect(AppConfig.isSupabaseConfigured, isTrue);
      });

      test('should have consistent configuration values', () {
        // Act & Assert
        expect(AppConfig.supabaseUrl, equals('https://jslerlyixschpaefyaft.supabase.co'));
        expect(AppConfig.supabaseAnonKey, startsWith('eyJ')); // JWT tokens start with eyJ
      });
    });

    group('Environment Detection', () {
      test('isProduction should be based on dart.vm.product', () {
        // Act
        final isProduction = AppConfig.isProduction;
        final isDebug = AppConfig.isDebug;

        // Assert
        expect(isProduction, isA<bool>());
        expect(isDebug, isA<bool>());
        expect(isProduction, equals(!isDebug)); // Should be opposite values
      });

      test('isDebug should be opposite of isProduction', () {
        // Act & Assert
        expect(AppConfig.isDebug, equals(!AppConfig.isProduction));
      });
    });

    group('App Metadata', () {
      test('should have valid app name', () {
        // Act & Assert
        expect(AppConfig.appName, equals('Good Deeds Reminder'));
        expect(AppConfig.appName, isNotEmpty);
      });

      test('should have valid app version', () {
        // Act & Assert
        expect(AppConfig.appVersion, equals('1.0.0'));
        expect(AppConfig.appVersion, matches(RegExp(r'^\d+\.\d+\.\d+$'))); // Semantic versioning pattern
      });

      test('app metadata should be consistent', () {
        // Act & Assert
        expect(AppConfig.appName, isA<String>());
        expect(AppConfig.appVersion, isA<String>());
        expect(AppConfig.appName.trim(), equals(AppConfig.appName)); // No leading/trailing whitespace
        expect(AppConfig.appVersion.trim(), equals(AppConfig.appVersion)); // No leading/trailing whitespace
      });
    });

    group('Configuration Validation', () {
      test('all configuration values should be non-null', () {
        // Act & Assert
        expect(AppConfig.supabaseUrl, isNotNull);
        expect(AppConfig.supabaseAnonKey, isNotNull);
        expect(AppConfig.appName, isNotNull);
        expect(AppConfig.appVersion, isNotNull);
      });

      test('boolean configuration values should be valid', () {
        // Act & Assert
        expect(AppConfig.isSupabaseConfigured, isNotNull);
        expect(AppConfig.isProduction, isNotNull);
        expect(AppConfig.isDebug, isNotNull);
      });

      test('configuration should be immutable', () {
        // These are const values, so they should not be modifiable
        // This test ensures the configuration is properly set up as constants
        expect(() => AppConfig.supabaseUrl, returnsNormally);
        expect(() => AppConfig.supabaseAnonKey, returnsNormally);
        expect(() => AppConfig.appName, returnsNormally);
        expect(() => AppConfig.appVersion, returnsNormally);
      });
    });

    group('Edge Cases', () {
      test('should handle configuration access multiple times', () {
        // Act - Access configuration multiple times
        final url1 = AppConfig.supabaseUrl;
        final url2 = AppConfig.supabaseUrl;
        final key1 = AppConfig.supabaseAnonKey;
        final key2 = AppConfig.supabaseAnonKey;

        // Assert - Should return same values consistently
        expect(url1, equals(url2));
        expect(key1, equals(key2));
      });

      test('isSupabaseConfigured should handle edge cases', () {
        // This test verifies the logic of isSupabaseConfigured
        // Since we can't modify const values, we test the current state
        final hasUrl = AppConfig.supabaseUrl.isNotEmpty;
        final hasKey = AppConfig.supabaseAnonKey.isNotEmpty;
        final isConfigured = AppConfig.isSupabaseConfigured;

        // Assert
        expect(isConfigured, equals(hasUrl && hasKey));
      });
    });

    group('Security Considerations', () {
      test('Supabase anonymous key should look like a valid JWT', () {
        // Act
        final anonKey = AppConfig.supabaseAnonKey;

        // Assert - Basic JWT structure validation
        expect(anonKey, startsWith('eyJ')); // JWT header
        expect(anonKey.split('.'), hasLength(3)); // JWT has 3 parts separated by dots
      });

      test('Supabase URL should use HTTPS', () {
        // Act & Assert
        expect(AppConfig.supabaseUrl, startsWith('https://'));
      });

      test('configuration should not contain obvious test values', () {
        // Act & Assert
        expect(AppConfig.supabaseUrl.toLowerCase(), isNot(contains('test')));
        expect(AppConfig.supabaseUrl.toLowerCase(), isNot(contains('localhost')));
        expect(AppConfig.supabaseUrl.toLowerCase(), isNot(contains('127.0.0.1')));
      });
    });
  });
}