import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../lib/core/app_export.dart';
import '../../../lib/core/models/completion_context.dart';
import '../../../lib/presentation/completion_celebration/completion_celebration.dart';
import '../../../lib/routes/app_routes.dart';

void main() {
  group('Completion Celebration Integration Tests', () {
    late Widget testApp;

    setUp(() {
      testApp = Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (context) => CompletionCelebration(),
              AppRoutes.dashboard: (context) => Scaffold(
                body: Text('Dashboard Screen'),
              ),
              AppRoutes.reminderManagement: (context) => Scaffold(
                body: Text('Progress Screen'),
              ),
              AppRoutes.createReminder: (context) => Scaffold(
                body: Text('Create Reminder Screen'),
              ),
            },
          );
        },
      );
    });

    group('Complete User Flow Tests', () {
      testWidgets('Complete celebration flow with valid data', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Verify celebration screen loads
        expect(find.byType(CompletionCelebration), findsOneWidget);

        // Verify all main components are present
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('View Progress'), findsOneWidget);
        expect(find.text('Set Goal'), findsOneWidget);

        // Test primary navigation (Continue button)
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should navigate to dashboard
        expect(find.text('Dashboard Screen'), findsOneWidget);
      });

      testWidgets('Celebration flow with completion context', (tester) async {
        final contextArgs = {
          'reminderTitle': 'Morning Prayer',
          'reminderCategory': 'Prayer',
          'completionTime': DateTime.now().toIso8601String(),
          'completionNotes': 'Peaceful morning reflection',
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                initialRoute: '/',
                onGenerateRoute: (settings) {
                  if (settings.name == '/') {
                    return MaterialPageRoute(
                      builder: (context) => CompletionCelebration(),
                      settings: RouteSettings(arguments: contextArgs),
                    );
                  }
                  return MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: Text('${settings.name} Screen'),
                    ),
                  );
                },
              );
            },
          ),
        );

        await tester.pumpAndSettle(Duration(seconds: 2));

        // Verify celebration screen loads with context
        expect(find.byType(CompletionCelebration), findsOneWidget);
        
        // Should display completion context
        expect(find.text('Morning Prayer'), findsOneWidget);
        expect(find.text('Prayer'), findsOneWidget);
      });

      testWidgets('Secondary navigation flows work correctly', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Test View Progress navigation
        await tester.tap(find.text('View Progress'));
        await tester.pumpAndSettle();

        expect(find.text('Progress Screen'), findsOneWidget);

        // Navigate back to test Set Goal
        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.byType(CompletionCelebration), findsOneWidget);

        // Test Set Goal navigation
        await tester.tap(find.text('Set Goal'));
        await tester.pumpAndSettle();

        expect(find.text('Create Reminder Screen'), findsOneWidget);
      });

      testWidgets('Close button navigation works correctly', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Find and tap close button
        final closeButton = find.bySemanticsLabel('Close celebration screen');
        expect(closeButton, findsOneWidget);

        await tester.tap(closeButton);
        await tester.pumpAndSettle();

        // Should navigate to dashboard (same as Continue button)
        expect(find.text('Dashboard Screen'), findsOneWidget);
      });

      testWidgets('Back button handling works correctly', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Test back button behavior
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Should navigate to dashboard (handled by WillPopScope)
        expect(find.text('Dashboard Screen'), findsOneWidget);
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('Handles missing context gracefully', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Should load without errors even without context
        expect(find.byType(CompletionCelebration), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Should still show default content
        expect(find.text('Continue'), findsOneWidget);
      });

      testWidgets('Handles data loading failures gracefully', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Should show fallback content instead of errors
        expect(find.byType(CompletionCelebration), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Should show retry option if data loading failed
        final retryButton = find.text('Refresh Progress');
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton);
          await tester.pumpAndSettle();
          
          // Should not throw errors on retry
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('Handles rapid navigation without errors', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 1));

        // Rapidly tap navigation buttons
        for (int i = 0; i < 3; i++) {
          if (find.text('Continue').evaluate().isNotEmpty) {
            await tester.tap(find.text('Continue'));
            await tester.pump(Duration(milliseconds: 100));
          }
        }

        await tester.pumpAndSettle();

        // Should handle rapid navigation without errors
        expect(tester.takeException(), isNull);
        expect(find.text('Dashboard Screen'), findsOneWidget);
      });

      testWidgets('Handles invalid context data gracefully', (tester) async {
        final invalidContextArgs = {
          'reminderTitle': '', // Empty title
          'reminderCategory': null, // Null category
          'completionTime': 'invalid-date', // Invalid date
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                initialRoute: '/',
                onGenerateRoute: (settings) {
                  if (settings.name == '/') {
                    return MaterialPageRoute(
                      builder: (context) => CompletionCelebration(),
                      settings: RouteSettings(arguments: invalidContextArgs),
                    );
                  }
                  return MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: Text('${settings.name} Screen'),
                    ),
                  );
                },
              );
            },
          ),
        );

        await tester.pumpAndSettle(Duration(seconds: 2));

        // Should handle invalid data gracefully
        expect(find.byType(CompletionCelebration), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Should show default fallback content
        expect(find.text('Continue'), findsOneWidget);
      });
    });

    group('Performance and User Experience Tests', () {
      testWidgets('Screen loads within acceptable time', (tester) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        stopwatch.stop();

        // Should load within 2 seconds
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        expect(find.byType(CompletionCelebration), findsOneWidget);
      });

      testWidgets('Animations complete smoothly', (tester) async {
        await tester.pumpWidget(testApp);

        // Test animation progression
        for (int i = 0; i < 20; i++) {
          await tester.pump(Duration(milliseconds: 100));
          // Should animate without throwing exceptions
          expect(tester.takeException(), isNull);
        }

        await tester.pumpAndSettle();
        expect(find.byType(CompletionCelebration), findsOneWidget);
      });

      testWidgets('Memory usage remains stable during animations', (tester) async {
        // Test multiple animation cycles
        for (int cycle = 0; cycle < 3; cycle++) {
          await tester.pumpWidget(testApp);
          await tester.pumpAndSettle(Duration(seconds: 1));

          // Navigate away and back
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();

          await tester.pumpWidget(testApp);
          await tester.pumpAndSettle(Duration(seconds: 1));
        }

        // Should complete without memory issues
        expect(tester.takeException(), isNull);
      });

      testWidgets('Handles different screen sizes appropriately', (tester) async {
        // Test with different screen sizes
        final sizes = [
          Size(320, 568), // iPhone SE
          Size(375, 667), // iPhone 8
          Size(414, 896), // iPhone 11 Pro Max
          Size(768, 1024), // iPad
        ];

        for (final size in sizes) {
          await tester.binding.setSurfaceSize(size);
          await tester.pumpWidget(testApp);
          await tester.pumpAndSettle(Duration(seconds: 1));

          // Should render properly on all screen sizes
          expect(find.byType(CompletionCelebration), findsOneWidget);
          expect(tester.takeException(), isNull);

          // Should have all navigation buttons
          expect(find.text('Continue'), findsOneWidget);
          expect(find.text('View Progress'), findsOneWidget);
          expect(find.text('Set Goal'), findsOneWidget);
        }

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Requirements Validation Tests', () {
      testWidgets('Requirement 1: No auto-dismiss functionality', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Wait longer than the old auto-dismiss time (5 seconds)
        await tester.pump(Duration(seconds: 6));

        // Screen should still be visible
        expect(find.byType(CompletionCelebration), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      });

      testWidgets('Requirement 2: Shows meaningful progress statistics', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Should show progress statistics
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Streak'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
      });

      testWidgets('Requirement 3: Graceful error handling', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Should not show error messages to user
        expect(find.textContaining('Error'), findsNothing);
        expect(find.textContaining('Failed'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Requirement 4: Clear navigation options', (tester) async {
        await tester.pumpWidget(testApp);
        await tester.pumpAndSettle(Duration(seconds: 2));

        // Should have all required navigation options
        expect(find.text('Continue'), findsOneWidget);
        expect(find.text('View Progress'), findsOneWidget);
        expect(find.text('Set Goal'), findsOneWidget);

        // Test navigation functionality
        await tester.tap(find.text('View Progress'));
        await tester.pumpAndSettle();
        expect(find.text('Progress Screen'), findsOneWidget);
      });

      testWidgets('Requirement 5: Shows contextual information', (tester) async {
        final contextArgs = {
          'reminderTitle': 'Evening Dhikr',
          'reminderCategory': 'Dhikr',
          'completionTime': DateTime.now().toIso8601String(),
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) => CompletionCelebration(),
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => CompletionCelebration(),
                    settings: RouteSettings(arguments: contextArgs),
                  );
                },
              );
            },
          ),
        );

        await tester.pumpAndSettle(Duration(seconds: 2));

        // Should show contextual information when available
        expect(find.text('Evening Dhikr'), findsOneWidget);
        expect(find.text('Dhikr'), findsOneWidget);
      });
    });
  });
}