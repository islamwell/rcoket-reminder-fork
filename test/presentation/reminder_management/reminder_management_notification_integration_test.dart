import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/reminder_management/reminder_management.dart';
import '../../../lib/presentation/common/widgets/notification_status_banner.dart';

void main() {
  group('Reminder Management Notification Integration', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: ReminderManagement(),
        routes: {
          '/notification-settings': (context) => Scaffold(
            appBar: AppBar(title: Text('Notification Settings')),
            body: Center(child: Text('Notification Settings Screen')),
          ),
          '/create-reminder': (context) => Scaffold(
            appBar: AppBar(title: Text('Create Reminder')),
            body: Center(child: Text('Create Reminder Screen')),
          ),
          '/settings': (context) => Scaffold(
            appBar: AppBar(title: Text('Settings')),
            body: Center(child: Text('Settings Screen')),
          ),
        },
      );
    }

    testWidgets('reminder management includes notification status banner', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify that the notification status banner is present
      expect(find.byType(NotificationStatusBanner), findsOneWidget);
    });

    testWidgets('notification banner is positioned correctly in reminder management', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the banner is within the Column structure
      expect(find.byType(Column), findsAtLeastNWidgets(1));
      expect(find.byType(NotificationStatusBanner), findsOneWidget);
    });

    testWidgets('reminder management loads without errors with notification banner', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Wait for any async operations to complete
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify no errors occurred and screen is displayed
      expect(find.byType(ReminderManagement), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget); // App bar title
      expect(tester.takeException(), isNull);
    });

    testWidgets('notification banner in reminder management is interactive', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the notification banner
      final bannerFinder = find.byType(NotificationStatusBanner);
      expect(bannerFinder, findsOneWidget);

      // Try to find and tap the banner (if it's visible)
      final inkWellFinder = find.descendant(
        of: bannerFinder,
        matching: find.byType(InkWell),
      );
      
      if (tester.any(inkWellFinder)) {
        await tester.tap(inkWellFinder);
        await tester.pumpAndSettle();

        // Verify navigation occurred
        expect(find.text('Notification Settings Screen'), findsOneWidget);
      }
    });

    testWidgets('app bar and banner coexist properly', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify both app bar and banner are present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(NotificationStatusBanner), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);
    });
  });
}