import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../../lib/core/models/completion_context.dart';
import '../../../../lib/presentation/completion_celebration/widgets/completion_context_widget.dart';
import '../../../../lib/theme/app_theme.dart';

void main() {
  group('CompletionContextWidget', () {
    Widget createTestWidget({CompletionContext? completionContext, bool showAnimation = false}) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CompletionContextWidget(
                context: completionContext,
                showAnimation: showAnimation,
              ),
            ),
          );
        },
      );
    }

    group('Widget Rendering', () {
      testWidgets('should render with default context when no context provided', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Your Achievement'), findsOneWidget);
        expect(find.text('General'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should render with provided context', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Morning Prayer',
          reminderCategory: 'Prayer',
          completionTime: DateTime.now().subtract(Duration(minutes: 30)),
          completionNotes: 'Felt peaceful and focused',
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('Completed'), findsOneWidget);
        expect(find.text('Morning Prayer'), findsOneWidget);
        expect(find.text('Prayer'), findsOneWidget);
        expect(find.text('30 minutes ago'), findsOneWidget);
        expect(find.text('Felt peaceful and focused'), findsOneWidget);
      });

      testWidgets('should display duration when available', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Quran Reading',
          reminderCategory: 'Reading',
          completionTime: DateTime.now(),
          actualDuration: Duration(minutes: 25),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('25m'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });

      testWidgets('should display notes section when notes are provided', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Evening Dhikr',
          reminderCategory: 'Dhikr',
          completionTime: DateTime.now(),
          completionNotes: 'Recited 100 times SubhanAllah',
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('Notes'), findsOneWidget);
        expect(find.text('Recited 100 times SubhanAllah'), findsOneWidget);
        expect(find.byIcon(Icons.note), findsOneWidget);
      });

      testWidgets('should not display notes section when notes are empty', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Test Reminder',
          reminderCategory: 'General',
          completionTime: DateTime.now(),
          completionNotes: '',
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('Notes'), findsNothing);
      });

      testWidgets('should display fallback message for incomplete context', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: '',
          reminderCategory: 'General',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('Some details may be missing, but your achievement still counts!'), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);
      });
    });

    group('Category Icons', () {
      testWidgets('should display correct icon for prayer category', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Fajr Prayer',
          reminderCategory: 'Prayer',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        // The mosque icon should be displayed for prayer category
        expect(find.text('Prayer'), findsOneWidget);
      });

      testWidgets('should display correct icon for quran category', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Daily Quran',
          reminderCategory: 'Quran',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('Quran'), findsOneWidget);
      });

      testWidgets('should display default icon for unknown category', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Custom Task',
          reminderCategory: 'Unknown Category',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('Unknown Category'), findsOneWidget);
      });
    });

    group('Time Formatting', () {
      testWidgets('should display "Just now" for recent completion', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Recent Task',
          reminderCategory: 'General',
          completionTime: DateTime.now().subtract(Duration(seconds: 30)),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('Just now'), findsOneWidget);
      });

      testWidgets('should display minutes ago for completion within an hour', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Recent Task',
          reminderCategory: 'General',
          completionTime: DateTime.now().subtract(Duration(minutes: 15)),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('15 minutes ago'), findsOneWidget);
      });

      testWidgets('should display hours ago for completion within a day', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Earlier Task',
          reminderCategory: 'General',
          completionTime: DateTime.now().subtract(Duration(hours: 3)),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('3 hours ago'), findsOneWidget);
      });
    });

    group('Duration Formatting', () {
      testWidgets('should format hours and minutes correctly', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Long Task',
          reminderCategory: 'Study',
          completionTime: DateTime.now(),
          actualDuration: Duration(hours: 2, minutes: 30),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('2h 30m'), findsOneWidget);
      });

      testWidgets('should format hours only when no minutes', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Hour Task',
          reminderCategory: 'Study',
          completionTime: DateTime.now(),
          actualDuration: Duration(hours: 1),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('1h'), findsOneWidget);
      });

      testWidgets('should format minutes only when less than an hour', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Short Task',
          reminderCategory: 'General',
          completionTime: DateTime.now(),
          actualDuration: Duration(minutes: 45),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('45m'), findsOneWidget);
      });

      testWidgets('should format seconds when less than a minute', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Quick Task',
          reminderCategory: 'General',
          completionTime: DateTime.now(),
          actualDuration: Duration(seconds: 30),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('30s'), findsOneWidget);
      });
    });

    group('Animation', () {
      testWidgets('should render without animation when showAnimation is false', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Test Task',
          reminderCategory: 'General',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext, showAnimation: false));
        
        // Should be immediately visible without animation
        expect(find.text('Test Task'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });

      testWidgets('should animate when showAnimation is true', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Animated Task',
          reminderCategory: 'General',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext, showAnimation: true));
        
        // Initially might not be fully visible due to animation
        await tester.pump();
        
        // After animation completes, should be visible
        await tester.pumpAndSettle();
        expect(find.text('Animated Task'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
      });
    });

    group('Widget Structure', () {
      testWidgets('should have proper container decoration', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(CompletionContextWidget),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.decoration, isA<BoxDecoration>());
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.gradient, isNotNull);
        expect(decoration.borderRadius, isNotNull);
        expect(decoration.border, isNotNull);
        expect(decoration.boxShadow, isNotNull);
      });

      testWidgets('should have proper text styling', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Styled Task',
          reminderCategory: 'General',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        final titleText = tester.widget<Text>(find.text('Styled Task'));
        expect(titleText.style?.fontWeight, FontWeight.w700);
        expect(titleText.style?.color, AppTheme.primaryLight);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null completion notes gracefully', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'No Notes Task',
          reminderCategory: 'General',
          completionTime: DateTime.now(),
          completionNotes: null,
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.text('Notes'), findsNothing);
        expect(find.text('No Notes Task'), findsOneWidget);
      });

      testWidgets('should handle very long reminder titles', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'This is a very long reminder title that might overflow the container and cause layout issues',
          reminderCategory: 'General',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.textContaining('This is a very long reminder title'), findsOneWidget);
      });

      testWidgets('should handle very long category names', (tester) async {
        final completionContext = CompletionContext(
          reminderTitle: 'Test Task',
          reminderCategory: 'Very Long Category Name That Might Cause Issues',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(completionContext: completionContext));
        await tester.pumpAndSettle();

        expect(find.textContaining('Very Long Category Name'), findsOneWidget);
      });
    });
  });
}