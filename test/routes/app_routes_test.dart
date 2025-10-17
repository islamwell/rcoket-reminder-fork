import 'package:flutter_test/flutter_test.dart';
import '../../lib/routes/app_routes.dart';

void main() {
  group('AppRoutes', () {
    group('_validateCompletionCelebrationArgs', () {
      test('should validate valid arguments correctly', () {
        final validArgs = {
          'reminderTitle': 'Morning Prayer',
          'reminderCategory': 'Prayer',
          'completionTime': DateTime.now().toIso8601String(),
          'completionNotes': 'Felt peaceful',
          'reminderId': 123,
          'actualDuration': 300000, // 5 minutes in milliseconds
        };

        final result = AppRoutes.validateCompletionCelebrationArgs(validArgs);
        
        expect(result, isNotNull);
        expect(result!['reminderTitle'], equals('Morning Prayer'));
        expect(result['reminderCategory'], equals('Prayer'));
        expect(result['completionNotes'], equals('Felt peaceful'));
        expect(result['reminderId'], equals(123));
        expect(result['actualDuration'], equals(300000));
      });

      test('should handle alternative argument keys', () {
        final argsWithAlternativeKeys = {
          'title': 'Evening Reflection', // Alternative key
          'category': 'Reflection', // Alternative key
          'completionTime': DateTime.now(),
        };

        final result = AppRoutes.validateCompletionCelebrationArgs(argsWithAlternativeKeys);
        
        expect(result, isNotNull);
        expect(result!['reminderTitle'], equals('Evening Reflection'));
        expect(result['reminderCategory'], equals('Reflection'));
      });

      test('should handle invalid argument types gracefully', () {
        final invalidArgs = {
          'reminderTitle': 123, // Invalid type
          'reminderCategory': '', // Empty string
          'completionTime': 'invalid-date', // Invalid date format
          'reminderId': 'not-a-number', // Invalid ID format
          'actualDuration': -100, // Negative duration
        };

        final result = AppRoutes.validateCompletionCelebrationArgs(invalidArgs);
        
        // Should return null or empty map since no valid args found
        expect(result, isNull);
      });

      test('should handle missing arguments', () {
        final emptyArgs = <String, dynamic>{};

        final result = AppRoutes.validateCompletionCelebrationArgs(emptyArgs);
        
        expect(result, isNull);
      });

      test('should trim whitespace from string values', () {
        final argsWithWhitespace = {
          'reminderTitle': '  Morning Prayer  ',
          'reminderCategory': '  Prayer  ',
          'completionNotes': '  Felt peaceful  ',
        };

        final result = AppRoutes.validateCompletionCelebrationArgs(argsWithWhitespace);
        
        expect(result, isNotNull);
        expect(result!['reminderTitle'], equals('Morning Prayer'));
        expect(result['reminderCategory'], equals('Prayer'));
        expect(result['completionNotes'], equals('Felt peaceful'));
      });

      test('should handle string reminderId conversion', () {
        final argsWithStringId = {
          'reminderTitle': 'Test Reminder',
          'reminderId': '456',
        };

        final result = AppRoutes.validateCompletionCelebrationArgs(argsWithStringId);
        
        expect(result, isNotNull);
        expect(result!['reminderId'], equals(456));
      });

      test('should handle DateTime object for completionTime', () {
        final now = DateTime.now();
        final argsWithDateTime = {
          'reminderTitle': 'Test Reminder',
          'completionTime': now,
        };

        final result = AppRoutes.validateCompletionCelebrationArgs(argsWithDateTime);
        
        expect(result, isNotNull);
        expect(result!['completionTime'], equals(now.toIso8601String()));
      });

      test('should handle Duration object for actualDuration', () {
        final duration = Duration(minutes: 5);
        final argsWithDuration = {
          'reminderTitle': 'Test Reminder',
          'actualDuration': duration,
        };

        final result = AppRoutes.validateCompletionCelebrationArgs(argsWithDuration);
        
        expect(result, isNotNull);
        expect(result!['actualDuration'], equals(duration.inMilliseconds));
      });

      test('should ignore empty strings for optional fields', () {
        final argsWithEmptyStrings = {
          'reminderTitle': 'Valid Title',
          'reminderCategory': '', // Empty category should be ignored
          'completionNotes': '', // Empty notes should be ignored
        };

        final result = AppRoutes.validateCompletionCelebrationArgs(argsWithEmptyStrings);
        
        expect(result, isNotNull);
        expect(result!['reminderTitle'], equals('Valid Title'));
        expect(result.containsKey('reminderCategory'), isFalse);
        expect(result.containsKey('completionNotes'), isFalse);
      });

      test('should handle partial valid arguments', () {
        final partialArgs = {
          'reminderTitle': 'Valid Title',
          'invalidField': 'should be ignored',
          'reminderId': 'invalid-id', // Invalid ID should be ignored
          'actualDuration': -50, // Negative duration should be ignored
        };

        final result = AppRoutes.validateCompletionCelebrationArgs(partialArgs);
        
        expect(result, isNotNull);
        expect(result!['reminderTitle'], equals('Valid Title'));
        expect(result.containsKey('invalidField'), isFalse);
        expect(result.containsKey('reminderId'), isFalse);
        expect(result.containsKey('actualDuration'), isFalse);
      });
    });

    group('route constants', () {
      test('should have all required route constants', () {
        expect(AppRoutes.initial, equals('/'));
        expect(AppRoutes.login, equals('/login'));
        expect(AppRoutes.dashboard, equals('/dashboard'));
        expect(AppRoutes.completionCelebration, equals('/completion-celebration'));
        expect(AppRoutes.createReminder, equals('/create-reminder'));
        expect(AppRoutes.reminderManagement, equals('/reminder-management'));
        expect(AppRoutes.completionFeedback, equals('/completion-feedback'));
      });

      test('should have routes map with all required routes', () {
        expect(AppRoutes.routes.containsKey(AppRoutes.initial), isTrue);
        expect(AppRoutes.routes.containsKey(AppRoutes.login), isTrue);
        expect(AppRoutes.routes.containsKey(AppRoutes.dashboard), isTrue);
        expect(AppRoutes.routes.containsKey(AppRoutes.completionCelebration), isTrue);
        expect(AppRoutes.routes.containsKey(AppRoutes.createReminder), isTrue);
        expect(AppRoutes.routes.containsKey(AppRoutes.reminderManagement), isTrue);
        expect(AppRoutes.routes.containsKey(AppRoutes.completionFeedback), isTrue);
      });
    });
  });
}