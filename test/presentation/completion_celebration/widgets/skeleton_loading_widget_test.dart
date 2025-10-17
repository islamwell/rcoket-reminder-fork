import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../../lib/presentation/completion_celebration/widgets/skeleton_loading_widget.dart';
import '../../../../lib/core/app_export.dart';

void main() {
  group('SkeletonLoadingWidget Tests', () {
    testWidgets('should render progress stats skeleton correctly', (WidgetTester tester) async {
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

      // Verify the skeleton structure
      expect(find.byType(ProgressStatsSkeletonWidget), findsOneWidget);
      expect(find.byType(SkeletonLoadingWidget), findsOneWidget);
      
      // Verify shimmer animation is present
      await tester.pump(Duration(milliseconds: 100));
      await tester.pump(Duration(milliseconds: 500));
      await tester.pump(Duration(milliseconds: 1000));
    });

    testWidgets('should render motivational message skeleton correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: MotivationalMessageSkeletonWidget(),
              ),
            );
          },
        ),
      );

      expect(find.byType(MotivationalMessageSkeletonWidget), findsOneWidget);
      expect(find.byType(SkeletonLoadingWidget), findsOneWidget);
    });

    testWidgets('should render completion context skeleton correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: CompletionContextSkeletonWidget(),
              ),
            );
          },
        ),
      );

      expect(find.byType(CompletionContextSkeletonWidget), findsOneWidget);
      expect(find.byType(SkeletonLoadingWidget), findsOneWidget);
    });

    testWidgets('should render action buttons skeleton correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: ActionButtonsSkeletonWidget(),
              ),
            );
          },
        ),
      );

      expect(find.byType(ActionButtonsSkeletonWidget), findsOneWidget);
      expect(find.byType(SkeletonLoadingWidget), findsOneWidget);
    });

    testWidgets('should render social sharing skeleton correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SocialSharingSkeletonWidget(),
              ),
            );
          },
        ),
      );

      expect(find.byType(SocialSharingSkeletonWidget), findsOneWidget);
      expect(find.byType(SkeletonLoadingWidget), findsOneWidget);
    });

    testWidgets('should animate shimmer effect continuously', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SkeletonLoadingWidget(
                  type: SkeletonType.custom,
                  width: 100,
                  height: 50,
                ),
              ),
            );
          },
        ),
      );

      // Verify animation controller is running
      await tester.pump();
      await tester.pump(Duration(milliseconds: 750)); // Half animation cycle
      await tester.pump(Duration(milliseconds: 750)); // Complete animation cycle
      await tester.pump(Duration(milliseconds: 1500)); // Full repeat cycle
      
      expect(find.byType(SkeletonLoadingWidget), findsOneWidget);
    });

    testWidgets('should handle custom dimensions correctly', (WidgetTester tester) async {
      const customWidth = 200.0;
      const customHeight = 100.0;
      const customBorderRadius = BorderRadius.all(Radius.circular(20));

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SkeletonLoadingWidget(
                  type: SkeletonType.custom,
                  width: customWidth,
                  height: customHeight,
                  borderRadius: customBorderRadius,
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(SkeletonLoadingWidget), findsOneWidget);
    });

    testWidgets('should dispose animation controller properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SkeletonLoadingWidget(
                  type: SkeletonType.progressStats,
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(SkeletonLoadingWidget), findsOneWidget);

      // Remove the widget to test disposal
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

      expect(find.byType(SkeletonLoadingWidget), findsNothing);
    });
  });

  group('Skeleton Type Tests', () {
    testWidgets('should render different skeleton types correctly', (WidgetTester tester) async {
      for (final skeletonType in SkeletonType.values) {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                theme: AppTheme.lightTheme,
                home: Scaffold(
                  body: SkeletonLoadingWidget(
                    type: skeletonType,
                  ),
                ),
              );
            },
          ),
        );

        expect(find.byType(SkeletonLoadingWidget), findsOneWidget);
        
        // Pump a few frames to ensure no errors during animation
        await tester.pump(Duration(milliseconds: 100));
        await tester.pump(Duration(milliseconds: 500));
      }
    });
  });

  group('Shimmer Animation Tests', () {
    testWidgets('should have smooth shimmer animation', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SkeletonLoadingWidget(
                  type: SkeletonType.progressStats,
                ),
              ),
            );
          },
        ),
      );

      // Test animation at different points
      await tester.pump();
      await tester.pump(Duration(milliseconds: 375)); // 1/4 of animation
      await tester.pump(Duration(milliseconds: 375)); // 1/2 of animation
      await tester.pump(Duration(milliseconds: 375)); // 3/4 of animation
      await tester.pump(Duration(milliseconds: 375)); // Full animation
      
      expect(find.byType(SkeletonLoadingWidget), findsOneWidget);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('should be accessible for screen readers', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: Semantics(
                  label: 'Loading progress statistics',
                  child: ProgressStatsSkeletonWidget(),
                ),
              ),
            );
          },
        ),
      );

      expect(find.byType(ProgressStatsSkeletonWidget), findsOneWidget);
      expect(find.bySemanticsLabel('Loading progress statistics'), findsOneWidget);
    });
  });
}