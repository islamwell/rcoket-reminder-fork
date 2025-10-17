import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/services/user_preferences_service.dart';

void main() {
  group('UserPreferencesService', () {
    late UserPreferencesService service;

    setUp(() {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      service = UserPreferencesService.instance;
    });

    group('getPreferences', () {
      test('should return default preferences for new user', () async {
        // Act
        final preferences = await service.getPreferences();
        
        // Assert
        expect(preferences, isA<Map<String, dynamic>>());
        expect(preferences['notifications'], isA<Map<String, dynamic>>());
        expect(preferences['theme'], isA<Map<String, dynamic>>());
        expect(preferences['reminders'], isA<Map<String, dynamic>>());
        expect(preferences['audio'], isA<Map<String, dynamic>>());
        expect(preferences['privacy'], isA<Map<String, dynamic>>());
        
        // Check default values
        expect(preferences['notifications']['enabled'], true);
        expect(preferences['theme']['darkMode'], false);
        expect(preferences['reminders']['defaultTime'], '09:00');
        expect(preferences['audio']['defaultVolume'], 0.8);
        expect(preferences['privacy']['analyticsEnabled'], false);
      });

      test('should load preferences from local storage', () async {
        // Arrange
        final testPreferences = {
          'notifications': {'enabled': false, 'sound': true, 'vibration': false, 'showOnLockScreen': true},
          'theme': {'darkMode': true, 'accentColor': '#FF5722'},
          'reminders': {'defaultCategory': 'Work', 'defaultTime': '08:00', 'snoozeMinutes': 10},
          'audio': {'defaultVolume': 0.5, 'enableAudioReminders': false},
          'privacy': {'analyticsEnabled': true, 'crashReportingEnabled': false},
          'version': '1.0.0',
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        SharedPreferences.setMockInitialValues({
          'user_preferences': jsonEncode(testPreferences),
        });
        
        // Act
        final preferences = await service.getPreferences();
        
        // Assert
        expect(preferences['notifications']['enabled'], false);
        expect(preferences['theme']['darkMode'], true);
        expect(preferences['reminders']['defaultCategory'], 'Work');
        expect(preferences['audio']['defaultVolume'], 0.5);
      });
    });

    group('savePreferences', () {
      test('should save valid preferences locally', () async {
        // Arrange
        final validPreferences = {
          'notifications': {'enabled': true, 'sound': false, 'vibration': true, 'showOnLockScreen': false},
          'theme': {'darkMode': false, 'accentColor': '#2196F3'},
          'reminders': {'defaultCategory': 'Personal', 'defaultTime': '18:00', 'snoozeMinutes': 15},
          'audio': {'defaultVolume': 0.7, 'enableAudioReminders': true},
          'privacy': {'analyticsEnabled': false, 'crashReportingEnabled': true},
          'version': '1.0.0',
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        // Act
        await service.savePreferences(validPreferences);
        
        // Assert - verify preferences were saved locally
        final savedPreferences = await service.getPreferences();
        expect(savedPreferences['notifications']['enabled'], true);
        expect(savedPreferences['theme']['accentColor'], '#2196F3');
        expect(savedPreferences['reminders']['defaultTime'], '18:00');
      });

      test('should throw error for invalid preferences data', () async {
        // Arrange
        final invalidPreferences = {
          'notifications': {'enabled': 'not_a_boolean'}, // Invalid type
          'theme': {'darkMode': true},
          // Missing required sections
        };
        
        // Act & Assert
        expect(
          () => service.savePreferences(invalidPreferences),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('updatePreference', () {
      test('should update specific preference value', () async {
        // First get default preferences
        await service.getPreferences();
        
        // Act
        await service.updatePreference('theme', {'darkMode': true, 'accentColor': '#9C27B0'});
        
        // Assert
        final updatedPreferences = await service.getPreferences();
        expect(updatedPreferences['theme']['darkMode'], true);
        expect(updatedPreferences['theme']['accentColor'], '#9C27B0');
      });
    });

    group('getPreference', () {
      test('should return specific preference value with default fallback', () async {
        // Act
        final nonExistentValue = await service.getPreference<String>('nonexistent.key', 'default');
        
        // Assert
        expect(nonExistentValue, 'default');
      });
    });

    group('clearPreferences', () {
      test('should reset preferences to defaults', () async {
        // First set some custom preferences
        final customPreferences = {
          'notifications': {'enabled': false, 'sound': false, 'vibration': false, 'showOnLockScreen': false},
          'theme': {'darkMode': true, 'accentColor': '#FF0000'},
          'reminders': {'defaultCategory': 'Custom', 'defaultTime': '23:59', 'snoozeMinutes': 30},
          'audio': {'defaultVolume': 0.1, 'enableAudioReminders': false},
          'privacy': {'analyticsEnabled': true, 'crashReportingEnabled': false},
          'version': '1.0.0',
          'createdAt': DateTime.now().toIso8601String(),
        };
        await service.savePreferences(customPreferences);
        
        // Act
        await service.clearPreferences();
        
        // Assert
        final resetPreferences = await service.getPreferences();
        expect(resetPreferences['notifications']['enabled'], true); // Back to default
        expect(resetPreferences['theme']['darkMode'], false); // Back to default
        expect(resetPreferences['reminders']['defaultTime'], '09:00'); // Back to default
      });
    });
  });
}