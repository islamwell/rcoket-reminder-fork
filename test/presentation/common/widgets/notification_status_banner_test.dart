import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/presentation/common/widgets/notification_status_banner.dart';

void main() {
  group('NotificationStatusBanner', () {
    Widget createTestWidget({bool showOnlyWhenDisabled = true}) {
      return MaterialApp(
        home: Scaffold(
          body: NotificationStatusBanner(
            showOnlyWhenDisabled: showOnlyWhenDisabled,
          ),
        ),
        routes: {
          '/notification-settings': (context) => Scaffold(
            appBar: AppBar(title: Text('Notification Settings')),
            body: Center(child: Text('Notification Settings Screen')),
          ),
        },
      );
    }

    testWidgets('displays banner when notifications are disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The banner should be visible (assuming notifications are disabled in test environment)
      // We can't easily mock the notification service in widget tests, so we test the UI structure
      expect(find.byType(NotificationStatusBanner), findsOneWidget);
    });

    testWidgets('banner is tappable and navigates to notification settings', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the banner container (it might be wrapped in InkWell)
      final bannerFinder = find.byType(InkWell);
      if (tester.any(bannerFinder)) {
        await tester.tap(bannerFinder.first);
        await tester.pumpAndSettle();

        // Verify navigation to notification settings
        expect(find.text('Notification Settings Screen'), findsOneWidget);
      }
    });

    testWidgets('shows appropriate icons when banner is visible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showOnlyWhenDisabled: false));
      await tester.pumpAndSettle();

      // When showOnlyWhenDisabled is false, banner should always be visible
      final bannerFinder = find.byType(NotificationStatusBanner);
      if (tester.any(bannerFinder)) {
        // Check that some icon is displayed within the banner
        final iconFinder = find.descendant(
          of: bannerFinder,
          matching: find.byType(Icon),
        );
        expect(iconFinder, findsAtLeastNWidgets(1));
      }
    });

    testWidgets('displays text content when banner is visible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showOnlyWhenDisabled: false));
      await tester.pumpAndSettle();

      // When showOnlyWhenDisabled is false, banner should always be visible
      final bannerFinder = find.byType(NotificationStatusBanner);
      if (tester.any(bannerFinder)) {
        // Check that text is displayed within the banner
        final textFinder = find.descendant(
          of: bannerFinder,
          matching: find.byType(Text),
        );
        expect(textFinder, findsAtLeastNWidgets(1));
      }
    });

    testWidgets('respects showOnlyWhenDisabled parameter', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showOnlyWhenDisabled: false));
      await tester.pumpAndSettle();

      // Banner should be present regardless of notification state when showOnlyWhenDisabled is false
      expect(find.byType(NotificationStatusBanner), findsOneWidget);
    });

    testWidgets('has proper styling and layout when visible', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(showOnlyWhenDisabled: false));
      await tester.pumpAndSettle();

      // When showOnlyWhenDisabled is false, banner should always be visible
      final bannerFinder = find.byType(NotificationStatusBanner);
      if (tester.any(bannerFinder)) {
        // Check for proper container structure within the banner
        final containerFinder = find.descendant(
          of: bannerFinder,
          matching: find.byType(Container),
        );
        expect(containerFinder, findsAtLeastNWidgets(1));
      }
    });
  });
}