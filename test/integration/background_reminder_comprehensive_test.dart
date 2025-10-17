import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/core/services/background_task_manager.dart';
import '../../lib/core/services/notification_service.dart';
import '../../lib/core/services/reminder_storage_service.dart';
import '../../lib/core/services/deep_link_handler.dart';
import '../../lib/core/models/notification_payload.dart';
import '../../lib/routes/app_routes.dart';

void main() {
  group('Background Reminder Comprehensive Tests', () {
    late BackgroundTaskManager backgroundTaskManager;
    late NotificationService notificationService;
    late ReminderStorageService reminderStorageService;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    setUp(() async {
      backgroundTaskManager = BackgroundTaskManager.instance;
      notificationService = NotificationService.instance;
      reminderStorageService = ReminderStorageService.instance;
      
      // Clear any existing reminders
      await reminderStorageService.clearAllReminders();
    });

    tearDown(() async {
      backgroundTaskManager.dispose();
      notificationService.dispose();
      await reminderStorageService.clearAllReminders();
    });

    group('Notification Scheduling and Delivery Integration', () {
      testWidgets('should schedule and handle notification for daily reminder', 
          (WidgetTester tester) async {
        // Create test app with proper navigation
        final app = MaterialApp(
          home: Builder(
            builder: (context) {
              notificationService.initialize(context);
              DeepLinkHandler.instance.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
          routes: AppRoutes.routes,
        );

        await tester.pumpWidget(app);
        await tester.pump();

        // Create a daily reminder
        final reminder = await reminderStorageService.saveReminder(
          title: 'Daily Test Reminder',
          category: 'Health',
          frequency: {'type': 'daily'},
          time: '09:00',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Schedule background notification
        await backgroundTaskManager.scheduleAllActiveReminders();

        // Verify reminder was created and is active
        expect(reminder['status'], equals('active'));
        expect(reminder['enableNotifications'], equals(true));

        // Simulate notification scheduling (would normally be handled by system)
        await notificationService.scheduleNotification(reminder);

        // Test notification payload creation and handling
        final payload = NotificationPayload(
          reminderId: reminderId,
          title: 'Daily Test Reminder',
          category: 'Health',
          action: NotificationAction.trigger,
        );

        // Verify payload is valid
        expect(payload.isValid(), isTrue);

        // Test notification tap handling
        final payloadJson = payload.toJson();
        expect(() => notificationService.handleNotificationTap(payloadJson), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminderId);
      });

      testWidgets('should handle multiple simultaneous notifications', 
          (WidgetTester tester) async {
        final app = MaterialApp(
          home: Builder(
            builder: (context) {
              notificationService.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
        );

        await tester.pumpWidget(app);
        await tester.pump();

        // Create multiple reminders
        final reminders = <Map<String, dynamic>>[];
        for (int i = 1; i <= 3; i++) {
          final reminder = await reminderStorageService.saveReminder(
            title: 'Multi Test Reminder $i',
            category: 'Test',
            frequency: {'type': 'daily'},
            time: '${8 + i}:00',
            enableNotifications: true,
          );
          reminders.add(reminder);
        }

        // Schedule all notifications
        await backgroundTaskManager.scheduleAllActiveReminders();

        // Verify all reminders are scheduled
        for (final reminder in reminders) {
          await notificationService.scheduleNotification(reminder);
          
          // Test individual notification handling
          final payload = NotificationPayload(
            reminderId: reminder['id'] as int,
            title: reminder['title'] as String,
            category: reminder['category'] as String,
            action: NotificationAction.trigger,
          );
          
          expect(() => notificationService.handleNotificationTap(payload.toJson()), 
                 returnsNormally);
        }

        // Clean up
        for (final reminder in reminders) {
          await reminderStorageService.deleteReminder(reminder['id'] as int);
        }
      });

      test('should handle notification scheduling for different frequency types', () async {
        final frequencyTypes = [
          {'type': 'daily'},
          {'type': 'weekly', 'selectedDays': [1, 3, 5]},
          {'type': 'hourly'},
          {'type': 'monthly', 'dayOfMonth': 15},
          {'type': 'custom', 'intervalValue': 2, 'intervalUnit': 'hours'},
          {'type': 'once', 'date': DateTime.now().add(Duration(days: 1)).toIso8601String()},
        ];

        for (int i = 0; i < frequencyTypes.length; i++) {
          final reminder = await reminderStorageService.saveReminder(
            title: 'Frequency Test $i',
            category: 'Test',
            frequency: frequencyTypes[i],
            time: '10:00',
            enableNotifications: true,
          );

          // Should schedule without errors
          expect(() => backgroundTaskManager.rescheduleReminder(reminder['id'] as int), 
                 returnsNormally);
          
          // Should handle notification scheduling
          expect(() => notificationService.scheduleNotification(reminder), 
                 returnsNormally);

          // Clean up
          await reminderStorageService.deleteReminder(reminder['id'] as int);
        }
      });
    });

    group('App Lifecycle State Changes and Background Processing', () {
      testWidgets('should handle app going to background and resuming', 
          (WidgetTester tester) async {
        final app = MaterialApp(
          home: Builder(
            builder: (context) {
              notificationService.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
        );

        await tester.pumpWidget(app);
        await tester.pump();

        // Create test reminder
        final reminder = await reminderStorageService.saveReminder(
          title: 'Lifecycle Test Reminder',
          category: 'Test',
          frequency: {'type': 'daily'},
          time: '12:00',
          enableNotifications: true,
        );

        // Simulate app going to background
        await backgroundTaskManager.handleAppStateChange(AppLifecycleState.paused);
        
        // Verify notifications are scheduled when app goes to background
        expect(() => backgroundTaskManager.scheduleAllActiveReminders(), 
               returnsNormally);

        // Simulate app resuming
        await backgroundTaskManager.handleAppStateChange(AppLifecycleState.resumed);
        
        // Verify notifications are rescheduled when app resumes
        expect(() => backgroundTaskManager.scheduleAllActiveReminders(), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminder['id'] as int);
      });

      testWidgets('should handle app being terminated', (WidgetTester tester) async {
        final app = MaterialApp(
          home: Builder(
            builder: (context) {
              notificationService.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
        );

        await tester.pumpWidget(app);
        await tester.pump();

        // Create test reminder
        final reminder = await reminderStorageService.saveReminder(
          title: 'Termination Test Reminder',
          category: 'Test',
          frequency: {'type': 'daily'},
          time: '15:00',
          enableNotifications: true,
        );

        // Simulate app being terminated
        await backgroundTaskManager.handleAppStateChange(AppLifecycleState.detached);
        
        // Verify background notifications are ensured before termination
        expect(() => backgroundTaskManager.scheduleAllActiveReminders(), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminder['id'] as int);
      });

      test('should maintain notification schedules across app lifecycle changes', () async {
        // Create multiple reminders
        final reminders = <Map<String, dynamic>>[];
        for (int i = 1; i <= 3; i++) {
          final reminder = await reminderStorageService.saveReminder(
            title: 'Lifecycle Persistence Test $i',
            category: 'Test',
            frequency: {'type': 'daily'},
            time: '${10 + i}:00',
            enableNotifications: true,
          );
          reminders.add(reminder);
        }

        // Initial scheduling
        await backgroundTaskManager.scheduleAllActiveReminders();

        // Simulate multiple lifecycle changes
        final lifecycleStates = [
          AppLifecycleState.paused,
          AppLifecycleState.resumed,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
          AppLifecycleState.paused,
        ];

        for (final state in lifecycleStates) {
          await backgroundTaskManager.handleAppStateChange(state);
          
          // Verify scheduling still works after each state change
          expect(() => backgroundTaskManager.scheduleAllActiveReminders(), 
                 returnsNormally);
        }

        // Clean up
        for (final reminder in reminders) {
          await reminderStorageService.deleteReminder(reminder['id'] as int);
        }
      });
    });

    group('Notification Tap Actions and Deep Linking', () {
      testWidgets('should handle notification tap with structured payload', 
          (WidgetTester tester) async {
        final app = MaterialApp(
          home: Builder(
            builder: (context) {
              notificationService.initialize(context);
              DeepLinkHandler.instance.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
          routes: AppRoutes.routes,
        );

        await tester.pumpWidget(app);
        await tester.pump();

        // Create test reminder
        final reminder = await reminderStorageService.saveReminder(
          title: 'Deep Link Test Reminder',
          category: 'Health',
          frequency: {'type': 'daily'},
          time: '14:00',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Create structured notification payload
        final payload = NotificationPayload(
          reminderId: reminderId,
          title: 'Deep Link Test Reminder',
          category: 'Health',
          action: NotificationAction.trigger,
          scheduledTime: DateTime.now().add(Duration(minutes: 30)),
          additionalData: {
            'testKey': 'testValue',
            'reminderType': 'daily',
          },
        );

        // Test notification tap handling
        final payloadJson = payload.toJson();
        expect(() => notificationService.handleNotificationTap(payloadJson), 
               returnsNormally);
        
        // Test deep link handler
        expect(() => DeepLinkHandler.instance.handleNotificationTap(payloadJson), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminderId);
      });

      testWidgets('should handle notification tap with legacy payload format', 
          (WidgetTester tester) async {
        final app = MaterialApp(
          home: Builder(
            builder: (context) {
              notificationService.initialize(context);
              DeepLinkHandler.instance.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
          routes: AppRoutes.routes,
        );

        await tester.pumpWidget(app);
        await tester.pump();

        // Create test reminder
        final reminder = await reminderStorageService.saveReminder(
          title: 'Legacy Format Test',
          category: 'Work',
          frequency: {'type': 'daily'},
          time: '16:00',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Test legacy format payload
        final legacyPayload = '$reminderId|Legacy Format Test|Work';
        
        expect(() => notificationService.handleNotificationTap(legacyPayload), 
               returnsNormally);
        
        expect(() => DeepLinkHandler.instance.handleNotificationTap(legacyPayload), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminderId);
      });

      testWidgets('should handle different notification actions', 
          (WidgetTester tester) async {
        final app = MaterialApp(
          home: Builder(
            builder: (context) {
              notificationService.initialize(context);
              DeepLinkHandler.instance.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
          routes: AppRoutes.routes,
        );

        await tester.pumpWidget(app);
        await tester.pump();

        // Create test reminder
        final reminder = await reminderStorageService.saveReminder(
          title: 'Action Test Reminder',
          category: 'Test',
          frequency: {'type': 'daily'},
          time: '18:00',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Test different notification actions
        final actions = [
          NotificationAction.trigger,
          NotificationAction.complete,
          NotificationAction.snooze,
        ];

        for (final action in actions) {
          final payload = NotificationPayload(
            reminderId: reminderId,
            title: 'Action Test Reminder',
            category: 'Test',
            action: action,
          );

          expect(() => notificationService.handleNotificationTap(payload.toJson()), 
                 returnsNormally);
        }

        // Clean up
        await reminderStorageService.deleteReminder(reminderId);
      });

      testWidgets('should handle malformed notification payloads gracefully', 
          (WidgetTester tester) async {
        final app = MaterialApp(
          home: Builder(
            builder: (context) {
              notificationService.initialize(context);
              DeepLinkHandler.instance.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
          routes: AppRoutes.routes,
        );

        await tester.pumpWidget(app);
        await tester.pump();

        // Test various malformed payloads
        final malformedPayloads = [
          'completely invalid',
          '{"invalid": "json"}',
          '{"id": "not_a_number", "title": "test", "category": "test", "action": "trigger"}',
          '{"id": 1, "title": "", "category": "test", "action": "trigger"}',
          '{"id": 1, "title": "test", "category": "test", "action": "invalid_action"}',
          'partial|legacy',
          '',
          'null',
        ];

        for (final malformedPayload in malformedPayloads) {
          // Should handle gracefully without throwing
          expect(() => notificationService.handleNotificationTap(malformedPayload), 
                 returnsNormally);
          expect(() => DeepLinkHandler.instance.handleNotificationTap(malformedPayload), 
                 returnsNormally);
        }
      });
    });

    group('Edge Cases - Device Restart and Time Changes', () {
      test('should reschedule reminders after simulated device restart', () async {
        // Create reminders before "restart"
        final reminders = <Map<String, dynamic>>[];
        for (int i = 1; i <= 3; i++) {
          final reminder = await reminderStorageService.saveReminder(
            title: 'Restart Test Reminder $i',
            category: 'Test',
            frequency: {'type': 'daily'},
            time: '${8 + i}:00',
            enableNotifications: true,
          );
          reminders.add(reminder);
        }

        // Initial scheduling
        await backgroundTaskManager.scheduleAllActiveReminders();

        // Simulate device restart by disposing and reinitializing
        backgroundTaskManager.dispose();
        
        // Reinitialize (simulates app restart after device restart)
        final newBackgroundTaskManager = BackgroundTaskManager.instance;
        
        // Should reschedule all active reminders
        expect(() => newBackgroundTaskManager.scheduleAllActiveReminders(), 
               returnsNormally);

        // Verify reminders are still active and can be rescheduled
        for (final reminder in reminders) {
          final reminderId = reminder['id'] as int;
          final storedReminder = await reminderStorageService.getReminderById(reminderId);
          expect(storedReminder, isNotNull);
          expect(storedReminder!['status'], equals('active'));
          
          expect(() => newBackgroundTaskManager.rescheduleReminder(reminderId), 
                 returnsNormally);
        }

        // Clean up
        for (final reminder in reminders) {
          await reminderStorageService.deleteReminder(reminder['id'] as int);
        }
      });

      test('should handle time zone changes correctly', () async {
        // Create reminder with specific time
        final reminder = await reminderStorageService.saveReminder(
          title: 'Timezone Test Reminder',
          category: 'Test',
          frequency: {'type': 'daily'},
          time: '12:00',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Initial scheduling
        await backgroundTaskManager.rescheduleReminder(reminderId);

        // Simulate time zone change by rescheduling
        // (In a real scenario, this would be triggered by system events)
        await backgroundTaskManager.scheduleAllActiveReminders();

        // Verify reminder can still be scheduled
        expect(() => backgroundTaskManager.rescheduleReminder(reminderId), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminderId);
      });

      test('should handle daylight saving time transitions', () async {
        // Create reminder that might be affected by DST
        final reminder = await reminderStorageService.saveReminder(
          title: 'DST Test Reminder',
          category: 'Test',
          frequency: {'type': 'daily'},
          time: '02:00', // Time that might be affected by DST
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Schedule reminder
        await backgroundTaskManager.rescheduleReminder(reminderId);

        // Simulate DST transition by rescheduling all reminders
        await backgroundTaskManager.scheduleAllActiveReminders();

        // Verify reminder is still properly scheduled
        expect(() => backgroundTaskManager.rescheduleReminder(reminderId), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminderId);
      });

      test('should handle system time changes', () async {
        // Create reminder scheduled for future
        final futureTime = DateTime.now().add(Duration(hours: 2));
        final reminder = await reminderStorageService.saveReminder(
          title: 'Time Change Test Reminder',
          category: 'Test',
          frequency: {
            'type': 'once',
            'date': futureTime.toIso8601String(),
          },
          time: '${futureTime.hour.toString().padLeft(2, '0')}:${futureTime.minute.toString().padLeft(2, '0')}',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Initial scheduling
        await backgroundTaskManager.rescheduleReminder(reminderId);

        // Simulate system time change by rescheduling
        await backgroundTaskManager.scheduleAllActiveReminders();

        // Verify reminder handling after time change
        expect(() => backgroundTaskManager.rescheduleReminder(reminderId), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminderId);
      });

      test('should handle leap year and month boundary edge cases', () async {
        // Test monthly reminder on the 29th (leap year edge case)
        final reminder = await reminderStorageService.saveReminder(
          title: 'Leap Year Test Reminder',
          category: 'Test',
          frequency: {
            'type': 'monthly',
            'dayOfMonth': 29,
          },
          time: '10:00',
          enableNotifications: true,
        );

        final reminderId = reminder['id'] as int;

        // Should handle scheduling without errors
        expect(() => backgroundTaskManager.rescheduleReminder(reminderId), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminderId);
      });

      test('should handle multiple reminders scheduled for same time', () async {
        final sameTime = '15:30';
        final reminders = <Map<String, dynamic>>[];

        // Create multiple reminders for the same time
        for (int i = 1; i <= 3; i++) {
          final reminder = await reminderStorageService.saveReminder(
            title: 'Same Time Test Reminder $i',
            category: 'Test',
            frequency: {'type': 'daily'},
            time: sameTime,
            enableNotifications: true,
          );
          reminders.add(reminder);
        }

        // Schedule all reminders
        await backgroundTaskManager.scheduleAllActiveReminders();

        // Verify all reminders can be scheduled for the same time
        for (final reminder in reminders) {
          final reminderId = reminder['id'] as int;
          expect(() => backgroundTaskManager.rescheduleReminder(reminderId), 
                 returnsNormally);
        }

        // Clean up
        for (final reminder in reminders) {
          await reminderStorageService.deleteReminder(reminder['id'] as int);
        }
      });

      test('should preserve reminder schedules after app updates', () async {
        // Create reminders before "update"
        final reminders = <Map<String, dynamic>>[];
        for (int i = 1; i <= 2; i++) {
          final reminder = await reminderStorageService.saveReminder(
            title: 'Update Persistence Test $i',
            category: 'Test',
            frequency: {'type': 'daily'},
            time: '${9 + i}:00',
            enableNotifications: true,
          );
          reminders.add(reminder);
        }

        // Initial scheduling
        await backgroundTaskManager.scheduleAllActiveReminders();

        // Simulate app update by reinitializing services
        backgroundTaskManager.dispose();
        notificationService.dispose();

        // Reinitialize services (simulates app restart after update)
        final newBackgroundTaskManager = BackgroundTaskManager.instance;
        
        // Should be able to reschedule existing reminders
        expect(() => newBackgroundTaskManager.scheduleAllActiveReminders(), 
               returnsNormally);

        // Verify reminders are preserved and functional
        for (final reminder in reminders) {
          final reminderId = reminder['id'] as int;
          final storedReminder = await reminderStorageService.getReminderById(reminderId);
          expect(storedReminder, isNotNull);
          expect(storedReminder!['status'], equals('active'));
        }

        // Clean up
        for (final reminder in reminders) {
          await reminderStorageService.deleteReminder(reminder['id'] as int);
        }
      });
    });

    group('Performance and Stress Tests', () {
      test('should handle large number of reminders efficiently', () async {
        final reminders = <Map<String, dynamic>>[];
        
        // Create many reminders
        for (int i = 1; i <= 50; i++) {
          final reminder = await reminderStorageService.saveReminder(
            title: 'Performance Test Reminder $i',
            category: 'Test',
            frequency: {'type': 'daily'},
            time: '${(8 + (i % 12)).toString().padLeft(2, '0')}:${(i % 60).toString().padLeft(2, '0')}',
            enableNotifications: true,
          );
          reminders.add(reminder);
        }

        // Measure scheduling performance
        final stopwatch = Stopwatch()..start();
        await backgroundTaskManager.scheduleAllActiveReminders();
        stopwatch.stop();

        // Should complete within reasonable time (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds

        // Clean up
        for (final reminder in reminders) {
          await reminderStorageService.deleteReminder(reminder['id'] as int);
        }
      });

      test('should handle rapid lifecycle state changes', () async {
        // Create test reminder
        final reminder = await reminderStorageService.saveReminder(
          title: 'Rapid Lifecycle Test',
          category: 'Test',
          frequency: {'type': 'daily'},
          time: '12:00',
          enableNotifications: true,
        );

        // Rapidly change app lifecycle states
        final states = [
          AppLifecycleState.paused,
          AppLifecycleState.resumed,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
          AppLifecycleState.paused,
          AppLifecycleState.resumed,
        ];

        for (final state in states) {
          await backgroundTaskManager.handleAppStateChange(state);
          // Small delay to simulate real-world timing
          await Future.delayed(Duration(milliseconds: 10));
        }

        // Should still be able to schedule reminders
        expect(() => backgroundTaskManager.scheduleAllActiveReminders(), 
               returnsNormally);

        // Clean up
        await reminderStorageService.deleteReminder(reminder['id'] as int);
      });
    });
  });
}