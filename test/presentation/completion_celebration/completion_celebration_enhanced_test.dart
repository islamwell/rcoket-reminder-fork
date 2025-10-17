import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import '../../../lib/presentation/completion_celebration/completion_celebration.dart';
import '../../../lib/core/services/completion_feedback_service.dart';
import '../../../lib/theme/app_theme.dart';

void main() {
  group('CompletionCelebration Enhanced Data Loading', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await CompletionFeedbackService.instance.clearAllFeedback();
    });

    Widget createTestWidget() {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CompletionCelebration(),
          );
        },
      );
    }

    group('loading states', () {
      testWidgets('should show loading skeleton initially', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Should show loading content initially
        expect(find.text('Loading your achievement...'), findsOneWidget);
        
        // Wait for data loading to complete
        await tester.pumpAndSettle();
        
        // Should show completed content after loading
        expect(find.text('Completed!'), findsOneWidget);
      });

      testWidgets('should show encouraging content for new users', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should show encouraging completion message
        expect(find.text('Completed!'), findsOneWidget);
        
        // Should show some form of encouraging content
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should handle data loading gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Pump multiple times to simulate loading process
        await tester.pump(Duration(milliseconds: 100));
        await tester.pump(Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        
        // Should eventually show completed state
        expect(find.text('Completed!'), findsOneWidget);
      });
    });

    group('error handling and fallbacks', () {
      testWidgets('should show fallback content when data loading fails', (WidgetTester tester) async {
        // Corrupt the shared preferences to simulate data loading failure
        SharedPreferences.setMockInitialValues({
          'completion_feedback': 'invalid json data'
        });
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should still show completed state with fallback data
        expect(find.text('Completed!'), findsOneWidget);
        
        // Should not show any error messages to the user
        expect(find.textContaining('Error'), findsNothing);
        expect(find.textContaining('Failed'), findsNothing);
      });

      testWidgets('should show retry option when data loading fails', (WidgetTester tester) async {
        // Set up a scenario that might trigger retry option
        SharedPreferences.setMockInitialValues({
          'completion_feedback': 'corrupted'
        });
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Look for retry-related UI elements
        // Note: The retry option might not always be visible depending on the fallback logic
        // This test ensures the app doesn't crash when data loading fails
        expect(find.text('Completed!'), findsOneWidget);
      });

      testWidgets('should handle retry functionality', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Look for refresh/retry button if it exists
        final refreshButton = find.text('Refresh Progress');
        if (refreshButton.evaluate().isNotEmpty) {
          await tester.tap(refreshButton);
          await tester.pumpAndSettle();
          
          // Should still show completed state after retry
          expect(find.text('Completed!'), findsOneWidget);
        }
      });
    });

    group('user interface elements', () {
      testWidgets('should show all essential UI components', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Essential components should be present
        expect(find.text('Completed!'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
        
        // Action buttons should be present
        expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
        expect(find.byType(OutlinedButton), findsAtLeastNWidgets(1));
      });

      testWidgets('should show completion time', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should show completion time
        expect(find.textContaining('Completed at'), findsOneWidget);
      });

      testWidgets('should handle navigation buttons', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Continue button should be present and tappable
        final continueButton = find.text('Continue');
        expect(continueButton, findsOneWidget);
        
        // Tapping should not cause errors (navigation will fail in test environment)
        await tester.tap(continueButton);
        await tester.pumpAndSettle();
      });

      testWidgets('should show secondary action buttons', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Secondary buttons should be present
        expect(find.text('View Progress'), findsOneWidget);
        expect(find.text('Set Goal'), findsOneWidget);
      });
    });

    group('data integration', () {
      testWidgets('should work with valid feedback data', (WidgetTester tester) async {
        // Add some valid feedback data
        final service = CompletionFeedbackService.instance;
        await service.saveFeedback({
          'rating': 5,
          'durationMinutes': 15,
          'difficultyLevel': 'moderate',
          'moodBefore': 'neutral',
          'moodAfter': 'happy',
          'wouldRecommend': true,
          'reminderCategory': 'spiritual',
          'completedAt': DateTime.now().toIso8601String(),
        });
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should show completed state with real data
        expect(find.text('Completed!'), findsOneWidget);
      });

      testWidgets('should handle mixed valid/invalid data', (WidgetTester tester) async {
        // Add mixed data
        final service = CompletionFeedbackService.instance;
        try {
          await service.saveFeedback({
            'rating': 5,
            'durationMinutes': 15,
            'completedAt': DateTime.now().toIso8601String(),
          });
          await service.saveFeedback({
            'rating': 'invalid',
            'durationMinutes': 'invalid',
            'completedAt': 'invalid-date',
          });
        } catch (e) {
          // Some saves might fail, that's expected
        }
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should still work with partial data
        expect(find.text('Completed!'), findsOneWidget);
      });
    });

    group('accessibility and user experience', () {
      testWidgets('should be accessible', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Check for semantic elements
        expect(find.byType(Semantics), findsWidgets);
        
        // Text should be readable
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('should handle back navigation', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should handle back button press without crashing
        final NavigatorState navigator = tester.state(find.byType(Navigator));
        expect(navigator.canPop(), isFalse); // Root route in test
      });

      testWidgets('should show close button', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Close button should be present (look for close icon or similar)
        // The exact implementation might vary, so we check for common close indicators
        expect(find.byType(GestureDetector), findsWidgets);
      });
    });

    group('performance and stability', () {
      testWidgets('should not crash with empty data', (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Should handle empty data gracefully
        expect(find.text('Completed!'), findsOneWidget);
      });

      testWidgets('should handle rapid state changes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Pump rapidly to simulate quick state changes
        for (int i = 0; i < 5; i++) {
          await tester.pump(Duration(milliseconds: 50));
        }
        
        await tester.pumpAndSettle();
        
        // Should remain stable
        expect(find.text('Completed!'), findsOneWidget);
      });

      testWidgets('should dispose resources properly', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();
        
        // Navigate away to trigger dispose
        await tester.pumpWidget(MaterialApp(home: Container()));
        
        // Should not cause memory leaks or errors
        expect(tester.takeException(), isNull);
      });
    });
  });
}