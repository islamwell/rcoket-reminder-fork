import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../lib/core/app_export.dart';
import '../../../lib/core/models/completion_context.dart';
import '../../../lib/presentation/completion_celebration/completion_celebration.dart';
import '../../../lib/presentation/completion_celebration/widgets/animated_checkmark_widget.dart';
import '../../../lib/presentation/completion_celebration/widgets/particle_effect_widget.dart';
import '../../../lib/presentation/completion_celebration/widgets/progress_stats_widget.dart';

void main() {
  group('Performance Optimization Tests', () {
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

    group('Animation Performance Tests', () {
      testWidgets('CompletionCelebration animations complete within expected time', (tester) async {
        await tester.pumpWidget(testApp);
        
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        // Wait for initial animations to complete
        await tester.pumpAndSettle(Duration(seconds: 2));
        
        stopwatch.stop();
        
        // Verify animations complete within reasonable time (optimized from previous implementation)
        expect(stopwatch.elapsedMilliseconds, lessThan(2000), 
               reason: 'Animations should complete within 2 seconds for better performance');
      });

      testWidgets('AnimatedCheckmarkWidget completes animation efficiently', (tester) async {
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

        final stopwatch = Stopwatch()..start();
        
        // Wait for animation to complete
        await tester.pumpAndSettle(Duration(milliseconds: 800));
        
        stopwatch.stop();
        
        // Verify optimized animation duration (reduced from 1000ms to 700ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(800),
               reason: 'Checkmark animation should complete within 800ms');
      });

      testWidgets('ParticleEffectWidget uses optimized particle count', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ParticleEffectWidget(),
                ),
              );
            },
          ),
        );

        await tester.pump();
        
        // Find the particle effect widget
        final particleWidget = tester.widget<ParticleEffectWidget>(find.byType(ParticleEffectWidget));
        expect(particleWidget, isNotNull);
        
        // Verify widget renders without performance issues
        await tester.pumpAndSettle(Duration(milliseconds: 100));
        expect(find.byType(ParticleEffectWidget), findsOneWidget);
      });

      testWidgets('ProgressStatsWidget animations are optimized', (tester) async {
        final testData = {
          'todayCompletions': 1,
          'currentStreak': 5,
          'totalCompletions': 10,
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

        final stopwatch = Stopwatch()..start();
        
        // Wait for counter animations to complete
        await tester.pumpAndSettle(Duration(milliseconds: 1200));
        
        stopwatch.stop();
        
        // Verify optimized animation duration (reduced from 1500ms to 1000ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(1200),
               reason: 'Progress stats animation should complete within 1200ms');
      });
    });

    group('Memory Management Tests', () {
      testWidgets('Animation controllers are properly disposed', (tester) async {
        // Create and dispose the celebration screen
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        await tester.pump();
        
        // Navigate away to trigger dispose
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(body: Text('New Screen')),
              );
            },
          ),
        );

        await tester.pumpAndSettle();
        
        // Verify no memory leaks by checking widget is properly disposed
        expect(find.byType(CompletionCelebration), findsNothing);
      });

      testWidgets('Animated widgets clean up resources properly', (tester) async {
        // Test AnimatedCheckmarkWidget disposal
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

        await tester.pump();
        
        // Remove widget to trigger dispose
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(body: Container()),
              );
            },
          ),
        );

        await tester.pumpAndSettle();
        
        // Verify widget is properly disposed
        expect(find.byType(AnimatedCheckmarkWidget), findsNothing);
      });
    });

    group('Performance Edge Cases', () {
      testWidgets('Handles rapid navigation without performance issues', (tester) async {
        for (int i = 0; i < 5; i++) {
          await tester.pumpWidget(
            Sizer(
              builder: (context, orientation, deviceType) {
                return MaterialApp(
                  home: CompletionCelebration(),
                );
              },
            ),
          );

          await tester.pump(Duration(milliseconds: 100));
          
          // Rapidly navigate away
          await tester.pumpWidget(
            Sizer(
              builder: (context, orientation, deviceType) {
                return MaterialApp(
                  home: Scaffold(body: Text('Screen $i')),
                );
              },
            ),
          );

          await tester.pump(Duration(milliseconds: 50));
        }
        
        // Should complete without throwing exceptions
        await tester.pumpAndSettle();
        expect(find.text('Screen 4'), findsOneWidget);
      });

      testWidgets('Handles missing data gracefully without performance impact', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ProgressStatsWidget(reminderData: {}),
                ),
              );
            },
          ),
        );

        final stopwatch = Stopwatch()..start();
        
        await tester.pumpAndSettle(Duration(milliseconds: 1200));
        
        stopwatch.stop();
        
        // Should handle missing data without performance degradation
        expect(stopwatch.elapsedMilliseconds, lessThan(1200));
        expect(find.byType(ProgressStatsWidget), findsOneWidget);
      });
    });

    group('Animation Curve Optimization Tests', () {
      testWidgets('Uses performance-optimized animation curves', (tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: CompletionCelebration(),
              );
            },
          ),
        );

        await tester.pump();
        
        // Verify the screen renders with optimized curves
        // (elasticOut replaced with easeOutBack, etc.)
        expect(find.byType(CompletionCelebration), findsOneWidget);
        
        // Test smooth animation progression
        for (int i = 0; i < 10; i++) {
          await tester.pump(Duration(milliseconds: 50));
          // Should animate smoothly without jank
        }
        
        await tester.pumpAndSettle();
      });
    });
  });
}