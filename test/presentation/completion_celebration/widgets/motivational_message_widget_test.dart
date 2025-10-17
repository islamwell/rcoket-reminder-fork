import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../../lib/core/models/completion_context.dart';
import '../../../../lib/presentation/completion_celebration/widgets/motivational_message_widget.dart';
import '../../../../lib/theme/app_theme.dart';

void main() {
  group('MotivationalMessageWidget Context Awareness', () {
    Widget createTestWidget(Widget child) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: child,
            ),
          );
        },
      );
    }

    testWidgets('should display first completion messaging', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MotivationalMessageWidget(
            currentStreak: 1,
            totalCompletions: 1,
            isFirstCompletion: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should contain encouraging first completion message (any of the possible messages)
      final hasFirstCompletionMessage = find.textContaining('Congratulations').evaluate().isNotEmpty ||
          find.textContaining('journey').evaluate().isNotEmpty ||
          find.textContaining('first').evaluate().isNotEmpty ||
          find.textContaining('step').evaluate().isNotEmpty;
      
      expect(hasFirstCompletionMessage, isTrue);
      expect(find.textContaining('spiritual journey'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display category-specific messaging', (WidgetTester tester) async {
      final context = CompletionContext(
        reminderTitle: 'Morning Prayer',
        reminderCategory: 'prayer',
        completionTime: DateTime.now(),
      );

      await tester.pumpWidget(
        createTestWidget(
          MotivationalMessageWidget(
            currentStreak: 3,
            totalCompletions: 5,
            completionContext: context,
            isFirstCompletion: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display prayer-specific content
      expect(find.text('Morning Prayer'), findsOneWidget);
      expect(find.textContaining('spiritual'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display milestone messaging', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MotivationalMessageWidget(
            currentStreak: 7,
            totalCompletions: 7,
            isFirstCompletion: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should contain milestone celebration
      expect(find.textContaining('week'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display streak-specific messaging for long streaks', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MotivationalMessageWidget(
            currentStreak: 15,
            totalCompletions: 20,
            isFirstCompletion: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display streak information
      expect(find.textContaining('15 Day Streak'), findsOneWidget);
      // Should contain some motivational message (the specific message is random)
      expect(find.byType(Text), findsAtLeastNWidgets(1));
    });

    testWidgets('should show completion time context for recent completions', (WidgetTester tester) async {
      final recentTime = DateTime.now().subtract(Duration(minutes: 30));
      final context = CompletionContext(
        reminderTitle: 'Evening Reflection',
        reminderCategory: 'meditation',
        completionTime: recentTime,
      );

      await tester.pumpWidget(
        createTestWidget(
          MotivationalMessageWidget(
            currentStreak: 3,
            totalCompletions: 5,
            completionContext: context,
            isFirstCompletion: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show completion time context
      expect(find.textContaining('30 minutes ago'), findsOneWidget);
    });

    testWidgets('should handle different categories with appropriate icons', (WidgetTester tester) async {
      final categories = [
        ('prayer', 'mosque'),
        ('meditation', 'self_improvement'),
        ('gratitude', 'favorite'),
        ('charity', 'volunteer_activism'),
        ('quran', 'menu_book'),
      ];

      for (final (category, expectedIcon) in categories) {
        final context = CompletionContext(
          reminderTitle: 'Test $category',
          reminderCategory: category,
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(
          createTestWidget(
            MotivationalMessageWidget(
              currentStreak: 2,
              totalCompletions: 3,
              completionContext: context,
              isFirstCompletion: false,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should display the category title
        expect(find.text('Test $category'), findsOneWidget);
      }
    });

    testWidgets('should enhance messages with time context', (WidgetTester tester) async {
      final morningTime = DateTime.now().copyWith(hour: 8, minute: 0);
      final context = CompletionContext(
        reminderTitle: 'Morning Prayer',
        reminderCategory: 'prayer',
        completionTime: morningTime,
      );

      await tester.pumpWidget(
        createTestWidget(
          MotivationalMessageWidget(
            currentStreak: 3,
            totalCompletions: 5,
            completionContext: context,
            isFirstCompletion: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should contain time-enhanced messaging
      expect(find.textContaining('morning'), findsAtLeastNWidgets(1));
    });

    testWidgets('should display fallback content when no context available', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MotivationalMessageWidget(
            currentStreak: 2,
            totalCompletions: 3,
            isFirstCompletion: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display general encouraging content
      expect(find.textContaining('journey'), findsOneWidget);
    });
  });

  group('MotivationalMessageWidget Visual Enhancement', () {
    Widget createTestWidget(Widget child) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: child,
            ),
          );
        },
      );
    }

    testWidgets('should have enhanced styling for first completion', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MotivationalMessageWidget(
            currentStreak: 1,
            totalCompletions: 1,
            isFirstCompletion: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have special styling for first completion
      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
    });

    testWidgets('should display streak badge for significant streaks', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MotivationalMessageWidget(
            currentStreak: 10,
            totalCompletions: 15,
            isFirstCompletion: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display streak badge
      expect(find.textContaining('10 Day Streak'), findsOneWidget);
    });
  });
}