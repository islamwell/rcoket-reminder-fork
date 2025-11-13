import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'error_handling_service.dart';
import '../models/completion_context.dart';

/// Service for tracking reminder completions with detailed data
/// Stores completion data including ratings, duration, mood, and notes
class CompletionTrackingService {
  static CompletionTrackingService? _instance;
  static CompletionTrackingService get instance => _instance ??= CompletionTrackingService._();
  CompletionTrackingService._();

  static const String _completionsKey = 'completions';
  static const String _ratingsKey = 'ratings';
  static const String _completionsTable = 'kiro_completions';
  static const String _ratingsTable = 'kiro_ratings';

  final SupabaseService _supabaseService = SupabaseService.instance;
  final AuthService _authService = AuthService.instance;

  /// Record a reminder completion with detailed tracking data
  Future<Map<String, dynamic>> recordCompletion({
    required int reminderId,
    required String reminderTitle,
    required String reminderCategory,
    String? completionNotes,
    int? actualDurationMinutes,
    String? mood, // 'excellent', 'good', 'neutral', 'poor'
    int? satisfactionRating, // 1-5 scale
    DateTime? completedAt,
  }) async {
    final completionData = {
      'reminder_id': reminderId,
      'reminder_title': reminderTitle,
      'reminder_category': reminderCategory,
      'completed_at': (completedAt ?? DateTime.now()).toIso8601String(),
      'completion_notes': completionNotes,
      'actual_duration_minutes': actualDurationMinutes,
      'mood': mood,
      'satisfaction_rating': satisfactionRating,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Validate completion data
    if (!_validateCompletionData(completionData)) {
      throw ArgumentError('Invalid completion data provided');
    }

    Map<String, dynamic> completion;

    // Try to save to Supabase if user is authenticated and not in guest mode
    if (_shouldUseSupabase()) {
      try {
        final userId = _authService.currentUser?['id'];
        final supabaseData = {
          ...completionData,
          'user_id': userId,
        };
        
        completion = await _supabaseService.insert(_completionsTable, supabaseData);
        print('CompletionTrackingService: Saved completion to Supabase with ID: ${completion['id']}');
        
        // Also cache locally for offline access
        await _cacheCompletionLocally(completion);
      } catch (e) {
        print('CompletionTrackingService: Error saving to Supabase, falling back to local storage: $e');
        completion = await _saveCompletionLocally(completionData);
      }
    } else {
      // Save locally for guest users or when Supabase is not available
      completion = await _saveCompletionLocally(completionData);
    }

    // Log completion for analytics
    await ErrorHandlingService.instance.logError(
      'COMPLETION_RECORDED',
      'Reminder completion recorded: $reminderTitle',
      severity: ErrorSeverity.info,
      metadata: {
        'reminderId': reminderId,
        'category': reminderCategory,
        'duration': actualDurationMinutes,
        'mood': mood,
        'rating': satisfactionRating,
      },
    );

    return completion;
  }

  /// Record a rating for a completion or reminder
  Future<Map<String, dynamic>> recordRating({
    required int rating, // 1-5 scale
    int? reminderId,
    int? completionId,
    String? feedbackText,
    String ratingType = 'completion', // 'completion', 'reminder', 'app'
  }) async {
    final ratingData = {
      'rating': rating,
      'reminder_id': reminderId,
      'completion_id': completionId,
      'feedback_text': feedbackText,
      'rating_type': ratingType,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Validate rating data
    if (!_validateRatingData(ratingData)) {
      throw ArgumentError('Invalid rating data provided');
    }

    Map<String, dynamic> ratingRecord;

    // Try to save to Supabase if user is authenticated and not in guest mode
    if (_shouldUseSupabase()) {
      try {
        final userId = _authService.currentUser?['id'];
        final supabaseData = {
          ...ratingData,
          'user_id': userId,
        };
        
        ratingRecord = await _supabaseService.insert(_ratingsTable, supabaseData);
        print('CompletionTrackingService: Saved rating to Supabase with ID: ${ratingRecord['id']}');
        
        // Also cache locally for offline access
        await _cacheRatingLocally(ratingRecord);
      } catch (e) {
        print('CompletionTrackingService: Error saving rating to Supabase, falling back to local storage: $e');
        ratingRecord = await _saveRatingLocally(ratingData);
      }
    } else {
      // Save locally for guest users or when Supabase is not available
      ratingRecord = await _saveRatingLocally(ratingData);
    }

    return ratingRecord;
  }

  /// Get completion history for a user
  /// Always merges local and Supabase data to ensure nothing is lost
  Future<List<Map<String, dynamic>>> getCompletionHistory({
    int? reminderId,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      List<Map<String, dynamic>> allCompletions = [];

      // Always get local completions first
      final localCompletions = await _getCompletionsLocally();
      print('CompletionTrackingService: Loaded ${localCompletions.length} completions from local storage');
      allCompletions.addAll(localCompletions);

      // Try to get from Supabase if user is authenticated and not in guest mode
      if (_shouldUseSupabase()) {
        try {
          final userId = _authService.currentUser?['id'];
          // Use the SupabaseService select method instead of direct client access
          final filters = <String, dynamic>{'user_id': userId};

          if (reminderId != null) {
            filters['reminder_id'] = reminderId;
          }

          if (category != null) {
            filters['reminder_category'] = category;
          }

          final supabaseCompletions = await _supabaseService.select(
            _completionsTable,
            filters: filters,
          );

          print('CompletionTrackingService: Loaded ${supabaseCompletions.length} completions from Supabase');

          // Merge Supabase completions, avoiding duplicates
          for (final supabaseCompletion in supabaseCompletions) {
            final existsInLocal = allCompletions.any((local) =>
              local['id'] == supabaseCompletion['id'] ||
              (local['reminder_id'] == supabaseCompletion['reminder_id'] &&
               local['completed_at'] == supabaseCompletion['completed_at'])
            );

            if (!existsInLocal) {
              allCompletions.add(supabaseCompletion);
            }
          }
        } catch (e) {
          print('CompletionTrackingService: Error loading from Supabase, using local data only: $e');
          // Continue with local data only
        }
      }

      // Apply filtering for reminderId, category, and date ranges
      var filteredCompletions = allCompletions;

      if (reminderId != null) {
        filteredCompletions = filteredCompletions.where((c) => c['reminder_id'] == reminderId).toList();
      }

      if (category != null) {
        filteredCompletions = filteredCompletions.where((c) => c['reminder_category'] == category).toList();
      }

      if (startDate != null || endDate != null) {
        filteredCompletions = filteredCompletions.where((completion) {
          final completedAt = DateTime.parse(completion['completed_at'] as String);
          if (startDate != null && completedAt.isBefore(startDate)) return false;
          if (endDate != null && completedAt.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      // Sort by completion date (most recent first)
      filteredCompletions.sort((a, b) {
        final aDate = DateTime.parse(a['completed_at'] as String);
        final bDate = DateTime.parse(b['completed_at'] as String);
        return bDate.compareTo(aDate);
      });

      if (limit != null && filteredCompletions.length > limit) {
        filteredCompletions = filteredCompletions.take(limit).toList();
      }

      print('CompletionTrackingService: Returning ${filteredCompletions.length} total completions after filtering');

      return filteredCompletions;
    } catch (e) {
      await ErrorHandlingService.instance.logError(
        'COMPLETION_HISTORY_ERROR',
        'Error loading completion history: $e',
        severity: ErrorSeverity.error,
        stackTrace: StackTrace.current,
      );
      // Fallback to local storage on any error
      try {
        return await _getCompletionsLocally();
      } catch (localError) {
        print('CompletionTrackingService: Error loading from local storage: $localError');
        return [];
      }
    }
  }

  /// Get completion statistics
  Future<Map<String, dynamic>> getCompletionStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final completions = await getCompletionHistory(
        startDate: startDate,
        endDate: endDate,
      );

      final categoryCounts = <String, int>{};
      final moodCounts = <String, int>{};
      final completionsByDay = <String, int>{};
      
      final stats = {
        'totalCompletions': completions.length,
        'categoryCounts': categoryCounts,
        'averageRating': 0.0,
        'averageDuration': 0.0,
        'moodCounts': moodCounts,
        'completionsByDay': completionsByDay,
      };

      if (completions.isEmpty) {
        return stats;
      }

      // Calculate category counts
      for (final completion in completions) {
        final category = completion['reminder_category'] as String? ?? 'Unknown';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      // Calculate average rating
      final ratingsWithValues = completions
          .where((c) => c['satisfaction_rating'] != null)
          .map((c) => c['satisfaction_rating'] as int)
          .toList();
      
      if (ratingsWithValues.isNotEmpty) {
        stats['averageRating'] = ratingsWithValues.reduce((a, b) => a + b) / ratingsWithValues.length;
      }

      // Calculate average duration
      final durationsWithValues = completions
          .where((c) => c['actual_duration_minutes'] != null)
          .map((c) => c['actual_duration_minutes'] as int)
          .toList();
      
      if (durationsWithValues.isNotEmpty) {
        stats['averageDuration'] = durationsWithValues.reduce((a, b) => a + b) / durationsWithValues.length;
      }

      // Calculate mood counts
      for (final completion in completions) {
        final mood = completion['mood'] as String?;
        if (mood != null) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        }
      }

      // Calculate completions by day
      for (final completion in completions) {
        final completedAt = DateTime.parse(completion['completed_at'] as String);
        final dayKey = '${completedAt.year}-${completedAt.month.toString().padLeft(2, '0')}-${completedAt.day.toString().padLeft(2, '0')}';
        completionsByDay[dayKey] = (completionsByDay[dayKey] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      await ErrorHandlingService.instance.logError(
        'COMPLETION_STATS_ERROR',
        'Error calculating completion stats: $e',
        severity: ErrorSeverity.error,
        stackTrace: StackTrace.current,
      );
      return {
        'totalCompletions': 0,
        'categoryCounts': <String, int>{},
        'averageRating': 0.0,
        'averageDuration': 0.0,
        'moodCounts': <String, int>{},
        'completionsByDay': <String, int>{},
      };
    }
  }

  /// Helper method to save completion locally
  Future<Map<String, dynamic>> _saveCompletionLocally(Map<String, dynamic> completionData) async {
    final prefs = await SharedPreferences.getInstance();
    final completions = await _getCompletionsLocally();
    
    // Generate local ID
    final nextId = DateTime.now().millisecondsSinceEpoch;
    
    final completion = {
      "id": nextId,
      ...completionData,
    };
    
    completions.add(completion);
    
    // Save completions
    await prefs.setString(_completionsKey, jsonEncode(completions));
    
    return completion;
  }

  /// Helper method to save rating locally
  Future<Map<String, dynamic>> _saveRatingLocally(Map<String, dynamic> ratingData) async {
    final prefs = await SharedPreferences.getInstance();
    final ratings = await _getRatingsLocally();
    
    // Generate local ID
    final nextId = DateTime.now().millisecondsSinceEpoch;
    
    final rating = {
      "id": nextId,
      ...ratingData,
    };
    
    ratings.add(rating);
    
    // Save ratings
    await prefs.setString(_ratingsKey, jsonEncode(ratings));
    
    return rating;
  }

  /// Helper method to get completions from local storage
  Future<List<Map<String, dynamic>>> _getCompletionsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completionsJson = prefs.getString(_completionsKey);
      
      if (completionsJson == null) {
        return <Map<String, dynamic>>[];
      }
      
      final List<dynamic> decoded = jsonDecode(completionsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('CompletionTrackingService: Error loading completions locally: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Helper method to get ratings from local storage
  Future<List<Map<String, dynamic>>> _getRatingsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratingsJson = prefs.getString(_ratingsKey);
      
      if (ratingsJson == null) {
        return <Map<String, dynamic>>[];
      }
      
      final List<dynamic> decoded = jsonDecode(ratingsJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('CompletionTrackingService: Error loading ratings locally: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// Helper method to cache completion locally
  Future<void> _cacheCompletionLocally(Map<String, dynamic> completion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localCompletions = await _getCompletionsLocally();
      
      // Check if completion already exists locally
      final existingIndex = localCompletions.indexWhere((c) => c['id'] == completion['id']);
      if (existingIndex != -1) {
        localCompletions[existingIndex] = completion;
      } else {
        localCompletions.add(completion);
      }
      
      await prefs.setString(_completionsKey, jsonEncode(localCompletions));
    } catch (e) {
      print('CompletionTrackingService: Error caching completion locally: $e');
    }
  }

  /// Helper method to cache rating locally
  Future<void> _cacheRatingLocally(Map<String, dynamic> rating) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localRatings = await _getRatingsLocally();
      
      // Check if rating already exists locally
      final existingIndex = localRatings.indexWhere((r) => r['id'] == rating['id']);
      if (existingIndex != -1) {
        localRatings[existingIndex] = rating;
      } else {
        localRatings.add(rating);
      }
      
      await prefs.setString(_ratingsKey, jsonEncode(localRatings));
    } catch (e) {
      print('CompletionTrackingService: Error caching rating locally: $e');
    }
  }

  /// Helper method to determine if Supabase should be used
  bool _shouldUseSupabase() {
    return _supabaseService.isInitialized && 
           _authService.isLoggedIn && 
           !_authService.isGuestMode;
  }

  /// Helper method to validate completion data
  bool _validateCompletionData(Map<String, dynamic> data) {
    try {
      // Required fields
      if (data['reminder_id'] == null || data['reminder_title'] == null || data['reminder_category'] == null) {
        return false;
      }

      // Validate rating if provided
      if (data['satisfaction_rating'] != null) {
        final rating = data['satisfaction_rating'] as int?;
        if (rating == null || rating < 1 || rating > 5) {
          return false;
        }
      }

      // Validate mood if provided
      if (data['mood'] != null) {
        final mood = data['mood'] as String?;
        final validMoods = ['excellent', 'good', 'neutral', 'poor'];
        if (mood == null || !validMoods.contains(mood)) {
          return false;
        }
      }

      // Validate duration if provided
      if (data['actual_duration_minutes'] != null) {
        final duration = data['actual_duration_minutes'] as int?;
        if (duration == null || duration < 0) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('CompletionTrackingService: Validation error: $e');
      return false;
    }
  }

  /// Helper method to validate rating data
  bool _validateRatingData(Map<String, dynamic> data) {
    try {
      // Required fields
      if (data['rating'] == null) {
        return false;
      }

      // Validate rating value
      final rating = data['rating'] as int?;
      if (rating == null || rating < 1 || rating > 5) {
        return false;
      }

      // Validate rating type if provided
      if (data['rating_type'] != null) {
        final ratingType = data['rating_type'] as String?;
        final validTypes = ['completion', 'reminder', 'app'];
        if (ratingType == null || !validTypes.contains(ratingType)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      print('CompletionTrackingService: Rating validation error: $e');
      return false;
    }
  }

  /// Clear all completion data (for testing/reset)
  Future<void> clearAllCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completionsKey);
    await prefs.remove(_ratingsKey);
  }
}