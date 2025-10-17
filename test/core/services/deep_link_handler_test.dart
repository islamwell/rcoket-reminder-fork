import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_deeds_reminder/core/services/deep_link_handler.dart';
import 'package:good_deeds_reminder/core/models/notification_payload.dart';

void main() {
  group('DeepLinkHandler', () {
    late DeepLinkHandler deepLinkHandler;

    setUp(() {
      deepLinkHandler = DeepLinkHandler.instance;
    });

    group('initialization', () {
      testWidgets('initializes with context', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                deepLinkHandler.initialize(context);
                return Container();
              },
            ),
          ),
        );

        // Verify initialization doesn't throw
        expect(() => deepLinkHandler.initialize(tester.element(find.byType(Container))), 
               returnsNormally);
      });
    });

    group('payload validation', () {
      testWidgets('handles valid JSON payload', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                deepLinkHandler.initialize(context);
                return Container();
              },
            ),
          ),
        );

        final payload = NotificationPayload(
          reminderId: 1,
          title: 'Test Reminder',
          category: 'Health',
          action: NotificationAction.trigger,
        );

        // This should not throw an exception
        expect(() => deepLinkHandler.handleNotificationTap(payload.toJson()), 
               returnsNormally);
      });

      testWidgets('handles legacy payload format', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                deepLinkHandler.initialize(context);
                return Container();
              },
            ),
          ),
        );

        const legacyPayload = '1|Test Reminder|Health';

        // This should not throw an exception
        expect(() => deepLinkHandler.handleNotificationTap(legacyPayload), 
               returnsNormally);
      });

      testWidgets('handles invalid payload gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                deepLinkHandler.initialize(context);
                return Container();
              },
            ),
          ),
        );

        const invalidPayload = 'completely invalid payload';

        // This should not throw an exception but should handle gracefully
        expect(() => deepLinkHandler.handleNotificationTap(invalidPayload), 
               returnsNormally);
      });
    });

    group('deep link URL handling', () {
      testWidgets('handles reminder deep links', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                deepLinkHandler.initialize(context);
                return Container();
              },
            ),
          ),
        );

        const reminderUrl = 'myapp://reminder/123';

        // This should not throw an exception
        expect(() => deepLinkHandler.handleDeepLink(reminderUrl), 
               returnsNormally);
      });

      testWidgets('handles notification deep links', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                deepLinkHandler.initialize(context);
                return Container();
              },
            ),
          ),
        );

        final payload = NotificationPayload(
          reminderId: 1,
          title: 'Test',
          category: 'Health',
          action: NotificationAction.trigger,
        );

        final notificationUrl = 'myapp://notification?payload=${Uri.encodeComponent(payload.toJson())}';

        // This should not throw an exception
        expect(() => deepLinkHandler.handleDeepLink(notificationUrl), 
               returnsNormally);
      });

      testWidgets('handles invalid deep link URLs gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                deepLinkHandler.initialize(context);
                return Container();
              },
            ),
          ),
        );

        const invalidUrl = 'invalid://url/format';

        // This should not throw an exception but should handle gracefully
        expect(() => deepLinkHandler.handleDeepLink(invalidUrl), 
               returnsNormally);
      });
    });

    group('context management', () {
      testWidgets('updates context correctly', (WidgetTester tester) async {
        Widget buildTestWidget() {
          return MaterialApp(
            home: Builder(
              builder: (context) {
                deepLinkHandler.updateContext(context);
                return Container();
              },
            ),
          );
        }

        await tester.pumpWidget(buildTestWidget());

        // Verify context update doesn't throw
        expect(() => deepLinkHandler.updateContext(tester.element(find.byType(Container))), 
               returnsNormally);
      });

      test('disposes correctly', () {
        expect(() => deepLinkHandler.dispose(), returnsNormally);
      });
    });

    group('error handling', () {
      test('handles uninitialized state gracefully', () {
        final handler = DeepLinkHandler.instance;
        handler.dispose(); // Ensure it's not initialized

        // Should handle gracefully without throwing
        expect(() => handler.handleNotificationTap('test payload'), 
               returnsNormally);
      });
    });
  });

  group('DeepLinkException', () {
    test('creates exception with message', () {
      const message = 'Test deep link error';
      final exception = DeepLinkException(message);
      
      expect(exception.message, equals(message));
      expect(exception.toString(), equals('DeepLinkException: $message'));
    });
  });
}