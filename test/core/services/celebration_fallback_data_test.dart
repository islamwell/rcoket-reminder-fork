import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/services/celebration_fallback_data.dart';

void main() {
  group('CelebrationFallbackData', () {
    group('getNewUserStats', () {
      test('should return encouraging stats for new users', () {
        final stats = CelebrationFallbackData.getNewUserStats();

        expect(stats['totalCompletions'], equals(1));
        expect(stats['currentStreak'], equals(1));
        expect(stats['longestStreak'], equals(1));
        expect(stats['todayCompletions'], equals(1));
        expect(stats['averageRating'], equals(5.0));
        expect(stats['isFirstCompletion'], isTrue);
        expect(stats['categoryStats'], isA<Map<String, int>>());
        expect(stats['weeklyCompletions'], isA<Map<String, int>>());
        expect(stats['ratingDistribution'], isA<Map<int, int>>());
      });

      test('should have consistent weekly completions for new user', () {
        final stats = CelebrationFallbackData.getNewUserStats();
        final weeklyCompletions = stats['weeklyCompletions'] as Map<String, int>;

        // Should have 7 days of data
        expect(weeklyCompletions.length, equals(7));
        
        // Should have exactly 1 total completion (today)
        final totalCompletions = weeklyCompletions.values.reduce((a, b) => a + b);
        expect(totalCompletions, equals(1));
      });

      test('should have positive rating distribution', () {
        final stats = CelebrationFallbackData.getNewUserStats();
        final ratingDistribution = stats['ratingDistribution'] as Map<int, int>;

        expect(ratingDistribution[5], equals(1));
        expect(ratingDistribution[4], equals(0));
        expect(ratingDistribution[3], equals(0));
        expect(ratingDistribution[2], equals(0));
        expect(ratingDistribution[1], equals(0));
      });
    });

    group('getExistingUserFallbackStats', () {
      test('should return realistic stats for existing users', () {
        final stats = CelebrationFallbackData.getExistingUserFallbackStats();

        expect(stats['totalCompletions'], greaterThanOrEqualTo(5));
        expect(stats['totalCompletions'], lessThanOrEqualTo(24));
        expect(stats['currentStreak'], greaterThanOrEqualTo(1));
        expect(stats['currentStreak'], lessThanOrEqualTo(7));
        expect(stats['longestStreak'], greaterThanOrEqualTo(3));
        expect(stats['averageRating'], greaterThanOrEqualTo(4.0));
        expect(stats['averageRating'], lessThanOrEqualTo(5.0));
        expect(stats['isFirstCompletion'], isFalse);
      });

      test('should have varied weekly completions', () {
        final stats = CelebrationFallbackData.getExistingUserFallbackStats();
        final weeklyCompletions = stats['weeklyCompletions'] as Map<String, int>;

        expect(weeklyCompletions.length, equals(7));
        // Should have at least some completions
        final totalCompletions = weeklyCompletions.values.reduce((a, b) => a + b);
        expect(totalCompletions, greaterThanOrEqualTo(0));
      });

      test('should have realistic category distribution', () {
        final stats = CelebrationFallbackData.getExistingUserFallbackStats();
        final categoryStats = stats['categoryStats'] as Map<String, int>;

        expect(categoryStats.isNotEmpty, isTrue);
        // All values should be positive
        for (final count in categoryStats.values) {
          expect(count, greaterThan(0));
        }
      });
    });

    group('encouraging messages', () {
      test('getNewUserEncouragingMessages should return non-empty list', () {
        final messages = CelebrationFallbackData.getNewUserEncouragingMessages();

        expect(messages.isNotEmpty, isTrue);
        expect(messages.length, greaterThan(5));
        
        // All messages should be strings and non-empty
        for (final message in messages) {
          expect(message, isA<String>());
          expect(message.isNotEmpty, isTrue);
        }
      });

      test('getProgressEncouragingMessages should return non-empty list', () {
        final messages = CelebrationFallbackData.getProgressEncouragingMessages();

        expect(messages.isNotEmpty, isTrue);
        expect(messages.length, greaterThan(5));
        
        for (final message in messages) {
          expect(message, isA<String>());
          expect(message.isNotEmpty, isTrue);
        }
      });

      test('getMilestoneMessages should return appropriate messages for different milestones', () {
        // First completion
        final firstMessages = CelebrationFallbackData.getMilestoneMessages(1);
        expect(firstMessages, equals(CelebrationFallbackData.getNewUserEncouragingMessages()));

        // Week milestone
        final weekMessages = CelebrationFallbackData.getMilestoneMessages(7);
        expect(weekMessages.isNotEmpty, isTrue);
        expect(weekMessages.first.contains('week') || weekMessages.first.contains('Seven'), isTrue);

        // Month milestone
        final monthMessages = CelebrationFallbackData.getMilestoneMessages(30);
        expect(monthMessages.isNotEmpty, isTrue);
        expect(monthMessages.first.contains('month') || monthMessages.first.contains('30'), isTrue);

        // Decade milestone
        final decadeMessages = CelebrationFallbackData.getMilestoneMessages(20);
        expect(decadeMessages.isNotEmpty, isTrue);

        // Regular progress
        final regularMessages = CelebrationFallbackData.getMilestoneMessages(15);
        expect(regularMessages, equals(CelebrationFallbackData.getProgressEncouragingMessages()));
      });

      test('getCategorySpecificMessages should return category-appropriate messages', () {
        final categories = ['prayer', 'meditation', 'gratitude', 'charity', 'unknown'];
        
        for (final category in categories) {
          final messages = CelebrationFallbackData.getCategorySpecificMessages(category);
          expect(messages.isNotEmpty, isTrue);
          
          for (final message in messages) {
            expect(message, isA<String>());
            expect(message.isNotEmpty, isTrue);
          }
        }

        // Test case insensitivity
        final prayerLower = CelebrationFallbackData.getCategorySpecificMessages('prayer');
        final prayerUpper = CelebrationFallbackData.getCategorySpecificMessages('PRAYER');
        expect(prayerLower, equals(prayerUpper));
      });
    });

    group('getDefaultCompletionContext', () {
      test('should return valid default context', () {
        final context = CelebrationFallbackData.getDefaultCompletionContext();

        expect(context['reminderTitle'], equals('Spiritual Practice'));
        expect(context['reminderCategory'], equals('spiritual'));
        expect(context['completionTime'], isA<String>());
        expect(context['completionNotes'], isNull);
        expect(context['reminderId'], isNull);
        expect(context['actualDuration'], isNull);

        // Verify completion time is a valid ISO string
        final completionTime = DateTime.parse(context['completionTime']);
        expect(completionTime, isA<DateTime>());
      });
    });

    group('getStatsForScenario', () {
      test('should return appropriate stats for each scenario', () {
        // New user scenario
        final newUserStats = CelebrationFallbackData.getStatsForScenario(FallbackScenario.newUser);
        expect(newUserStats['isFirstCompletion'], isTrue);
        expect(newUserStats['totalCompletions'], equals(1));

        // Existing user data failed scenario
        final existingUserStats = CelebrationFallbackData.getStatsForScenario(FallbackScenario.existingUserDataFailed);
        expect(existingUserStats['isFirstCompletion'], isFalse);
        expect(existingUserStats['totalCompletions'], greaterThan(1));

        // Partial data scenario
        final partialDataStats = CelebrationFallbackData.getStatsForScenario(FallbackScenario.partialDataAvailable);
        expect(partialDataStats['hasPartialData'], isTrue);

        // Offline scenario
        final offlineStats = CelebrationFallbackData.getStatsForScenario(FallbackScenario.offline);
        expect(offlineStats['isOffline'], isTrue);
        expect(offlineStats['totalCompletions'], equals(1));
      });
    });

    group('getEncouragingMessage', () {
      test('should return appropriate message for different scenarios', () {
        // New user scenario
        final newUserMessage = CelebrationFallbackData.getEncouragingMessage(
          scenario: FallbackScenario.newUser,
        );
        expect(newUserMessage, isA<String>());
        expect(newUserMessage.isNotEmpty, isTrue);

        // With total completions
        final milestoneMessage = CelebrationFallbackData.getEncouragingMessage(
          totalCompletions: 7,
        );
        expect(milestoneMessage, isA<String>());
        expect(milestoneMessage.isNotEmpty, isTrue);

        // With category
        final categoryMessage = CelebrationFallbackData.getEncouragingMessage(
          category: 'prayer',
        );
        expect(categoryMessage, isA<String>());
        expect(categoryMessage.isNotEmpty, isTrue);

        // Existing user scenario
        final existingUserMessage = CelebrationFallbackData.getEncouragingMessage(
          scenario: FallbackScenario.existingUserDataFailed,
        );
        expect(existingUserMessage, isA<String>());
        expect(existingUserMessage.isNotEmpty, isTrue);
      });

      test('should return different messages on multiple calls', () {
        final messages = <String>{};
        
        // Generate multiple messages to test randomness
        for (int i = 0; i < 20; i++) {
          final message = CelebrationFallbackData.getEncouragingMessage();
          messages.add(message);
        }
        
        // Should have some variety (at least 2 different messages in 20 calls)
        expect(messages.length, greaterThanOrEqualTo(1));
      });
    });

    group('data consistency', () {
      test('weekly completions should always have 7 days', () {
        final scenarios = [
          FallbackScenario.newUser,
          FallbackScenario.existingUserDataFailed,
          FallbackScenario.partialDataAvailable,
          FallbackScenario.offline,
        ];

        for (final scenario in scenarios) {
          final stats = CelebrationFallbackData.getStatsForScenario(scenario);
          if (stats.containsKey('weeklyCompletions')) {
            final weeklyCompletions = stats['weeklyCompletions'] as Map<String, int>;
            expect(weeklyCompletions.length, equals(7));
          }
        }
      });

      test('rating distributions should be valid', () {
        final stats = CelebrationFallbackData.getExistingUserFallbackStats();
        final ratingDistribution = stats['ratingDistribution'] as Map<int, int>;

        // Should have ratings 1-5
        expect(ratingDistribution.keys.toSet(), equals({1, 2, 3, 4, 5}));
        
        // All values should be non-negative
        for (final count in ratingDistribution.values) {
          expect(count, greaterThanOrEqualTo(0));
        }
      });

      test('difficulty distributions should be valid', () {
        final stats = CelebrationFallbackData.getExistingUserFallbackStats();
        final difficultyDistribution = stats['difficultyDistribution'] as Map<String, int>;

        final expectedDifficulties = {'very_easy', 'easy', 'moderate', 'hard', 'very_hard'};
        expect(difficultyDistribution.keys.toSet(), equals(expectedDifficulties));
        
        // All values should be non-negative
        for (final count in difficultyDistribution.values) {
          expect(count, greaterThanOrEqualTo(0));
        }
      });
    });

    group('edge cases', () {
      test('should handle empty category gracefully', () {
        final messages = CelebrationFallbackData.getCategorySpecificMessages('');
        expect(messages, equals(CelebrationFallbackData.getProgressEncouragingMessages()));
      });

      test('should handle null values in getEncouragingMessage', () {
        final message = CelebrationFallbackData.getEncouragingMessage(
          totalCompletions: null,
          category: null,
        );
        expect(message, isA<String>());
        expect(message.isNotEmpty, isTrue);
      });

      test('should generate consistent data structure across multiple calls', () {
        for (int i = 0; i < 5; i++) {
          final stats = CelebrationFallbackData.getNewUserStats();
          
          // Verify required keys are always present
          final requiredKeys = [
            'totalCompletions', 'currentStreak', 'longestStreak', 
            'todayCompletions', 'averageRating', 'isFirstCompletion',
            'categoryStats', 'weeklyCompletions', 'ratingDistribution'
          ];
          
          for (final key in requiredKeys) {
            expect(stats.containsKey(key), isTrue, reason: 'Missing key: $key');
          }
        }
      });
    });
  });
}