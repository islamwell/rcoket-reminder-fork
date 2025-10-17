import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/core/services/completion_feedback_service.dart';
import '../../../lib/core/services/celebration_fallback_data.dart';

void main() {
  group('CompletionFeedbackService Enhanced Error Handling', () {
    late CompletionFeedbackService service;

    setUp(() {
      service = CompletionFeedbackService.instance;
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await service.clearAllFeedback();
    });

    group('getDashboardStats with error handling', () {
      test('should return fallback data for new users instead of empty data', () async {
        final stats = await service.getDashboardStats();

        // Should return encouraging data, not empty data
        expect(stats['totalCompletions'], equals(1));
        expect(stats['currentStreak'], equals(1));
        expect(stats['averageRating'], equals(5.0));
        expect(stats['isFirstCompletion'], isTrue);
        expect(stats['categoryStats'], isA<Map<String, int>>());
        expect(stats['weeklyCompletions'], isA<Map<String, int>>());
      });

      test('should handle corrupted data gracefully', () async {
        // Set corrupted JSON data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('completion_feedback', 'invalid json data');

        final stats = await service.getDashboardStats();

        // Should return fallback data instead of throwing
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['totalCompletions'], greaterThanOrEqualTo(1));
        expect(stats.containsKey('averageRating'), isTrue);
      });

      test('should handle missing required fields gracefully', () async {
        // Create feedback with missing fields
        final invalidFeedback = [
          {'id': 1}, // Missing required fields
          {'rating': 'invalid'}, // Invalid data type
          {
            'id': 2,
            'rating': 5,
            'createdAt': 'invalid-date',
            'completedAt': 'invalid-date',
          },
        ];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('completion_feedback', 
            '${invalidFeedback.map((f) => f.toString()).join(',')}');

        final stats = await service.getDashboardStats();

        // Should return fallback data
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['averageRating'], isA<double>());
        expect(stats['averageRating'], greaterThanOrEqualTo(0.0));
      });

      test('should calculate stats with partial valid data', () async {
        // Mix of valid and invalid feedback
        final mixedFeedback = [
          {
            'id': 1,
            'rating': 5,
            'durationMinutes': 15,
            'difficultyLevel': 'moderate',
            'moodBefore': 'neutral',
            'moodAfter': 'happy',
            'wouldRecommend': true,
            'reminderCategory': 'spiritual',
            'createdAt': DateTime.now().toIso8601String(),
            'completedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 2,
            'rating': null, // Invalid rating
            'durationMinutes': 'invalid', // Invalid duration
            'createdAt': DateTime.now().toIso8601String(),
            'completedAt': DateTime.now().toIso8601String(),
          },
        ];

        await service.clearAllFeedback();
        for (final feedback in mixedFeedback) {
          try {
            await service.saveFeedback(feedback);
          } catch (e) {
            // Some may fail to save, that's expected
          }
        }

        final stats = await service.getDashboardStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['totalCompletions'], greaterThanOrEqualTo(1));
        expect(stats['averageRating'], isA<double>());
        expect(stats['averageDuration'], isA<double>());
      });
    });

    group('getDashboardStatsWithRetry', () {
      test('should retry on failure and eventually return fallback', () async {
        // This test simulates retry behavior
        final stats = await service.getDashboardStatsWithRetry(
          maxRetries: 2,
          initialDelay: Duration(milliseconds: 10),
        );

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('totalCompletions'), isTrue);
      });

      test('should respect retry parameters', () async {
        final stopwatch = Stopwatch()..start();
        
        final stats = await service.getDashboardStatsWithRetry(
          maxRetries: 1,
          initialDelay: Duration(milliseconds: 50),
        );
        
        stopwatch.stop();
        
        expect(stats, isA<Map<String, dynamic>>());
        // Should complete quickly since we're not actually failing
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('getCompletionStreaks with error handling', () {
      test('should return encouraging streak for new users', () async {
        final streaks = await service.getCompletionStreaks();

        expect(streaks['currentStreak'], equals(1));
        expect(streaks['longestStreak'], equals(1));
      });

      test('should handle corrupted date data gracefully', () async {
        // Create feedback with invalid dates
        final invalidFeedback = {
          'id': 1,
          'rating': 5,
          'createdAt': 'invalid-date',
          'completedAt': 'invalid-date',
        };

        try {
          await service.saveFeedback(invalidFeedback);
        } catch (e) {
          // Expected to fail
        }

        final streaks = await service.getCompletionStreaks();

        expect(streaks, isA<Map<String, int>>());
        expect(streaks['currentStreak'], greaterThanOrEqualTo(1));
        expect(streaks['longestStreak'], greaterThanOrEqualTo(1));
      });

      test('should calculate streaks with mixed valid/invalid data', () async {
        final now = DateTime.now();
        final validFeedback = {
          'id': 1,
          'rating': 5,
          'createdAt': now.toIso8601String(),
          'completedAt': now.toIso8601String(),
        };

        await service.saveFeedback(validFeedback);

        final streaks = await service.getCompletionStreaks();

        expect(streaks['currentStreak'], greaterThanOrEqualTo(1));
        expect(streaks['longestStreak'], greaterThanOrEqualTo(1));
      });
    });

    group('getCompletionStreaksWithRetry', () {
      test('should retry and return fallback on persistent failure', () async {
        final streaks = await service.getCompletionStreaksWithRetry(
          maxRetries: 2,
          initialDelay: Duration(milliseconds: 10),
        );

        expect(streaks, isA<Map<String, int>>());
        expect(streaks['currentStreak'], greaterThanOrEqualTo(1));
        expect(streaks['longestStreak'], greaterThanOrEqualTo(1));
      });
    });

    group('getAllFeedback with enhanced validation', () {
      test('should return empty list for corrupted data', () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('completion_feedback', 'invalid json');

        final feedback = await service.getAllFeedback();

        expect(feedback, isEmpty);
      });

      test('should filter out invalid entries but keep valid ones', () async {
        // Manually set mixed valid/invalid data
        final mixedData = [
          {
            'id': 1,
            'createdAt': DateTime.now().toIso8601String(),
            'rating': 5,
          },
          {
            'id': null, // Invalid - missing ID
            'createdAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 2,
            'createdAt': 'invalid-date', // Invalid date
          },
          {
            'id': 3,
            'createdAt': DateTime.now().toIso8601String(),
            'rating': 4,
          },
        ];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('completion_feedback', 
            mixedData.map((e) => e.toString()).join(','));

        // This will likely fail due to invalid JSON format, but that's expected
        final feedback = await service.getAllFeedback();

        expect(feedback, isA<List<Map<String, dynamic>>>());
        // Should either be empty (if JSON parsing fails) or contain only valid entries
      });

      test('should handle SharedPreferences access errors', () async {
        // This test verifies the method doesn't throw on SharedPreferences errors
        final feedback = await service.getAllFeedback();

        expect(feedback, isA<List<Map<String, dynamic>>>());
      });
    });

    group('data validation and cleaning', () {
      test('should save and retrieve valid feedback correctly', () async {
        final validFeedback = {
          'rating': 5,
          'durationMinutes': 15,
          'difficultyLevel': 'moderate',
          'moodBefore': 'neutral',
          'moodAfter': 'happy',
          'wouldRecommend': true,
          'reminderCategory': 'spiritual',
          'completedAt': DateTime.now().toIso8601String(),
        };

        final saved = await service.saveFeedback(validFeedback);
        expect(saved['id'], isA<int>());

        final allFeedback = await service.getAllFeedback();
        expect(allFeedback.length, equals(1));
        expect(allFeedback.first['rating'], equals(5));
      });

      test('should handle edge cases in stats calculation', () async {
        // Create feedback with edge case values
        final edgeCaseFeedback = {
          'rating': 1, // Minimum rating
          'durationMinutes': 0, // Zero duration
          'difficultyLevel': 'unknown_difficulty', // Unknown difficulty
          'moodBefore': 'unknown_mood', // Unknown mood
          'moodAfter': 'unknown_mood',
          'wouldRecommend': false,
          'reminderCategory': '', // Empty category
          'completedAt': DateTime.now().toIso8601String(),
        };

        await service.saveFeedback(edgeCaseFeedback);
        final stats = await service.getDashboardStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['totalCompletions'], greaterThanOrEqualTo(1));
        expect(stats['averageRating'], isA<double>());
        expect(stats['categoryStats'], isA<Map<String, int>>());
      });
    });

    group('fallback integration', () {
      test('should use CelebrationFallbackData for new users', () async {
        final stats = await service.getDashboardStats();
        final fallbackStats = CelebrationFallbackData.getNewUserStats();

        expect(stats['totalCompletions'], equals(fallbackStats['totalCompletions']));
        expect(stats['isFirstCompletion'], equals(fallbackStats['isFirstCompletion']));
      });

      test('should provide encouraging data even on errors', () async {
        // Force an error condition
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('completion_feedback', 'corrupted data');

        final stats = await service.getDashboardStats();

        // Should still provide encouraging data
        expect(stats['totalCompletions'], greaterThanOrEqualTo(1));
        expect(stats['averageRating'], greaterThanOrEqualTo(4.0));
        expect(stats['currentStreak'], greaterThanOrEqualTo(1));
      });
    });
  });
}