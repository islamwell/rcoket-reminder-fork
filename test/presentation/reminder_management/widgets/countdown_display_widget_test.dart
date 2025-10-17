import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_deeds_reminder/presentation/reminder_management/widgets/countdown_display_widget.dart';

void main() {
  group('CountdownDisplayWidget', () {
    late DateTime baseTime;

    setUp(() {
      // Use a fixed base time for consistent testing
      baseTime = DateTime(2024, 1, 15, 10, 30); // Monday, 10:30 AM
    });

    Widget createWidget({
      required DateTime nextOccurrence,
      TextStyle? textStyle,
      Color? overdueColor,
      bool showIcon = false,
      DateTime? currentTime,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CountdownDisplayWidget(
            reminder: {
              'id': 1,
              'status': 'active',
              'nextOccurrenceDateTime': nextOccurrence.toIso8601String(),
              'nextOccurrence': 'Test reminder',
            },
            textStyle: textStyle,
            overrideColor: overdueColor,
          ),
        ),
      );
    }

    testWidgets('displays "In X minutes" for reminders less than 60 minutes away', (tester) async {
      final nextOccurrence = baseTime.add(const Duration(minutes: 30));
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('In 30 minutes'), findsOneWidget);
    });

    testWidgets('displays "In 1 minute" (singular) for 1 minute away', (tester) async {
      final nextOccurrence = baseTime.add(const Duration(minutes: 1));
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('In 1 minute'), findsOneWidget);
    });

    testWidgets('displays "Now" for reminders due now or very soon', (tester) async {
      final nextOccurrence = baseTime;
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('Now'), findsOneWidget);
    });

    testWidgets('displays "Today at [time]" for same day reminders', (tester) async {
      final nextOccurrence = DateTime(2024, 1, 15, 14, 45); // Same day, 2:45 PM
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('Today at 2:45 PM'), findsOneWidget);
    });

    testWidgets('displays "Tomorrow at [time]" for next day reminders', (tester) async {
      final nextOccurrence = DateTime(2024, 1, 16, 9, 15); // Next day, 9:15 AM
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('Tomorrow at 9:15 AM'), findsOneWidget);
    });

    testWidgets('displays "[Day] at [time]" for this week reminders', (tester) async {
      final nextOccurrence = DateTime(2024, 1, 17, 16, 30); // Wednesday, 4:30 PM
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('Wednesday at 4:30 PM'), findsOneWidget);
    });

    testWidgets('displays full date for reminders more than a week away', (tester) async {
      final nextOccurrence = DateTime(2024, 1, 25, 11, 0); // More than a week away
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('Jan 25 at 11:00 AM'), findsOneWidget);
    });

    testWidgets('displays "Overdue" for past reminders', (tester) async {
      final nextOccurrence = baseTime.subtract(const Duration(hours: 2));
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('Overdue'), findsOneWidget);
    });

    testWidgets('formats 12-hour time correctly', (tester) async {
      // Test various times - use times after baseTime (10:30 AM) to avoid "Overdue"
      final testCases = [
        (DateTime(2024, 1, 16, 0, 30), '12:30 AM'), // Tomorrow midnight
        (DateTime(2024, 1, 15, 12, 0), '12:00 PM'), // Today noon
        (DateTime(2024, 1, 15, 13, 45), '1:45 PM'), // Today afternoon
        (DateTime(2024, 1, 15, 23, 59), '11:59 PM'), // Today late night
      ];

      for (final (dateTime, expectedTime) in testCases) {
        await tester.pumpWidget(createWidget(nextOccurrence: dateTime));
        expect(find.textContaining(expectedTime), findsOneWidget);
      }
    });

    testWidgets('shows icon when showIcon is true', (tester) async {
      final nextOccurrence = baseTime.add(const Duration(minutes: 30));
      
      await tester.pumpWidget(createWidget(
        nextOccurrence: nextOccurrence,
        showIcon: true,
      ));
      
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('shows warning icon for overdue reminders', (tester) async {
      final nextOccurrence = baseTime.subtract(const Duration(hours: 1));
      
      await tester.pumpWidget(createWidget(
        nextOccurrence: nextOccurrence,
        showIcon: true,
      ));
      
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('applies custom text style', (tester) async {
      final nextOccurrence = baseTime.add(const Duration(minutes: 30));
      const customStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
      
      await tester.pumpWidget(createWidget(
        nextOccurrence: nextOccurrence,
        textStyle: customStyle,
      ));
      
      final textWidget = tester.widget<Text>(find.text('In 30 minutes'));
      expect(textWidget.style?.fontSize, 18);
    });

    testWidgets('applies custom overdue color', (tester) async {
      final nextOccurrence = baseTime.subtract(const Duration(hours: 1));
      const customColor = Colors.orange;
      
      await tester.pumpWidget(createWidget(
        nextOccurrence: nextOccurrence,
        overdueColor: customColor,
      ));
      
      final textWidget = tester.widget<Text>(find.text('Overdue'));
      expect(textWidget.style?.color, customColor);
    });

    testWidgets('updates display when nextOccurrence changes', (tester) async {
      final initialOccurrence = baseTime.add(const Duration(minutes: 30));
      
      await tester.pumpWidget(createWidget(nextOccurrence: initialOccurrence));
      expect(find.text('In 30 minutes'), findsOneWidget);
      
      // Update with new occurrence
      final newOccurrence = baseTime.add(const Duration(hours: 2));
      await tester.pumpWidget(createWidget(nextOccurrence: newOccurrence));
      
      expect(find.text('Today at 12:30 PM'), findsOneWidget);
      expect(find.text('In 30 minutes'), findsNothing);
    });

    group('Day name formatting', () {
      testWidgets('formats weekdays correctly', (tester) async {
        // Use dates that are more than 2 days away but less than a week from baseTime
        // baseTime is Monday Jan 15, 2024 at 10:30 AM
        final testCases = [
          (DateTime(2024, 1, 17, 15, 0), 'Wednesday'), // Wednesday (2 days away)
          (DateTime(2024, 1, 18, 15, 0), 'Thursday'), // Thursday (3 days away)
          (DateTime(2024, 1, 19, 15, 0), 'Friday'), // Friday (4 days away)
          (DateTime(2024, 1, 20, 15, 0), 'Saturday'), // Saturday (5 days away)
          (DateTime(2024, 1, 21, 15, 0), 'Sunday'), // Sunday (6 days away)
        ];

        for (final (nextOccurrence, expectedDay) in testCases) {
          await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
          expect(find.textContaining(expectedDay), findsOneWidget);
        }
      });
    });

    group('Month formatting', () {
      testWidgets('formats months correctly', (tester) async {
        final testCases = [
          (DateTime(2024, 1, 25, 10, 0), 'Jan 25'),
          (DateTime(2024, 2, 25, 10, 0), 'Feb 25'),
          (DateTime(2024, 12, 25, 10, 0), 'Dec 25'),
        ];

        for (final (date, expectedFormat) in testCases) {
          await tester.pumpWidget(createWidget(nextOccurrence: date));
          expect(find.textContaining(expectedFormat), findsOneWidget);
        }
      });
    });

    testWidgets('handles edge case of exactly 60 minutes', (tester) async {
      final nextOccurrence = baseTime.add(const Duration(minutes: 60));
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      // Should show "Today at" format, not "In 60 minutes"
      expect(find.text('Today at 11:30 AM'), findsOneWidget);
      expect(find.textContaining('In 60 minutes'), findsNothing);
    });

    testWidgets('handles midnight time correctly', (tester) async {
      final nextOccurrence = DateTime(2024, 1, 16, 0, 0); // Tomorrow at midnight
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('Tomorrow at 12:00 AM'), findsOneWidget);
    });

    testWidgets('handles noon time correctly', (tester) async {
      final nextOccurrence = DateTime(2024, 1, 15, 12, 0); // Today at noon
      
      await tester.pumpWidget(createWidget(nextOccurrence: nextOccurrence));
      
      expect(find.text('Today at 12:00 PM'), findsOneWidget);
    });
  });
}