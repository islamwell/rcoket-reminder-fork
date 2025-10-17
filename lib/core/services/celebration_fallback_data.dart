import 'dart:math';

/// Utility class providing fallback data for celebration screens
/// when actual user data is unavailable or fails to load
class CelebrationFallbackData {
  static final Random _random = Random();

  /// Returns empty statistics for new users or when data loading fails
  static Map<String, dynamic> getNewUserStats() {
    return {
      'totalCompletions': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'todayCompletions': 0,
      'averageRating': 0.0,
      'averageDuration': 0.0,
      'mostCommonDifficulty': null,
      'moodImprovement': 0.0,
      'recommendationRate': 0.0,
      'categoryStats': {},
      'weeklyCompletions': _getEmptyWeeklyCompletions(),
      'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      'difficultyDistribution': {},
      'isFirstCompletion': true,
    };
  }

  /// Returns empty statistics for users when data loading failed
  static Map<String, dynamic> getExistingUserFallbackStats() {
    return {
      'totalCompletions': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'todayCompletions': 0,
      'averageRating': 0.0,
      'averageDuration': 0.0,
      'mostCommonDifficulty': null,
      'moodImprovement': 0.0,
      'recommendationRate': 0.0,
      'categoryStats': {},
      'weeklyCompletions': _getEmptyWeeklyCompletions(),
      'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      'difficultyDistribution': {},
      'isFirstCompletion': false,
    };
  }

  /// Returns a list of encouraging messages for new users
  static List<String> getNewUserEncouragingMessages() {
    return [
      "Congratulations on your first completion! 🎉",
      "Every journey begins with a single step! 👣",
      "You've started something beautiful! ✨",
      "What a wonderful way to begin your spiritual journey! 🌟",
      "Your first step towards mindfulness is complete! 🧘‍♀️",
      "Amazing start! Keep building this positive habit! 💪",
      "You've taken the first step towards inner peace! ☮️",
      "Congratulations on beginning this meaningful practice! 🙏",
    ];
  }

  /// Returns encouraging messages for users with existing progress
  static List<String> getProgressEncouragingMessages() {
    return [
      "You're building an amazing habit! Keep it up! 🔥",
      "Your consistency is inspiring! 💫",
      "Another step forward in your spiritual journey! 🌱",
      "You're making wonderful progress! 📈",
      "Your dedication is truly admirable! 👏",
      "Keep up this fantastic momentum! 🚀",
      "You're creating positive change in your life! 🌈",
      "Your commitment to growth is beautiful! 🌸",
      "Every completion brings you closer to your goals! 🎯",
      "You're developing such a meaningful practice! 🕊️",
    ];
  }

  /// Returns milestone celebration messages
  static List<String> getMilestoneMessages(int completions) {
    if (completions == 1) {
      return getNewUserEncouragingMessages();
    } else if (completions == 7) {
      return [
        "One week of dedication! You're amazing! 🗓️",
        "Seven days of spiritual growth! 🌟",
        "A full week of mindfulness! Incredible! 📅",
      ];
    } else if (completions == 30) {
      return [
        "One month of consistent practice! 🎊",
        "30 days of spiritual dedication! 🏆",
        "A full month of growth! Outstanding! 📆",
      ];
    } else if (completions % 10 == 0) {
      return [
        "Wow! $completions completions! You're unstoppable! 🎯",
        "$completions spiritual moments completed! 🌟",
        "Amazing milestone: $completions completions! 🏅",
      ];
    }
    return getProgressEncouragingMessages();
  }

  /// Returns category-specific motivational messages
  static List<String> getCategorySpecificMessages(String category) {
    switch (category.toLowerCase()) {
      case 'prayer':
      case 'spiritual':
        return [
          "Your spiritual connection grows stronger! 🤲",
          "Beautiful moments of prayer and reflection! 🕌",
          "Your faith journey continues to flourish! ✨",
          "Each prayer brings you closer to Allah! 🌟",
          "Your devotion is truly inspiring! 💫",
        ];
      case 'meditation':
      case 'mindfulness':
        return [
          "Your mind becomes more peaceful with each session! 🧘‍♀️",
          "Inner calm and clarity are growing! 🌊",
          "Mindfulness is becoming your superpower! 🧠",
          "Your awareness deepens with each practice! 🌸",
          "Finding peace within yourself! ☮️",
        ];
      case 'gratitude':
        return [
          "Your grateful heart attracts more blessings! 🙏",
          "Gratitude is transforming your perspective! 💝",
          "Your appreciation for life is beautiful! 🌺",
          "Counting blessings brings more joy! ✨",
          "Your thankful spirit shines bright! 🌟",
        ];
      case 'charity':
      case 'kindness':
        return [
          "Your kindness makes the world brighter! 🌟",
          "Generosity of spirit is your gift! 💖",
          "Your compassion touches many lives! 🤗",
          "Spreading love through your actions! 💕",
          "Your giving heart is beautiful! 🎁",
        ];
      case 'quran':
      case 'reading':
        return [
          "Enriching your soul with divine wisdom! 📖",
          "Each verse brings new understanding! ✨",
          "Your love for learning is inspiring! 🌟",
          "Growing in knowledge and faith! 📚",
          "The Quran guides your heart! 💚",
        ];
      case 'dhikr':
      case 'remembrance':
        return [
          "Remembering Allah in all moments! 🤲",
          "Your heart finds peace in dhikr! 💚",
          "Beautiful remembrance of the Divine! ✨",
          "Each dhikr purifies your soul! 🌟",
          "Constant remembrance brings tranquility! ☮️",
        ];
      case 'fasting':
      case 'sawm':
        return [
          "Your discipline strengthens body and soul! 💪",
          "Fasting brings you closer to Allah! 🌙",
          "Your self-control is admirable! ⭐",
          "Purifying through beautiful sacrifice! ✨",
          "Your devotion through fasting shines! 🌟",
        ];
      case 'dua':
      case 'supplication':
        return [
          "Your prayers reach the heavens! 🤲",
          "Beautiful conversations with Allah! 💫",
          "Your supplications are heard! 👂",
          "Connecting with the Divine through dua! ✨",
          "Your faith in prayer is inspiring! 🌟",
        ];
      case 'study':
      case 'learning':
        return [
          "Knowledge is the light of faith! 💡",
          "Your pursuit of learning is noble! 📚",
          "Growing wiser with each study session! 🧠",
          "Education elevates your soul! ⬆️",
          "Your dedication to learning inspires! 🌟",
        ];
      case 'reflection':
      case 'contemplation':
        return [
          "Deep thoughts bring spiritual growth! 🤔",
          "Your contemplation enriches your soul! 💭",
          "Reflection leads to wisdom! 🧘‍♂️",
          "Thoughtful moments create understanding! ✨",
          "Your introspection is beautiful! 🌸",
        ];
      default:
        return getProgressEncouragingMessages();
    }
  }

  /// Returns default completion context when actual context is unavailable
  static Map<String, dynamic> getDefaultCompletionContext() {
    return {
      'reminderTitle': 'Spiritual Practice',
      'reminderCategory': 'spiritual',
      'completionTime': DateTime.now().toIso8601String(),
      'completionNotes': null,
      'reminderId': null,
      'actualDuration': null,
    };
  }

  /// Factory method for different fallback scenarios
  static Map<String, dynamic> getStatsForScenario(FallbackScenario scenario) {
    switch (scenario) {
      case FallbackScenario.newUser:
        return getNewUserStats();
      case FallbackScenario.existingUserDataFailed:
        return getExistingUserFallbackStats();
      case FallbackScenario.partialDataAvailable:
        return _getPartialDataFallback();
      case FallbackScenario.offline:
        return _getOfflineFallback();
    }
  }

  /// Returns appropriate encouraging message based on scenario and context
  static String getEncouragingMessage({
    FallbackScenario scenario = FallbackScenario.newUser,
    int? totalCompletions,
    String? category,
  }) {
    List<String> messages;
    
    if (totalCompletions != null) {
      messages = getMilestoneMessages(totalCompletions);
    } else if (category != null) {
      messages = getCategorySpecificMessages(category);
    } else {
      switch (scenario) {
        case FallbackScenario.newUser:
          messages = getNewUserEncouragingMessages();
          break;
        case FallbackScenario.existingUserDataFailed:
        case FallbackScenario.partialDataAvailable:
        case FallbackScenario.offline:
          messages = getProgressEncouragingMessages();
          break;
      }
    }
    
    return messages[_random.nextInt(messages.length)];
  }

  // Private helper methods

  static Map<String, int> _getEmptyWeeklyCompletions() {
    final now = DateTime.now();
    final weeklyCompletions = <String, int>{};
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      weeklyCompletions[dateKey] = 0; // All days empty
    }
    
    return weeklyCompletions;
  }









  static Map<String, dynamic> _getPartialDataFallback() {
    // Return empty data when partial data is unavailable
    final base = getExistingUserFallbackStats();
    base['hasPartialData'] = true;
    return base;
  }

  static Map<String, dynamic> _getOfflineFallback() {
    // Empty data for offline scenarios
    return {
      'totalCompletions': 0,
      'currentStreak': 0,
      'longestStreak': 0,
      'todayCompletions': 0,
      'isOffline': true,
      'weeklyCompletions': _getEmptyWeeklyCompletions(),
    };
  }
}

/// Enum defining different fallback scenarios
enum FallbackScenario {
  newUser,
  existingUserDataFailed,
  partialDataAvailable,
  offline,
}