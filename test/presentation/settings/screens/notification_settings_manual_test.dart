import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/presentation/settings/screens/notification_settings_screen.dart';
import '../../../../lib/routes/app_routes.dart';

/// Manual test for NotificationSettingsScreen
/// Run this test to verify the UI components are rendered correctly
void main() {
  group('NotificationSettingsScreen Manual Tests', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      // Create test app with routes
      final app = MaterialApp(
        home: NotificationSettingsScreen(),
        routes: AppRoutes.routes,
      );

      // Pump the widget
      await tester.pumpWidget(app);
      
      // Verify the screen loads
      expect(find.byType(NotificationSettingsScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has required UI elements', (WidgetTester tester) async {
      final app = MaterialApp(
        home: NotificationSettingsScreen(),
        routes: AppRoutes.routes,
      );

      await tester.pumpWidget(app);
      await tester.pump(Duration(seconds: 1)); // Give time for initial load

      // Check for key UI elements
      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}

/// Test runner for manual verification
/// This can be run to manually verify the screen works
class NotificationSettingsTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Settings Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NotificationSettingsScreen(),
      routes: AppRoutes.routes,
    );
  }
}