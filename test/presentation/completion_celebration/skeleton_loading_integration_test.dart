import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../lib/presentation/completion_celebration/completion_celebration.dart';
import '../../../lib/presentation/completion_celebration/widgets/skeleton_loading_widget.dart';
import '../../../lib/core/app_export.dart';
import '../../../lib/routes/app_routes.dart';

void main() {
  group('Skeleton Loading Integration Tests', () {
    testWidgets('should show skeleton loading initially and transition to content', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              routes: {
                AppRoutes.completionCelebration: (context) => CompletionCelebration(),
                AppRoutes.dashboard: (context) => Scaffold(body: Text('Dashboard')),
                AppRoutes.reminderManagement: (context) => Scaffold(body: Text('Reminder Management')),
                AppRoutes.createReminder: (context) => Scaffold(body: Text('Create Reminder')),
              },
              home: CompletionCelebration(),
            );
          },
        ),
      );

      // Initially should show skeleton loading widgets
      await tester.pump();
      
      // Look for skeleton widgets
      expect(find.byType(SkeletonLoadingWidget), findsWidgets);
      
      // Wait for animations to complete
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 300));
      
      // Should still have skeleton widgets during loading
      expect(find.byType(SkeletonLoadingWidget), findsWidgets);
    });

    testWidgets('should render skeleton widgets without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Column(
                  children: [
                    ProgressStatsSkeletonWidget(),
                    SizedBox(height: 20),
                    MotivationalMessageSkeletonWidget(),
                    SizedBox(height: 20),
                    SocialSharingSkeletonWidget(),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pump();
      
      // Verify all skeleton widgets are rendered
      expect(find.byType(ProgressStatsSkeletonWidget), findsOneWidget);
      expect(find.byType(MotivationalMessageSkeletonWidget), findsOneWidget);
      expect(find.byType(SocialSharingSkeletonWidget), findsOneWidget);
      
      // Verify they contain the base skeleton widget
      expect(find.byType(SkeletonLoadingWidget), findsNWidgets(3));
      
      // Test animation frames
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(milliseconds: 500));
      
      // Should still be there after animation frames
      expect(find.byType(SkeletonLoadingWidget), findsNWidgets(3));
    });

    testWidgets('should handle AnimatedSwitcher transitions', (WidgetTester tester) async {
      bool isLoading = true;
      
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: StatefulBuilder(
                builder: (context, setState) {
                  return Scaffold(
                    body: Column(
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 300),
                          child: isLoading
                              ? ProgressStatsSkeletonWidget(key: ValueKey('skeleton'))
                              : Container(
                                  key: ValueKey('content'),
                                  child: Text('Loaded Content'),
                                ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = !isLoading;
                            });
                          },
                          child: Text('Toggle Loading'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      );

      // Initially should show skeleton
      await tester.pump();
      expect(find.byType(ProgressStatsSkeletonWidget), findsOneWidget);
      expect(find.text('Loaded Content'), findsNothing);

      // Tap to toggle loading state
      await tester.tap(find.text('Toggle Loading'));
      await tester.pump();
      
      // Wait for the full transition to complete
      await tester.pumpAndSettle();
      
      // Should now show content
      expect(find.text('Loaded Content'), findsOneWidget);
      expect(find.byType(ProgressStatsSkeletonWidget), findsNothing);
    });

    testWidgets('should handle skeleton widget disposal correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: ProgressStatsSkeletonWidget(),
              ),
            );
          },
        ),
      );

      await tester.pump();
      expect(find.byType(ProgressStatsSkeletonWidget), findsOneWidget);

      // Remove the widget
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Container(),
              ),
            );
          },
        ),
      );

      await tester.pump();
      expect(find.byType(ProgressStatsSkeletonWidget), findsNothing);
    });

    testWidgets('should render different skeleton types correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      SkeletonLoadingWidget(type: SkeletonType.progressStats),
                      SizedBox(height: 10),
                      SkeletonLoadingWidget(type: SkeletonType.motivationalMessage),
                      SizedBox(height: 10),
                      SkeletonLoadingWidget(type: SkeletonType.completionContext),
                      SizedBox(height: 10),
                      SkeletonLoadingWidget(type: SkeletonType.actionButton),
                      SizedBox(height: 10),
                      SkeletonLoadingWidget(type: SkeletonType.socialSharing),
                      SizedBox(height: 10),
                      SkeletonLoadingWidget(
                        type: SkeletonType.custom,
                        width: 100,
                        height: 50,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      await tester.pump();
      
      // Should find all skeleton types
      expect(find.byType(SkeletonLoadingWidget), findsNWidgets(6));
      
      // Test animation frames
      await tester.pump(Duration(milliseconds: 200));
      await tester.pump(Duration(milliseconds: 400));
      await tester.pump(Duration(milliseconds: 600));
      
      // Should still be there
      expect(find.byType(SkeletonLoadingWidget), findsNWidgets(6));
    });
  });
}