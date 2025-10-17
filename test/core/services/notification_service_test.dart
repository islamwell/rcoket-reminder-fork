import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_deeds_reminder/core/services/notification_service.dart';
import 'package:good_deeds_reminder/core/models/delay_option.dart';

void main() {
  group('NotificationService', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService.instance;
    });

    testWidgets('should initialize without errors', (WidgetTester tester) async {
      // Create a minimal app context
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Initialize the service
              notificationService.initialize(context);
              return Container();
            },
          ),
        ),
      );

      // Verify service is initialized
      expect(notificationService, isNotNull);
    });

    test('should handle notification tap payload correctly', () {
      // Test JSON payload format
      const jsonPayload = '{"id": 123, "title": "Test Reminder", "category": "Health", "action": "trigger"}';
      
      // This should not throw an exception
      expect(() => notificationService.handleNotificationTap(jsonPayload), returnsNormally);
    });

    test('should handle legacy notification tap payload correctly', () {
      // Test legacy pipe-separated format
      const legacyPayload = '123|Test Reminder|Health';
      
      // This should not throw an exception
      expect(() => notificationService.handleNotificationTap(legacyPayload), returnsNormally);
    });

    test('should handle malformed notification payload gracefully', () {
      // Test malformed payload
      const malformedPayload = 'invalid-payload';
      
      // This should not throw an exception
      expect(() => notificationService.handleNotificationTap(malformedPayload), returnsNormally);
    });

    test('should provide native notifications enabled status', () {
      // Initially should be false until permissions are granted
      expect(notificationService.nativeNotificationsEnabled, isFalse);
    });

    group('Delay Functionality', () {
      test('should validate schedule time correctly', () {
        // Test future time (valid)
        final futureTime = DateTime.now().add(Duration(minutes: 5));
        expect(notificationService.validateDelayOption(
          DelayOption(
            id: 'test',
            label: '5 minutes',
            duration: Duration(minutes: 5),
            icon: Icons.timer,
          )
        ), isTrue);

        // Test past time (invalid)
        expect(notificationService.validateDelayOption(
          DelayOption(
            id: 'test',
            label: 'invalid',
            duration: Duration(minutes: -5),
            icon: Icons.timer,
          )
        ), isFalse);

        // Test zero duration (invalid)
        expect(notificationService.validateDelayOption(
          DelayOption(
            id: 'test',
            label: 'invalid',
            duration: Duration.zero,
            icon: Icons.timer,
          )
        ), isFalse);

        // Test very long duration (invalid - more than 7 days)
        expect(notificationService.validateDelayOption(
          DelayOption(
            id: 'test',
            label: 'invalid',
            duration: Duration(days: 8),
            icon: Icons.timer,
          )
        ), isFalse);
      });

      test('should provide predefined delay options', () {
        final delayPresets = notificationService.getDelayPresets();
        
        expect(delayPresets, isNotEmpty);
        expect(delayPresets.length, equals(5)); // 1min, 5min, 15min, 1hr, custom
        
        // Check that all presets have required properties
        for (final preset in delayPresets) {
          expect(preset.id, isNotEmpty);
          expect(preset.label, isNotEmpty);
          expect(preset.icon, isNotNull);
          
          if (!preset.isCustom) {
            expect(preset.duration.inSeconds, greaterThan(0));
          }
        }
        
        // Check specific presets exist
        expect(delayPresets.any((p) => p.id == '1min'), isTrue);
        expect(delayPresets.any((p) => p.id == '5min'), isTrue);
        expect(delayPresets.any((p) => p.id == '15min'), isTrue);
        expect(delayPresets.any((p) => p.id == '1hr'), isTrue);
        expect(delayPresets.any((p) => p.id == 'custom'), isTrue);
      });

      testWidgets('should show completion delay dialog', (WidgetTester tester) async {
        // Create a test app with the notification service
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                notificationService.initialize(context);
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await notificationService.showCompletionDelayDialog('Test Reminder');
                    },
                    child: Text('Show Dialog'),
                  ),
                );
              },
            ),
          ),
        );

        // Tap the button to show the dialog
        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        // Verify dialog is shown (should contain delay options)
        expect(find.text('Complete Later'), findsOneWidget);
        expect(find.text('1 minute'), findsOneWidget);
        expect(find.text('5 minutes'), findsOneWidget);
        expect(find.text('15 minutes'), findsOneWidget);
        expect(find.text('1 hour'), findsOneWidget);
        expect(find.text('Custom time'), findsOneWidget);
      });
    });
  });
}