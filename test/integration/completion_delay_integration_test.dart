import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_deeds_reminder/core/services/notification_service.dart';
import 'package:good_deeds_reminder/core/services/reminder_storage_service.dart';
import 'package:good_deeds_reminder/core/models/delay_option.dart';

void main() {
  group('Completion Delay Integration Tests', () {
    late NotificationService notificationService;
    late ReminderStorageService storageService;

    setUp(() {
      notificationService = NotificationService.instance;
      storageService = ReminderStorageService.instance;
    });

    testWidgets('should integrate delay functionality with notification system', (WidgetTester tester) async {
      // Create a test app with the notification service
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              notificationService.initialize(context);
              return Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await notificationService.showCompletionDelayDialog('Test Reminder');
                      },
                      child: Text('Show Delay Dialog'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final delayOption = DelayOption(
                          id: '5min',
                          label: '5 minutes',
                          duration: Duration(minutes: 5),
                          icon: Icons.timer,
                        );
                        await notificationService.scheduleDelayedCompletion(1, delayOption);
                      },
                      child: Text('Schedule Delay'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Test showing the delay dialog
      await tester.tap(find.text('Show Delay Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown with all delay options
      expect(find.text('Complete Later'), findsOneWidget);
      expect(find.text('1 minute'), findsOneWidget);
      expect(find.text('5 minutes'), findsOneWidget);
      expect(find.text('15 minutes'), findsOneWidget);
      expect(find.text('1 hour'), findsOneWidget);
      expect(find.text('Custom time'), findsOneWidget);

      // Close the dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Test scheduling a delay (this will fail in test environment but should not crash)
      await tester.tap(find.text('Schedule Delay'));
      await tester.pumpAndSettle();

      // Verify no crashes occurred
      expect(tester.takeException(), isNull);
    });

    test('should validate delay options correctly', () {
      // Test valid delay options
      final validDelays = [
        DelayOption(id: '1min', label: '1 minute', duration: Duration(minutes: 1), icon: Icons.timer),
        DelayOption(id: '5min', label: '5 minutes', duration: Duration(minutes: 5), icon: Icons.timer),
        DelayOption(id: '1hr', label: '1 hour', duration: Duration(hours: 1), icon: Icons.timer),
        DelayOption(id: '1day', label: '1 day', duration: Duration(days: 1), icon: Icons.timer),
      ];

      for (final delay in validDelays) {
        expect(notificationService.validateDelayOption(delay), isTrue, 
               reason: 'Delay ${delay.label} should be valid');
      }

      // Test invalid delay options
      final invalidDelays = [
        DelayOption(id: 'zero', label: 'zero', duration: Duration.zero, icon: Icons.timer),
        DelayOption(id: 'negative', label: 'negative', duration: Duration(minutes: -5), icon: Icons.timer),
        DelayOption(id: 'toolong', label: 'too long', duration: Duration(days: 10), icon: Icons.timer),
      ];

      for (final delay in invalidDelays) {
        expect(notificationService.validateDelayOption(delay), isFalse, 
               reason: 'Delay ${delay.label} should be invalid');
      }
    });

    test('should provide correct delay presets', () {
      final presets = notificationService.getDelayPresets();
      
      expect(presets.length, equals(5));
      
      // Verify specific presets
      final oneMinute = presets.firstWhere((p) => p.id == '1min');
      expect(oneMinute.duration, equals(Duration(minutes: 1)));
      expect(oneMinute.isCustom, isFalse);
      
      final fiveMinutes = presets.firstWhere((p) => p.id == '5min');
      expect(fiveMinutes.duration, equals(Duration(minutes: 5)));
      expect(fiveMinutes.isCustom, isFalse);
      
      final fifteenMinutes = presets.firstWhere((p) => p.id == '15min');
      expect(fifteenMinutes.duration, equals(Duration(minutes: 15)));
      expect(fifteenMinutes.isCustom, isFalse);
      
      final oneHour = presets.firstWhere((p) => p.id == '1hr');
      expect(oneHour.duration, equals(Duration(hours: 1)));
      expect(oneHour.isCustom, isFalse);
      
      final custom = presets.firstWhere((p) => p.id == 'custom');
      expect(custom.isCustom, isTrue);
    });

    test('should handle edge cases in delay scheduling', () {
      // Test with very short delay (should be valid)
      final shortDelay = DelayOption(
        id: 'short',
        label: '1 minute',
        duration: Duration(minutes: 1),
        icon: Icons.timer,
      );
      expect(notificationService.validateDelayOption(shortDelay), isTrue);

      // Test with maximum allowed delay (7 days should be valid)
      final maxDelay = DelayOption(
        id: 'max',
        label: '7 days',
        duration: Duration(days: 7),
        icon: Icons.timer,
      );
      expect(notificationService.validateDelayOption(maxDelay), isTrue);

      // Test with just over maximum (should be invalid)
      final overMaxDelay = DelayOption(
        id: 'overmax',
        label: '8 days',
        duration: Duration(days: 8),
        icon: Icons.timer,
      );
      expect(notificationService.validateDelayOption(overMaxDelay), isFalse);
    });
  });
}