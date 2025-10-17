import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/services/completion_feedback_service.dart';

void main() {
  group('CompletionFeedbackService Editing Capabilities', () {
    late CompletionFeedbackService service;

    setUp(() {
      service = CompletionFeedbackService.instance;
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await service.clearAllFeedback();
    });

    group('getFeedbackById', () {
      test('should return feedback by ID', () async {
        // Create test feedback
        final feedbackData = {
          'reminderId': 1,
          'reminderTitle': 'Test Reminder',
          'rating': 5,
          'notes': 'Great task!',
        };

        final savedFeedback = await service.saveFeedback(feedbackData);
        final feedbackId = savedFeedback['id'] as int;

        // Get feedback by ID
        final retrievedFeedback = await service.getFeedbackById(feedbackId);

        expect(retrievedFeedback, isNotNull);
        expect(retrievedFeedback!['id'], equals(feedbackId));
        expect(retrievedFeedback['rating'], equals(5));
        expect(retrievedFeedback['notes'], equals('Great task!'));
        expect(retrievedFeedback['version'], equals(1));
        expect(retrievedFeedback['isEdited'], equals(false));
      });

      test('should return null for non-existent ID', () async {
        final result = await service.getFeedbackById(999);
        expect(result, isNull);
      });

      test('should handle errors gracefully', () async {
        // This test ensures the method doesn't throw exceptions
        final result = await service.getFeedbackById(-1);
        expect(result, isNull);
      });
    });

    group('updateFeedback', () {
      test('should update feedback with version tracking', () async {
        // Create initial feedback
        final initialData = {
          'reminderId': 1,
          'reminderTitle': 'Test Reminder',
          'rating': 3,
          'notes': 'Initial notes',
          'difficultyLevel': 'easy',
        };

        final savedFeedback = await service.saveFeedback(initialData);
        final feedbackId = savedFeedback['id'] as int;

        // Update the feedback
        final updates = {
          'rating': 5,
          'notes': 'Updated notes',
          'difficultyLevel': 'hard',
        };

        final updatedFeedback = await service.updateFeedback(feedbackId, updates);

        expect(updatedFeedback, isNotNull);
        expect(updatedFeedback!['id'], equals(feedbackId));
        expect(updatedFeedback['rating'], equals(5));
        expect(updatedFeedback['notes'], equals('Updated notes'));
        expect(updatedFeedback['difficultyLevel'], equals('hard'));
        expect(updatedFeedback['version'], equals(2));
        expect(updatedFeedback['isEdited'], equals(true));
        expect(updatedFeedback['editedAt'], isNotNull);
        expect(updatedFeedback['originalCreatedAt'], equals(savedFeedback['createdAt']));
      });

      test('should validate updates and reject invalid data', () async {
        // Create initial feedback
        final initialData = {
          'reminderId': 1,
          'rating': 3,
        };

        final savedFeedback = await service.saveFeedback(initialData);
        final feedbackId = savedFeedback['id'] as int;

        // Try to update with invalid data
        final invalidUpdates = {
          'rating': 10, // Invalid rating (should be 1-5)
          'difficultyLevel': 'invalid_difficulty',
          'durationMinutes': -5, // Invalid duration
          'id': 999, // System field that shouldn't be updated
        };

        final result = await service.updateFeedback(feedbackId, invalidUpdates);

        // Should return the original feedback since no valid updates were provided
        expect(result, isNotNull);
        expect(result!['rating'], equals(3)); // Original rating unchanged
        expect(result['version'], equals(1)); // Version unchanged
        expect(result['isEdited'], equals(false)); // Not marked as edited
      });

      test('should handle partial valid updates', () async {
        // Create initial feedback
        final initialData = {
          'reminderId': 1,
          'rating': 3,
          'notes': 'Initial notes',
        };

        final savedFeedback = await service.saveFeedback(initialData);
        final feedbackId = savedFeedback['id'] as int;

        // Mix of valid and invalid updates
        final mixedUpdates = {
          'rating': 4, // Valid
          'notes': 'Updated notes', // Valid
          'difficultyLevel': 'invalid_level', // Invalid
          'durationMinutes': -10, // Invalid
        };

        final result = await service.updateFeedback(feedbackId, mixedUpdates);

        expect(result, isNotNull);
        expect(result!['rating'], equals(4)); // Valid update applied
        expect(result['notes'], equals('Updated notes')); // Valid update applied
        expect(result['version'], equals(2)); // Version incremented
        expect(result['isEdited'], equals(true)); // Marked as edited
      });

      test('should return null for non-existent feedback ID', () async {
        final updates = {'rating': 5};
        final result = await service.updateFeedback(999, updates);
        expect(result, isNull);
      });

      test('should preserve original creation time', () async {
        // Create initial feedback
        final initialData = {
          'reminderId': 1,
          'rating': 3,
        };

        final savedFeedback = await service.saveFeedback(initialData);
        final feedbackId = savedFeedback['id'] as int;
        final originalCreatedAt = savedFeedback['createdAt'];

        // Wait a bit to ensure different timestamps
        await Future.delayed(Duration(milliseconds: 10));

        // Update the feedback
        final updates = {'rating': 5};
        final updatedFeedback = await service.updateFeedback(feedbackId, updates);

        expect(updatedFeedback, isNotNull);
        expect(updatedFeedback!['createdAt'], equals(originalCreatedAt));
        expect(updatedFeedback['originalCreatedAt'], equals(originalCreatedAt));
        expect(updatedFeedback['editedAt'], isNotNull);
        expect(updatedFeedback['editedAt'], isNot(equals(originalCreatedAt)));
      });
    });

    group('getFeedbackHistory', () {
      test('should return feedback history for a reminder', () async {
        // Create multiple feedback entries for the same reminder
        final reminder1Data = {
          'reminderId': 1,
          'reminderTitle': 'Test Reminder 1',
          'rating': 3,
        };

        final reminder2Data = {
          'reminderId': 2,
          'reminderTitle': 'Test Reminder 2',
          'rating': 4,
        };

        // Save feedback for both reminders
        await service.saveFeedback(reminder1Data);
        final feedback2 = await service.saveFeedback(reminder2Data);

        // Update feedback for reminder 2 multiple times
        await service.updateFeedback(feedback2['id'] as int, {'rating': 5});
        await service.updateFeedback(feedback2['id'] as int, {'notes': 'Added notes'});

        // Get history for reminder 2
        final history = await service.getFeedbackHistory(2);

        expect(history.length, equals(1)); // Only one feedback entry for reminder 2
        expect(history[0]['reminderId'], equals(2));
        expect(history[0]['version'], equals(3)); // Should be version 3 after 2 updates
        expect(history[0]['rating'], equals(5));
        expect(history[0]['notes'], equals('Added notes'));
      });

      test('should return empty list for reminder with no feedback', () async {
        final history = await service.getFeedbackHistory(999);
        expect(history, isEmpty);
      });

      test('should sort feedback by version (latest first)', () async {
        // Create feedback
        final feedbackData = {
          'reminderId': 1,
          'rating': 3,
        };

        final savedFeedback = await service.saveFeedback(feedbackData);
        final feedbackId = savedFeedback['id'] as int;

        // Create multiple versions by updating
        await service.updateFeedback(feedbackId, {'rating': 4});
        await service.updateFeedback(feedbackId, {'rating': 5});

        final history = await service.getFeedbackHistory(1);

        expect(history.length, equals(1));
        expect(history[0]['version'], equals(3)); // Latest version first
        expect(history[0]['rating'], equals(5)); // Latest rating
      });
    });

    group('validation', () {
      test('should validate rating range', () async {
        final feedbackData = {'reminderId': 1, 'rating': 3};
        final savedFeedback = await service.saveFeedback(feedbackData);
        final feedbackId = savedFeedback['id'] as int;

        // Test valid ratings
        for (int rating = 1; rating <= 5; rating++) {
          final result = await service.updateFeedback(feedbackId, {'rating': rating});
          expect(result!['rating'], equals(rating));
        }

        // Test invalid ratings
        final invalidRatings = [0, 6, -1, 10];
        for (int invalidRating in invalidRatings) {
          final result = await service.updateFeedback(feedbackId, {'rating': invalidRating});
          expect(result!['rating'], isNot(equals(invalidRating)));
        }
      });

      test('should validate difficulty levels', () async {
        final feedbackData = {'reminderId': 1, 'rating': 3};
        final savedFeedback = await service.saveFeedback(feedbackData);
        final feedbackId = savedFeedback['id'] as int;

        // Test valid difficulty levels
        final validDifficulties = ['very_easy', 'easy', 'moderate', 'hard', 'very_hard'];
        for (String difficulty in validDifficulties) {
          final result = await service.updateFeedback(feedbackId, {'difficultyLevel': difficulty});
          expect(result!['difficultyLevel'], equals(difficulty));
        }

        // Test invalid difficulty level
        final result = await service.updateFeedback(feedbackId, {'difficultyLevel': 'invalid'});
        expect(result!['difficultyLevel'], isNot(equals('invalid')));
      });

      test('should validate mood values', () async {
        final feedbackData = {'reminderId': 1, 'rating': 3};
        final savedFeedback = await service.saveFeedback(feedbackData);
        final feedbackId = savedFeedback['id'] as int;

        // Test valid moods
        final validMoods = ['sad', 'neutral', 'happy', 'excited', 'blessed'];
        for (String mood in validMoods) {
          final result = await service.updateFeedback(feedbackId, {'moodBefore': mood});
          expect(result!['moodBefore'], equals(mood));
        }

        // Test invalid mood
        final result = await service.updateFeedback(feedbackId, {'moodBefore': 'invalid_mood'});
        expect(result!['moodBefore'], isNot(equals('invalid_mood')));
      });

      test('should validate duration range', () async {
        final feedbackData = {'reminderId': 1, 'rating': 3};
        final savedFeedback = await service.saveFeedback(feedbackData);
        final feedbackId = savedFeedback['id'] as int;

        // Test valid durations
        final validDurations = [1, 30, 60, 120, 1440]; // 1 min to 24 hours
        for (int duration in validDurations) {
          final result = await service.updateFeedback(feedbackId, {'durationMinutes': duration});
          expect(result!['durationMinutes'], equals(duration));
        }

        // Test invalid durations
        final invalidDurations = [-1, 0, 1441]; // Negative, zero, over 24 hours
        for (int invalidDuration in invalidDurations) {
          final result = await service.updateFeedback(feedbackId, {'durationMinutes': invalidDuration});
          expect(result!['durationMinutes'], isNot(equals(invalidDuration)));
        }
      });

      test('should validate string length limits', () async {
        final feedbackData = {'reminderId': 1, 'rating': 3};
        final savedFeedback = await service.saveFeedback(feedbackData);
        final feedbackId = savedFeedback['id'] as int;

        // Test valid length string
        final validNotes = 'A' * 500; // Max length
        final result1 = await service.updateFeedback(feedbackId, {'notes': validNotes});
        expect(result1!['notes'], equals(validNotes));

        // Test over-length string
        final tooLongNotes = 'A' * 1001; // Over max length
        final result2 = await service.updateFeedback(feedbackId, {'notes': tooLongNotes});
        expect(result2!['notes'], isNot(equals(tooLongNotes)));
      });
    });

    group('error handling', () {
      test('should handle corrupted data gracefully', () async {
        // This test ensures the service doesn't crash with unexpected data
        final updates = {
          'rating': 'not_a_number', // Wrong type
          'wouldRecommend': 'yes', // Wrong type (should be bool)
          'tags': 'not_a_list', // Wrong type (should be list)
        };

        final result = await service.updateFeedback(1, updates);
        expect(result, isNull); // Should return null for non-existent ID
      });

      test('should handle empty updates', () async {
        final feedbackData = {'reminderId': 1, 'rating': 3};
        final savedFeedback = await service.saveFeedback(feedbackData);
        final feedbackId = savedFeedback['id'] as int;

        final result = await service.updateFeedback(feedbackId, {});
        expect(result, isNotNull);
        expect(result!['version'], equals(1)); // Version should not increment
        expect(result['isEdited'], equals(false)); // Should not be marked as edited
      });
    });
  });
}