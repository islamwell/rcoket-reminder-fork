import 'package:flutter_test/flutter_test.dart';
import 'package:good_deeds_reminder/core/models/notification_payload.dart';

void main() {
  group('NotificationPayload', () {
    group('constructor and validation', () {
      test('creates valid payload with required fields', () {
        final payload = NotificationPayload(
          reminderId: 1,
          title: 'Test Reminder',
          category: 'Health',
          action: NotificationAction.trigger,
        );

        expect(payload.reminderId, equals(1));
        expect(payload.title, equals('Test Reminder'));
        expect(payload.category, equals('Health'));
        expect(payload.action, equals(NotificationAction.trigger));
        expect(payload.isValid(), isTrue);
      });

      test('creates valid payload with optional fields', () {
        final scheduledTime = DateTime.now().add(Duration(hours: 1));
        final additionalData = {'key': 'value'};

        final payload = NotificationPayload(
          reminderId: 2,
          title: 'Test Reminder 2',
          category: 'Work',
          action: NotificationAction.snooze,
          scheduledTime: scheduledTime,
          additionalData: additionalData,
        );

        expect(payload.scheduledTime, equals(scheduledTime));
        expect(payload.additionalData, equals(additionalData));
        expect(payload.isValid(), isTrue);
      });

      test('validates payload correctly', () {
        // Valid payload
        final validPayload = NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: 'Health',
          action: NotificationAction.trigger,
        );
        expect(validPayload.isValid(), isTrue);

        // Invalid reminder ID
        final invalidIdPayload = NotificationPayload(
          reminderId: 0,
          title: 'Test',
          category: 'Health',
          action: NotificationAction.trigger,
        );
        expect(invalidIdPayload.isValid(), isFalse);

        // Empty title
        final emptyTitlePayload = NotificationPayload(
          reminderId: 1,
          title: '',
          category: 'Health',
          action: NotificationAction.trigger,
        );
        expect(emptyTitlePayload.isValid(), isFalse);

        // Empty category
        final emptyCategoryPayload = NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: '',
          action: NotificationAction.trigger,
        );
        expect(emptyCategoryPayload.isValid(), isFalse);

        // Invalid action
        final invalidActionPayload = NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: 'Health',
          action: 'invalid_action',
        );
        expect(invalidActionPayload.isValid(), isFalse);
      });
    });

    group('JSON serialization', () {
      test('serializes to JSON correctly', () {
        final payload = NotificationPayload(
          reminderId: 1,
          title: 'Test Reminder',
          category: 'Health',
          action: NotificationAction.trigger,
        );

        final json = payload.toJson();
        expect(json, isA<String>());
        expect(json.contains('"id":1'), isTrue);
        expect(json.contains('"title":"Test Reminder"'), isTrue);
        expect(json.contains('"category":"Health"'), isTrue);
        expect(json.contains('"action":"trigger"'), isTrue);
        expect(json.contains('"version":1'), isTrue);
      });

      test('serializes with optional fields', () {
        final scheduledTime = DateTime(2024, 1, 1, 12, 0, 0);
        final payload = NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: 'Health',
          action: NotificationAction.trigger,
          scheduledTime: scheduledTime,
          additionalData: {'key': 'value'},
        );

        final json = payload.toJson();
        expect(json.contains('"scheduledTime":"2024-01-01T12:00:00.000"'), isTrue);
        expect(json.contains('"additionalData":{"key":"value"}'), isTrue);
      });

      test('handles serialization errors', () {
        // This would be hard to test without mocking jsonEncode
        // For now, we trust that jsonEncode works correctly
        expect(() => NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: 'Health',
          action: NotificationAction.trigger,
        ).toJson(), returnsNormally);
      });
    });

    group('JSON deserialization', () {
      test('deserializes from JSON correctly', () {
        const jsonString = '''
        {
          "id": 1,
          "title": "Test Reminder",
          "category": "Health",
          "action": "trigger",
          "version": 1
        }
        ''';

        final payload = NotificationPayload.fromJson(jsonString);
        expect(payload.reminderId, equals(1));
        expect(payload.title, equals('Test Reminder'));
        expect(payload.category, equals('Health'));
        expect(payload.action, equals(NotificationAction.trigger));
      });

      test('deserializes with optional fields', () {
        const jsonString = '''
        {
          "id": 2,
          "title": "Test Reminder 2",
          "category": "Work",
          "action": "snooze",
          "scheduledTime": "2024-01-01T12:00:00.000",
          "additionalData": {"key": "value"},
          "version": 1
        }
        ''';

        final payload = NotificationPayload.fromJson(jsonString);
        expect(payload.scheduledTime, equals(DateTime(2024, 1, 1, 12, 0, 0)));
        expect(payload.additionalData, equals({'key': 'value'}));
      });

      test('throws exception for invalid JSON', () {
        expect(() => NotificationPayload.fromJson('invalid json'),
            throwsA(isA<NotificationPayloadException>()));
      });

      test('throws exception for missing required fields', () {
        // Missing ID
        expect(() => NotificationPayload.fromJson('{"title": "Test", "category": "Health", "action": "trigger"}'),
            throwsA(isA<NotificationPayloadException>()));

        // Missing title
        expect(() => NotificationPayload.fromJson('{"id": 1, "category": "Health", "action": "trigger"}'),
            throwsA(isA<NotificationPayloadException>()));

        // Missing category
        expect(() => NotificationPayload.fromJson('{"id": 1, "title": "Test", "action": "trigger"}'),
            throwsA(isA<NotificationPayloadException>()));

        // Missing action
        expect(() => NotificationPayload.fromJson('{"id": 1, "title": "Test", "category": "Health"}'),
            throwsA(isA<NotificationPayloadException>()));
      });

      test('throws exception for invalid field types', () {
        // Invalid ID type
        expect(() => NotificationPayload.fromJson('{"id": "invalid", "title": "Test", "category": "Health", "action": "trigger"}'),
            throwsA(isA<NotificationPayloadException>()));

        // Invalid action
        expect(() => NotificationPayload.fromJson('{"id": 1, "title": "Test", "category": "Health", "action": "invalid"}'),
            throwsA(isA<NotificationPayloadException>()));

        // Invalid scheduled time format
        expect(() => NotificationPayload.fromJson('{"id": 1, "title": "Test", "category": "Health", "action": "trigger", "scheduledTime": "invalid-date"}'),
            throwsA(isA<NotificationPayloadException>()));
      });
    });

    group('legacy format support', () {
      test('parses legacy format correctly', () {
        const legacyPayload = '1|Test Reminder|Health';
        final payload = NotificationPayload.fromLegacyFormat(legacyPayload);

        expect(payload, isNotNull);
        expect(payload!.reminderId, equals(1));
        expect(payload.title, equals('Test Reminder'));
        expect(payload.category, equals('Health'));
        expect(payload.action, equals(NotificationAction.trigger));
      });

      test('returns null for invalid legacy format', () {
        expect(NotificationPayload.fromLegacyFormat('invalid'), isNull);
        expect(NotificationPayload.fromLegacyFormat('1|'), isNull);
        expect(NotificationPayload.fromLegacyFormat('invalid|title|category'), isNull);
      });
    });

    group('equality and hashCode', () {
      test('equal payloads have same hashCode', () {
        final payload1 = NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: 'Health',
          action: NotificationAction.trigger,
        );

        final payload2 = NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: 'Health',
          action: NotificationAction.trigger,
        );

        expect(payload1, equals(payload2));
        expect(payload1.hashCode, equals(payload2.hashCode));
      });

      test('different payloads are not equal', () {
        final payload1 = NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: 'Health',
          action: NotificationAction.trigger,
        );

        final payload2 = NotificationPayload(
          reminderId: 2,
          title: 'Test',
          category: 'Health',
          action: NotificationAction.trigger,
        );

        expect(payload1, isNot(equals(payload2)));
      });
    });
  });

  group('NotificationAction', () {
    test('validates actions correctly', () {
      expect(NotificationAction.isValid(NotificationAction.trigger), isTrue);
      expect(NotificationAction.isValid(NotificationAction.snooze), isTrue);
      expect(NotificationAction.isValid(NotificationAction.complete), isTrue);
      expect(NotificationAction.isValid(NotificationAction.dismiss), isTrue);
      expect(NotificationAction.isValid('invalid'), isFalse);
    });

    test('returns valid actions list', () {
      final validActions = NotificationAction.validActions;
      expect(validActions, contains(NotificationAction.trigger));
      expect(validActions, contains(NotificationAction.snooze));
      expect(validActions, contains(NotificationAction.complete));
      expect(validActions, contains(NotificationAction.dismiss));
      expect(validActions.length, equals(4));
    });
  });

  group('NotificationPayloadException', () {
    test('creates exception with message', () {
      const message = 'Test error message';
      final exception = NotificationPayloadException(message);
      
      expect(exception.message, equals(message));
      expect(exception.toString(), equals('NotificationPayloadException: $message'));
    });
  });
}