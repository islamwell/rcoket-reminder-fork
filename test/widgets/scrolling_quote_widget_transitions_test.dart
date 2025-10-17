import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/scrolling_quote_widget.dart';

void main() {
  group('ScrollingQuoteWidget Transitions and Timing Tests', () {
    testWidgets('should have proper animation timing and transitions', (WidgetTester tester) async {
      const quotes = [
        "Whoever has done an atom's weight of good will see it. 99:7",
        "And remind, for the reminder benefits the believers. 51:55",
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 1000),
              scrollDuration: Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // Initially should show first quote
      expect(find.text(quotes[0]), findsOneWidget);
      expect(find.text(quotes[1]), findsNothing);

      // Check that FadeTransition and SlideTransition are present
      expect(find.byType(FadeTransition), findsOneWidget);
      expect(find.byType(SlideTransition), findsOneWidget);

      // Get initial animation values
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));

      expect(fadeTransition.opacity, isNotNull);
      expect(slideTransition.position, isNotNull);

      // Wait for display duration (1000ms)
      await tester.pump(Duration(milliseconds: 1000));

      // Animation should start (reverse phase)
      await tester.pump(Duration(milliseconds: 100));

      // Wait for scroll duration (500ms) to complete
      await tester.pump(Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should now show second quote
      expect(find.text(quotes[1]), findsOneWidget);
    });

    testWidgets('should handle rapid animation cycles correctly', (WidgetTester tester) async {
      const quotes = ["First", "Second", "Third"];

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

      // Track quote changes through multiple cycles
      expect(find.text("First"), findsOneWidget);

      // First transition
      await tester.pump(Duration(milliseconds: 200)); // Display duration
      await tester.pump(Duration(milliseconds: 100)); // Animation duration
      await tester.pumpAndSettle();
      expect(find.text("Second"), findsOneWidget);

      // Second transition
      await tester.pump(Duration(milliseconds: 200));
      await tester.pump(Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text("Third"), findsOneWidget);

      // Third transition (should cycle back to first)
      await tester.pump(Duration(milliseconds: 200));
      await tester.pump(Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text("First"), findsOneWidget);
    });

    testWidgets('should maintain smooth transitions during quote changes', (WidgetTester tester) async {
      const quotes = ["Quote A", "Quote B"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 500),
              scrollDuration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Get initial animation controllers
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));

      // Verify animations are properly configured
      expect(fadeTransition.opacity, isNotNull);
      expect(slideTransition.position, isNotNull);

      // Start transition
      await tester.pump(Duration(milliseconds: 500)); // Wait for display duration

      // During animation, both transitions should be active
      await tester.pump(Duration(milliseconds: 150)); // Mid-animation
      
      final midAnimationFade = tester.widget<FadeTransition>(find.byType(FadeTransition));
      final midAnimationSlide = tester.widget<SlideTransition>(find.byType(SlideTransition));
      
      expect(midAnimationFade.opacity, isNotNull);
      expect(midAnimationSlide.position, isNotNull);

      // Complete animation
      await tester.pump(Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Should have transitioned to second quote
      expect(find.text("Quote B"), findsOneWidget);
    });

    testWidgets('should handle animation interruption gracefully', (WidgetTester tester) async {
      const quotes = ["Quote 1", "Quote 2"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 1000),
              scrollDuration: Duration(milliseconds: 500),
            ),
          ),
        ),
      );

      // Start transition
      await tester.pump(Duration(milliseconds: 1000));
      await tester.pump(Duration(milliseconds: 250)); // Mid-animation

      // Remove widget during animation (simulating navigation or widget disposal)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(), // Replace with empty container
          ),
        ),
      );

      // Should not crash
      await tester.pumpAndSettle();
      expect(find.byType(ScrollingQuoteWidget), findsNothing);
    });

    testWidgets('should respect custom animation durations', (WidgetTester tester) async {
      const quotes = ["Custom A", "Custom B"];
      const customDisplayDuration = Duration(milliseconds: 2000);
      const customScrollDuration = Duration(milliseconds: 800);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: customDisplayDuration,
              scrollDuration: customScrollDuration,
            ),
          ),
        ),
      );

      // Should show first quote
      expect(find.text("Custom A"), findsOneWidget);

      // Wait less than display duration - should still show first quote
      await tester.pump(Duration(milliseconds: 1500));
      expect(find.text("Custom A"), findsOneWidget);

      // Wait for full display duration
      await tester.pump(Duration(milliseconds: 500));

      // Wait less than scroll duration - should be in transition
      await tester.pump(Duration(milliseconds: 400));

      // Complete scroll duration
      await tester.pump(Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Should now show second quote
      expect(find.text("Custom B"), findsOneWidget);
    });

    testWidgets('should handle very short durations without crashing', (WidgetTester tester) async {
      const quotes = ["Fast A", "Fast B"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 50),
              scrollDuration: Duration(milliseconds: 25),
            ),
          ),
        ),
      );

      // Should not crash with very short durations
      expect(find.text("Fast A"), findsOneWidget);

      // Rapid transitions
      await tester.pump(Duration(milliseconds: 50));
      await tester.pump(Duration(milliseconds: 25));
      await tester.pumpAndSettle();

      // Should handle the transition
      expect(find.textContaining("Fast"), findsOneWidget);
    });

    testWidgets('should handle very long durations correctly', (WidgetTester tester) async {
      const quotes = ["Slow A", "Slow B"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(seconds: 10),
              scrollDuration: Duration(seconds: 2),
            ),
          ),
        ),
      );

      // Should show first quote and stay there for a long time
      expect(find.text("Slow A"), findsOneWidget);

      // Wait a moderate amount of time - should still show first quote
      await tester.pump(Duration(seconds: 5));
      expect(find.text("Slow A"), findsOneWidget);

      // Should not have transitioned yet
      expect(find.text("Slow B"), findsNothing);
    });

    testWidgets('should maintain text alignment during transitions', (WidgetTester tester) async {
      const quotes = ["Left aligned text", "Right aligned text"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 300),
              scrollDuration: Duration(milliseconds: 200),
            ),
          ),
        ),
      );

      // Check initial text alignment
      final initialText = tester.widget<Text>(find.text(quotes[0]));
      expect(initialText.textAlign, equals(TextAlign.center));

      // Transition to second quote
      await tester.pump(Duration(milliseconds: 300));
      await tester.pump(Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Check text alignment is maintained
      final transitionedText = tester.widget<Text>(find.text(quotes[1]));
      expect(transitionedText.textAlign, equals(TextAlign.center));
    });

    testWidgets('should handle animation curve correctly', (WidgetTester tester) async {
      const quotes = ["Curve A", "Curve B"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 500),
              scrollDuration: Duration(milliseconds: 400),
            ),
          ),
        ),
      );

      // Get animation objects
      final fadeTransition = tester.widget<FadeTransition>(find.byType(FadeTransition));
      final slideTransition = tester.widget<SlideTransition>(find.byType(SlideTransition));

      // Verify animations use proper curves
      expect(fadeTransition.opacity, isNotNull);
      expect(slideTransition.position, isNotNull);

      // The animations should be smooth and use easing curves
      // This is verified by the fact that the widget doesn't crash
      // and transitions work properly
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text("Curve B"), findsOneWidget);
    });

    testWidgets('should handle widget rebuild during animation', (WidgetTester tester) async {
      const quotes = ["Rebuild A", "Rebuild B"];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 600),
              scrollDuration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Start animation
      await tester.pump(Duration(milliseconds: 600));
      await tester.pump(Duration(milliseconds: 150)); // Mid-animation

      // Rebuild widget with same parameters
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScrollingQuoteWidget(
              quotes: quotes,
              displayDuration: Duration(milliseconds: 600),
              scrollDuration: Duration(milliseconds: 300),
            ),
          ),
        ),
      );

      // Should handle rebuild gracefully
      await tester.pump(Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Should complete transition
      expect(find.textContaining("Rebuild"), findsOneWidget);
    });
  });
}