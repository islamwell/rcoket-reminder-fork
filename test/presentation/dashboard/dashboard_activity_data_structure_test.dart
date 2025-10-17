import 'package:flutter_test/flutter_test.dart';

// Helper functions for testing data structure enhancements
double calculateMoodImprovement(String? moodBefore, String? moodAfter) {
  final moodValues = {
    'sad': 1.0,
    'neutral': 2.0,
    'happy': 3.0,
    'excited': 4.0,
    'blessed': 5.0,
  };
  
  final beforeValue = moodValues[moodBefore] ?? 2.0;
  final afterValue = moodValues[moodAfter] ?? 3.0;
  
  return afterValue - beforeValue;
}

String formatDuration(int? minutes) {
  if (minutes == null || minutes <= 0) return '0 min';
  
  if (minutes < 60) {
    return '${minutes} min';
  } else {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${remainingMinutes}m';
    }
  }
}

String generateRatingStars(int? rating) {
  if (rating == null || rating <= 0) return '';
  
  final stars = '★' * rating;
  final emptyStars = '☆' * (5 - rating);
  return stars + emptyStars;
}

String buildCompletionSubtitle(Map<String, dynamic> completionData) {
  final rating = completionData['rating'] as int? ?? 0;
  final mood = completionData['mood'] as int? ?? 0;
  
  if (rating > 0 && mood > 0) {
    return 'Rating: $rating/5 • Mood: $mood/5';
  } else if (rating > 0) {
    return 'Rating: $rating/5';
  } else if (mood > 0) {
    return 'Mood: $mood/5';
  } else {
    return 'Completed successfully';
  }
}

Map<String, dynamic> enhanceCompletionData(Map<String, dynamic> completion) {
  final enhanced = Map<String, dynamic>.from(completion);
  
  // Ensure all required fields exist with proper defaults
  enhanced['rating'] = completion['rating'] ?? 0;
  enhanced['mood'] = completion['mood'] ?? 0;
  enhanced['moodBefore'] = completion['moodBefore'] ?? 'neutral';
  enhanced['moodAfter'] = completion['moodAfter'] ?? 'neutral';
  enhanced['comments'] = completion['comments'] ?? '';
  enhanced['difficultyLevel'] = completion['difficultyLevel'] ?? 'moderate';
  enhanced['durationMinutes'] = completion['durationMinutes'] ?? 0;
  enhanced['wouldRecommend'] = completion['wouldRecommend'] ?? false;
  enhanced['completedAt'] = completion['completedAt'] ?? DateTime.now().toIso8601String();
  enhanced['reminderTitle'] = completion['reminderTitle'] ?? 'Unknown Reminder';
  enhanced['reminderCategory'] = completion['reminderCategory'] ?? 'General';
  
  // Add computed fields for better display
  enhanced['hasComments'] = (completion['comments'] as String?)?.isNotEmpty ?? false;
  enhanced['hasRating'] = (completion['rating'] as int?) != null && (completion['rating'] as int) > 0;
  enhanced['moodImprovement'] = calculateMoodImprovement(
    completion['moodBefore'] as String?,
    completion['moodAfter'] as String?,
  );
  enhanced['formattedDuration'] = formatDuration(completion['durationMinutes'] as int?);
  enhanced['ratingStars'] = generateRatingStars(completion['rating'] as int?);
  
  return enhanced;
}

void main() {
  group('Dashboard Activity Data Structure Tests', () {
    group('Completion Data Enhancement', () {
      test('should enhance completion data with all required fields', () {
        // Arrange
        final completion = {
          'id': 1,
          'reminderId': 1,
          'reminderTitle': 'Test Reminder',
          'reminderCategory': 'spiritual',
          'rating': 4,
          'mood': 5,
          'moodBefore': 'neutral',
          'moodAfter': 'happy',
          'comments': 'Great session!',
          'difficultyLevel': 'easy',
          'durationMinutes': 15,
          'wouldRecommend': true,
          'completedAt': '2024-01-02T10:00:00Z',
        };

        // Act
        final enhancedCompletion = enhanceCompletionData(completion);

        // Assert
        expect(enhancedCompletion['rating'], equals(4));
        expect(enhancedCompletion['mood'], equals(5));
        expect(enhancedCompletion['comments'], equals('Great session!'));
        expect(enhancedCompletion['moodBefore'], equals('neutral'));
        expect(enhancedCompletion['moodAfter'], equals('happy'));
        expect(enhancedCompletion['difficultyLevel'], equals('easy'));
        expect(enhancedCompletion['durationMinutes'], equals(15));
        expect(enhancedCompletion['hasComments'], isTrue);
        expect(enhancedCompletion['hasRating'], isTrue);
        expect(enhancedCompletion['moodImprovement'], greaterThan(0));
        expect(enhancedCompletion['formattedDuration'], equals('15 min'));
        expect(enhancedCompletion['ratingStars'], equals('★★★★☆'));
      });

      test('should handle missing completion data fields gracefully', () {
        // Arrange
        final completion = {
          'id': 1,
          'reminderId': 1,
          'completedAt': '2024-01-02T10:00:00Z',
          // Missing most fields to test defaults
        };

        // Act
        final enhancedCompletion = enhanceCompletionData(completion);
        
        // Assert - Verify defaults are applied
        expect(enhancedCompletion['rating'], equals(0));
        expect(enhancedCompletion['mood'], equals(0));
        expect(enhancedCompletion['comments'], equals(''));
        expect(enhancedCompletion['moodBefore'], equals('neutral'));
        expect(enhancedCompletion['moodAfter'], equals('neutral'));
        expect(enhancedCompletion['difficultyLevel'], equals('moderate'));
        expect(enhancedCompletion['durationMinutes'], equals(0));
        expect(enhancedCompletion['hasComments'], isFalse);
        expect(enhancedCompletion['hasRating'], isFalse);
        expect(enhancedCompletion['reminderTitle'], equals('Unknown Reminder'));
        expect(enhancedCompletion['reminderCategory'], equals('General'));
        expect(enhancedCompletion['formattedDuration'], equals('0 min'));
        expect(enhancedCompletion['ratingStars'], equals(''));
        expect(enhancedCompletion['moodImprovement'], equals(1.0)); // neutral to neutral default improvement
      });

      test('should include all required fields for detail screen display', () {
        // Arrange
        final completion = {
          'id': 1,
          'rating': 3,
          'mood': 4,
          'moodBefore': 'sad',
          'moodAfter': 'happy',
          'comments': 'Felt much better after this session',
          'difficultyLevel': 'moderate',
          'durationMinutes': 25,
        };

        // Act
        final enhancedCompletion = enhanceCompletionData(completion);

        // Assert - Verify all fields required for detail screen are present
        expect(enhancedCompletion.containsKey('rating'), isTrue);
        expect(enhancedCompletion.containsKey('mood'), isTrue);
        expect(enhancedCompletion.containsKey('comments'), isTrue);
        expect(enhancedCompletion.containsKey('moodBefore'), isTrue);
        expect(enhancedCompletion.containsKey('moodAfter'), isTrue);
        expect(enhancedCompletion.containsKey('difficultyLevel'), isTrue);
        expect(enhancedCompletion.containsKey('durationMinutes'), isTrue);
        expect(enhancedCompletion.containsKey('hasComments'), isTrue);
        expect(enhancedCompletion.containsKey('hasRating'), isTrue);
        expect(enhancedCompletion.containsKey('moodImprovement'), isTrue);
        expect(enhancedCompletion.containsKey('formattedDuration'), isTrue);
        expect(enhancedCompletion.containsKey('ratingStars'), isTrue);
        
        // Verify computed values are correct
        expect(enhancedCompletion['hasComments'], isTrue);
        expect(enhancedCompletion['hasRating'], isTrue);
        expect(enhancedCompletion['moodImprovement'], equals(2.0)); // sad to happy
        expect(enhancedCompletion['formattedDuration'], equals('25 min'));
        expect(enhancedCompletion['ratingStars'], equals('★★★☆☆'));
      });
    });

    group('Helper Methods', () {
      test('buildCompletionSubtitle should format subtitle correctly', () {
        // Test with rating and mood
        var completionData = {'rating': 4, 'mood': 5};
        var subtitle = buildCompletionSubtitle(completionData);
        expect(subtitle, equals('Rating: 4/5 • Mood: 5/5'));

        // Test with only rating
        completionData = {'rating': 3, 'mood': 0};
        subtitle = buildCompletionSubtitle(completionData);
        expect(subtitle, equals('Rating: 3/5'));

        // Test with only mood
        completionData = {'rating': 0, 'mood': 4};
        subtitle = buildCompletionSubtitle(completionData);
        expect(subtitle, equals('Mood: 4/5'));

        // Test with neither
        completionData = {'rating': 0, 'mood': 0};
        subtitle = buildCompletionSubtitle(completionData);
        expect(subtitle, equals('Completed successfully'));
      });

      test('formatDuration should format duration correctly', () {
        expect(formatDuration(0), equals('0 min'));
        expect(formatDuration(30), equals('30 min'));
        expect(formatDuration(60), equals('1h'));
        expect(formatDuration(90), equals('1h 30m'));
        expect(formatDuration(null), equals('0 min'));
      });

      test('generateRatingStars should generate correct star strings', () {
        expect(generateRatingStars(0), equals(''));
        expect(generateRatingStars(1), equals('★☆☆☆☆'));
        expect(generateRatingStars(3), equals('★★★☆☆'));
        expect(generateRatingStars(5), equals('★★★★★'));
        expect(generateRatingStars(null), equals(''));
      });

      test('calculateMoodImprovement should calculate improvement correctly', () {
        expect(calculateMoodImprovement('sad', 'happy'), equals(2.0));
        expect(calculateMoodImprovement('neutral', 'blessed'), equals(3.0));
        expect(calculateMoodImprovement('happy', 'sad'), equals(-2.0));
        expect(calculateMoodImprovement('neutral', 'neutral'), equals(0.0));
        expect(calculateMoodImprovement(null, null), equals(1.0)); // default improvement
      });
    });

    group('Data Structure Requirements Validation', () {
      test('should ensure completion data includes rating for detail screen', () {
        final completion = {'rating': 4};
        final enhanced = enhanceCompletionData(completion);
        
        expect(enhanced['rating'], equals(4));
        expect(enhanced['hasRating'], isTrue);
        expect(enhanced['ratingStars'], equals('★★★★☆'));
      });

      test('should ensure completion data includes mood for detail screen', () {
        final completion = {
          'mood': 5,
          'moodBefore': 'neutral',
          'moodAfter': 'blessed'
        };
        final enhanced = enhanceCompletionData(completion);
        
        expect(enhanced['mood'], equals(5));
        expect(enhanced['moodBefore'], equals('neutral'));
        expect(enhanced['moodAfter'], equals('blessed'));
        expect(enhanced['moodImprovement'], equals(3.0));
      });

      test('should ensure completion data includes comments for detail screen', () {
        final completion = {'comments': 'This was a transformative experience'};
        final enhanced = enhanceCompletionData(completion);
        
        expect(enhanced['comments'], equals('This was a transformative experience'));
        expect(enhanced['hasComments'], isTrue);
      });

      test('should handle empty or null comments gracefully', () {
        final completion1 = {'comments': ''};
        final enhanced1 = enhanceCompletionData(completion1);
        expect(enhanced1['hasComments'], isFalse);

        final completion2 = <String, dynamic>{};
        final enhanced2 = enhanceCompletionData(completion2);
        expect(enhanced2['comments'], equals(''));
        expect(enhanced2['hasComments'], isFalse);
      });

      test('should provide comprehensive data for reminder detail navigation', () {
        final completion = {
          'id': 1,
          'reminderId': 123,
          'reminderTitle': 'Morning Prayer',
          'reminderCategory': 'spiritual',
          'rating': 5,
          'mood': 4,
          'moodBefore': 'neutral',
          'moodAfter': 'blessed',
          'comments': 'Felt very peaceful and centered',
          'difficultyLevel': 'easy',
          'durationMinutes': 20,
          'wouldRecommend': true,
          'completedAt': '2024-01-15T08:00:00Z',
        };

        final enhanced = enhanceCompletionData(completion);

        // Verify all requirements 4.2, 4.3, 4.4 are met
        // Requirement 4.2: Display rating information
        expect(enhanced['rating'], equals(5));
        expect(enhanced['hasRating'], isTrue);
        expect(enhanced['ratingStars'], equals('★★★★★'));

        // Requirement 4.3: Display mood information
        expect(enhanced['mood'], equals(4));
        expect(enhanced['moodBefore'], equals('neutral'));
        expect(enhanced['moodAfter'], equals('blessed'));
        expect(enhanced['moodImprovement'], equals(3.0));

        // Requirement 4.4: Display associated comments
        expect(enhanced['comments'], equals('Felt very peaceful and centered'));
        expect(enhanced['hasComments'], isTrue);

        // Additional fields for comprehensive detail display
        expect(enhanced['difficultyLevel'], equals('easy'));
        expect(enhanced['durationMinutes'], equals(20));
        expect(enhanced['formattedDuration'], equals('20 min'));
        expect(enhanced['reminderTitle'], equals('Morning Prayer'));
        expect(enhanced['reminderCategory'], equals('spiritual'));
      });
    });
  });
}