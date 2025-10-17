import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/services/reminder_storage_service.dart';

void main() {
  group('Daily Reminder Scheduling Tests', () {
    late ReminderStorageService reminderService;

    setUpAll(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      reminderService = ReminderStorageService.instance;
    });

    tearDown(() async {
      // Clean up after each test
      await reminderService.clearAllReminders();
    });

    test('should schedule daily reminder for same day if time has not passed', () async {
      final now = DateTime.now();
      final futureTime = now.add(Duration(hours: 2));
      final timeString = '${futureTime.hour.toString().padLeft(2, '0')}:${futureTime.minute.toString().padLeft(2, '0')}';

      // Create a daily reminder for 2 hours from now
      final reminder = await reminderService.saveReminder(
        title: 'Future Daily Reminder',
        category: 'test',
        frequency: {'type': 'daily'},
        time: timeString,
        enableNotifications: true,
      );

      // Verify reminder was created
      expect(reminder['id'], isNotNull);
      expect(reminder['title'], equals('Future Daily Reminder'));
      expect(reminder['status'], equals('active'));

      // Parse the next occurrence date
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime'] as String);
      
      // Should be scheduled for today (same day)
      expect(nextOccurrenceDateTime.year, equals(now.year));
      expect(nextOccurrenceDateTime.month, equals(now.month));
      expect(nextOccurrenceDateTime.day, equals(now.day));
      expect(nextOccurrenceDateTime.hour, equals(futureTime.hour));
      expect(nextOccurrenceDateTime.minute, equals(futureTime.minute));
    });

    test('should schedule daily reminder for tomorrow if time has passed', () async {
      final now = DateTime.now();
      final pastTime = now.subtract(Duration(hours: 2));
      final timeString = '${pastTime.hour.toString().padLeft(2, '0')}:${pastTime.minute.toString().padLeft(2, '0')}';

      // Create a daily reminder for 2 hours ago
      final reminder = await reminderService.saveReminder(
        title: 'Past Daily Reminder',
        category: 'test',
        frequency: {'type': 'daily'},
        time: timeString,
        enableNotifications: true,
      );

      // Verify reminder was created
      expect(reminder['id'], isNotNull);
      expect(reminder['title'], equals('Past Daily Reminder'));
      expect(reminder['status'], equals('active'));

      // Parse the next occurrence date
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime'] as String);
      final tomorrow = now.add(Duration(days: 1));
      
      // Should be scheduled for tomorrow
      expect(nextOccurrenceDateTime.year, equals(tomorrow.year));
      expect(nextOccurrenceDateTime.month, equals(tomorrow.month));
      expect(nextOccurrenceDateTime.day, equals(tomorrow.day));
      expect(nextOccurrenceDateTime.hour, equals(pastTime.hour));
      expect(nextOccurrenceDateTime.minute, equals(pastTime.minute));
    });

    test('should schedule daily reminder for tomorrow if time is within 1 minute', () async {
      final now = DateTime.now();
      final nearTime = now.add(Duration(seconds: 30)); // 30 seconds from now
      final timeString = '${nearTime.hour.toString().padLeft(2, '0')}:${nearTime.minute.toString().padLeft(2, '0')}';

      // Create a daily reminder for 30 seconds from now (within 1 minute buffer)
      final reminder = await reminderService.saveReminder(
        title: 'Near Time Daily Reminder',
        category: 'test',
        frequency: {'type': 'daily'},
        time: timeString,
        enableNotifications: true,
      );

      // Verify reminder was created
      expect(reminder['id'], isNotNull);
      expect(reminder['title'], equals('Near Time Daily Reminder'));
      expect(reminder['status'], equals('active'));

      // Parse the next occurrence date
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime'] as String);
      final tomorrow = now.add(Duration(days: 1));
      
      // Should be scheduled for tomorrow due to 1-minute buffer
      expect(nextOccurrenceDateTime.year, equals(tomorrow.year));
      expect(nextOccurrenceDateTime.month, equals(tomorrow.month));
      expect(nextOccurrenceDateTime.day, equals(tomorrow.day));
      expect(nextOccurrenceDateTime.hour, equals(nearTime.hour));
      expect(nextOccurrenceDateTime.minute, equals(nearTime.minute));
    });

    test('should schedule daily reminder for same day if time is more than 1 minute away', () async {
      final now = DateTime.now();
      final futureTime = now.add(Duration(minutes: 5)); // 5 minutes from now
      final timeString = '${futureTime.hour.toString().padLeft(2, '0')}:${futureTime.minute.toString().padLeft(2, '0')}';

      // Create a daily reminder for 5 minutes from now
      final reminder = await reminderService.saveReminder(
        title: 'Future Time Daily Reminder',
        category: 'test',
        frequency: {'type': 'daily'},
        time: timeString,
        enableNotifications: true,
      );

      // Verify reminder was created
      expect(reminder['id'], isNotNull);
      expect(reminder['title'], equals('Future Time Daily Reminder'));
      expect(reminder['status'], equals('active'));

      // Parse the next occurrence date
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime'] as String);
      
      // Should be scheduled for today (same day)
      expect(nextOccurrenceDateTime.year, equals(now.year));
      expect(nextOccurrenceDateTime.month, equals(now.month));
      expect(nextOccurrenceDateTime.day, equals(now.day));
      expect(nextOccurrenceDateTime.hour, equals(futureTime.hour));
      expect(nextOccurrenceDateTime.minute, equals(futureTime.minute));
    });
  });
}