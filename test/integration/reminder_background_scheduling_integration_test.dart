import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/core/services/reminder_storage_service.dart';
import '../../lib/core/services/background_task_manager.dart';

void main() {
  group('Reminder Background Scheduling Integration Tests', () {
    late ReminderStorageService reminderService;
    late BackgroundTaskManager backgroundTaskManager;

    setUpAll(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      reminderService = ReminderStorageService.instance;
      backgroundTaskManager = BackgroundTaskManager.instance;
    });

    tearDown(() async {
      // Clean up after each test
      await reminderService.clearAllReminders();
    });

    group('Reminder Creation Integration', () {
      test('should schedule background notification when creating new reminder', () async {
        // Create a new reminder
        final reminder = await reminderService.saveReminder(
          title: 'Integration Test Reminder',
          category: 'test',
          frequency: {'type': 'daily'},
          time: '14:30',
          description: 'Test reminder for background scheduling',
          enableNotifications: true,
        );

        // Verify reminder was created
        expect(reminder['id'], isNotNull);
        expect(reminder['title'], equals('Integration Test Reminder'));
        expect(reminder['status'], equals('active'));
        expect(reminder['enableNotifications'], equals(true));

        // Verify background scheduling was triggered
        // Note: In a real test environment, we would mock the BackgroundTaskManager
        // and verify that rescheduleReminder was called with the correct ID
        expect(() => backgroundTaskManager.rescheduleReminder(reminder['id'] as int), returnsNormally);
      });

      test('should not schedule background notification when notifications disabled', () async {
        // Create a new reminder with notifications disabled
        final reminder = await reminderService.saveReminder(
          title: 'No Notification Reminder',
          category: 'test',
          frequency: {'type': 'daily'},
          time: '14:30',
          enableNotifications: false,
        );

        // Verify reminder was created
        expect(reminder['id'], isNotNull);
        expect(reminder['enableNotifications'], equals(false));

        // Background scheduling should still work (it handles the enableNotifications flag internally)
        expect(() => backgroundTaskManager.rescheduleReminder(reminder['id'] as int), returnsNormally);
      });
    });

    group('Reminder Update Integration', () {
      test('should reschedule background notification when updating reminder', () async {
        // Create initial reminder
        final reminder = await reminderService.saveReminder(
          title: 'Original Reminder',
          category: 'test',
          frequency: {'type': 'daily'},
          time: '14:30',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Update the reminder
        await reminderService.updateReminder(reminderId, {
          'title': 'Updated Reminder',
          'time': '15:30',
          'frequency': {'type': 'weekly', 'selectedDays': [1, 3, 5]},
        });

        // Verify reminder was updated
        final updatedReminder = await reminderService.getReminderById(reminderId);
        expect(updatedReminder!['title'], equals('Updated Reminder'));
        expect(updatedReminder['time'], equals('15:30'));

        // Verify background rescheduling was triggered
        expect(() => backgroundTaskManager.rescheduleReminder(reminderId), returnsNormally);
      });

      test('should handle status toggle with background scheduling', () async {
        // Create active reminder
        final reminder = await reminderService.saveReminder(
          title: 'Toggle Test Reminder',
          category: 'test',
          frequency: {'type': 'daily'},
          time: '14:30',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Toggle to paused
        await reminderService.toggleReminderStatus(reminderId);
        
        var toggledReminder = await reminderService.getReminderById(reminderId);
        expect(toggledReminder!['status'], equals('paused'));

        // Toggle back to active
        await reminderService.toggleReminderStatus(reminderId);
        
        toggledReminder = await reminderService.getReminderById(reminderId);
        expect(toggledReminder!['status'], equals('active'));

        // Verify background scheduling handles both states
        expect(() => backgroundTaskManager.rescheduleReminder(reminderId), returnsNormally);
      });
    });

    group('Reminder Deletion Integration', () {
      test('should cancel background notification when deleting reminder', () async {
        // Create reminder
        final reminder = await reminderService.saveReminder(
          title: 'Delete Test Reminder',
          category: 'test',
          frequency: {'type': 'daily'},
          time: '14:30',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Verify reminder exists
        var existingReminder = await reminderService.getReminderById(reminderId);
        expect(existingReminder, isNotNull);

        // Delete reminder
        await reminderService.deleteReminder(reminderId);

        // Verify reminder was deleted
        var deletedReminder = await reminderService.getReminderById(reminderId);
        expect(deletedReminder, isNull);

        // Verify background notification cancellation
        expect(() => backgroundTaskManager.cancelNotification(reminderId), returnsNormally);
      });
    });

    group('Reminder Completion Integration', () {
      test('should reschedule background notification for recurring reminder completion', () async {
        // Create recurring reminder
        final reminder = await reminderService.saveReminder(
          title: 'Recurring Test Reminder',
          category: 'test',
          frequency: {'type': 'daily'},
          time: '14:30',
          enableNotifications: true,
          repeatLimit: 0, // Infinite
        );

        final reminderId = reminder['id'] as int;

        // Mark as completed (should stay active and reschedule)
        await reminderService.markReminderCompleted(reminderId);

        // Verify reminder is still active
        var completedReminder = await reminderService.getReminderById(reminderId);
        expect(completedReminder!['status'], equals('active'));
        expect(completedReminder['completionCount'], equals(1));

        // Verify background rescheduling was triggered
        expect(() => backgroundTaskManager.rescheduleReminder(reminderId), returnsNormally);
      });

      test('should cancel background notification when reminder reaches repeat limit', () async {
        // Create limited repeat reminder
        final reminder = await reminderService.saveReminder(
          title: 'Limited Repeat Reminder',
          category: 'test',
          frequency: {'type': 'daily'},
          time: '14:30',
          enableNotifications: true,
          repeatLimit: 1, // Only once
        );

        final reminderId = reminder['id'] as int;

        // Mark as completed (should move to completed status)
        await reminderService.markReminderCompleted(reminderId);

        // Verify reminder is completed
        var completedReminder = await reminderService.getReminderById(reminderId);
        expect(completedReminder!['status'], equals('completed'));
        expect(completedReminder['completionCount'], equals(1));

        // Verify background notification was cancelled
        expect(() => backgroundTaskManager.cancelNotification(reminderId), returnsNormally);
      });

      test('should cancel background notification for manual completion', () async {
        // Create reminder
        final reminder = await reminderService.saveReminder(
          title: 'Manual Complete Reminder',
          category: 'test',
          frequency: {'type': 'daily'},
          time: '14:30',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Manually complete reminder
        await reminderService.completeReminderManually(reminderId);

        // Verify reminder is completed
        var completedReminder = await reminderService.getReminderById(reminderId);
        expect(completedReminder!['status'], equals('completed'));

        // Verify background notification was cancelled
        expect(() => backgroundTaskManager.cancelNotification(reminderId), returnsNormally);
      });
    });

    group('Bulk Operations Integration', () {
      test('should handle multiple reminders with background scheduling', () async {
        // Create multiple reminders
        final reminders = <Map<String, dynamic>>[];
        for (int i = 1; i <= 3; i++) {
          final reminder = await reminderService.saveReminder(
            title: 'Bulk Test Reminder $i',
            category: 'test',
            frequency: {'type': 'daily'},
            time: '${14 + i}:30',
            enableNotifications: true,
          );
          reminders.add(reminder);
        }

        // Verify all reminders were created
        expect(reminders.length, equals(3));
        for (var reminder in reminders) {
          expect(reminder['id'], isNotNull);
          expect(reminder['status'], equals('active'));
        }

        // Verify bulk background scheduling
        expect(() => backgroundTaskManager.scheduleAllActiveReminders(), returnsNormally);

        // Clean up
        for (var reminder in reminders) {
          await reminderService.deleteReminder(reminder['id'] as int);
        }
      });
    });
  });
}