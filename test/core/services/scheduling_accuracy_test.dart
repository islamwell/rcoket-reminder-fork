import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/services/reminder_storage_service.dart';

void main() {
  group('Scheduling Accuracy Tests', () {
    late ReminderStorageService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = ReminderStorageService.instance;
    });

    test('should schedule reminder for exactly 2 minutes in the future', () async {
      final now = DateTime.now();
      
      // Create a custom frequency for 2 minutes
      final frequency = {
        'type': 'custom',
        'intervalValue': 2,
        'intervalUnit': 'minutes',
      };
      
      final reminder = await service.saveReminder(
        title: '2 Minute Test',
        category: 'Test',
        frequency: frequency,
        time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
      
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime']);
      final difference = nextOccurrenceDateTime.difference(now);
      
      // Should be approximately 2 minutes (allowing for small processing delays)
      expect(difference.inMinutes, equals(2));
      expect(difference.inSeconds, greaterThanOrEqualTo(115)); // At least 1:55
      expect(difference.inSeconds, lessThanOrEqualTo(125)); // At most 2:05
    });

    test('should not move today reminder to tomorrow if time is in future', () async {
      final now = DateTime.now();
      final futureTime = now.add(Duration(minutes: 30));
      
      final frequency = {'type': 'daily'};
      final timeStr = '${futureTime.hour.toString().padLeft(2, '0')}:${futureTime.minute.toString().padLeft(2, '0')}';
      
      final reminder = await service.saveReminder(
        title: 'Future Today Test',
        category: 'Test',
        frequency: frequency,
        time: timeStr,
      );
      
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime']);
      
      // Should be scheduled for today, not tomorrow
      expect(nextOccurrenceDateTime.day, equals(now.day));
      expect(nextOccurrenceDateTime.month, equals(now.month));
      expect(nextOccurrenceDateTime.year, equals(now.year));
    });

    test('should apply minimum 1 minute buffer for very near future times', () async {
      final now = DateTime.now();
      final veryNearFuture = now.add(Duration(seconds: 30)); // 30 seconds
      
      final frequency = {'type': 'daily'};
      final timeStr = '${veryNearFuture.hour.toString().padLeft(2, '0')}:${veryNearFuture.minute.toString().padLeft(2, '0')}';
      
      final reminder = await service.saveReminder(
        title: 'Buffer Test',
        category: 'Test',
        frequency: frequency,
        time: timeStr,
      );
      
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime']);
      final difference = nextOccurrenceDateTime.difference(now);
      
      // Should have at least 1 minute buffer
      expect(difference.inMinutes, greaterThanOrEqualTo(1));
    });

    test('should handle past time by scheduling for tomorrow', () async {
      final now = DateTime.now();
      final pastTime = now.subtract(Duration(hours: 1));
      
      final frequency = {'type': 'daily'};
      final timeStr = '${pastTime.hour.toString().padLeft(2, '0')}:${pastTime.minute.toString().padLeft(2, '0')}';
      
      final reminder = await service.saveReminder(
        title: 'Past Time Test',
        category: 'Test',
        frequency: frequency,
        time: timeStr,
      );
      
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime']);
      
      // Should be scheduled for tomorrow
      expect(nextOccurrenceDateTime.day, equals(now.day + 1));
    });

    test('should validate schedule time correctly', () async {
      final now = DateTime.now();
      
      // Test validateScheduleTime method
      final proposedTime = now.add(Duration(seconds: 30)); // Less than 1 minute
      final validatedTime = service.validateScheduleTime(proposedTime);
      
      final difference = validatedTime.difference(now);
      expect(difference.inMinutes, greaterThanOrEqualTo(1));
    });

    test('should adjust for time conflicts correctly', () async {
      final now = DateTime.now();
      
      // Test adjustForTimeConflicts method
      final pastTime = now.subtract(Duration(minutes: 5));
      final adjustedTime = service.adjustForTimeConflicts(pastTime);
      
      final difference = adjustedTime.difference(now);
      expect(difference.inMinutes, greaterThanOrEqualTo(1));
    });

    test('should calculate precise schedule time for minutely frequency', () async {
      final now = DateTime.now();
      
      final frequency = {
        'type': 'minutely',
        'minutesFromNow': 5,
      };
      
      final reminder = await service.saveReminder(
        title: 'Minutely Test',
        category: 'Test',
        frequency: frequency,
        time: '12:00', // This should be ignored for minutely
      );
      
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime']);
      final difference = nextOccurrenceDateTime.difference(now);
      
      // Should be exactly 5 minutes
      expect(difference.inMinutes, equals(5));
    });

    test('should handle weekly reminders with proper buffer', () async {
      final now = DateTime.now();
      final currentWeekday = now.weekday;
      
      // Schedule for today if time is in future
      final futureTime = now.add(Duration(minutes: 30));
      final frequency = {
        'type': 'weekly',
        'selectedDays': [currentWeekday],
      };
      
      final timeStr = '${futureTime.hour.toString().padLeft(2, '0')}:${futureTime.minute.toString().padLeft(2, '0')}';
      
      final reminder = await service.saveReminder(
        title: 'Weekly Buffer Test',
        category: 'Test',
        frequency: frequency,
        time: timeStr,
      );
      
      final nextOccurrenceDateTime = DateTime.parse(reminder['nextOccurrenceDateTime']);
      
      // Should be today since time is in future with adequate buffer
      expect(nextOccurrenceDateTime.day, equals(now.day));
      expect(nextOccurrenceDateTime.hour, equals(futureTime.hour));
      expect(nextOccurrenceDateTime.minute, equals(futureTime.minute));
    });

    test('should prioritize local storage for immediate response', () async {
      final stopwatch = Stopwatch()..start();
      
      final reminder = await service.saveReminder(
        title: 'Performance Test',
        category: 'Test',
        frequency: {'type': 'daily'},
        time: '12:00',
      );
      
      stopwatch.stop();
      
      // Should complete quickly (under 100ms for local storage)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(reminder['id'], isNotNull);
      expect(reminder['title'], equals('Performance Test'));
    });
  });
}