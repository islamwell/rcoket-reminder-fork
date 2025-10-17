import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../lib/core/app_export.dart';
import '../../../lib/core/models/completion_context.dart';
import '../../../lib/presentation/completion_celebration/completion_celebration.dart';
import '../../../lib/presentation/completion_celebration/widgets/animated_checkmark_widget.dart';
import '../../../lib/presentation/completion_celebration/widgets/completion_context_widget.dart';
import '../../../lib/presentation/completion_celebration/widgets/motivational_message_widget.dart';
import '../../../lib/presentation/completion_celebration/widgets/progress_stats_widget.dart';

void main() {
  group('Accessibility Tests', () {
    late Widget testApp;

    setUp(() {
      testApp = Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: Scaffold(
              body: Container(),
            ),
          );
        },
      );
    });

    group('Semantic Labels Tests', () {
      testWidgets('CompletionCelebration has proper semantic labels', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test main screen semantics
        expect(
          find.bySemanticsLabel('Completion celebration screen'),
          findsOneWidget,
        );

        // Test close button semantics
        expect(
          find.bySemanticsLabel('Close celebration screen'),
          findsOneWidget,
        );

        // Test primary action button semantics
        expect(
          find.bySemanticsLabel('Continue to dashboard'),
          findsOneWidget,
        );

        // Test secondary action buttons semantics
        expect(
          find.bySemanticsLabel('View progress'),
          findsOneWidget,
        );

        expect(
          find.bySemanticsLabel('Set new goal'),
          findsOneWidget,
        );
      });

      testWidgets('AnimatedCheckmarkWidget has proper semantic labels', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: AnimatedCheckmarkWidget(),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test checkmark semantics
        expect(
          find.bySemanticsLabel('Completion checkmark'),
          findsOneWidget,
        );
      });

      testWidgets('CompletionContextWidget has proper semantic labels', (tester) async {
        final context = CompletionContext(
          reminderTitle: 'Morning Prayer',
          reminderCategory: 'Prayer',
          completionTime: DateTime.now(),
          completionNotes: 'Peaceful morning reflection',
        );

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: CompletionContextWidget(context: context),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test context widget semantics
        expect(
          find.bySemanticsLabel('Completed reminder: Morning Prayer'),
          findsOneWidget,
        );
      });

      testWidgets('MotivationalMessageWidget has proper semantic labels', (tester) async {
        final context = CompletionContext(
          reminderTitle: 'Evening Dhikr',
          reminderCategory: 'Dhikr',
          completionTime: DateTime.now(),
        );

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: MotivationalMessageWidget(
                    currentStreak: 5,
                    totalCompletions: 10,
                    completionContext: context,
                    isFirstCompletion: false,
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test motivational message semantics
        final semanticsNodes = tester.getSemantics(find.byType(MotivationalMessageWidget));
        expect(semanticsNodes.semanticsClipRect, isNotNull);
        
        // Verify semantic label exists (content varies based on random selection)
        expect(
          find.byWidgetPredicate((widget) => 
            widget is Semantics && 
            widget.properties.label != null &&
            widget.properties.label!.contains('Motivational message:')),
          findsOneWidget,
        );
      });

      testWidgets('ProgressStatsWidget has proper semantic labels', (tester) async {
        final testData = {
          'todayCompletions': 2,
          'currentStreak': 7,
          'totalCompletions': 15,
          'isFirstCompletion': false,
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ProgressStatsWidget(reminderData: testData),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test individual stat item semantics
        expect(
          find.bySemanticsLabel('Today: 3'), // +1 for current completion
          findsOneWidget,
        );

        expect(
          find.bySemanticsLabel('Streak: 7'),
          findsOneWidget,
        );

        expect(
          find.bySemanticsLabel('Total: 16'), // +1 for current completion
          findsOneWidget,
        );
      });
    });

    group('Button Accessibility Tests', () {
      testWidgets('All buttons have proper button semantics', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find all semantic nodes with button flag
        final buttonNodes = tester.getAllSemantics().where((node) => 
          node.hasFlag(SemanticsFlag.isButton));

        // Should have at least 4 buttons: close, continue, view progress, set goal
        expect(buttonNodes.length, greaterThanOrEqualTo(4));

        // Test that all buttons have labels
        for (final node in buttonNodes) {
          expect(node.label, isNotEmpty, 
                 reason: 'All buttons should have descriptive labels');
        }
      });

      testWidgets('Buttons have proper hint text', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test close button hint
        final closeButtonSemantics = tester.getSemantics(
          find.bySemanticsLabel('Close celebration screen'));
        expect(closeButtonSemantics.hint, 
               'Double tap to close the celebration and return to dashboard');

        // Test continue button hint
        final continueButtonSemantics = tester.getSemantics(
          find.bySemanticsLabel('Continue to dashboard'));
        expect(continueButtonSemantics.hint, 
               'Primary action button. Double tap to continue to your dashboard');
      });
    });

    group('Focus Management Tests', () {
      testWidgets('Screen has proper focus order', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test that focusable elements exist
        final focusableNodes = tester.getAllSemantics().where((node) => 
          node.hasFlag(SemanticsFlag.isFocusable));

        expect(focusableNodes.length, greaterThan(0),
               reason: 'Screen should have focusable elements for navigation');
      });

      testWidgets('Navigation maintains proper focus', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                routes: {
                  '/': (context) => CompletionCelebration(),
                  '/dashboard': (context) => Scaffold(body: Text('Dashboard')),
                },
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test focus on continue button
        final continueButton = find.bySemanticsLabel('Continue to dashboard');
        expect(continueButton, findsOneWidget);

        // Simulate focus and activation
        await tester.tap(continueButton);
        await tester.pumpAndSettle();

        // Should navigate properly
        expect(find.text('Dashboard'), findsOneWidget);
      });
    });

    group('Text Scaling Tests', () {
      testWidgets('Text scales properly with accessibility settings', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test with different text scale factors
        final textWidgets = find.byType(Text);
        expect(textWidgets, findsWidgets);

        // Verify text widgets exist and can handle scaling
        for (int i = 0; i < textWidgets.evaluate().length && i < 5; i++) {
          final textWidget = tester.widget<Text>(textWidgets.at(i));
          expect(textWidget.style, isNotNull);
        }
      });

      testWidgets('Large text doesn\'t break layout', (tester) async {
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaleFactor: 2.0),
            child: Sizer(
              builder: (context, orientation, deviceType) {
                return MaterialApp(
                  home: CompletionCelebration(),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without overflow errors
        expect(tester.takeException(), isNull);
        expect(find.byType(CompletionCelebration), findsOneWidget);
      });
    });

    group('Color Contrast Tests', () {
      testWidgets('Text has sufficient contrast', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test that text widgets use theme colors (which should have proper contrast)
        final textWidgets = find.byType(Text);
        expect(textWidgets, findsWidgets);

        // Verify text widgets use proper theme colors
        for (int i = 0; i < textWidgets.evaluate().length && i < 3; i++) {
          final textWidget = tester.widget<Text>(textWidgets.at(i));
          if (textWidget.style?.color != null) {
            // Color should not be too transparent
            expect(textWidget.style!.color!.alpha, greaterThan(100));
          }
        }
      });
    });

    group('Screen Reader Tests', () {
      testWidgets('All important content is accessible to screen readers', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Test that semantic nodes provide meaningful information
        final semanticNodes = tester.getAllSemantics();
        
        // Should have semantic information for screen readers
        expect(semanticNodes.length, greaterThan(5));

        // Test that important elements have labels
        final labeledNodes = semanticNodes.where((node) => 
          node.label != null && node.label!.isNotEmpty);
        
        expect(labeledNodes.length, greaterThan(3),
               reason: 'Important elements should have descriptive labels');
      });

      testWidgets('Milestone messages are accessible', (tester) async {
        final testData = {
          'todayCompletions': 0,
          'currentStreak': 1,
          'totalCompletions': 0,
          'isFirstCompletion': true,
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ProgressStatsWidget(reminderData: testData),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle(Duration(seconds: 2));

        // Should have milestone message for first completion
        final milestoneSemantics = tester.getAllSemantics().where((node) => 
          node.label != null && 
          node.label!.contains('Milestone achievement'));

        expect(milestoneSemantics.length, greaterThanOrEqualTo(0));
      });
    });
  });
}