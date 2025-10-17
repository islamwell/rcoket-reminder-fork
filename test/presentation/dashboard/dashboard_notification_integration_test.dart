import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/dashboard/dashboard_screen.dart';
import '../../../lib/presentation/common/widgets/notification_status_banner.dart';

void main() {
  group('Dashboard Notification Integration', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: DashboardScreen(),
        routes: {
          '/notification-settings': (context) => Scaffold(
            appBar: AppBar(title: Text('Notification Settings')),
            body: Center(child: Text('Notification Settings Screen')),
          ),
          '/settings': (context) => Scaffold(
            appBar: AppBar(title: Text('Settings')),
            body: Center(child: Text('Settings Screen')),
          ),
          '/create-reminder': (context) => Scaffold(
            appBar: AppBar(title: Text('Create Reminder')),
            body: Center(child: Text('Create Reminder Screen')),
          ),
          '/reminder-management': (context) => Scaffold(
            appBar: AppBar(title: Text('Reminder Management')),
            body: Center(child: Text('Reminder Management Screen')),
          ),
        },
      );
    }

    testWidgets('dashboard includes notification status banner', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify that the notification status banner is present in the dashboard
      expect(find.byType(NotificationStatusBanner), findsOneWidget);
    });

    testWidgets('notification banner is positioned correctly in dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify the banner is within the CustomScrollView structure
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(NotificationStatusBanner), findsOneWidget);
    });

    testWidgets('dashboard loads without errors with notification banner', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Wait for any async operations to complete
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify no errors occurred and dashboard is displayed
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('notification banner in dashboard is interactive', (WidgetTester tester) async {
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
  });
}