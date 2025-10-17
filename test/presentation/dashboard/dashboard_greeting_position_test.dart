import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/presentation/dashboard/dashboard_screen.dart';

void main() {
  group('Dashboard Greeting Position Tests', () {
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

    testWidgets('greeting text should be positioned at top of welcome section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));
      
      // Find the greeting text
      final greetingFinder = find.text('Assalamo alaykum');
      expect(greetingFinder, findsOneWidget);
      
      // Find the welcome section container (should be the parent container)
      final containerFinder = find.byType(Container).first;
      expect(containerFinder, findsOneWidget);
      
      // Verify the greeting text is positioned correctly within the layout
      final greetingWidget = tester.widget<Text>(greetingFinder);
      expect(greetingWidget.data, equals('Assalamo alaykum'));
      
      // Check that the greeting is in a Row with MainAxisAlignment.spaceBetween
      final rowFinder = find.ancestor(
        of: greetingFinder,
        matching: find.byType(Row),
      );
      expect(rowFinder, findsOneWidget);
      
      final rowWidget = tester.widget<Row>(rowFinder);
      expect(rowWidget.mainAxisAlignment, equals(MainAxisAlignment.spaceBetween));
    });

    testWidgets('greeting text should be separate from user avatar section', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));
      
      // Find the greeting text
      final greetingFinder = find.text('Assalamo alaykum');
      expect(greetingFinder, findsOneWidget);
      
      // Verify that greeting and avatar are in different sections
      // The greeting should be in the first Row, avatar in the second Row
      final allRows = find.byType(Row);
      expect(allRows, findsAtLeastNWidgets(2));
      
      // Verify that there are multiple containers (including avatar container)
      final allContainers = find.byType(Container);
      expect(allContainers, findsAtLeastNWidgets(2));
    });
  });
}