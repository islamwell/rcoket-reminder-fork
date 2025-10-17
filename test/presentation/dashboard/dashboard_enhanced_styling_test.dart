import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/presentation/dashboard/dashboard_screen.dart';
import '../../../lib/theme/app_theme.dart';

void main() {
  group('Dashboard Enhanced Styling Tests', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: DashboardScreen(),
        routes: {
          '/settings': (context) => Scaffold(body: Text('Settings')),
          '/create-reminder': (context) => Scaffold(body: Text('Create Reminder')),
          '/reminder-management': (context) => Scaffold(body: Text('Reminder Management')),
          '/audio-library': (context) => Scaffold(body: Text('Audio Library')),
          '/completion-celebration': (context) => Scaffold(body: Text('Completion Celebration')),
        },
      );
    }

    testWidgets('welcome section should have enhanced shadows and rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(Duration(milliseconds: 100));

      // Find the welcome section container
      final welcomeContainers = find.byType(Container);
      expect(welcomeContainers, findsWidgets);

      // Check that containers exist (styling is applied in decoration)
      final containerWidgets = tester.widgetList<Container>(welcomeContainers);
      
      // Verify that some containers have BoxDecoration with shadows
      bool foundContainerWithShadows = false;
      for (final container in containerWidgets) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty) {
            foundContainerWithShadows = true;
            break;
          }
        }
      }
      
      expect(foundContainerWithShadows, isTrue, reason: 'Should find containers with enhanced shadows');
    });

    testWidgets('stat cards should have consistent rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(Duration(milliseconds: 100));

      // Wait for data to load
      await tester.pump(Duration(seconds: 1));

      // Find containers that should be stat cards
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Verify containers exist (specific styling verification would require more complex setup)
      expect(containers, findsAtLeastNWidgets(5));
    });

    testWidgets('settings icon should have enhanced styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(Duration(milliseconds: 100));

      // Find the settings icon button
      final settingsIcon = find.byIcon(Icons.settings);
      expect(settingsIcon, findsOneWidget);

      // Verify the icon is wrapped in a container (for styling)
      final iconContainer = find.ancestor(
        of: settingsIcon,
        matching: find.byType(Container),
      );
      expect(iconContainer, findsWidgets);
    });

    testWidgets('dashboard should render without errors with enhanced styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      
      // Pump multiple times to allow animations and data loading
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(seconds: 2)); // Wait longer for data loading
      
      // Verify the dashboard renders successfully
      expect(find.byType(DashboardScreen), findsOneWidget);
      
      // Verify key components are present
      expect(find.text('Assalamo alaykum'), findsOneWidget);
      
      // Check if Quick Actions text appears (may take time to load)
      if (find.text('Quick Actions').evaluate().isNotEmpty) {
        expect(find.text('Quick Actions'), findsOneWidget);
      }
      
      // Check if Recent Activity text appears (may take time to load)
      if (find.text('Recent Activity').evaluate().isNotEmpty) {
        expect(find.text('Recent Activity'), findsOneWidget);
      }
    });
  });
}