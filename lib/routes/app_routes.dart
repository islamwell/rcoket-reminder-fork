import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/dashboard/dashboard_screen.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/settings/screens/notification_settings_screen.dart';
import '../presentation/completion_celebration/completion_celebration.dart';
import '../presentation/create_reminder/create_reminder.dart';
import '../presentation/reminder_management/reminder_management.dart';
import '../presentation/audio_library/audio_library.dart';
import '../presentation/audio_library/audio_library_selection.dart';
import '../presentation/reminder_detail/reminder_detail.dart';
import '../presentation/completion_feedback/completion_feedback.dart';
import '../presentation/completion_feedback/feedback_edit_screen.dart';
import '../presentation/progress/progress_history_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String notificationSettings = '/notification-settings';
  static const String completionCelebration = '/completion-celebration';
  static const String progressHistory = '/progress-history';
  static const String createReminder = '/create-reminder';
  static const String reminderManagement = '/reminder-management';
  static const String audioLibrary = '/audio-library';
  static const String audioLibrarySelection = '/audio-library-selection';
  static const String reminderDetail = '/reminder-detail';
  static const String completionFeedback = '/completion-feedback';
  static const String feedbackEdit = '/feedback-edit';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const LoginScreen(),
    login: (context) => const LoginScreen(),
    dashboard: (context) => const DashboardScreen(),
    settings: (context) => const SettingsScreen(),
    notificationSettings: (context) => const NotificationSettingsScreen(),
    completionCelebration: (context) {
      // Extract and validate arguments for completion celebration
      final args = ModalRoute.of(context)?.settings.arguments;
      
      // Validate arguments and provide fallback handling
      Map<String, dynamic>? validatedArgs;
      if (args != null && args is Map<String, dynamic>) {
        try {
          // Validate required context parameters
          validatedArgs = validateCompletionCelebrationArgs(args);
        } catch (e) {
          // Log validation error but don't break the flow
          debugPrint('Invalid completion celebration arguments: $e');
          validatedArgs = null;
        }
      }
      
      return const CompletionCelebration();
    },
    progressHistory: (context) => const ProgressHistoryScreen(),
    createReminder: (context) => const CreateReminder(),
    reminderManagement: (context) => const ReminderManagement(),
    audioLibrary: (context) => const AudioLibrary(),
    audioLibrarySelection: (context) => const AudioLibrarySelection(),
    reminderDetail: (context) => const ReminderDetail(),
    completionFeedback: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return CompletionFeedback(reminder: args ?? {});
    },
    feedbackEdit: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return FeedbackEditScreen(
        feedback: args?['feedback'] ?? {},
        onFeedbackUpdated: args?['onFeedbackUpdated'],
      );
    },
  };

  /// Validates and sanitizes arguments for completion celebration route
  /// Returns validated arguments or null if validation fails
  static Map<String, dynamic>? validateCompletionCelebrationArgs(Map<String, dynamic> args) {
    final validatedArgs = <String, dynamic>{};
    
    // Validate reminderTitle (required for meaningful celebration)
    if (args.containsKey('reminderTitle') && args['reminderTitle'] is String) {
      final title = args['reminderTitle'] as String;
      if (title.trim().isNotEmpty) {
        validatedArgs['reminderTitle'] = title.trim();
      }
    } else if (args.containsKey('title') && args['title'] is String) {
      final title = args['title'] as String;
      if (title.trim().isNotEmpty) {
        validatedArgs['reminderTitle'] = title.trim();
      }
    }
    
    // Validate reminderCategory (optional but useful for context)
    if (args.containsKey('reminderCategory') && args['reminderCategory'] is String) {
      final category = args['reminderCategory'] as String;
      if (category.trim().isNotEmpty) {
        validatedArgs['reminderCategory'] = category.trim();
      }
    } else if (args.containsKey('category') && args['category'] is String) {
      final category = args['category'] as String;
      if (category.trim().isNotEmpty) {
        validatedArgs['reminderCategory'] = category.trim();
      }
    }
    
    // Validate completionTime (optional, defaults to now if not provided)
    if (args.containsKey('completionTime')) {
      if (args['completionTime'] is String) {
        try {
          DateTime.parse(args['completionTime'] as String);
          validatedArgs['completionTime'] = args['completionTime'];
        } catch (e) {
          // Invalid date format, will use default
          debugPrint('Invalid completionTime format: ${args['completionTime']}');
        }
      } else if (args['completionTime'] is DateTime) {
        validatedArgs['completionTime'] = (args['completionTime'] as DateTime).toIso8601String();
      }
    }
    
    // Validate completionNotes (optional)
    if (args.containsKey('completionNotes') && args['completionNotes'] is String) {
      final notes = args['completionNotes'] as String;
      if (notes.trim().isNotEmpty) {
        validatedArgs['completionNotes'] = notes.trim();
      }
    }
    
    // Validate reminderId (optional but useful for tracking)
    if (args.containsKey('reminderId')) {
      if (args['reminderId'] is int) {
        validatedArgs['reminderId'] = args['reminderId'];
      } else if (args['reminderId'] is String) {
        try {
          final id = int.parse(args['reminderId'] as String);
          validatedArgs['reminderId'] = id;
        } catch (e) {
          // Invalid ID format, skip it
          debugPrint('Invalid reminderId format: ${args['reminderId']}');
        }
      }
    }
    
    // Validate actualDuration (optional)
    if (args.containsKey('actualDuration')) {
      if (args['actualDuration'] is int) {
        final duration = args['actualDuration'] as int;
        if (duration >= 0) {
          validatedArgs['actualDuration'] = duration;
        }
      } else if (args['actualDuration'] is Duration) {
        validatedArgs['actualDuration'] = (args['actualDuration'] as Duration).inMilliseconds;
      }
    }
    
    // Return validated arguments (can be empty if no valid args found)
    // The CompletionCelebration widget will handle empty args gracefully
    return validatedArgs.isNotEmpty ? validatedArgs : null;
  }
}
