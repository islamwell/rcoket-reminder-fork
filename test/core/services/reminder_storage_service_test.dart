import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/core/services/reminder_storage_service.dart';

void main() {
  group('ReminderStorageService Time Calculation Tests', () {
    late ReminderStorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = ReminderStorageService.instance;
    });

    tearDown(() async {
      await service.clearAllReminders();
    });

    test('should calculate accurate next occurrence for hourly reminders', () async {
      final now = DateTime.now();
      final reminder = await service.saveReminder(
        title: 'Hourly Test',
        category: 'test',
        frequency: {'type': 'hourly'},
        time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );

      expect(reminder['nextOccurrenceDateTime'], isNotNull);
      
      final nextDateTime = DateTime.parse(reminder['nextOccurrenceDateTime']);
      final expectedNext = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
      
      // Should be scheduled for the next hour boundary
      expect(nextDateTime.hour, equals(expectedNext.hour));
      expect(nextDateTime.minute, equals(0));
    });

    test('should format time remaining correctly for different ranges', () async {
      final now = DateTime.now();
      
      // Test "In X minutes" format - use a more precise time
      final in30Minutes = DateTime(now.year, now.month, now.day, now.hour, now.minute + 30);
      final reminder30 = await service.saveReminder(
        title: '30 Min Test',
        category: 'test',
        frequency: {'type': 'once', 'date': in30Minutes.toIso8601String().split('T')[0]},
        time: '${in30Minutes.hour.toString().padLeft(2, '0')}:${in30Minutes.minute.toString().padLeft(2, '0')}',
      );
      
      expect(reminder30['nextOccurrence'], contains('minutes'));
      
      // Test "In X hours" format
      final in3Hours = now.add(Duration(hours: 3));
      final reminder3h = await service.saveReminder(
        title: '3 Hour Test',
        category: 'test',
        frequency: {'type': 'once', 'date': in3Hours.toIso8601String().split('T')[0]},
        time: '${in3Hours.hour.toString().padLeft(2, '0')}:${in3Hours.minute.toString().padLeft(2, '0')}',
      );
      
      expect(reminder3h['nextOccurrence'], contains('hours'));
    });

    test('should include nextOccurrenceDateTime field in new reminders', () async {
      final reminder = await service.saveReminder(
        title: 'DateTime Test',
        category: 'test',
        frequency: {'type': 'daily'},
        time: '09:00',
      );

      expect(reminder['nextOccurrenceDateTime'], isNotNull);
      expect(reminder['nextOccurrenceDateTime'], isA<String>());
      
      // Should be valid ISO 8601 format
      expect(() => DateTime.parse(reminder['nextOccurrenceDateTime']), returnsNormally);
    });

    test('should calculate time remaining in minutes correctly', () async {
      final now = DateTime.now();
      final in45Minutes = now.add(Duration(minutes: 45));
      
      final reminder = await service.saveReminder(
        title: 'Time Remaining Test',
        category: 'test',
        frequency: {'type': 'once', 'date': in45Minutes.toIso8601String().split('T')[0]},
        time: '${in45Minutes.hour.toString().padLeft(2, '0')}:${in45Minutes.minute.toString().padLeft(2, '0')}',
      );

      final timeRemaining = service.getTimeRemainingInMinutes(reminder);
      
      // Should be approximately 45 minutes (allowing for small timing differences)
      expect(timeRemaining, greaterThanOrEqualTo(44));
      expect(timeRemaining, lessThanOrEqualTo(46));
    });

    test('should handle overdue reminders correctly', () async {
      final now = DateTime.now();
      final past = now.subtract(Duration(minutes: 30));
      
      final reminder = await service.saveReminder(
        title: 'Overdue Test',
        category: 'test',
        frequency: {'type': 'once', 'date': past.toIso8601String().split('T')[0]},
        time: '${past.hour.toString().padLeft(2, '0')}:${past.minute.toString().padLeft(2, '0')}',
      );

      final timeRemaining = service.getTimeRemainingInMinutes(reminder);
      expect(timeRemaining, equals(-1)); // Overdue indicator
    });

    test('should update nextOccurrenceDateTime when reminder is completed', () async {
      final reminder = await service.saveReminder(
        title: 'Completion Test',
        category: 'test',
        frequency: {
          'type': 'custom',
          'intervalValue': 1,
          'intervalUnit': 'hours'
        },
        time: '10:00',
      );

      final originalDateTime = reminder['nextOccurrenceDateTime'];
      
      // Wait a small amount to ensure time difference
      await Future.delayed(Duration(milliseconds: 10));
      
      await service.markReminderCompleted(reminder['id']);
      
      final updatedReminder = await service.getReminderById(reminder['id']);
      expect(updatedReminder!['nextOccurrenceDateTime'], isNot(equals(originalDateTime)));
      expect(updatedReminder['nextOccurrenceDateTime'], isNotNull);
    });
  });
}