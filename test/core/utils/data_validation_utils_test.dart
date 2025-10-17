import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/utils/data_validation_utils.dart';

void main() {
  group('DataValidationUtils', () {
    group('isValidEmail', () {
      test('should validate correct email formats', () {
        expect(DataValidationUtils.isValidEmail('test@example.com'), true);
        expect(DataValidationUtils.isValidEmail('user.name@domain.co.uk'), true);
        expect(DataValidationUtils.isValidEmail('user+tag@example.org'), true);
      });

      test('should reject invalid email formats', () {
        expect(DataValidationUtils.isValidEmail(''), false);
        expect(DataValidationUtils.isValidEmail('invalid-email'), false);
        expect(DataValidationUtils.isValidEmail('@example.com'), false);
        expect(DataValidationUtils.isValidEmail('test@'), false);
        expect(DataValidationUtils.isValidEmail('test@.com'), false);
      });
    });

    group('isValidPassword', () {
      test('should validate strong passwords', () {
        expect(DataValidationUtils.isValidPassword('password123'), true);
        expect(DataValidationUtils.isValidPassword('MyPass1'), true);
        expect(DataValidationUtils.isValidPassword('abc123def'), true);
      });

      test('should reject weak passwords', () {
        expect(DataValidationUtils.isValidPassword(''), false);
        expect(DataValidationUtils.isValidPassword('12345'), false); // Too short
        expect(DataValidationUtils.isValidPassword('password'), false); // No numbers
        expect(DataValidationUtils.isValidPassword('123456'), false); // No letters
      });
    });

    group('isValidTimeFormat', () {
      test('should validate correct time formats', () {
        expect(DataValidationUtils.isValidTimeFormat('09:30'), true);
        expect(DataValidationUtils.isValidTimeFormat('23:59'), true);
        expect(DataValidationUtils.isValidTimeFormat('00:00'), true);
        expect(DataValidationUtils.isValidTimeFormat('12:00'), true);
      });

      test('should reject invalid time formats', () {
        expect(DataValidationUtils.isValidTimeFormat(''), false);
        expect(DataValidationUtils.isValidTimeFormat('25:00'), false); // Invalid hour
        expect(DataValidationUtils.isValidTimeFormat('12:60'), false); // Invalid minute
        expect(DataValidationUtils.isValidTimeFormat('9:30'), true); // Single digit hour is valid
        expect(DataValidationUtils.isValidTimeFormat('12:5'), false); // Single digit minute
      });
    });

    group('isValidHexColor', () {
      test('should validate correct hex color formats', () {
        expect(DataValidationUtils.isValidHexColor('#FF0000'), true);
        expect(DataValidationUtils.isValidHexColor('#00ff00'), true);
        expect(DataValidationUtils.isValidHexColor('#ABC'), true);
        expect(DataValidationUtils.isValidHexColor('#123456'), true);
      });

      test('should reject invalid hex color formats', () {
        expect(DataValidationUtils.isValidHexColor(''), false);
        expect(DataValidationUtils.isValidHexColor('FF0000'), false); // Missing #
        expect(DataValidationUtils.isValidHexColor('#GG0000'), false); // Invalid characters
        expect(DataValidationUtils.isValidHexColor('#12'), false); // Too short
        expect(DataValidationUtils.isValidHexColor('#1234567'), false); // Too long
      });
    });

    group('isValidReminderFrequency', () {
      test('should validate daily frequency', () {
        final frequency = {'type': 'daily'};
        expect(DataValidationUtils.isValidReminderFrequency(frequency), true);
      });

      test('should validate weekly frequency with selected days', () {
        final frequency = {
          'type': 'weekly',
          'selectedDays': [1, 3, 5] // Monday, Wednesday, Friday
        };
        expect(DataValidationUtils.isValidReminderFrequency(frequency), true);
      });

      test('should reject weekly frequency without selected days', () {
        final frequency = {'type': 'weekly'};
        expect(DataValidationUtils.isValidReminderFrequency(frequency), false);
      });

      test('should validate monthly frequency', () {
        final frequency = {
          'type': 'monthly',
          'dayOfMonth': 15
        };
        expect(DataValidationUtils.isValidReminderFrequency(frequency), true);
      });

      test('should reject monthly frequency with invalid day', () {
        final frequency = {
          'type': 'monthly',
          'dayOfMonth': 32 // Invalid day
        };
        expect(DataValidationUtils.isValidReminderFrequency(frequency), false);
      });

      test('should validate custom frequency', () {
        final frequency = {
          'type': 'custom',
          'interval': 2,
          'unit': 'hours'
        };
        expect(DataValidationUtils.isValidReminderFrequency(frequency), true);
      });

      test('should reject custom frequency with invalid interval', () {
        final frequency = {
          'type': 'custom',
          'interval': 0, // Invalid interval
          'unit': 'hours'
        };
        expect(DataValidationUtils.isValidReminderFrequency(frequency), false);
      });

      test('should validate once frequency with valid date', () {
        final tomorrow = DateTime.now().add(Duration(days: 1));
        final frequency = {
          'type': 'once',
          'date': tomorrow.toIso8601String()
        };
        expect(DataValidationUtils.isValidReminderFrequency(frequency), true);
      });
    });

    group('isValidUserPreferences', () {
      test('should validate complete valid preferences', () {
        final preferences = {
          'notifications': {
            'enabled': true,
            'sound': true,
            'vibration': false,
            'showOnLockScreen': true
          },
          'theme': {
            'darkMode': false,
            'accentColor': '#2196F3'
          },
          'reminders': {
            'defaultCategory': 'General',
            'defaultTime': '09:00',
            'snoozeMinutes': 5
          },
          'audio': {
            'defaultVolume': 0.8,
            'enableAudioReminders': true
          },
          'privacy': {
            'analyticsEnabled': false,
            'crashReportingEnabled': true
          }
        };
        expect(DataValidationUtils.isValidUserPreferences(preferences), true);
      });

      test('should reject preferences missing required sections', () {
        final preferences = {
          'notifications': {
            'enabled': true,
            'sound': true,
            'vibration': false,
            'showOnLockScreen': true
          },
          // Missing other required sections
        };
        expect(DataValidationUtils.isValidUserPreferences(preferences), false);
      });

      test('should reject preferences with invalid color', () {
        final preferences = {
          'notifications': {
            'enabled': true,
            'sound': true,
            'vibration': false,
            'showOnLockScreen': true
          },
          'theme': {
            'darkMode': false,
            'accentColor': 'invalid-color' // Invalid hex color
          },
          'reminders': {
            'defaultCategory': 'General',
            'defaultTime': '09:00',
            'snoozeMinutes': 5
          },
          'audio': {
            'defaultVolume': 0.8,
            'enableAudioReminders': true
          },
          'privacy': {
            'analyticsEnabled': false,
            'crashReportingEnabled': true
          }
        };
        expect(DataValidationUtils.isValidUserPreferences(preferences), false);
      });

      test('should reject preferences with invalid time format', () {
        final preferences = {
          'notifications': {
            'enabled': true,
            'sound': true,
            'vibration': false,
            'showOnLockScreen': true
          },
          'theme': {
            'darkMode': false,
            'accentColor': '#2196F3'
          },
          'reminders': {
            'defaultCategory': 'General',
            'defaultTime': '25:00', // Invalid time
            'snoozeMinutes': 5
          },
          'audio': {
            'defaultVolume': 0.8,
            'enableAudioReminders': true
          },
          'privacy': {
            'analyticsEnabled': false,
            'crashReportingEnabled': true
          }
        };
        expect(DataValidationUtils.isValidUserPreferences(preferences), false);
      });
    });

    group('isValidNumericRange', () {
      test('should validate numbers within range', () {
        expect(DataValidationUtils.isValidNumericRange(5, min: 0, max: 10), true);
        expect(DataValidationUtils.isValidNumericRange(0.5, min: 0.0, max: 1.0), true);
        expect(DataValidationUtils.isValidNumericRange(10, min: 10, max: 10), true);
      });

      test('should reject numbers outside range', () {
        expect(DataValidationUtils.isValidNumericRange(-1, min: 0, max: 10), false);
        expect(DataValidationUtils.isValidNumericRange(11, min: 0, max: 10), false);
        expect(DataValidationUtils.isValidNumericRange(1.5, min: 0.0, max: 1.0), false);
      });

      test('should reject null values', () {
        expect(DataValidationUtils.isValidNumericRange(null, min: 0, max: 10), false);
      });
    });

    group('hasRequiredKeys', () {
      test('should validate map with all required keys', () {
        final data = {'name': 'John', 'email': 'john@example.com', 'age': 30};
        final requiredKeys = ['name', 'email'];
        expect(DataValidationUtils.hasRequiredKeys(data, requiredKeys), true);
      });

      test('should reject map missing required keys', () {
        final data = {'name': 'John', 'age': 30};
        final requiredKeys = ['name', 'email'];
        expect(DataValidationUtils.hasRequiredKeys(data, requiredKeys), false);
      });

      test('should reject map with null values for required keys', () {
        final data = {'name': 'John', 'email': null};
        final requiredKeys = ['name', 'email'];
        expect(DataValidationUtils.hasRequiredKeys(data, requiredKeys), false);
      });
    });
  });
}