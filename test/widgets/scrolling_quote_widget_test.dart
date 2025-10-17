import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/scrolling_quote_widget.dart';

void main() {
  group('ScrollingQuoteWidget', () {
    tearDown(() async {
      // Clean up any pending timers after each test
      await Future.delayed(Duration.zero);
    });
    testWidgets('should display first quote initially', (WidgetTester tester) async {
      const quotes = [
        "Whoever has done an atom's weight of good will see it. 99:7",
        "And remind, for the reminder benefits the believers. 51:55",
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(seconds: 1),
              scrollDuration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Should display the first quote initially
      expect(find.text(quotes[0]), findsOneWidget);
      expect(find.text(quotes[1]), findsNothing);
    });

    testWidgets('should animate to second quote after display duration', (WidgetTester tester) async {
      const quotes = [
        "Whoever has done an atom's weight of good will see it. 99:7",
        "And remind, for the reminder benefits the believers. 51:55",
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 500),
              scrollDuration: Duration(milliseconds: 200),
            ),
          ),
        ),
      );

      // Initially shows first quote
      expect(find.text(quotes[0]), findsOneWidget);

      // Wait for display duration + animation time
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Should now show second quote
      expect(find.text(quotes[1]), findsOneWidget);
    });

    testWidgets('should cycle back to first quote after showing all quotes', (WidgetTester tester) async {
      const quotes = [
        "First quote",
        "Second quote",
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 300),
              scrollDuration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Initially shows first quote
      expect(find.text(quotes[0]), findsOneWidget);

      // Wait for first cycle (display + animation)
      await tester.pump(Duration(milliseconds: 300));
      await tester.pump(Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Should show second quote
      expect(find.text(quotes[1]), findsOneWidget);

      // Wait for second cycle
      await tester.pump(Duration(milliseconds: 300));
      await tester.pump(Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Should cycle back to first quote
      expect(find.text(quotes[0]), findsOneWidget);
    });

    testWidgets('should apply custom text style', (WidgetTester tester) async {
      const quotes = ["Test quote"];
      const customStyle = TextStyle(
        fontSize: 24,
        color: Colors.red,
        fontWeight: FontWeight.bold,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              textStyle: customStyle,
              displayDuration: Duration(milliseconds: 100), // Short duration for testing
              scrollDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text(quotes[0]));
      expect(textWidget.style?.fontSize, equals(24));
      expect(textWidget.style?.color, equals(Colors.red));
      expect(textWidget.style?.fontWeight, equals(FontWeight.bold));
      
      // Clean up by removing the widget
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pumpAndSettle();
    });

    testWidgets('should use default text style when none provided', (WidgetTester tester) async {
      const quotes = ["Test quote"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 100), // Short duration for testing
              scrollDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text(quotes[0]));
      expect(textWidget.style?.fontSize, equals(18));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w400));
      expect(textWidget.textAlign, equals(TextAlign.center));
      
      // Clean up by removing the widget
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle empty quotes list gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: [],
            ),
          ),
        ),
      );

      // Should not crash and should show empty text
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('should handle single quote without cycling', (WidgetTester tester) async {
      const quotes = ["Single quote"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 100),
              scrollDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      // Should show the single quote
      expect(find.text(quotes[0]), findsOneWidget);

      // Wait for display duration + animation
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Should still show the same quote (cycling back to itself)
      expect(find.text(quotes[0]), findsOneWidget);
      
      // Clean up by removing the widget
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pumpAndSettle();
    });

    testWidgets('should properly dispose animation controller', (WidgetTester tester) async {
      const quotes = ["Test quote"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 100),
              scrollDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      // Widget should be present
      expect(find.byType(ScrollingQuoteWidget), findsOneWidget);

      // Remove the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not crash when disposing
      expect(find.byType(ScrollingQuoteWidget), findsNothing);
    });

    testWidgets('should have proper animation transitions', (WidgetTester tester) async {
      const quotes = ["First", "Second"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 100),
              scrollDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      // Find the FadeTransition and SlideTransition widgets
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      // Initially should be visible
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fadeTransition.opacity, isNotNull);

      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));
      expect(slideTransition.position, isNotNull);
      
      // Clean up by removing the widget
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pumpAndSettle();
    });

    testWidgets('should start with fade animation at beginning', (WidgetTester tester) async {
      const quotes = ["Test quote"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(seconds: 1),
              scrollDuration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Get the fade transition at the start
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      
      // Animation should be progressing from 0 to 1
      expect(fadeTransition.opacity.value, greaterThanOrEqualTo(0.0));
      expect(fadeTransition.opacity.value, lessThanOrEqualTo(1.0));
      
      // Clean up
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pumpAndSettle();
    });

    testWidgets('should complete fade-in animation', (WidgetTester tester) async {
      const quotes = ["Test quote"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(seconds: 1),
              scrollDuration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pump(Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Animation should be at full opacity
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      expect(fadeTransition.opacity.value, equals(1.0));
      
      // Clean up
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pumpAndSettle();
    });

    testWidgets('should have correct slide animation offset', (WidgetTester tester) async {
      const quotes = ["Test quote"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(seconds: 1),
              scrollDuration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Get the slide transition
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));
      
      // Position should be animating from (0, 0.3) to (0, 0)
      expect(slideTransition.position.value.dx, equals(0.0));
      expect(slideTransition.position.value.dy, greaterThanOrEqualTo(0.0));
      expect(slideTransition.position.value.dy, lessThanOrEqualTo(0.3));
      
      // Clean up
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pumpAndSettle();
    });

    testWidgets('should handle animation controller lifecycle properly', (WidgetTester tester) async {
      const quotes = ["First", "Second"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 200),
              scrollDuration: Duration(milliseconds: 100),
            ),
          ),
        ),
      );

      // Widget should be present with animations
      expect(find.byType(ScrollingQuoteWidget), findsOneWidget);
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      // Wait for one complete cycle
      await tester.pump(Duration(milliseconds: 200)); // Display duration
      await tester.pump(Duration(milliseconds: 100)); // Animation duration
      await tester.pumpAndSettle();

      // Should still be working after one cycle
      expect(find.byType(ScrollingQuoteWidget), findsOneWidget);
      expect(find.text("Second"), findsOneWidget);

      // Clean up - this should not throw any errors
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pumpAndSettle();

      // Widget should be disposed without errors
      expect(find.byType(ScrollingQuoteWidget), findsNothing);
    });

    testWidgets('should maintain animation state during quote transitions', (WidgetTester tester) async {
      const quotes = ["Quote 1", "Quote 2", "Quote 3"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 150),
              scrollDuration: Duration(milliseconds: 75),
            ),
          ),
        ),
      );

      // Initially shows first quote
      expect(find.text("Quote 1"), findsOneWidget);

      // Wait for first transition
      await tester.pump(Duration(milliseconds: 150)); // Display time
      await tester.pump(Duration(milliseconds: 75));  // Animation time
      await tester.pumpAndSettle();

      // Should show second quote
      expect(find.text("Quote 2"), findsOneWidget);
      expect(find.text("Quote 1"), findsNothing);

      // Verify animations are still active
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      // Wait for second transition
      await tester.pump(Duration(milliseconds: 150));
      await tester.pump(Duration(milliseconds: 75));
      await tester.pumpAndSettle();

      // Should show third quote
      expect(find.text("Quote 3"), findsOneWidget);
      expect(find.text("Quote 2"), findsNothing);

      // Clean up
      await tester.pumpWidget(MaterialApp(home: Container()));
      await tester.pumpAndSettle();
    });
  });
}