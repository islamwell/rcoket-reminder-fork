import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/dashboard/dashboard_screen.dart';
import '../../../lib/widgets/custom_bottom_bar.dart';

void main() {
  group('Dashboard Layout Verification', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: DashboardScreen(),
        routes: {
          '/settings': (context) => Scaffold(body: Text('Settings')),
          '/create-reminder': (context) => Scaffold(body: Text('Create Reminder')),
          '/reminder-management': (context) => Scaffold(body: Text('Reminder Management')),
          '/audio-library': (context) => Scaffold(body: Text('Audio Library')),
          '/completion-celebration': (context) => Scaffold(body: Text('Completion Celebration')),
        },
      );
    }

    testWidgets('dashboard and bottom bar render without overflow', (WidgetTester tester) async {
      // Test on iPhone SE size (smaller screen to catch overflow issues)
      await tester.binding.setSurfaceSize(Size(375, 667));
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));
      
      // Verify main components are present
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(CustomBottomBar), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      
      // Most importantly, verify no overflow exceptions occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('bottom bar layout is properly sized', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(Size(375, 667));
      
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump(Duration(milliseconds: 100));
      
      // Find the bottom bar container
      final bottomBarFinder = find.byType(CustomBottomBar);
      expect(bottomBarFinder, findsOneWidget);
      
      // Verify no overflow exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('layout adjustments work on different screen sizes', (WidgetTester tester) async {
      final testSizes = [
        Size(375, 667),   // iPhone SE
        Size(414, 896),   // iPhone 11 Pro Max  
        Size(360, 640),   // Small Android
      ];
      
      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(Duration(milliseconds: 100));
        
        // Verify no overflow on any screen size
        expect(tester.takeException(), isNull, 
               reason: 'No overflow should occur on ${size.width}x${size.height}');
        
        // Verify components are present
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(CustomBottomBar), findsOneWidget);
      }
    });
  });
}