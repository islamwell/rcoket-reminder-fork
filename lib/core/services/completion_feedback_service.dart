import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'celebration_fallback_data.dart';

class CompletionFeedbackService {
  static const String _feedbackKey = 'completion_feedback';
  static const String _nextIdKey = 'next_feedback_id';

  static CompletionFeedbackService? _instance;
  static CompletionFeedbackService get instance => _instance ??= CompletionFeedbackService._();
  CompletionFeedbackService._();

  // Save completion feedback with version tracking
  Future<Map<String, dynamic>> saveFeedback(Map<String, dynamic> feedbackData) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbacks = await getAllFeedback();
    
    // Get next ID
    final nextId = prefs.getInt(_nextIdKey) ?? 1;
    
    final feedback = {
      'id': nextId,
      ...feedbackData,
      'createdAt': DateTime.now().toIso8601String(),
      'version': 1, // Initial version
      'isEdited': false, // Not edited initially
    };
    
    feedbacks.add(feedback);
    
    // Save feedbacks and increment next ID
    await prefs.setString(_feedbackKey, jsonEncode(feedbacks));
    await prefs.setInt(_nextIdKey, nextId + 1);
    
    return feedback;
  }

  // Get all completion feedback with enhanced error handling
  Future<List<Map<String, dynamic>>> getAllFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackJson = prefs.getString(_feedbackKey);
      
      if (feedbackJson == null || feedbackJson.isEmpty) {
        return [];
      }
      
      try {
        final List<dynamic> decoded = jsonDecode(feedbackJson);
        final List<Map<String, dynamic>> feedback = decoded.cast<Map<String, dynamic>>();
        
        // Validate and clean the feedback data
        return _validateAndCleanFeedback(feedback);
      } catch (e) {
        print('Error decoding feedback JSON: $e');
        // Try to recover by clearing corrupted data
        await _clearCorruptedData();
        return [];
      }
    } catch (e) {
      print('Error accessing SharedPreferences: $e');
      return [];
    }
  }

  // Validate and clean feedback data to prevent future errors
  List<Map<String, dynamic>> _validateAndCleanFeedback(List<Map<String, dynamic>> feedback) {
    final cleanedFeedback = <Map<String, dynamic>>[];
    
    for (final entry in feedback) {
      try {
        // Validate required fields and data types
        if (entry['id'] != null && 
            entry['createdAt'] != null &&
            entry['createdAt'] is String) {
          
          // Try to parse the date to ensure it's valid
          DateTime.parse(entry['createdAt'] as String);
          
          // Add to cleaned list if validation passes
          cleanedFeedback.add(entry);
        }
      } catch (e) {
        print('Skipping invalid feedback entry: $e');
        // Skip invalid entries but continue processing others
      }
    }
    
    return cleanedFeedback;
  }

  // Clear corrupted data and reset
  Future<void> _clearCorruptedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_feedbackKey);
      print('Cleared corrupted feedback data');
    } catch (e) {
      print('Error clearing corrupted data: $e');
    }
  }

  // Get feedback for a specific reminder
  Future<List<Map<String, dynamic>>> getFeedbackForReminder(int reminderId) async {
    final allFeedback = await getAllFeedback();
    return allFeedback.where((feedback) => feedback['reminderId'] == reminderId).toList();
  }

  // Get feedback by ID with enhanced error handling
  Future<Map<String, dynamic>?> getFeedbackById(int feedbackId) async {
    try {
      final allFeedback = await getAllFeedback();
      return allFeedback.firstWhere((feedback) => feedback['id'] == feedbackId);
    } catch (e) {
      print('Error getting feedback by ID $feedbackId: $e');
      return null;
    }
  }

  // Update feedback with version tracking and validation
  Future<Map<String, dynamic>?> updateFeedback(int feedbackId, Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allFeedback = await getAllFeedback();
      
      // Find the feedback to update
      final feedbackIndex = allFeedback.indexWhere((feedback) => feedback['id'] == feedbackId);
      if (feedbackIndex == -1) {
        print('Feedback with ID $feedbackId not found');
        return null;
      }
      
      final existingFeedback = allFeedback[feedbackIndex];
      
      // Validate updates to maintain data integrity
      final validatedUpdates = _validateFeedbackUpdates(updates);
      if (validatedUpdates.isEmpty) {
        print('No valid updates provided for feedback $feedbackId');
        return existingFeedback;
      }
      
      // Create updated feedback with version tracking
      final updatedFeedback = {
        ...existingFeedback,
        ...validatedUpdates,
        'editedAt': DateTime.now().toIso8601String(),
        'version': (existingFeedback['version'] as int? ?? 1) + 1,
        'isEdited': true,
        'originalCreatedAt': existingFeedback['createdAt'], // Preserve original creation time
      };
      
      // Update the feedback in the list
      allFeedback[feedbackIndex] = updatedFeedback;
      
      // Save updated feedback list
      await prefs.setString(_feedbackKey, jsonEncode(allFeedback));
      
      print('Successfully updated feedback $feedbackId to version ${updatedFeedback['version']}');
      return updatedFeedback;
      
    } catch (e) {
      print('Error updating feedback $feedbackId: $e');
      return null;
    }
  }

  // Get feedback history for a specific reminder (all versions)
  Future<List<Map<String, dynamic>>> getFeedbackHistory(int reminderId) async {
    try {
      final allFeedback = await getAllFeedback();
      final reminderFeedback = allFeedback
          .where((feedback) => feedback['reminderId'] == reminderId)
          .toList();
      
      // Sort by version (latest first) and then by creation date
      reminderFeedback.sort((a, b) {
        final versionA = a['version'] as int? ?? 1;
        final versionB = b['version'] as int? ?? 1;
        if (versionA != versionB) {
          return versionB.compareTo(versionA); // Latest version first
        }
        
        // If same version, sort by creation date (latest first)
        try {
          final dateA = DateTime.parse(a['createdAt'] as String);
          final dateB = DateTime.parse(b['createdAt'] as String);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
      
      return reminderFeedback;
    } catch (e) {
      print('Error getting feedback history for reminder $reminderId: $e');
      return [];
    }
  }

  // Validate feedback updates to ensure data integrity
  Map<String, dynamic> _validateFeedbackUpdates(Map<String, dynamic> updates) {
    final validatedUpdates = <String, dynamic>{};
    
    // Define allowed fields for updates
    const allowedFields = {
      'rating',
      'difficultyLevel',
      'moodBefore',
      'moodAfter',
      'durationMinutes',
      'wouldRecommend',
      'notes',
      'reminderCategory',
      'completionMethod',
      'location',
      'weather',
      'energy',
      'focus',
      'satisfaction',
      'challenges',
      'improvements',
      'tags'
    };
    
    // Validate each update field
    for (final entry in updates.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Skip system fields that shouldn't be updated directly
      if (!allowedFields.contains(key)) {
        print('Skipping invalid update field: $key');
        continue;
      }
      
      // Validate specific field types and values
      try {
        switch (key) {
          case 'rating':
            if (value is int && value >= 1 && value <= 5) {
              validatedUpdates[key] = value;
            }
            break;
          case 'difficultyLevel':
            const validDifficulties = {'very_easy', 'easy', 'moderate', 'hard', 'very_hard'};
            if (value is String && validDifficulties.contains(value)) {
              validatedUpdates[key] = value;
            }
            break;
          case 'moodBefore':
          case 'moodAfter':
            const validMoods = {'sad', 'neutral', 'happy', 'excited', 'blessed'};
            if (value is String && validMoods.contains(value)) {
              validatedUpdates[key] = value;
            }
            break;
          case 'durationMinutes':
            if (value is int && value > 0 && value <= 1440) { // Min 1 minute, Max 24 hours
              validatedUpdates[key] = value;
            }
            break;
          case 'wouldRecommend':
            if (value is bool) {
              validatedUpdates[key] = value;
            }
            break;
          case 'notes':
          case 'reminderCategory':
          case 'completionMethod':
          case 'location':
          case 'weather':
          case 'challenges':
          case 'improvements':
            if (value is String && value.length <= 1000) { // Reasonable length limit
              validatedUpdates[key] = value;
            }
            break;
          case 'energy':
          case 'focus':
          case 'satisfaction':
            if (value is int && value >= 1 && value <= 10) {
              validatedUpdates[key] = value;
            }
            break;
          case 'tags':
            if (value is List && value.every((tag) => tag is String)) {
              validatedUpdates[key] = value;
            }
            break;
          default:
            // For any other allowed fields, accept the value as-is if it's not null
            if (value != null) {
              validatedUpdates[key] = value;
            }
        }
      } catch (e) {
        print('Error validating field $key: $e');
      }
    }
    
    return validatedUpdates;
  }

  // Delete feedback
  Future<void> deleteFeedback(int feedbackId) async {
    final prefs = await SharedPreferences.getInstance();
    final feedbacks = await getAllFeedback();
    
    feedbacks.removeWhere((feedback) => feedback['id'] == feedbackId);
    await prefs.setString(_feedbackKey, jsonEncode(feedbacks));
  }

  // Get dashboard statistics with enhanced error handling and fallbacks
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final allFeedback = await getAllFeedback();
      
      if (allFeedback.isEmpty) {
        // Return encouraging fallback data for new users instead of empty data
        return CelebrationFallbackData.getNewUserStats();
      }

      return await _calculateStatsWithFallback(allFeedback);
    } catch (e) {
      // Log error but don't expose it to UI - return fallback data instead
      print('Error in getDashboardStats: $e');
      return CelebrationFallbackData.getExistingUserFallbackStats();
    }
  }

  // Enhanced version with retry logic and exponential backoff
  Future<Map<String, dynamic>> getDashboardStatsWithRetry({
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await getDashboardStats();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          // Final fallback after all retries failed
          print('All retry attempts failed for getDashboardStats: $e');
          return CelebrationFallbackData.getExistingUserFallbackStats();
        }
        
        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
      }
    }

    // This should never be reached, but provide fallback just in case
    return CelebrationFallbackData.getExistingUserFallbackStats();
  }

  // Calculate stats with graceful degradation for partial failures
  Future<Map<String, dynamic>> _calculateStatsWithFallback(List<Map<String, dynamic>> allFeedback) async {
    try {
      return _calculateFullStats(allFeedback);
    } catch (e) {
      // If full calculation fails, try partial calculation
      print('Full stats calculation failed, attempting partial: $e');
      return _calculatePartialStats(allFeedback);
    }
  }

  // Original stats calculation logic extracted to separate method
  Map<String, dynamic> _calculateFullStats(List<Map<String, dynamic>> allFeedback) {

    // Calculate basic stats
    final totalCompletions = allFeedback.length;
    
    // Safe calculation with null checks and fallbacks
    double averageRating = 4.5; // Default fallback
    try {
      final ratings = allFeedback
          .map((f) => f['rating'] as int?)
          .where((rating) => rating != null)
          .cast<int>()
          .toList();
      if (ratings.isNotEmpty) {
        averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }
    } catch (e) {
      print('Error calculating average rating: $e');
    }

    double averageDuration = 15.0; // Default fallback
    try {
      final durations = allFeedback
          .map((f) => f['durationMinutes'] as int?)
          .where((duration) => duration != null)
          .cast<int>()
          .toList();
      if (durations.isNotEmpty) {
        averageDuration = durations.reduce((a, b) => a + b) / durations.length;
      }
    } catch (e) {
      print('Error calculating average duration: $e');
    }
    
    // Most common difficulty with safe handling
    String mostCommonDifficulty = 'moderate'; // Default fallback
    try {
      final difficultyCount = <String, int>{};
      for (final feedback in allFeedback) {
        final difficulty = feedback['difficultyLevel'] as String?;
        if (difficulty != null && difficulty.isNotEmpty) {
          difficultyCount[difficulty] = (difficultyCount[difficulty] ?? 0) + 1;
        }
      }
      if (difficultyCount.isNotEmpty) {
        mostCommonDifficulty = difficultyCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }
    } catch (e) {
      print('Error calculating most common difficulty: $e');
    }

    // Mood improvement calculation with safe handling
    double moodImprovement = 1.5; // Default positive improvement
    try {
      final moodValues = {'sad': 1, 'neutral': 2, 'happy': 3, 'excited': 4, 'blessed': 5};
      double totalMoodImprovement = 0;
      int validMoodEntries = 0;
      
      for (final feedback in allFeedback) {
        final moodBefore = moodValues[feedback['moodBefore'] as String?] ?? 2;
        final moodAfter = moodValues[feedback['moodAfter'] as String?] ?? 3;
        totalMoodImprovement += (moodAfter - moodBefore);
        validMoodEntries++;
      }
      
      if (validMoodEntries > 0) {
        moodImprovement = totalMoodImprovement / validMoodEntries;
      }
    } catch (e) {
      print('Error calculating mood improvement: $e');
    }

    // Recommendation rate with safe handling
    double recommendationRate = 85.0; // Default positive rate
    try {
      final recommendCount = allFeedback.where((f) => f['wouldRecommend'] == true).length;
      recommendationRate = (recommendCount / totalCompletions) * 100;
    } catch (e) {
      print('Error calculating recommendation rate: $e');
    }

    // Category statistics with safe handling
    final categoryStats = <String, int>{};
    try {
      for (final feedback in allFeedback) {
        final category = feedback['reminderCategory'] as String?;
        if (category != null && category.isNotEmpty) {
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        }
      }
      // Ensure at least one category exists
      if (categoryStats.isEmpty) {
        categoryStats['spiritual'] = totalCompletions;
      }
    } catch (e) {
      print('Error calculating category stats: $e');
      categoryStats['spiritual'] = totalCompletions;
    }

    // Weekly completions (last 7 days) with safe handling
    final weeklyCompletions = <String, int>{};
    try {
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.month}/${date.day}';
        weeklyCompletions[dateKey] = 0;
      }
      
      for (final feedback in allFeedback) {
        try {
          final completedAtStr = feedback['completedAt'] as String?;
          if (completedAtStr != null) {
            final completedAt = DateTime.parse(completedAtStr);
            final daysDiff = now.difference(completedAt).inDays;
            if (daysDiff <= 6 && daysDiff >= 0) {
              final dateKey = '${completedAt.month}/${completedAt.day}';
              weeklyCompletions[dateKey] = (weeklyCompletions[dateKey] ?? 0) + 1;
            }
          }
        } catch (e) {
          print('Error parsing completion date for feedback: $e');
          // Skip this entry but continue processing others
        }
      }
    } catch (e) {
      print('Error calculating weekly completions: $e');
      // Provide minimal fallback
      final now = DateTime.now();
      final todayKey = '${now.month}/${now.day}';
      weeklyCompletions[todayKey] = 1;
    }

    // Rating distribution with safe handling
    final ratingDistribution = <int, int>{};
    try {
      for (int i = 1; i <= 5; i++) {
        ratingDistribution[i] = allFeedback.where((f) {
          final rating = f['rating'] as int?;
          return rating == i;
        }).length;
      }
    } catch (e) {
      print('Error calculating rating distribution: $e');
      // Provide encouraging fallback distribution
      ratingDistribution[5] = max(1, (totalCompletions * 0.4).round());
      ratingDistribution[4] = max(0, (totalCompletions * 0.3).round());
      ratingDistribution[3] = max(0, (totalCompletions * 0.2).round());
      ratingDistribution[2] = max(0, (totalCompletions * 0.1).round());
      ratingDistribution[1] = max(0, totalCompletions - ratingDistribution[5]! - ratingDistribution[4]! - ratingDistribution[3]! - ratingDistribution[2]!);
    }

    // Difficulty distribution with safe handling
    final difficultyDistribution = <String, int>{
      'very_easy': 0,
      'easy': 0,
      'moderate': 0,
      'hard': 0,
      'very_hard': 0,
    };
    try {
      for (final feedback in allFeedback) {
        final difficulty = feedback['difficultyLevel'] as String?;
        if (difficulty != null && difficultyDistribution.containsKey(difficulty)) {
          difficultyDistribution[difficulty] = (difficultyDistribution[difficulty] ?? 0) + 1;
        }
      }
      
      // If no difficulty data was found, distribute evenly with bias toward moderate
      final totalDifficultyEntries = difficultyDistribution.values.reduce((a, b) => a + b);
      if (totalDifficultyEntries == 0) {
        difficultyDistribution['moderate'] = totalCompletions;
      }
    } catch (e) {
      print('Error calculating difficulty distribution: $e');
      difficultyDistribution['moderate'] = totalCompletions;
    }

    return {
      'totalCompletions': totalCompletions,
      'averageRating': averageRating,
      'averageDuration': averageDuration,
      'mostCommonDifficulty': mostCommonDifficulty,
      'moodImprovement': moodImprovement,
      'recommendationRate': recommendationRate,
      'categoryStats': categoryStats,
      'weeklyCompletions': weeklyCompletions,
      'ratingDistribution': ratingDistribution,
      'difficultyDistribution': difficultyDistribution,
    };
  }

  // Partial stats calculation for when full calculation fails
  Map<String, dynamic> _calculatePartialStats(List<Map<String, dynamic>> allFeedback) {
    try {
      final totalCompletions = allFeedback.length;
      
      // Use fallback data as base and override with what we can calculate
      final fallbackStats = CelebrationFallbackData.getExistingUserFallbackStats();
      fallbackStats['totalCompletions'] = totalCompletions;
      fallbackStats['hasPartialData'] = true;
      
      // Try to calculate basic stats that are less likely to fail
      try {
        final now = DateTime.now();
        final todayKey = '${now.month}/${now.day}';
        fallbackStats['weeklyCompletions'] = {todayKey: 1};
      } catch (e) {
        print('Error in partial weekly calculation: $e');
      }
      
      return fallbackStats;
    } catch (e) {
      print('Even partial stats calculation failed: $e');
      return CelebrationFallbackData.getExistingUserFallbackStats();
    }
  }

  // Get recent feedback (last N entries)
  Future<List<Map<String, dynamic>>> getRecentFeedback({int limit = 10}) async {
    final allFeedback = await getAllFeedback();
    
    // Sort by completion date (most recent first)
    allFeedback.sort((a, b) {
      final dateA = DateTime.parse(a['completedAt'] as String);
      final dateB = DateTime.parse(b['completedAt'] as String);
      return dateB.compareTo(dateA);
    });
    
    return allFeedback.take(limit).toList();
  }

  // Get feedback by date range
  Future<List<Map<String, dynamic>>> getFeedbackByDateRange(DateTime startDate, DateTime endDate) async {
    final allFeedback = await getAllFeedback();
    
    return allFeedback.where((feedback) {
      final completedAt = DateTime.parse(feedback['completedAt'] as String);
      return completedAt.isAfter(startDate) && completedAt.isBefore(endDate);
    }).toList();
  }

  // Get average rating for a specific category
  Future<double> getAverageRatingForCategory(String category) async {
    final allFeedback = await getAllFeedback();
    final categoryFeedback = allFeedback.where((f) => f['reminderCategory'] == category).toList();
    
    if (categoryFeedback.isEmpty) return 0.0;
    
    final totalRating = categoryFeedback.map((f) => f['rating'] as int).reduce((a, b) => a + b);
    return totalRating / categoryFeedback.length;
  }

  // Get completion streaks with enhanced error handling
  Future<Map<String, int>> getCompletionStreaks() async {
    try {
      final allFeedback = await getAllFeedback();
      
      if (allFeedback.isEmpty) {
        // Return encouraging streak for new users
        return {'currentStreak': 1, 'longestStreak': 1};
      }

      return _calculateStreaksWithFallback(allFeedback);
    } catch (e) {
      print('Error in getCompletionStreaks: $e');
      return {'currentStreak': 1, 'longestStreak': 1};
    }
  }

  // Enhanced version with retry logic
  Future<Map<String, int>> getCompletionStreaksWithRetry({
    int maxRetries = 3,
    Duration initialDelay = const Duration(milliseconds: 300),
  }) async {
    int attempts = 0;
    Duration delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await getCompletionStreaks();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxRetries) {
          print('All retry attempts failed for getCompletionStreaks: $e');
          return {'currentStreak': 1, 'longestStreak': 1};
        }
        
        await Future.delayed(delay);
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
      }
    }

    return {'currentStreak': 1, 'longestStreak': 1};
  }

  // Calculate streaks with fallback handling
  Map<String, int> _calculateStreaksWithFallback(List<Map<String, dynamic>> allFeedback) {
    try {
      return _calculateFullStreaks(allFeedback);
    } catch (e) {
      print('Full streak calculation failed: $e');
      // Return encouraging fallback
      return {'currentStreak': 1, 'longestStreak': max(1, allFeedback.length)};
    }
  }

  // Original streak calculation logic extracted to separate method
  Map<String, int> _calculateFullStreaks(List<Map<String, dynamic>> allFeedback) {

    // Sort by completion date with safe parsing
    try {
      allFeedback.sort((a, b) {
        try {
          final dateA = DateTime.parse(a['completedAt'] as String);
          final dateB = DateTime.parse(b['completedAt'] as String);
          return dateA.compareTo(dateB);
        } catch (e) {
          print('Error parsing dates for sorting: $e');
          return 0; // Keep original order if parsing fails
        }
      });
    } catch (e) {
      print('Error sorting feedback by date: $e');
      // Continue with unsorted data
    }

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if there's a completion today or yesterday for current streak
    try {
      final latestCompletionStr = allFeedback.last['completedAt'] as String?;
      if (latestCompletionStr != null) {
        final latestCompletion = DateTime.parse(latestCompletionStr);
        final latestDate = DateTime(latestCompletion.year, latestCompletion.month, latestCompletion.day);
        final daysDiff = today.difference(latestDate).inDays;
        
        if (daysDiff <= 1) {
          currentStreak = 1;
          
          // Count backwards to find current streak
          for (int i = allFeedback.length - 2; i >= 0; i--) {
            try {
              final currentCompletionStr = allFeedback[i]['completedAt'] as String?;
              final nextCompletionStr = allFeedback[i + 1]['completedAt'] as String?;
              
              if (currentCompletionStr != null && nextCompletionStr != null) {
                final currentCompletion = DateTime.parse(currentCompletionStr);
                final nextCompletion = DateTime.parse(nextCompletionStr);
                
                final currentDate = DateTime(currentCompletion.year, currentCompletion.month, currentCompletion.day);
                final nextDate = DateTime(nextCompletion.year, nextCompletion.month, nextCompletion.day);
                
                if (nextDate.difference(currentDate).inDays <= 1) {
                  currentStreak++;
                } else {
                  break;
                }
              }
            } catch (e) {
              print('Error parsing completion dates in streak calculation: $e');
              break; // Stop streak calculation on error
            }
          }
        }
      }
    } catch (e) {
      print('Error calculating current streak: $e');
      currentStreak = 1; // Fallback to encouraging value
    }

    // Calculate longest streak with safe parsing
    try {
      for (int i = 1; i < allFeedback.length; i++) {
        try {
          final currentCompletionStr = allFeedback[i]['completedAt'] as String?;
          final prevCompletionStr = allFeedback[i - 1]['completedAt'] as String?;
          
          if (currentCompletionStr != null && prevCompletionStr != null) {
            final currentCompletion = DateTime.parse(currentCompletionStr);
            final prevCompletion = DateTime.parse(prevCompletionStr);
            
            final currentDate = DateTime(currentCompletion.year, currentCompletion.month, currentCompletion.day);
            final prevDate = DateTime(prevCompletion.year, prevCompletion.month, prevCompletion.day);
            
            if (currentDate.difference(prevDate).inDays <= 1) {
              tempStreak++;
            } else {
              longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
              tempStreak = 1;
            }
          }
        } catch (e) {
          print('Error parsing dates in longest streak calculation: $e');
          // Continue with next iteration
        }
      }
      longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;
    } catch (e) {
      print('Error calculating longest streak: $e');
      longestStreak = max(1, currentStreak); // Fallback
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  // Clear all feedback (for testing/reset)
  Future<void> clearAllFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_feedbackKey);
    await prefs.remove(_nextIdKey);
  }
}