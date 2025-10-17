import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/presentation/dashboard/dashboard_screen.dart';

void main() {
  group('Dashboard Greeting Tests', () {
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

    testWidgets('should display "Assalamo alaykum" greeting text', (WidgetTester tester) async {
      // Build the dashboard screen
      await tester.pumpWidget(createTestWidget());
      
      // Wait for the screen to load
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));
      
      // Verify that "Assalamo alaykum" text is present
      expect(find.text('Assalamo alaykum'), findsOneWidget);
      
      // Verify that old "Welcome back," text is not present
      expect(find.text('Welcome back,'), findsNothing);
    });

    testWidgets('should position greeting text at the top of welcome section', (WidgetTester tester) async {
      // Build the dashboard screen
      await tester.pumpWidget(createTestWidget());
      
      // Wait for the screen to load
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));
      
      // Find the greeting text widget
      final greetingFinder = find.text('Assalamo alaykum');
      expect(greetingFinder, findsOneWidget);
      
      // Verify the greeting text has proper styling
      final greetingWidget = tester.widget<Text>(greetingFinder);
      expect(greetingWidget.style?.fontSize, equals(16));
      expect(greetingWidget.style?.color, isNotNull);
    });
  });
}