import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/models/completion_context.dart';

void main() {
  group('CompletionContext', () {
    group('Constructor', () {
      test('should create CompletionContext with required fields', () {
        final completionTime = DateTime.now();
        final context = CompletionContext(
          reminderTitle: 'Morning Prayer',
          reminderCategory: 'Spiritual',
          completionTime: completionTime,
        );

        expect(context.reminderTitle, equals('Morning Prayer'));
        expect(context.reminderCategory, equals('Spiritual'));
        expect(context.completionTime, equals(completionTime));
        expect(context.completionNotes, isNull);
        expect(context.reminderId, isNull);
        expect(context.actualDuration, isNull);
      });

      test('should create CompletionContext with all fields', () {
        final completionTime = DateTime.now();
        final duration = Duration(minutes: 15);
        final context = CompletionContext(
          reminderTitle: 'Evening Reflection',
          reminderCategory: 'Meditation',
          completionTime: completionTime,
          completionNotes: 'Felt peaceful',
          reminderId: 123,
          actualDuration: duration,
        );

        expect(context.reminderTitle, equals('Evening Reflection'));
        expect(context.reminderCategory, equals('Meditation'));
        expect(context.completionTime, equals(completionTime));
        expect(context.completionNotes, equals('Felt peaceful'));
        expect(context.reminderId, equals(123));
        expect(context.actualDuration, equals(duration));
      });
    });

    group('fromReminder factory', () {
      test('should create CompletionContext from reminder map with all fields', () {
        final reminderMap = {
          'title': 'Daily Scripture',
          'category': 'Reading',
          'notes': 'Inspiring verse',
          'id': 456,
          'duration': 20,
        };

        final context = CompletionContext.fromReminder(reminderMap);

        expect(context.reminderTitle, equals('Daily Scripture'));
        expect(context.reminderCategory, equals('Reading'));
        expect(context.completionNotes, equals('Inspiring verse'));
        expect(context.reminderId, equals(456));
        expect(context.actualDuration, equals(Duration(minutes: 20)));
        expect(context.completionTime, isA<DateTime>());
      });

      test('should handle reminder map with alternative field names', () {
        final reminderMap = {
          'name': 'Prayer Time',
          'type': 'Worship',
        };

        final context = CompletionContext.fromReminder(reminderMap);

        expect(context.reminderTitle, equals('Prayer Time'));
        expect(context.reminderCategory, equals('Worship'));
      });

      test('should use defaults for missing fields', () {
        final reminderMap = <String, dynamic>{};

        final context = CompletionContext.fromReminder(reminderMap);

        expect(context.reminderTitle, equals('Reminder'));
        expect(context.reminderCategory, equals('General'));
        expect(context.completionNotes, isNull);
        expect(context.reminderId, isNull);
        expect(context.actualDuration, isNull);
      });
    });

    group('fromNavigation factory', () {
      test('should create CompletionContext from navigation args', () {
        final completionTime = DateTime.now();
        final args = {
          'reminderTitle': 'Bible Study',
          'reminderCategory': 'Study',
          'completionTime': completionTime.toIso8601String(),
          'completionNotes': 'Great insights',
          'reminderId': 789,
          'actualDuration': 1800000, // 30 minutes in milliseconds
        };

        final context = CompletionContext.fromNavigation(args);

        expect(context.reminderTitle, equals('Bible Study'));
        expect(context.reminderCategory, equals('Study'));
        expect(context.completionTime.millisecondsSinceEpoch, 
               equals(completionTime.millisecondsSinceEpoch));
        expect(context.completionNotes, equals('Great insights'));
        expect(context.reminderId, equals(789));
        expect(context.actualDuration, equals(Duration(minutes: 30)));
      });

      test('should handle navigation args with alternative field names', () {
        final args = {
          'title': 'Worship',
          'category': 'Music',
        };

        final context = CompletionContext.fromNavigation(args);

        expect(context.reminderTitle, equals('Worship'));
        expect(context.reminderCategory, equals('Music'));
      });

      test('should use defaults for missing navigation args', () {
        final args = <String, dynamic>{};

        final context = CompletionContext.fromNavigation(args);

        expect(context.reminderTitle, equals('Reminder'));
        expect(context.reminderCategory, equals('General'));
        expect(context.completionTime, isA<DateTime>());
      });
    });

    group('defaultContext factory', () {
      test('should create default CompletionContext', () {
        final context = CompletionContext.defaultContext();

        expect(context.reminderTitle, equals('Your Achievement'));
        expect(context.reminderCategory, equals('General'));
        expect(context.completionTime, isA<DateTime>());
        expect(context.completionNotes, isNull);
        expect(context.reminderId, isNull);
        expect(context.actualDuration, isNull);
      });
    });

    group('toMap', () {
      test('should convert CompletionContext to map', () {
        final completionTime = DateTime.now();
        final duration = Duration(minutes: 25);
        final context = CompletionContext(
          reminderTitle: 'Gratitude Journal',
          reminderCategory: 'Reflection',
          completionTime: completionTime,
          completionNotes: 'Thankful today',
          reminderId: 101,
          actualDuration: duration,
        );

        final map = context.toMap();

        expect(map['reminderTitle'], equals('Gratitude Journal'));
        expect(map['reminderCategory'], equals('Reflection'));
        expect(map['completionTime'], equals(completionTime.toIso8601String()));
        expect(map['completionNotes'], equals('Thankful today'));
        expect(map['reminderId'], equals(101));
        expect(map['actualDuration'], equals(duration.inMilliseconds));
      });
    });

    group('copyWith', () {
      test('should create copy with updated values', () {
        final originalTime = DateTime.now();
        final newTime = originalTime.add(Duration(hours: 1));
        final context = CompletionContext(
          reminderTitle: 'Original Title',
          reminderCategory: 'Original Category',
          completionTime: originalTime,
        );

        final updatedContext = context.copyWith(
          reminderTitle: 'Updated Title',
          completionTime: newTime,
        );

        expect(updatedContext.reminderTitle, equals('Updated Title'));
        expect(updatedContext.reminderCategory, equals('Original Category'));
        expect(updatedContext.completionTime, equals(newTime));
      });

      test('should keep original values when no updates provided', () {
        final completionTime = DateTime.now();
        final context = CompletionContext(
          reminderTitle: 'Test Title',
          reminderCategory: 'Test Category',
          completionTime: completionTime,
        );

        final copiedContext = context.copyWith();

        expect(copiedContext.reminderTitle, equals(context.reminderTitle));
        expect(copiedContext.reminderCategory, equals(context.reminderCategory));
        expect(copiedContext.completionTime, equals(context.completionTime));
      });
    });

    group('hasCompleteInfo', () {
      test('should return true when title and category are not empty', () {
        final context = CompletionContext(
          reminderTitle: 'Valid Title',
          reminderCategory: 'Valid Category',
          completionTime: DateTime.now(),
        );

        expect(context.hasCompleteInfo, isTrue);
      });

      test('should return false when title is empty', () {
        final context = CompletionContext(
          reminderTitle: '',
          reminderCategory: 'Valid Category',
          completionTime: DateTime.now(),
        );

        expect(context.hasCompleteInfo, isFalse);
      });

      test('should return false when category is empty', () {
        final context = CompletionContext(
          reminderTitle: 'Valid Title',
          reminderCategory: '',
          completionTime: DateTime.now(),
        );

        expect(context.hasCompleteInfo, isFalse);
      });
    });

    group('formattedCompletionTime', () {
      test('should return "Just now" for recent completion', () {
        final context = CompletionContext(
          reminderTitle: 'Test',
          reminderCategory: 'Test',
          completionTime: DateTime.now().subtract(Duration(seconds: 30)),
        );

        expect(context.formattedCompletionTime, equals('Just now'));
      });

      test('should return minutes ago for completion within an hour', () {
        final context = CompletionContext(
          reminderTitle: 'Test',
          reminderCategory: 'Test',
          completionTime: DateTime.now().subtract(Duration(minutes: 15)),
        );

        expect(context.formattedCompletionTime, equals('15 minutes ago'));
      });

      test('should return hours ago for completion within a day', () {
        final context = CompletionContext(
          reminderTitle: 'Test',
          reminderCategory: 'Test',
          completionTime: DateTime.now().subtract(Duration(hours: 3)),
        );

        expect(context.formattedCompletionTime, equals('3 hours ago'));
      });

      test('should return days ago for older completions', () {
        final context = CompletionContext(
          reminderTitle: 'Test',
          reminderCategory: 'Test',
          completionTime: DateTime.now().subtract(Duration(days: 2)),
        );

        expect(context.formattedCompletionTime, equals('2 days ago'));
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all fields match', () {
        final completionTime = DateTime.now();
        final context1 = CompletionContext(
          reminderTitle: 'Test Title',
          reminderCategory: 'Test Category',
          completionTime: completionTime,
          completionNotes: 'Test Notes',
          reminderId: 123,
          actualDuration: Duration(minutes: 10),
        );
        final context2 = CompletionContext(
          reminderTitle: 'Test Title',
          reminderCategory: 'Test Category',
          completionTime: completionTime,
          completionNotes: 'Test Notes',
          reminderId: 123,
          actualDuration: Duration(minutes: 10),
        );

        expect(context1, equals(context2));
        expect(context1.hashCode, equals(context2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final completionTime = DateTime.now();
        final context1 = CompletionContext(
          reminderTitle: 'Test Title 1',
          reminderCategory: 'Test Category',
          completionTime: completionTime,
        );
        final context2 = CompletionContext(
          reminderTitle: 'Test Title 2',
          reminderCategory: 'Test Category',
          completionTime: completionTime,
        );

        expect(context1, isNot(equals(context2)));
        expect(context1.hashCode, isNot(equals(context2.hashCode)));
      });
    });

    group('toString', () {
      test('should return string representation of CompletionContext', () {
        final completionTime = DateTime.now();
        final context = CompletionContext(
          reminderTitle: 'Test Title',
          reminderCategory: 'Test Category',
          completionTime: completionTime,
        );

        final stringRepresentation = context.toString();

        expect(stringRepresentation, contains('CompletionContext'));
        expect(stringRepresentation, contains('Test Title'));
        expect(stringRepresentation, contains('Test Category'));
      });
    });
  });
}