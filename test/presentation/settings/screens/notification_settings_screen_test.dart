import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/presentation/settings/screens/notification_settings_screen.dart';

void main() {
  group('NotificationSettingsScreen', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: NotificationSettingsScreen(),
      );
    }

    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays main sections after loading', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Notification Status'), findsOneWidget);
      expect(find.text('Permission Management'), findsOneWidget);
      expect(find.text('Test Notifications'), findsOneWidget);
      expect(find.text('Troubleshooting'), findsOneWidget);
    });

    testWidgets('opens troubleshooting dialog when troubleshooting button is tapped', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('View Troubleshooting Guide'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Troubleshooting Guide'), findsOneWidget);
      expect(find.text('Android Users:'), findsOneWidget);
      expect(find.text('iOS Users:'), findsOneWidget);
      expect(find.text('Battery Optimization:'), findsOneWidget);
    });

    testWidgets('has refresh status button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Refresh Status'), findsOneWidget);
    });

    testWidgets('has test notification button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Send Test Notification'), findsOneWidget);
    });

    testWidgets('displays app bar with correct title', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('has back button in app bar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('troubleshooting dialog has close and recheck buttons', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('View Troubleshooting Guide'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Recheck Status'), findsOneWidget);
    });

    testWidgets('can close troubleshooting dialog', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('View Troubleshooting Guide'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Troubleshooting Guide'), findsNothing);
    });
  });
}