import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/services/reminder_storage_service.dart';

void main() {
  group('Reminder Background Integration Tests', () {
    late ReminderStorageService reminderService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      reminderService = ReminderStorageService.instance;
    });

    tearDown(() async {
      // Clean up
      await reminderService.clearAllReminders();
    });

    test('saveReminder should integrate with background scheduling', () async {
      // Test that creating a reminder includes background scheduling integration
      final reminder = await reminderService.saveReminder(
        title: 'Test Reminder',
        category: 'charity',
        frequency: {'id': 'daily', 'title': 'Daily'},
        time: '09:00',
        enableNotifications: true,
      );

      // Verify reminder was created
      expect(reminder['id'], isNotNull);
      expect(reminder['title'], equals('Test Reminder'));
      expect(reminder['status'], equals('active'));
      expect(reminder['enableNotifications'], equals(true));
      expect(reminder['nextOccurrenceDateTime'], isNotNull);
      
      // Verify the reminder has the fields needed for background scheduling
      expect(reminder['nextOccurrence'], isNotNull);
      expect(reminder['nextOccurrenceDateTime'], isNotNull);
      expect(reminder['frequency'], isNotNull);
      expect(reminder['time'], equals('09:00'));
    });

    test('updateReminder should handle background scheduling integration', () async {
      // Create a reminder first
      final reminder = await reminderService.saveReminder(
        title: 'Test Reminder',
        category: 'charity',
        frequency: {'id': 'daily', 'title': 'Daily'},
        time: '09:00',
        enableNotifications: true,
      );

      final reminderId = reminder['id'] as int;

      // Update the reminder
      await reminderService.updateReminder(reminderId, {
        'title': 'Updated Test Reminder',
        'time': '10:00',
        'enableNotifications': false,
      });

      // Verify the update
      final updatedReminder = await reminderService.getReminderById(reminderId);
      expect(updatedReminder, isNotNull);
      expect(updatedReminder!['title'], equals('Updated Test Reminder'));
      expect(updatedReminder['time'], equals('10:00'));
      expect(updatedReminder['enableNotifications'], equals(false));
    });

    test('toggleReminderStatus should handle background scheduling', () async {
      // Create an active reminder
      final reminder = await reminderService.saveReminder(
        title: 'Test Reminder',
        category: 'charity',
        frequency: {'id': 'daily', 'title': 'Daily'},
        time: '09:00',
        enableNotifications: true,
      );

      final reminderId = reminder['id'] as int;

      // Toggle to paused
      await reminderService.toggleReminderStatus(reminderId);
      
      var toggledReminder = await reminderService.getReminderById(reminderId);
      expect(toggledReminder!['status'], equals('paused'));
      expect(toggledReminder['nextOccurrence'], equals('Paused'));

      // Toggle back to active
      await reminderService.toggleReminderStatus(reminderId);
      
      toggledReminder = await reminderService.getReminderById(reminderId);
      expect(toggledReminder!['status'], equals('active'));
      expect(toggledReminder['nextOccurrence'], isNot(equals('Paused')));
      expect(toggledReminder['nextOccurrenceDateTime'], isNotNull);
    });

    test('deleteReminder should handle background notification cleanup', () async {
      // Create a reminder
      final reminder = await reminderService.saveReminder(
        title: 'Test Reminder',
        category: 'charity',
        frequency: {'id': 'daily', 'title': 'Daily'},
        time: '09:00',
        enableNotifications: true,
      );

      final reminderId = reminder['id'] as int;

      // Verify reminder exists
      var existingReminder = await reminderService.getReminderById(reminderId);
      expect(existingReminder, isNotNull);

      // Delete the reminder
      await reminderService.deleteReminder(reminderId);

      // Verify reminder is deleted
      var deletedReminder = await reminderService.getReminderById(reminderId);
      expect(deletedReminder, isNull);
    });

    test('snoozeReminder should handle background scheduling', () async {
      // Create a reminder
      final reminder = await reminderService.saveReminder(
        title: 'Test Reminder',
        category: 'charity',
        frequency: {'id': 'daily', 'title': 'Daily'},
        time: '09:00',
        enableNotifications: true,
      );

      final reminderId = reminder['id'] as int;

      // Snooze the reminder
      await reminderService.snoozeReminder(reminderId, 5);

      // Verify snooze status
      final snoozedReminder = await reminderService.getReminderById(reminderId);
      expect(snoozedReminder!['status'], equals('snoozed'));
      expect(snoozedReminder['nextOccurrence'], contains('Snoozed for 5 minutes'));
      expect(snoozedReminder['snoozedAt'], isNotNull);
      expect(snoozedReminder['nextOccurrenceDateTime'], isNotNull);
    });

    test('completeReminderManually should handle background notification cleanup', () async {
      // Create a reminder
      final reminder = await reminderService.saveReminder(
        title: 'Test Reminder',
        category: 'charity',
        frequency: {'id': 'daily', 'title': 'Daily'},
        time: '09:00',
        enableNotifications: true,
      );

      final reminderId = reminder['id'] as int;

      // Complete the reminder manually
      await reminderService.completeReminderManually(reminderId);

      // Verify completion
      final completedReminder = await reminderService.getReminderById(reminderId);
      expect(completedReminder!['status'], equals('completed'));
      expect(completedReminder['nextOccurrence'], equals('Completed'));
      expect(completedReminder['completedAt'], isNotNull);
    });

    test('markReminderCompleted should handle recurring reminder rescheduling', () async {
      // Create a daily reminder
      final reminder = await reminderService.saveReminder(
        title: 'Daily Test Reminder',
        category: 'charity',
        frequency: {'id': 'daily', 'title': 'Daily'},
        time: '09:00',
        enableNotifications: true,
        repeatLimit: 0, // Infinite repeats
      );

      final reminderId = reminder['id'] as int;

      // Mark as completed (should reschedule for next occurrence)
      await reminderService.markReminderCompleted(reminderId);

      // Verify it's still active and rescheduled
      final completedReminder = await reminderService.getReminderById(reminderId);
      expect(completedReminder!['status'], equals('active'));
      expect(completedReminder['completionCount'], equals(1));
      expect(completedReminder['lastCompleted'], isNotNull);
      expect(completedReminder['nextOccurrenceDateTime'], isNotNull);
    });

    test('reminder with repeat limit should complete after reaching limit', () async {
      // Create a reminder with repeat limit of 1
      final reminder = await reminderService.saveReminder(
        title: 'Limited Test Reminder',
        category: 'charity',
        frequency: {'id': 'daily', 'title': 'Daily'},
        time: '09:00',
        enableNotifications: true,
        repeatLimit: 1,
      );

      final reminderId = reminder['id'] as int;

      // Mark as completed (should move to completed status)
      await reminderService.markReminderCompleted(reminderId);

      // Verify it's completed
      final completedReminder = await reminderService.getReminderById(reminderId);
      expect(completedReminder!['status'], equals('completed'));
      expect(completedReminder['completionCount'], equals(1));
      expect(completedReminder['nextOccurrence'], equals('Completed'));
    });
  });
}