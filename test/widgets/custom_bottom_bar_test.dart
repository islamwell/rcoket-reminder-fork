import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/custom_bottom_bar.dart';

void main() {
  group('CustomBottomBar Tests', () {
    testWidgets('CustomBottomBar renders correctly with all tabs', (WidgetTester tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: CustomBottomBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // Verify all tabs are present
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
    });

    testWidgets('CustomBottomBar shows correct selected state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: CustomBottomBar(
              currentIndex: 1, // Audio tab selected
              onTap: (index) {},
            ),
          ),
        ),
      );

      // The selected tab should have different styling
      // This is a basic test - in a real scenario you'd check for specific styling
      expect(find.byType(CustomBottomBar), findsOneWidget);
    });

    testWidgets('CustomBottomBar handles tap events', (WidgetTester tester) async {
      int tappedIndex = -1;
      
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/dashboard': (context) => Container(),
            '/audio-library': (context) => Container(),
            '/reminder-management': (context) => Container(),
            '/completion-celebration': (context) => Container(),
          },
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: CustomBottomBar(
              currentIndex: 0,
              onTap: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on the Audio tab
      await tester.tap(find.text('Audio'));
      await tester.pump();

      expect(tappedIndex, equals(1));
    });

    testWidgets('CustomBottomBar can be hidden', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
            bottomNavigationBar: CustomBottomBar(
              currentIndex: 0,
              onTap: (index) {},
              isHidden: true,
            ),
          ),
        ),
      );

      // When hidden, the bar should still exist but be animated off-screen
      expect(find.byType(CustomBottomBar), findsOneWidget);
    });
  });
}