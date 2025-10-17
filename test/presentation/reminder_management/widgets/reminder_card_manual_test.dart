import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../lib/presentation/reminder_management/widgets/reminder_card_widget.dart';
import '../../../../lib/core/app_export.dart';

/// Manual test app to visually verify the countdown display integration
/// Run with: flutter run test/presentation/reminder_management/widgets/reminder_card_manual_test.dart
void main() {
  runApp(ReminderCardManualTestApp());
}

class ReminderCardManualTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          title: 'Reminder Card Manual Test',
          theme: AppTheme.lightTheme,
          home: ReminderCardTestScreen(),
        );
      },
    );
  }
}

class ReminderCardTestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final testReminders = [
      // Active reminder - 30 minutes from now
      {
        "id": 1,
        "title": "Prayer Reminder (30 min)",
        "category": "spiritual",
        "frequency": {"type": "daily"},
        "time": "09:00",
        "status": "active",
        "nextOccurrence": "In 30 minutes",
        "nextOccurrenceDateTime": DateTime.now().add(Duration(minutes: 30)).toIso8601String(),
      },
      // Active reminder - 2 hours from now
      {
        "id": 2,
        "title": "Exercise Reminder (2 hours)",
        "category": "health",
        "frequency": {"type": "daily"},
        "time": "11:00",
        "status": "active",
        "nextOccurrence": "Today at 11:00 AM",
        "nextOccurrenceDateTime": DateTime.now().add(Duration(hours: 2)).toIso8601String(),
      },
      // Active reminder - tomorrow
      {
        "id": 3,
        "title": "Work Meeting (tomorrow)",
        "category": "work",
        "frequency": {"type": "weekly"},
        "time": "14:00",
        "status": "active",
        "nextOccurrence": "Tomorrow at 2:00 PM",
        "nextOccurrenceDateTime": DateTime.now().add(Duration(days: 1)).toIso8601String(),
      },
      // Overdue reminder
      {
        "id": 4,
        "title": "Overdue Reminder",
        "category": "personal",
        "frequency": {"type": "daily"},
        "time": "08:00",
        "status": "active",
        "nextOccurrence": "Overdue",
        "nextOccurrenceDateTime": DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
      },
      // Paused reminder
      {
        "id": 5,
        "title": "Paused Reminder",
        "category": "family",
        "frequency": {"type": "daily"},
        "time": "12:00",
        "status": "paused",
        "nextOccurrence": "Paused",
      },
      // Completed reminder
      {
        "id": 6,
        "title": "Completed Reminder",
        "category": "charity",
        "frequency": {"type": "once"},
        "time": "15:00",
        "status": "completed",
        "nextOccurrence": "Completed",
      },
      // Active reminder without nextOccurrenceDateTime (fallback test)
      {
        "id": 7,
        "title": "Legacy Reminder (no DateTime)",
        "category": "spiritual",
        "frequency": {"type": "daily"},
        "time": "16:00",
        "status": "active",
        "nextOccurrence": "Today at 4:00 PM",
        // No nextOccurrenceDateTime field
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Reminder Card Countdown Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        itemCount: testReminders.length,
        itemBuilder: (context, index) {
          final reminder = testReminders[index];
          return ReminderCardWidget(
            reminder: reminder,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tapped: ${reminder["title"]}'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            onToggle: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Toggled: ${reminder["title"]}'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Countdown displays should update automatically every minute'),
              duration: Duration(seconds: 3),
            ),
          );
        },
        child: Icon(Icons.info),
        tooltip: 'Info about countdown updates',
      ),
    );
  }
}