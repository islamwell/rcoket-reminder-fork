import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_deeds_reminder/core/models/notification_payload.dart';
import 'package:good_deeds_reminder/core/services/deep_link_handler.dart';
import 'package:good_deeds_reminder/core/services/notification_service.dart';

void main() {
  group('Notification Payload Integration Tests', () {
    testWidgets('complete notification flow from payload creation to handling', 
        (WidgetTester tester) async {
      // Create a test app with proper navigation
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Initialize services
              DeepLinkHandler.instance.initialize(context);
              
              return Scaffold(
                body: Center(
                  child: Text('Test App'),
                ),
              );
            },
          ),
        ),
      );

      // Create a notification payload
      final payload = NotificationPayload(
        reminderId: 123,
        title: 'Integration Test Reminder',
        category: 'Test Category',
        action: NotificationAction.trigger,
        scheduledTime: DateTime.now().add(Duration(minutes: 30)),
        additionalData: {
          'testKey': 'testValue',
          'reminderType': 'hourly',
        },
      );

      // Verify payload is valid
      expect(payload.isValid(), isTrue);

      // Serialize to JSON
      final jsonPayload = payload.toJson();
      expect(jsonPayload, isA<String>());
      expect(jsonPayload.contains('Integration Test Reminder'), isTrue);

      // Deserialize back from JSON
      final deserializedPayload = NotificationPayload.fromJson(jsonPayload);
      expect(deserializedPayload, equals(payload));

      // Test deep link handling (should not throw)
      expect(() => DeepLinkHandler.instance.handleNotificationTap(jsonPayload), 
             returnsNormally);

      // Test notification service handling (should not throw)
      expect(() => NotificationService.instance.handleNotificationTap(jsonPayload), 
             returnsNormally);
    });

    testWidgets('backward compatibility with legacy payload format', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              DeepLinkHandler.instance.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
        ),
      );

      // Test legacy format
      const legacyPayload = '456|Legacy Test Reminder|Legacy Category';

      // Should be parseable by legacy format parser
      final parsedLegacy = NotificationPayload.fromLegacyFormat(legacyPayload);
      expect(parsedLegacy, isNotNull);
      expect(parsedLegacy!.reminderId, equals(456));
      expect(parsedLegacy.title, equals('Legacy Test Reminder'));
      expect(parsedLegacy.category, equals('Legacy Category'));
      expect(parsedLegacy.action, equals(NotificationAction.trigger));

      // Should be handled by deep link handler
      expect(() => DeepLinkHandler.instance.handleNotificationTap(legacyPayload), 
             returnsNormally);

      // Should be handled by notification service
      expect(() => NotificationService.instance.handleNotificationTap(legacyPayload), 
             returnsNormally);
    });

    testWidgets('error handling for malformed payloads', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              DeepLinkHandler.instance.initialize(context);
              return Scaffold(body: Text('Test App'));
            },
          ),
        ),
      );

      // Test various malformed payloads
      final malformedPayloads = [
        'completely invalid',
        '{"invalid": "json"}',
        '{"id": "not_a_number", "title": "test", "category": "test", "action": "trigger"}',
        '{"id": 1, "title": "", "category": "test", "action": "trigger"}',
        '{"id": 1, "title": "test", "category": "test", "action": "invalid_action"}',
        'partial|legacy',
        '',
      ];

      for (final malformedPayload in malformedPayloads) {
        // Should handle gracefully without throwing
        expect(() => DeepLinkHandler.instance.handleNotificationTap(malformedPayload), 
               returnsNormally);
        expect(() => NotificationService.instance.handleNotificationTap(malformedPayload), 
               returnsNormally);
      }
    });

    test('notification action validation', () {
      // Test all valid actions
      for (final action in NotificationAction.validActions) {
        expect(NotificationAction.isValid(action), isTrue);
        
        // Should be able to create payload with valid action
        final payload = NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: 'Test',
          action: action,
        );
        expect(payload.isValid(), isTrue);
      }

      // Test invalid actions
      final invalidActions = ['invalid', 'TRIGGER', 'Trigger', 'unknown', ''];
      for (final action in invalidActions) {
        expect(NotificationAction.isValid(action), isFalse);
      }
    });

    test('payload data integrity', () {
      final originalPayload = NotificationPayload(
        reminderId: 789,
        title: 'Data Integrity Test',
        category: 'Integrity',
        action: NotificationAction.complete,
        scheduledTime: DateTime(2024, 6, 15, 14, 30, 0),
        additionalData: {
          'complex': {'nested': 'data'},
          'array': [1, 2, 3],
          'boolean': true,
          'null_value': null,
        },
      );

      // Serialize and deserialize
      final json = originalPayload.toJson();
      final reconstructedPayload = NotificationPayload.fromJson(json);

      // Verify all data is preserved
      expect(reconstructedPayload.reminderId, equals(originalPayload.reminderId));
      expect(reconstructedPayload.title, equals(originalPayload.title));
      expect(reconstructedPayload.category, equals(originalPayload.category));
      expect(reconstructedPayload.action, equals(originalPayload.action));
      expect(reconstructedPayload.scheduledTime, equals(originalPayload.scheduledTime));
      expect(reconstructedPayload.additionalData, equals(originalPayload.additionalData));
      expect(reconstructedPayload, equals(originalPayload));
    });
  });
}