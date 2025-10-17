import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/presentation/settings/screens/notification_settings_screen.dart';
import '../../lib/presentation/settings/widgets/permission_request_flow.dart';
import '../../lib/routes/app_routes.dart';

void main() {
  group('Notification Settings Integration Tests', () {
    testWidgets('notification settings screen integrates with app routes', (WidgetTester tester) async {
      // Create test app with full route configuration
      final app = MaterialApp(
        initialRoute: '/notification-settings',
        routes: AppRoutes.routes,
      );

      // Pump the widget
      await tester.pumpWidget(app);
      await tester.pump(Duration(seconds: 1));

      // Verify the screen loads correctly
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.text('Notification Settings'), findsOneWidget);
    });

    testWidgets('permission request flow can be opened from notification settings', (WidgetTester tester) async {
      final app = MaterialApp(
        home: NotificationSettingsScreen(),
        routes: AppRoutes.routes,
      );

      await tester.pumpWidget(app);
      await tester.pump(Duration(seconds: 1));

      // Find and tap the request permissions button (if notifications are disabled)
      final requestButton = find.text('Request Permissions');
      if (tester.any(requestButton)) {
        await tester.tap(requestButton);
        await tester.pumpAndSettle();

        // Verify permission request flow opens
        expect(find.byType(PermissionRequestFlow), findsOneWidget);
        expect(find.text('Setup Permissions'), findsOneWidget);
      }
    });

    testWidgets('troubleshooting dialog opens and closes correctly', (WidgetTester tester) async {
      final app = MaterialApp(
        home: NotificationSettingsScreen(),
        routes: AppRoutes.routes,
      );

      await tester.pumpWidget(app);
      await tester.pump(Duration(seconds: 1));

      // Open troubleshooting dialog
      await tester.tap(find.text('View Troubleshooting Guide'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Troubleshooting Guide'), findsOneWidget);
      expect(find.text('Android Users:'), findsOneWidget);
      expect(find.text('iOS Users:'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Troubleshooting Guide'), findsNothing);
    });

    testWidgets('refresh status button works correctly', (WidgetTester tester) async {
      final app = MaterialApp(
        home: NotificationSettingsScreen(),
        routes: AppRoutes.routes,
      );

      await tester.pumpWidget(app);
      await tester.pump(Duration(seconds: 1));

      // Tap refresh status button
      await tester.tap(find.text('Refresh Status'));
      await tester.pumpAndSettle();

      // Verify the screen still displays correctly after refresh
      expect(find.text('Notification Status'), findsOneWidget);
      expect(find.text('Permission Management'), findsOneWidget);
    });

    testWidgets('navigation back works correctly', (WidgetTester tester) async {
      final app = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/notification-settings'),
              child: Text('Go to Settings'),
            ),
          ),
        ),
        routes: AppRoutes.routes,
      );

      await tester.pumpWidget(app);

      // Navigate to notification settings
      await tester.tap(find.text('Go to Settings'));
      await tester.pumpAndSettle();

      // Verify we're on the notification settings screen
      expect(find.text('Notification Settings'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify we're back to the original screen
      expect(find.text('Go to Settings'), findsOneWidget);
      expect(find.text('Notification Settings'), findsNothing);
    });
  });
}