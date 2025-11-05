import 'dart:async';
import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'reminder_storage_service.dart';
import 'error_handling_service.dart';

/// Test helper class for testing reminder and notification functionality
/// This class provides utilities to test fullscreen reminders and notifications
class ReminderTestHelper {
  static ReminderTestHelper? _instance;
  static ReminderTestHelper get instance => _instance ??= ReminderTestHelper._();
  ReminderTestHelper._();

  /// Create a test reminder that will trigger immediately
  Future<Map<String, dynamic>?> createTestReminder({
    String title = 'Test Reminder',
    String category = 'Test',
    String? description,
    int delaySeconds = 10,
  }) async {
    try {
      print('TEST: Creating test reminder with ${delaySeconds}s delay');

      final now = DateTime.now();
      final triggerTime = now.add(Duration(seconds: delaySeconds));

      final testReminder = {
        'title': title,
        'category': category,
        'description': description ?? 'This is a test reminder to verify fullscreen notifications',
        'frequency': {
          'type': 'once',
        },
        'time': {
          'hour': triggerTime.hour,
          'minute': triggerTime.minute,
        },
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'nextOccurrenceDateTime': triggerTime.toIso8601String(),
      };

      // Save the test reminder
      final reminderId = await ReminderStorageService.instance.saveReminder(testReminder);

      // Get the saved reminder
      final savedReminder = await ReminderStorageService.instance.getReminderById(reminderId);

      if (savedReminder != null) {
        print('TEST: Test reminder created successfully with ID: $reminderId');
        print('TEST: Reminder will trigger at: ${triggerTime.toIso8601String()}');
        return savedReminder;
      } else {
        print('TEST: Failed to retrieve saved test reminder');
        return null;
      }

    } catch (e, stackTrace) {
      print('TEST ERROR: Failed to create test reminder: $e');
      await ErrorHandlingService.instance.logError(
        'TEST_REMINDER_CREATE_ERROR',
        'Failed to create test reminder: $e',
        severity: ErrorSeverity.error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Manually trigger the first active reminder for testing
  Future<void> triggerFirstActiveReminder() async {
    try {
      print('TEST: Manually triggering first active reminder');
      await NotificationService.instance.testTriggerReminder();
    } catch (e) {
      print('TEST ERROR: Failed to trigger reminder: $e');
      await ErrorHandlingService.instance.logError(
        'TEST_TRIGGER_ERROR',
        'Failed to trigger test reminder: $e',
        severity: ErrorSeverity.error,
        stackTrace: StackTrace.current,
      );
    }
  }

  /// Check if notifications are properly enabled
  Future<Map<String, dynamic>> checkNotificationStatus() async {
    try {
      print('TEST: Checking notification status');

      final notificationsEnabled = await NotificationService.instance.areNotificationsEnabled();
      final nativeNotificationsEnabled = NotificationService.instance.nativeNotificationsEnabled;
      final isInFallbackMode = ErrorHandlingService.instance.isInFallbackMode;

      final status = {
        'notificationsEnabled': notificationsEnabled,
        'nativeNotificationsEnabled': nativeNotificationsEnabled,
        'isInFallbackMode': isInFallbackMode,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('TEST: Notification status: $status');

      return status;

    } catch (e) {
      print('TEST ERROR: Failed to check notification status: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get all active reminders for testing
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    try {
      print('TEST: Getting all active reminders');

      final allReminders = await ReminderStorageService.instance.getReminders();
      final activeReminders = allReminders
          .where((r) => r['status'] == 'active')
          .toList();

      print('TEST: Found ${activeReminders.length} active reminders');

      for (var i = 0; i < activeReminders.length; i++) {
        final reminder = activeReminders[i];
        print('TEST: Reminder $i: ${reminder['title']} - Next: ${reminder['nextOccurrenceDateTime']}');
      }

      return activeReminders;

    } catch (e) {
      print('TEST ERROR: Failed to get active reminders: $e');
      return [];
    }
  }

  /// Get triggered reminders (for testing the trigger logic)
  Future<List<Map<String, dynamic>>> getTriggeredReminders() async {
    try {
      print('TEST: Getting triggered reminders');

      final triggeredReminders = await ReminderStorageService.instance.getTriggeredReminders();

      print('TEST: Found ${triggeredReminders.length} triggered reminders');

      for (var i = 0; i < triggeredReminders.length; i++) {
        final reminder = triggeredReminders[i];
        print('TEST: Triggered Reminder $i: ${reminder['title']}');
      }

      return triggeredReminders;

    } catch (e) {
      print('TEST ERROR: Failed to get triggered reminders: $e');
      return [];
    }
  }

  /// Delete all test reminders (reminders with category "Test")
  Future<void> deleteAllTestReminders() async {
    try {
      print('TEST: Deleting all test reminders');

      final allReminders = await ReminderStorageService.instance.getReminders();
      final testReminders = allReminders
          .where((r) => r['category'] == 'Test')
          .toList();

      print('TEST: Found ${testReminders.length} test reminders to delete');

      for (var reminder in testReminders) {
        final reminderId = reminder['id'] as int;
        await ReminderStorageService.instance.deleteReminder(reminderId);
        print('TEST: Deleted test reminder: ${reminder['title']} (ID: $reminderId)');
      }

      print('TEST: All test reminders deleted');

    } catch (e) {
      print('TEST ERROR: Failed to delete test reminders: $e');
    }
  }

  /// Request notification permissions (for testing permission flow)
  Future<bool> requestPermissions() async {
    try {
      print('TEST: Requesting notification permissions');

      final granted = await NotificationService.instance.requestPermissions();

      print('TEST: Permissions granted: $granted');

      return granted;

    } catch (e) {
      print('TEST ERROR: Failed to request permissions: $e');
      return false;
    }
  }

  /// Show test dialog to display status
  void showTestStatusDialog(BuildContext context, Map<String, dynamic> status) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notification Test Status'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusRow('Notifications Enabled', status['notificationsEnabled']),
              _buildStatusRow('Native Notifications', status['nativeNotificationsEnabled']),
              _buildStatusRow('Fallback Mode', status['isInFallbackMode']),
              SizedBox(height: 16),
              Text(
                'Timestamp: ${status['timestamp']}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, dynamic value) {
    final isEnabled = value is bool && value;
    final color = isEnabled ? Colors.green : Colors.red;
    final icon = isEnabled ? Icons.check_circle : Icons.cancel;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value.toString()),
        ],
      ),
    );
  }

  /// Print comprehensive test report
  Future<void> printTestReport() async {
    print('\n' + '='*60);
    print('REMINDER TEST REPORT');
    print('='*60);

    // Check notification status
    final status = await checkNotificationStatus();
    print('\n1. NOTIFICATION STATUS:');
    print('   - Notifications Enabled: ${status['notificationsEnabled']}');
    print('   - Native Notifications: ${status['nativeNotificationsEnabled']}');
    print('   - Fallback Mode: ${status['isInFallbackMode']}');

    // Check active reminders
    final activeReminders = await getActiveReminders();
    print('\n2. ACTIVE REMINDERS:');
    print('   - Total Active: ${activeReminders.length}');
    for (var i = 0; i < activeReminders.length && i < 5; i++) {
      final reminder = activeReminders[i];
      print('   - ${reminder['title']} (Next: ${reminder['nextOccurrenceDateTime']})');
    }

    // Check triggered reminders
    final triggeredReminders = await getTriggeredReminders();
    print('\n3. TRIGGERED REMINDERS:');
    print('   - Currently Triggered: ${triggeredReminders.length}');
    for (var i = 0; i < triggeredReminders.length && i < 5; i++) {
      final reminder = triggeredReminders[i];
      print('   - ${reminder['title']}');
    }

    print('\n' + '='*60);
    print('END OF TEST REPORT');
    print('='*60 + '\n');
  }
}
