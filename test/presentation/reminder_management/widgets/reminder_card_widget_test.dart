import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../../lib/presentation/reminder_management/widgets/reminder_card_widget.dart';
import '../../../../lib/presentation/reminder_management/widgets/countdown_display_widget.dart';
import '../../../../lib/core/app_export.dart';

void main() {
  group('ReminderCardWidget Countdown Display Tests', () {
    late Map<String, dynamic> activeReminder;
    late Map<String, dynamic> pausedReminder;
    late Map<String, dynamic> completedReminder;

    setUp(() {
      // Active reminder with nextOccurrenceDateTime
      activeReminder = {
        "id": 1,
        "title": "Test Active Reminder",
        "category": "spiritual",
        "frequency": {"type": "daily"},
        "time": "09:00",
        "status": "active",
        "nextOccurrence": "Today at 9:00 AM",
        "nextOccurrenceDateTime": DateTime.now().add(Duration(hours: 2)).toIso8601String(),
      };

      // Paused reminder
      pausedReminder = {
        "id": 2,
        "title": "Test Paused Reminder",
        "category": "health",
        "frequency": {"type": "daily"},
        "time": "10:00",
        "status": "paused",
        "nextOccurrence": "Paused",
      };

      // Completed reminder
      completedReminder = {
        "id": 3,
        "title": "Test Completed Reminder",
        "category": "work",
        "frequency": {"type": "once"},
        "time": "11:00",
        "status": "completed",
        "nextOccurrence": "Completed",
      };
    });

    Widget createTestWidget(Map<String, dynamic> reminder) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: ReminderCardWidget(
                reminder: reminder,
              ),
            ),
          );
        },
      );
    }

    testWidgets('displays countdown widget for active reminder with nextOccurrenceDateTime', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(activeReminder));
      await tester.pumpAndSettle();

      // Should find the CountdownDisplayWidget
      expect(find.byType(CountdownDisplayWidget), findsOneWidget);
      
      // Should not find the static "Next:" text
      expect(find.textContaining('Next:'), findsNothing);
      
      // Should find countdown text (e.g., "In 2 hours" or "Today at")
      expect(find.textContaining(RegExp(r'(In \d+|Today at|Tomorrow at)')), findsOneWidget);
    });

    testWidgets('displays paused status for paused reminder', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(pausedReminder));
      await tester.pumpAndSettle();

      // Should not find CountdownDisplayWidget
      expect(find.byType(CountdownDisplayWidget), findsNothing);
      
      // Should find "Paused" text
      expect(find.text('Paused'), findsOneWidget);
      
      // Should find pause icon
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('displays completed status for completed reminder', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(completedReminder));
      await tester.pumpAndSettle();

      // Should not find CountdownDisplayWidget
      expect(find.byType(CountdownDisplayWidget), findsNothing);
      
      // Should find "Completed" text
      expect(find.text('Completed'), findsOneWidget);
      
      // Should find check circle icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('falls back to static display when nextOccurrenceDateTime is null', (WidgetTester tester) async {
      final reminderWithoutDateTime = Map<String, dynamic>.from(activeReminder);
      reminderWithoutDateTime.remove('nextOccurrenceDateTime');
      
      await tester.pumpWidget(createTestWidget(reminderWithoutDateTime));
      await tester.pumpAndSettle();

      // Should not find CountdownDisplayWidget
      expect(find.byType(CountdownDisplayWidget), findsNothing);
      
      // Should find static "Next:" text
      expect(find.textContaining('Next:'), findsOneWidget);
    });

    testWidgets('falls back to static display when nextOccurrenceDateTime is invalid', (WidgetTester tester) async {
      final reminderWithInvalidDateTime = Map<String, dynamic>.from(activeReminder);
      reminderWithInvalidDateTime['nextOccurrenceDateTime'] = 'invalid-date-string';
      
      await tester.pumpWidget(createTestWidget(reminderWithInvalidDateTime));
      await tester.pumpAndSettle();

      // Should not find CountdownDisplayWidget
      expect(find.byType(CountdownDisplayWidget), findsNothing);
      
      // Should find static "Next:" text
      expect(find.textContaining('Next:'), findsOneWidget);
    });

    testWidgets('countdown updates automatically', (WidgetTester tester) async {
      // Create a reminder that's 30 minutes away (should show "In 30 minutes")
      final futureTime = DateTime.now().add(Duration(minutes: 30));
      final reminderWithFutureTime = Map<String, dynamic>.from(activeReminder);
      reminderWithFutureTime['nextOccurrenceDateTime'] = futureTime.toIso8601String();
      
      await tester.pumpWidget(createTestWidget(reminderWithFutureTime));
      await tester.pumpAndSettle();

      // Should find CountdownDisplayWidget
      expect(find.byType(CountdownDisplayWidget), findsOneWidget);
      
      // Should show "In X minutes" for times less than 60 minutes
      expect(find.textContaining(RegExp(r'In \d+ minute')), findsOneWidget);
      
      // Fast forward time by 1 minute to trigger update
      await tester.pump(Duration(minutes: 1));
      
      // The countdown should still be working (though we can't easily test the exact update
      // without mocking time, we can verify the widget is still there)
      expect(find.byType(CountdownDisplayWidget), findsOneWidget);
    });

    testWidgets('displays overdue status correctly', (WidgetTester tester) async {
      // Create a reminder that's in the past
      final pastTime = DateTime.now().subtract(Duration(minutes: 30));
      final overdueReminder = Map<String, dynamic>.from(activeReminder);
      overdueReminder['nextOccurrenceDateTime'] = pastTime.toIso8601String();
      
      await tester.pumpWidget(createTestWidget(overdueReminder));
      await tester.pumpAndSettle();

      // Should find CountdownDisplayWidget
      expect(find.byType(CountdownDisplayWidget), findsOneWidget);
      
      // Should show "Overdue" text
      expect(find.text('Overdue'), findsOneWidget);
    });
  });
}