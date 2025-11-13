import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_handling_service.dart';
import 'background_task_manager.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'completion_tracking_service.dart';
import '../utils/data_validation_utils.dart';

class ReminderStorageService {
  static const String _remindersKey = 'reminders';
  static const String _nextIdKey = 'next_reminder_id';
  static const String _remindersTable = 'kiro_reminders';

  static ReminderStorageService? _instance;
  static ReminderStorageService get instance => _instance ??= ReminderStorageService._();
  ReminderStorageService._();

  // Dependencies
  final SupabaseService _supabaseService = SupabaseService.instance;
  final AuthService _authService = AuthService.instance;
  final ErrorHandlingService _errorHandlingService = ErrorHandlingService.instance;

  // Save a new reminder
  Future<Map<String, dynamic>> saveReminder({
    required String title,
    required String category,
    required Map<String, dynamic> frequency,
    required String time, // Format: "HH:mm"
    String? description,
    Map<String, dynamic>? selectedAudio,
    bool enableNotifications = true,
    int repeatLimit = 0, // 0 means infinite
  }) async {
    print('ReminderStorageService: saveReminder() called with title: "$title", category: "$category"');
    final nextOccurrenceDateTime = calculatePreciseScheduleTime(frequency, time);
    final reminderData = {
      "title": title,
      "category": category,
      "frequency": frequency,
      "time": time,
      "description": description ?? "",
      "selectedAudio": selectedAudio,
      "enableNotifications": enableNotifications,
      "repeatLimit": repeatLimit,
      "status": "active",
      "createdAt": DateTime.now().toIso8601String(),
      "completionCount": 0,
      "nextOccurrence": _formatNextOccurrence(nextOccurrenceDateTime),
      "nextOccurrenceDateTime": nextOccurrenceDateTime.toIso8601String(),
      "needsSync": _shouldUseSupabase(), // Mark for sync if Supabase is available
    };

    // Validate reminder data
    if (!_validateReminderData(reminderData)) {
      throw ArgumentError('Invalid reminder data provided');
    }

    // ALWAYS save locally first for immediate response
    final reminder = await _saveReminderLocally(reminderData);
    print('ReminderStorageService: Saved reminder locally with ID: ${reminder['id']}');

    // Schedule background notification asynchronously (non-blocking for faster UI response)
    if (reminder['status'] == 'active' && enableNotifications) {
      // Run in background without awaiting to avoid blocking the save operation
      unawaited(
        BackgroundTaskManager.instance.rescheduleReminder(reminder['id']).then((_) {
          print('ReminderStorageService: Scheduled background notification for new reminder ${reminder['id']}');
        }).catchError((e) {
          print('ReminderStorageService: Error scheduling background notification for new reminder ${reminder['id']}: $e');
          // Continue without background scheduling - foreground notifications will still work
        })
      );
    }
    
    // Sync to Supabase asynchronously (non-blocking)
    if (_shouldUseSupabase()) {
      _syncReminderToSupabaseAsync(reminder);
    }
    
    return reminder;
  }

  // Helper method to save reminder locally
  Future<Map<String, dynamic>> _saveReminderLocally(Map<String, dynamic> reminderData) async {
    final prefs = await SharedPreferences.getInstance();
    final reminders = await _getRemindersLocally();
    
    // Get next ID
    final nextId = prefs.getInt(_nextIdKey) ?? 1;
    
    final reminder = {
      "id": nextId,
      ...reminderData,
    };
    
    reminders.add(reminder);
    
    // Save reminders and increment next ID
    await prefs.setString(_remindersKey, jsonEncode(reminders));
    await prefs.setInt(_nextIdKey, nextId + 1);
    
    return reminder;
  }

  // Helper method to cache reminder locally
  Future<void> _cacheReminderLocally(Map<String, dynamic> reminder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localReminders = await _getRemindersLocally();
      
      // Check if reminder already exists locally
      final existingIndex = localReminders.indexWhere((r) => r['id'] == reminder['id']);
      if (existingIndex != -1) {
        localReminders[existingIndex] = reminder;
      } else {
        localReminders.add(reminder);
      }
      
      await prefs.setString(_remindersKey, jsonEncode(localReminders));
    } catch (e) {
      print('ReminderStorageService: Error caching reminder locally: $e');
    }
  }

  // Get all reminders
  Future<List<Map<String, dynamic>>> getReminders() async {
    print('ReminderStorageService: getReminders() called');
    
    return await ErrorHandlingService.instance.retryOperation(
      'get_reminders',
      () async {
        try {
          // ALWAYS load from local storage first for immediate response
          print('ReminderStorageService: Loading from local storage');
          final localReminders = await _getRemindersLocally();
          print('ReminderStorageService: Loaded ${localReminders.length} reminders from local storage');
          
          // Trigger background sync if Supabase is available (non-blocking)
          if (_shouldUseSupabase()) {
            _syncRemindersFromSupabaseAsync();
          }
          
          return localReminders;
        } catch (e) {
          print('ReminderStorageService: Critical error loading reminders: $e');
          await ErrorHandlingService.instance.logError(
            'REMINDER_LOAD_ERROR',
            'Error loading reminders: $e',
            severity: ErrorSeverity.error,
            stackTrace: StackTrace.current,
          );
          
          // Return empty list as fallback
          return <Map<String, dynamic>>[];
        }
      },
      maxAttempts: 3,
    ) ?? <Map<String, dynamic>>[];
  }

  // Helper method to get reminders from local storage
  Future<List<Map<String, dynamic>>> _getRemindersLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getString(_remindersKey);
      
      if (remindersJson == null) {
        return <Map<String, dynamic>>[];
      }
      
      final List<dynamic> decoded = jsonDecode(remindersJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('ReminderStorageService: Error loading reminders locally: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // Helper method to cache reminders locally
  Future<void> _cacheRemindersLocally(List<Map<String, dynamic>> reminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_remindersKey, jsonEncode(reminders));
    } catch (e) {
      print('ReminderStorageService: Error caching reminders locally: $e');
    }
  }

  // Update reminder
  Future<void> updateReminder(dynamic reminderId, Map<String, dynamic> updates) async {
    // ALWAYS update locally first for immediate response
    await _updateReminderLocally(reminderId, updates);
    print('ReminderStorageService: Updated reminder $reminderId locally');
    
    // Mark for sync if Supabase is available
    if (_shouldUseSupabase()) {
      await _markReminderForSync(reminderId);
      _syncReminderUpdateToSupabaseAsync(reminderId, updates);
    }
    
    // Get the updated reminder for notification rescheduling
    final updatedReminder = await getReminderById(reminderId);
    if (updatedReminder != null) {
      // Reschedule background notification if reminder properties changed (non-blocking)
      final needsReschedule = _shouldRescheduleNotification({}, updatedReminder, updates);

      if (needsReschedule) {
        // Run in background without awaiting for faster UI response
        unawaited(
          BackgroundTaskManager.instance.rescheduleReminder(reminderId).then((_) {
            print('ReminderStorageService: Rescheduled background notification for updated reminder $reminderId');
          }).catchError((e) {
            print('ReminderStorageService: Error rescheduling background notification for updated reminder $reminderId: $e');
            // Continue without background scheduling - foreground notifications will still work
          })
        );
      }
    }
  }

  // Helper method to update reminder locally
  Future<void> _updateReminderLocally(int reminderId, Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminders = await _getRemindersLocally();
      
      final index = reminders.indexWhere((r) => r['id'] == reminderId);
      if (index != -1) {
        reminders[index] = {...reminders[index], ...updates};
        await prefs.setString(_remindersKey, jsonEncode(reminders));
      }
    } catch (e) {
      print('ReminderStorageService: Error updating reminder locally: $e');
    }
  }

  // Delete reminder
  Future<void> deleteReminder(dynamic reminderId) async {
    // ALWAYS delete locally first for immediate response
    await _deleteReminderLocally(reminderId);
    print('ReminderStorageService: Deleted reminder $reminderId locally');
    
    // Sync deletion to Supabase asynchronously if available
    if (_shouldUseSupabase()) {
      _syncReminderDeletionToSupabaseAsync(reminderId);
    }
    
    // Cancel background notification for the deleted reminder (non-blocking)
    unawaited(
      BackgroundTaskManager.instance.cancelNotification(reminderId).then((_) {
        print('ReminderStorageService: Cancelled background notification for deleted reminder $reminderId');
      }).catchError((e) {
        print('ReminderStorageService: Error cancelling background notification for deleted reminder $reminderId: $e');
        // Continue - the reminder is already deleted from storage
      })
    );
  }

  // Helper method to delete reminder locally
  Future<void> _deleteReminderLocally(int reminderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminders = await _getRemindersLocally();
      
      reminders.removeWhere((r) => r['id'] == reminderId);
      await prefs.setString(_remindersKey, jsonEncode(reminders));
    } catch (e) {
      print('ReminderStorageService: Error deleting reminder locally: $e');
    }
  }

  // Get reminder by ID
  Future<Map<String, dynamic>?> getReminderById(dynamic reminderId) async {
    final reminders = await getReminders();
    try {
      return reminders.firstWhere((r) => r['id'] == reminderId);
    } catch (e) {
      return null;
    }
  }

  // Toggle reminder status (active/paused)
  Future<void> toggleReminderStatus(dynamic reminderId) async {
    final reminder = await getReminderById(reminderId);
    if (reminder != null) {
      final oldStatus = reminder['status'] as String;
      final newStatus = oldStatus == 'active' ? 'paused' : 'active';
      String nextOccurrence = 'Paused';
      String? nextOccurrenceDateTime;
      
      if (newStatus == 'active') {
        final nextDateTime = _calculateNextOccurrenceDateTime(reminder['frequency'], reminder['time']);
        nextOccurrence = _formatNextOccurrence(nextDateTime);
        nextOccurrenceDateTime = nextDateTime.toIso8601String();
      }
      
      await updateReminder(reminderId, {
        'status': newStatus,
        'nextOccurrence': nextOccurrence,
        'nextOccurrenceDateTime': nextOccurrenceDateTime,
      });
      
      // Handle background notification scheduling based on status change (non-blocking)
      if (newStatus == 'paused') {
        // Cancel background notification when pausing (non-blocking)
        unawaited(
          BackgroundTaskManager.instance.cancelNotification(reminderId).then((_) {
            print('ReminderStorageService: Cancelled background notification for paused reminder $reminderId');
          }).catchError((e) {
            print('ReminderStorageService: Error cancelling background notification for paused reminder $reminderId: $e');
          })
        );
      } else if (newStatus == 'active' && reminder['enableNotifications'] == true) {
        // Schedule background notification when activating (non-blocking)
        unawaited(
          BackgroundTaskManager.instance.rescheduleReminder(reminderId).then((_) {
            print('ReminderStorageService: Scheduled background notification for activated reminder $reminderId');
          }).catchError((e) {
            print('ReminderStorageService: Error scheduling background notification for activated reminder $reminderId: $e');
          })
        );
      }
    }
  }

  // Mark reminder as completed (for recurring reminders - stays active)
  Future<void> markReminderCompleted(
    dynamic reminderId, {
    String? completionNotes,
    int? actualDurationMinutes,
    String? mood,
    int? satisfactionRating,
  }) async {
    final reminder = await getReminderById(reminderId);
    if (reminder != null) {
      final completionCount = (reminder['completionCount'] as int) + 1;
      final repeatLimit = reminder['repeatLimit'] as int;
      
      print('DEBUG: Marking reminder completed - ID: $reminderId, Count: $completionCount, Limit: $repeatLimit');
      
      // Record completion data for tracking
      try {
        await CompletionTrackingService.instance.recordCompletion(
          reminderId: reminderId,
          reminderTitle: reminder['title'] as String,
          reminderCategory: reminder['category'] as String,
          completionNotes: completionNotes,
          actualDurationMinutes: actualDurationMinutes,
          mood: mood,
          satisfactionRating: satisfactionRating,
        );
        print('ReminderStorageService: Recorded completion data for reminder $reminderId');
      } catch (e) {
        print('ReminderStorageService: Error recording completion data for reminder $reminderId: $e');
        // Continue with reminder update even if completion tracking fails
      }
      
      // Check if reminder should be marked as completed
      String newStatus = reminder['status'] as String;
      String nextOccurrence = reminder['nextOccurrence'] as String;
      
      String? nextOccurrenceDateTime;
      
      if (repeatLimit > 0 && completionCount >= repeatLimit) {
        newStatus = 'completed';
        nextOccurrence = 'Completed';
        print('DEBUG: Moving to completed status (reached repeat limit)');
        
        // Cancel background notification when reminder is completed (non-blocking)
        unawaited(
          BackgroundTaskManager.instance.cancelNotification(reminderId).then((_) {
            print('ReminderStorageService: Cancelled background notification for completed reminder $reminderId');
          }).catchError((e) {
            print('ReminderStorageService: Error cancelling background notification for completed reminder $reminderId: $e');
          })
        );
      } else {
        // Calculate next occurrence for recurring reminders
        final nextDateTime = _calculateNextOccurrenceAfterCompletion(
          reminder['frequency'], 
          reminder['time']
        );
        nextOccurrence = _formatNextOccurrence(nextDateTime);
        nextOccurrenceDateTime = nextDateTime.toIso8601String();
        print('DEBUG: Staying active, next occurrence: $nextOccurrence');
        
        // Reschedule background notification for the next occurrence (non-blocking)
        if (reminder['enableNotifications'] == true) {
          unawaited(
            BackgroundTaskManager.instance.rescheduleReminder(reminderId).then((_) {
              print('ReminderStorageService: Rescheduled background notification for recurring reminder $reminderId');
            }).catchError((e) {
              print('ReminderStorageService: Error rescheduling background notification for recurring reminder $reminderId: $e');
            })
          );
        }
      }
      
      final updateData = {
        'completionCount': completionCount,
        'status': newStatus,
        'nextOccurrence': nextOccurrence,
        'lastCompleted': DateTime.now().toIso8601String(),
      };
      
      if (nextOccurrenceDateTime != null) {
        updateData['nextOccurrenceDateTime'] = nextOccurrenceDateTime;
      }
      
      await updateReminder(reminderId, updateData);
    }
  }

  // Manually complete a reminder (moves to completed section)
  Future<void> completeReminderManually(
    dynamic reminderId, {
    String? completionNotes,
    int? actualDurationMinutes,
    String? mood,
    int? satisfactionRating,
  }) async {
    print('DEBUG: Manually completing reminder: $reminderId');
    
    final reminder = await getReminderById(reminderId);
    if (reminder != null) {
      // Record completion data for tracking
      try {
        await CompletionTrackingService.instance.recordCompletion(
          reminderId: reminderId,
          reminderTitle: reminder['title'] as String,
          reminderCategory: reminder['category'] as String,
          completionNotes: completionNotes,
          actualDurationMinutes: actualDurationMinutes,
          mood: mood,
          satisfactionRating: satisfactionRating,
        );
        print('ReminderStorageService: Recorded completion data for manually completed reminder $reminderId');
      } catch (e) {
        print('ReminderStorageService: Error recording completion data for manually completed reminder $reminderId: $e');
        // Continue with reminder update even if completion tracking fails
      }
    }
    
    await updateReminder(reminderId, {
      'status': 'completed',
      'nextOccurrence': 'Completed',
      'completedAt': DateTime.now().toIso8601String(),
    });
    
    // Cancel background notification when manually completing (non-blocking)
    unawaited(
      BackgroundTaskManager.instance.cancelNotification(reminderId).then((_) {
        print('ReminderStorageService: Cancelled background notification for manually completed reminder $reminderId');
      }).catchError((e) {
        print('ReminderStorageService: Error cancelling background notification for manually completed reminder $reminderId: $e');
      })
    );
  }

  // Snooze a reminder for a specified number of minutes
  Future<void> snoozeReminder(dynamic reminderId, int snoozeMinutes) async {
    final reminder = await getReminderById(reminderId);
    if (reminder == null) {
      throw ArgumentError('Reminder $reminderId not found');
    }
    
    final snoozeUntil = DateTime.now().add(Duration(minutes: snoozeMinutes));
    
    // Update reminder status to snoozed
    await updateReminder(reminderId, {
      'status': 'snoozed',
      'snoozedAt': DateTime.now().toIso8601String(),
      'nextOccurrence': 'Snoozed for $snoozeMinutes minutes',
      'nextOccurrenceDateTime': snoozeUntil.toIso8601String(),
    });
    
    // Schedule background notification for snooze time (non-blocking)
    unawaited(
      BackgroundTaskManager.instance.rescheduleReminder(reminderId).then((_) {
        print('ReminderStorageService: Scheduled background notification for snoozed reminder $reminderId');
      }).catchError((e) {
        print('ReminderStorageService: Error scheduling background notification for snoozed reminder $reminderId: $e');
      })
    );
    
    // Schedule a timer to revert status back to active after snooze period
    Timer(Duration(minutes: snoozeMinutes), () async {
      try {
        final currentReminder = await getReminderById(reminderId);
        if (currentReminder != null && currentReminder['status'] == 'snoozed') {
          // Calculate next regular occurrence
          final frequency = currentReminder['frequency'] as Map<String, dynamic>;
          final time = currentReminder['time'] as String;
          final nextDateTime = _calculateNextOccurrenceDateTime(frequency, time);
          
          await updateReminder(reminderId, {
            'status': 'active',
            'nextOccurrence': _formatNextOccurrence(nextDateTime),
            'nextOccurrenceDateTime': nextDateTime.toIso8601String(),
          });
          
          print('ReminderStorageService: Reverted snoozed reminder $reminderId back to active status');
        }
      } catch (e) {
        print('ReminderStorageService: Error reverting snoozed reminder $reminderId: $e');
      }
    });
    
    print('ReminderStorageService: Snoozed reminder $reminderId for $snoozeMinutes minutes');
  }

  // Get active reminders that should trigger now
  Future<List<Map<String, dynamic>>> getTriggeredReminders() async {
    final reminders = await getReminders();
    final now = DateTime.now();
    
    return reminders.where((reminder) {
      if (reminder['status'] != 'active') return false;
      
      final nextOccurrence = reminder['nextOccurrence'] as String;
      if (nextOccurrence == 'Paused' || nextOccurrence == 'Completed') return false;
      
      // Check if it's time to trigger this reminder
      return _shouldTriggerReminder(reminder, now);
    }).toList();
  }

  // Calculate next occurrence DateTime after a reminder is completed
  DateTime _calculateNextOccurrenceAfterCompletion(Map<String, dynamic> frequency, String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    print('DEBUG: Calculating next occurrence after completion');
    print('  Now: $now');
    print('  Frequency: $frequency');
    print('  Time: $time (${hour}:${minute})');
    
    DateTime nextOccurrence;
    
    final frequencyType = frequency['type'] ?? frequency['id'];
    switch (frequencyType) {
      case 'daily':
        // For daily reminders, always schedule for tomorrow at the specified time
        nextOccurrence = DateTime(now.year, now.month, now.day + 1, hour, minute);
        print('  Daily reminder - scheduled for tomorrow: $nextOccurrence');
        break;
        
      case 'hourly':
        // For hourly reminders, schedule for exactly one hour from now
        nextOccurrence = now.add(Duration(hours: 1));
        print('  Hourly reminder - next occurrence in 1 hour: $nextOccurrence');
        break;
        
      case 'weekly':
        final selectedDays = List<int>.from(frequency['selectedDays'] ?? []);
        nextOccurrence = _getNextWeeklyOccurrence(now, selectedDays, hour, minute);
        break;
        
      case 'custom':
        final intervalValue = (frequency['interval'] ?? frequency['intervalValue']) as int;
        final intervalUnit = (frequency['unit'] ?? frequency['intervalUnit']) as String;
        
        switch (intervalUnit) {
          case 'minutes':
            nextOccurrence = now.add(Duration(minutes: intervalValue));
            break;
          case 'hours':
            nextOccurrence = now.add(Duration(hours: intervalValue));
            break;
          case 'days':
            nextOccurrence = now.add(Duration(days: intervalValue));
            break;
          default:
            nextOccurrence = now.add(Duration(hours: 1));
        }
        break;
        
      default:
        // For other types, use the regular calculation
        return _calculateNextOccurrenceDateTime(frequency, time);
    }
    
    print('  Final next occurrence after completion: $nextOccurrence');
    return nextOccurrence;
  }

  // Calculate next occurrence DateTime based on frequency and time
  DateTime _calculateNextOccurrenceDateTime(Map<String, dynamic> frequency, String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    print('DEBUG: Calculating next occurrence DateTime');
    print('  Now: $now');
    print('  Frequency: $frequency');
    print('  Time: $time (${hour}:${minute})');
    
    DateTime nextOccurrence;
    
    // Handle both 'type' and 'id' fields for backward compatibility
    final frequencyType = frequency['type'] ?? frequency['id'];
    switch (frequencyType) {
      case 'once':
        final selectedDate = DateTime.parse(frequency['date']);
        nextOccurrence = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          hour,
          minute,
        );
        break;
        
      case 'daily':
        nextOccurrence = DateTime(now.year, now.month, now.day, hour, minute);
        print('  Initial daily occurrence: $nextOccurrence');
        
        // Apply smart scheduling logic that considers user intent
        final timeUntilScheduled = nextOccurrence.difference(now);
        
        if (timeUntilScheduled.isNegative) {
          // Time has already passed today, schedule for tomorrow
          nextOccurrence = nextOccurrence.add(Duration(days: 1));
          print('  Time passed, scheduled for tomorrow: $nextOccurrence');
        } else if (timeUntilScheduled.inMinutes < 1) {
          // Less than 1 minute buffer - this indicates user wants it very soon
          // For near-future scheduling, add minimum buffer time
          nextOccurrence = now.add(Duration(minutes: 1));
          print('  Applied minimum buffer, scheduled for: $nextOccurrence');
        } else {
          // Time is in the future with adequate buffer, keep today
          print('  Keeping today with adequate buffer: $nextOccurrence');
        }
        break;
        
      case 'weekly':
        final selectedDays = List<int>.from(frequency['selectedDays'] ?? []);
        nextOccurrence = _getNextWeeklyOccurrence(now, selectedDays, hour, minute);
        break;
        
      case 'hourly':
        // Calculate the next hour boundary from current time
        final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1, 0);
        nextOccurrence = nextHour;
        print('  Hourly reminder - next hour: $nextOccurrence');
        break;
        
      case 'monthly':
        final dayOfMonth = frequency['dayOfMonth'] as int;
        nextOccurrence = DateTime(now.year, now.month, dayOfMonth, hour, minute);
        if (nextOccurrence.isBefore(now) || nextOccurrence.isAtSameMomentAs(now)) {
          // Try next month, but handle month overflow
          var nextMonth = now.month + 1;
          var nextYear = now.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
          }
          nextOccurrence = DateTime(nextYear, nextMonth, dayOfMonth, hour, minute);
        }
        break;
        
      case 'custom':
        // Handle both data structures: 'interval'/'unit' and 'intervalValue'/'intervalUnit'
        final intervalValue = (frequency['interval'] ?? frequency['intervalValue']) as int;
        final intervalUnit = (frequency['unit'] ?? frequency['intervalUnit']) as String;
        
        switch (intervalUnit) {
          case 'minutes':
            nextOccurrence = now.add(Duration(minutes: intervalValue));
            break;
          case 'hours':
            nextOccurrence = now.add(Duration(hours: intervalValue));
            break;
          case 'days':
            nextOccurrence = now.add(Duration(days: intervalValue));
            break;
          default:
            nextOccurrence = now.add(Duration(hours: 1));
        }
        break;
        
      case 'minutely':
        // For testing - set reminder for specific minutes in the future
        final minutesFromNow = frequency['minutesFromNow'] as int? ?? 1;
        nextOccurrence = now.add(Duration(minutes: minutesFromNow));
        break;
        
      default:
        nextOccurrence = now.add(Duration(hours: 1));
    }
    
    // Validate the scheduled time and apply buffer if needed
    nextOccurrence = validateScheduleTime(nextOccurrence);
    
    print('  Final next occurrence DateTime: $nextOccurrence');
    return nextOccurrence;
  }

  DateTime _getNextWeeklyOccurrence(DateTime now, List<int> selectedDays, int hour, int minute) {
    if (selectedDays.isEmpty) {
      // Default to daily if no days selected
      return DateTime(now.year, now.month, now.day + 1, hour, minute);
    }
    
    // Check today first if the time hasn't passed yet with proper buffer
    final todayOccurrence = DateTime(now.year, now.month, now.day, hour, minute);
    if (selectedDays.contains(now.weekday)) {
      final timeUntilOccurrence = todayOccurrence.difference(now);
      if (timeUntilOccurrence.inMinutes >= 1) {
        // Today's occurrence is valid with adequate buffer
        return todayOccurrence;
      }
    }
    
    // Find the next occurrence in the coming days
    for (int i = 1; i <= 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final weekday = checkDate.weekday; // 1 = Monday, 7 = Sunday
      
      if (selectedDays.contains(weekday)) {
        return DateTime(checkDate.year, checkDate.month, checkDate.day, hour, minute);
      }
    }
    
    // Fallback to next week (should not reach here if selectedDays is not empty)
    final nextWeek = now.add(Duration(days: 7));
    return DateTime(nextWeek.year, nextWeek.month, nextWeek.day, hour, minute);
  }

  String _formatNextOccurrence(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    // Debug logging
    print('DEBUG: Formatting next occurrence');
    print('  Now: $now');
    print('  DateTime: $dateTime');
    print('  Difference: ${difference.inMinutes} minutes');
    print('  Difference in hours: ${difference.inHours}');
    print('  Difference in days: ${difference.inDays}');
    
    // Handle negative differences (past times)
    if (difference.isNegative) {
      print('  Result: Overdue');
      return 'Overdue';
    }
    
    // Less than 1 minute
    if (difference.inMinutes < 1) {
      print('  Result: Now');
      return 'Now';
    }
    
    // Less than 60 minutes - show exact minutes
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      final result = minutes == 1 ? 'In 1 minute' : 'In $minutes minutes';
      print('  Result: $result');
      return result;
    }
    
    // Same day - check if it's within reasonable hours to show "In X hours"
    if (difference.inDays == 0) {
      final hours = difference.inHours;
      if (hours < 12) {
        // Show "In X hours" for up to 12 hours
        final result = hours == 1 ? 'In 1 hour' : 'In $hours hours';
        print('  Result: $result');
        return result;
      } else {
        // Show "Today at time" for later today
        final result = 'Today at ${_formatTime(dateTime)}';
        print('  Result: $result');
        return result;
      }
    }
    
    // Tomorrow
    if (difference.inDays == 1) {
      final result = 'Tomorrow at ${_formatTime(dateTime)}';
      print('  Result: $result');
      return result;
    }
    
    // This week (within 7 days)
    if (difference.inDays < 7) {
      final weekday = _getWeekdayName(dateTime.weekday);
      final result = '$weekday at ${_formatTime(dateTime)}';
      print('  Result: $result');
      return result;
    }
    
    // More than a week away
    final result = '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${_formatTime(dateTime)}';
    print('  Result: $result');
    return result;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  bool _shouldTriggerReminder(Map<String, dynamic> reminder, DateTime now) {
    print('DEBUG: Checking if reminder should trigger');
    print('  Reminder: ${reminder['title']}');
    print('  Current time: $now');
    
    // Use nextOccurrenceDateTime if available for more precise triggering
    final nextOccurrenceDateTimeStr = reminder['nextOccurrenceDateTime'] as String?;
    if (nextOccurrenceDateTimeStr != null) {
      try {
        final nextOccurrenceDateTime = DateTime.parse(nextOccurrenceDateTimeStr);
        print('  Next occurrence DateTime: $nextOccurrenceDateTime');

        // Check if current time is at or past the scheduled time (within 5 minute tolerance for missed reminders)
        final difference = now.difference(nextOccurrenceDateTime);
        final shouldTrigger = difference.inSeconds >= 0 && difference.inMinutes <= 5;

        print('  Time difference: ${difference.inSeconds} seconds');
        print('  Should trigger: $shouldTrigger (within 5-minute window)');
        return shouldTrigger;
      } catch (e) {
        print('  Error parsing nextOccurrenceDateTime: $e');
        // Fall back to legacy method
      }
    }
    
    // Legacy method for backward compatibility
    final frequency = reminder['frequency'] as Map<String, dynamic>;
    final time = reminder['time'] as String;
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    print('  Using legacy trigger check');
    print('  Reminder time: $time (${hour}:${minute})');
    print('  Current time: ${now.hour}:${now.minute}');
    
    // Check if current time matches the reminder time (within 1 minute tolerance)
    final currentMinutes = now.hour * 60 + now.minute;
    final reminderMinutes = hour * 60 + minute;
    final timeDiff = (currentMinutes - reminderMinutes).abs();
    
    print('  Time difference: $timeDiff minutes');
    
    if (timeDiff > 1) {
      print('  Result: Not time yet (difference > 1 minute)');
      return false;
    }
    
    final frequencyType = frequency['type'] ?? frequency['id'];
    switch (frequencyType) {
      case 'once':
        final selectedDate = DateTime.parse(frequency['date']);
        return now.year == selectedDate.year &&
               now.month == selectedDate.month &&
               now.day == selectedDate.day;
               
      case 'daily':
        return true; // Daily reminders trigger every day at the specified time
        
      case 'weekly':
        final selectedDays = List<int>.from(frequency['selectedDays'] ?? []);
        return selectedDays.contains(now.weekday);
        
      case 'monthly':
        final dayOfMonth = frequency['dayOfMonth'] as int;
        return now.day == dayOfMonth;
        
      case 'hourly':
        // For hourly reminders, trigger every hour
        return now.minute == 0; // Trigger at the top of each hour
        
      case 'custom':
        // For custom intervals, check against last completion time
        final lastCompleted = reminder['lastCompleted'] as String?;
        if (lastCompleted == null) return true;
        
        final lastCompletedDate = DateTime.parse(lastCompleted);
        final intervalValue = (frequency['interval'] ?? frequency['intervalValue']) as int;
        final intervalUnit = (frequency['unit'] ?? frequency['intervalUnit']) as String;
        
        Duration interval;
        switch (intervalUnit) {
          case 'minutes':
            interval = Duration(minutes: intervalValue);
            break;
          case 'hours':
            interval = Duration(hours: intervalValue);
            break;
          case 'days':
            interval = Duration(days: intervalValue);
            break;
          default:
            interval = Duration(hours: 1);
        }
        
        return now.isAfter(lastCompletedDate.add(interval));
        
      default:
        return false;
    }
  }

  // Update existing reminders to include nextOccurrenceDateTime field
  Future<void> migrateRemindersToNewFormat() async {
    final reminders = await getReminders();
    bool needsUpdate = false;
    
    for (var reminder in reminders) {
      if (reminder['nextOccurrenceDateTime'] == null && reminder['status'] == 'active') {
        final nextDateTime = _calculateNextOccurrenceDateTime(
          reminder['frequency'], 
          reminder['time']
        );
        reminder['nextOccurrenceDateTime'] = nextDateTime.toIso8601String();
        reminder['nextOccurrence'] = _formatNextOccurrence(nextDateTime);
        needsUpdate = true;
      }
    }
    
    if (needsUpdate) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_remindersKey, jsonEncode(reminders));
      print('DEBUG: Migrated ${reminders.length} reminders to new format');
    }
  }

  // Get current time remaining for a reminder in minutes (for real-time updates)
  int getTimeRemainingInMinutes(Map<String, dynamic> reminder) {
    final nextOccurrenceDateTimeStr = reminder['nextOccurrenceDateTime'] as String?;
    if (nextOccurrenceDateTimeStr == null) return 0;
    
    try {
      final nextOccurrenceDateTime = DateTime.parse(nextOccurrenceDateTimeStr);
      final now = DateTime.now();
      final difference = nextOccurrenceDateTime.difference(now);
      
      if (difference.isNegative) return -1; // Overdue
      return difference.inMinutes;
    } catch (e) {
      print('Error calculating time remaining: $e');
      return 0;
    }
  }

  // Sync reminders between Supabase and local storage
  Future<void> syncReminders() async {
    if (!_shouldUseSupabase()) {
      print('ReminderStorageService: Skipping sync - Supabase not available or user is guest');
      return;
    }

    try {
      await retryWithAuth(() async {
        final userId = _authService.currentUser?['id'];
        if (userId == null) {
          throw AuthenticationException('No user ID available for sync');
        }
        
        // Get reminders from both sources
        final supabaseReminders = await _supabaseService.select(
          _remindersTable,
          filters: {'user_id': userId},
        );
        final localReminders = await _getRemindersLocally();
        
        // Find reminders that exist locally but not in Supabase (need to upload)
        final remindersToUpload = <Map<String, dynamic>>[];
        for (final localReminder in localReminders) {
          final existsInSupabase = supabaseReminders.any((sr) => sr['id'] == localReminder['id']);
          if (!existsInSupabase && localReminder['user_id'] == null) {
            // This is a local reminder that needs to be uploaded
            final reminderToUpload = Map<String, dynamic>.from(localReminder);
            reminderToUpload['user_id'] = userId;
            remindersToUpload.add(reminderToUpload);
          }
        }
        
        // Upload local reminders to Supabase
        for (final reminder in remindersToUpload) {
          try {
            await _supabaseService.insert(_remindersTable, reminder);
            print('ReminderStorageService: Uploaded local reminder ${reminder['id']} to Supabase');
          } catch (e) {
            print('ReminderStorageService: Error uploading reminder ${reminder['id']}: $e');
          }
        }
        
        // Cache all Supabase reminders locally
        await _cacheRemindersLocally(supabaseReminders);
        
        print('ReminderStorageService: Sync completed - ${supabaseReminders.length} reminders synced');
      }, operationName: 'sync_reminders');
      
    } catch (e) {
      print('ReminderStorageService: Error during sync: $e');
    }
  }

  // Clear all reminders (for testing/reset)
  Future<void> clearAllReminders() async {
    // Clear from Supabase if available
    if (_shouldUseSupabase()) {
      try {
        await retryWithAuth(() async {
          final userId = _authService.currentUser?['id'];
          if (userId == null) {
            throw AuthenticationException('No user ID available for clear operation');
          }
          await _supabaseService.delete(_remindersTable, {'user_id': userId});
          print('ReminderStorageService: Cleared all reminders from Supabase');
        }, operationName: 'clear_all_reminders');
        
      } catch (e) {
        print('ReminderStorageService: Error clearing Supabase reminders: $e');
      }
    }
    
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_remindersKey);
    await prefs.remove(_nextIdKey);
  }

  // Helper method to determine if Supabase should be used
  bool _shouldUseSupabase() {
    final supabaseInitialized = _supabaseService.isInitialized;
    final userLoggedIn = _authService.isLoggedIn;
    final notGuestMode = !_authService.isGuestMode;
    final isSupabaseUser = _authService.isSupabaseUser;
    
    final shouldUse = supabaseInitialized && userLoggedIn && notGuestMode && isSupabaseUser;
    
    print('ReminderStorageService: _shouldUseSupabase() check:');
    print('  Supabase initialized: $supabaseInitialized');
    print('  User logged in: $userLoggedIn');
    print('  Not guest mode: $notGuestMode');
    print('  Is Supabase user: $isSupabaseUser');
    print('  Result: $shouldUse');
    
    return shouldUse;
  }

  // Data validation methods
  bool _validateReminderData(Map<String, dynamic> reminderData) {
    try {
      // Required fields validation
      final requiredFields = ['title', 'category', 'frequency', 'time'];
      for (final field in requiredFields) {
        if (!reminderData.containsKey(field) || reminderData[field] == null) {
          print('ReminderStorageService: Validation failed - missing required field: $field');
          return false;
        }
      }

      // Title validation
      final title = reminderData['title'] as String?;
      if (title == null || title.trim().isEmpty || title.length > 255) {
        print('ReminderStorageService: Validation failed - invalid title');
        return false;
      }

      // Category validation
      final category = reminderData['category'] as String?;
      if (category == null || category.trim().isEmpty || category.length > 100) {
        print('ReminderStorageService: Validation failed - invalid category');
        return false;
      }

      // Time format validation (HH:mm)
      final time = reminderData['time'] as String?;
      if (time == null || !DataValidationUtils.isValidTimeFormat(time)) {
        print('ReminderStorageService: Validation failed - invalid time format');
        return false;
      }

      // Frequency validation
      final frequency = reminderData['frequency'];
      if (frequency == null || !DataValidationUtils.isValidReminderFrequency(frequency)) {
        print('ReminderStorageService: Validation failed - invalid frequency');
        return false;
      }

      // Optional fields validation
      if (reminderData.containsKey('description')) {
        final description = reminderData['description'] as String?;
        if (description != null && description.length > 1000) {
          print('ReminderStorageService: Validation failed - description too long');
          return false;
        }
      }

      if (reminderData.containsKey('repeatLimit')) {
        final repeatLimit = reminderData['repeatLimit'];
        if (repeatLimit != null && (repeatLimit is! int || repeatLimit < 0)) {
          print('ReminderStorageService: Validation failed - invalid repeatLimit');
          return false;
        }
      }

      if (reminderData.containsKey('enableNotifications')) {
        final enableNotifications = reminderData['enableNotifications'];
        if (enableNotifications != null && enableNotifications is! bool) {
          print('ReminderStorageService: Validation failed - invalid enableNotifications');
          return false;
        }
      }

      if (reminderData.containsKey('selectedAudio')) {
        final selectedAudio = reminderData['selectedAudio'];
        if (selectedAudio != null && selectedAudio is! Map<String, dynamic>) {
          print('ReminderStorageService: Validation failed - invalid selectedAudio');
          return false;
        }
      }

      // Status validation (if provided)
      if (reminderData.containsKey('status')) {
        final status = reminderData['status'] as String?;
        final validStatuses = ['active', 'paused', 'completed'];
        if (status == null || !validStatuses.contains(status)) {
          print('ReminderStorageService: Validation failed - invalid status');
          return false;
        }
      }

      // Date validation for timestamps
      final dateFields = ['createdAt', 'nextOccurrenceDateTime', 'lastCompleted'];
      for (final field in dateFields) {
        if (reminderData.containsKey(field)) {
          final dateValue = reminderData[field] as String?;
          if (dateValue != null && !DataValidationUtils.isValidISODate(dateValue)) {
            print('ReminderStorageService: Validation failed - invalid date format for $field');
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('ReminderStorageService: Validation error: $e');
      return false;
    }
  }

  /// Validate data before database insertion to prevent format errors
  bool _validateDataBeforeInsert(Map<String, dynamic> data) {
    try {
      // Ensure no local-only fields are being sent to database
      final localOnlyFields = ['id', 'supabase_id', 'needsSync', 'syncRetryCount', 'lastModified'];
      for (final field in localOnlyFields) {
        if (data.containsKey(field)) {
          print('ReminderStorageService: Validation failed - local-only field $field found in database data');
          return false;
        }
      }

      // Ensure user_id is a valid UUID format if present
      if (data.containsKey('user_id')) {
        final userId = data['user_id'];
        if (userId != null && !_isValidUUID(userId.toString())) {
          print('ReminderStorageService: Validation failed - invalid user_id UUID format: $userId');
          return false;
        }
      }

      // Validate JSON fields are properly formatted
      final jsonFields = ['frequency', 'selectedAudio'];
      for (final field in jsonFields) {
        if (data.containsKey(field) && data[field] != null) {
          if (data[field] is! Map && data[field] is! List) {
            print('ReminderStorageService: Validation failed - $field must be a Map or List for JSON storage');
            return false;
          }
        }
      }

      // Validate timestamp fields are properly formatted
      final timestampFields = ['createdAt', 'nextOccurrenceDateTime', 'lastCompleted', 'completed_at'];
      for (final field in timestampFields) {
        if (data.containsKey(field) && data[field] != null) {
          final timestamp = data[field].toString();
          if (!DataValidationUtils.isValidISODate(timestamp)) {
            print('ReminderStorageService: Validation failed - invalid timestamp format for $field: $timestamp');
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('ReminderStorageService: Data validation error: $e');
      return false;
    }
  }

  /// Check if a string is a valid UUID format
  bool _isValidUUID(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(uuid);
  }



  // Helper method to determine if a notification should be rescheduled
  bool _shouldRescheduleNotification(
    Map<String, dynamic> oldReminder, 
    Map<String, dynamic> updatedReminder, 
    Map<String, dynamic> updates
  ) {
    // Check if any scheduling-relevant fields have changed
    final schedulingFields = [
      'status',
      'frequency', 
      'time',
      'enableNotifications',
      'nextOccurrenceDateTime'
    ];
    
    for (final field in schedulingFields) {
      if (updates.containsKey(field)) {
        print('ReminderStorageService: Rescheduling needed due to $field change');
        return true;
      }
    }
    
    // Check if the reminder was activated/deactivated (if old reminder data is available)
    if (oldReminder.isNotEmpty) {
      final oldStatus = oldReminder['status'] as String?;
      final newStatus = updatedReminder['status'] as String?;
      if (oldStatus != null && newStatus != null && oldStatus != newStatus) {
        print('ReminderStorageService: Rescheduling needed due to status change: $oldStatus -> $newStatus');
        return true;
      }
    }
    
    return false;
  }

  // Validate and adjust schedule time to ensure it meets minimum requirements
  DateTime validateScheduleTime(DateTime proposedTime) {
    final now = DateTime.now();
    final timeDifference = proposedTime.difference(now);
    
    print('DEBUG: Validating schedule time');
    print('  Proposed time: $proposedTime');
    print('  Current time: $now');
    print('  Time difference: ${timeDifference.inMinutes} minutes');
    
    // Ensure minimum 1 minute buffer time
    if (timeDifference.inMinutes < 1) {
      final adjustedTime = now.add(Duration(minutes: 1));
      print('  Applied minimum buffer, adjusted to: $adjustedTime');
      return adjustedTime;
    }
    
    print('  Schedule time is valid: $proposedTime');
    return proposedTime;
  }

  // Handle time conflicts and provide user-friendly adjustments
  DateTime adjustForTimeConflicts(DateTime proposedTime) {
    final now = DateTime.now();
    
    print('DEBUG: Checking for time conflicts');
    print('  Proposed time: $proposedTime');
    print('  Current time: $now');
    
    // Check if the proposed time is in the past
    if (proposedTime.isBefore(now)) {
      print('  Time conflict: Proposed time is in the past');
      
      // If it's the same day but time has passed, suggest next day
      if (proposedTime.year == now.year && 
          proposedTime.month == now.month && 
          proposedTime.day == now.day) {
        final nextDay = proposedTime.add(Duration(days: 1));
        print('  Adjusted to next day: $nextDay');
        return nextDay;
      }
      
      // For other cases, add minimum buffer
      final adjusted = now.add(Duration(minutes: 1));
      print('  Applied minimum buffer: $adjusted');
      return adjusted;
    }
    
    // Check if the proposed time is too close (less than 1 minute)
    final timeDifference = proposedTime.difference(now);
    if (timeDifference.inMinutes < 1) {
      final adjusted = now.add(Duration(minutes: 1));
      print('  Time too close, adjusted with buffer: $adjusted');
      return adjusted;
    }
    
    print('  No time conflicts detected');
    return proposedTime;
  }

  // Calculate precise schedule time for near-future reminders
  DateTime calculatePreciseScheduleTime(Map<String, dynamic> frequency, String time) {
    final now = DateTime.now();
    final frequencyType = frequency['type'] ?? frequency['id'];
    
    print('DEBUG: Calculating precise schedule time');
    print('  Frequency type: $frequencyType');
    print('  Time: $time');
    print('  Current time: $now');
    
    // For custom intervals in minutes, calculate exact future time
    if (frequencyType == 'custom') {
      final intervalValue = (frequency['interval'] ?? frequency['intervalValue']) as int?;
      final intervalUnit = (frequency['unit'] ?? frequency['intervalUnit']) as String?;
      
      if (intervalUnit == 'minutes' && intervalValue != null) {
        final preciseTime = now.add(Duration(minutes: intervalValue));
        print('  Precise time for $intervalValue minutes: $preciseTime');
        return validateScheduleTime(preciseTime);
      }
    }
    
    // For minutely frequency (testing), calculate exact time
    if (frequencyType == 'minutely') {
      final minutesFromNow = frequency['minutesFromNow'] as int? ?? 1;
      final preciseTime = now.add(Duration(minutes: minutesFromNow));
      print('  Precise time for minutely ($minutesFromNow min): $preciseTime');
      return validateScheduleTime(preciseTime);
    }
    
    // For other frequencies, use the standard calculation
    return _calculateNextOccurrenceDateTime(frequency, time);
  }

  // Save reminder with schedule confirmation (for UI integration)
  Future<Map<String, dynamic>?> saveReminderWithConfirmation({
    required String title,
    required String category,
    required Map<String, dynamic> frequency,
    required String time,
    String? description,
    Map<String, dynamic>? selectedAudio,
    bool enableNotifications = true,
    int repeatLimit = 0,
    Function(DateTime original, DateTime adjusted)? onScheduleConflict,
    Function(DateTime scheduledTime)? onScheduleConfirmation,
  }) async {
    print('ReminderStorageService: saveReminderWithConfirmation() called');
    
    // Calculate the proposed schedule time
    final proposedTime = calculatePreciseScheduleTime(frequency, time);
    final originalTime = _calculateOriginalProposedTime(frequency, time);
    
    // Check for conflicts and adjustments
    final adjustedTime = adjustForTimeConflicts(proposedTime);
    final hasConflict = !adjustedTime.isAtSameMomentAs(proposedTime);
    
    if (hasConflict && onScheduleConflict != null) {
      // Notify UI about the conflict for user confirmation
      onScheduleConflict(originalTime, adjustedTime);
      return null; // Return null to indicate confirmation needed
    }
    
    // If no conflicts or conflicts are auto-resolved, proceed with saving
    final finalTime = hasConflict ? adjustedTime : proposedTime;
    
    // Notify UI about the final schedule for confirmation
    if (onScheduleConfirmation != null) {
      onScheduleConfirmation(finalTime);
    }
    
    // Save the reminder with the final schedule
    return await saveReminder(
      title: title,
      category: category,
      frequency: frequency,
      time: time,
      description: description,
      selectedAudio: selectedAudio,
      enableNotifications: enableNotifications,
      repeatLimit: repeatLimit,
    );
  }

  // Calculate what the user originally intended (before adjustments)
  DateTime _calculateOriginalProposedTime(Map<String, dynamic> frequency, String time) {
    final now = DateTime.now();
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final frequencyType = frequency['type'] ?? frequency['id'];
    
    switch (frequencyType) {
      case 'daily':
        // User intended today at the specified time
        return DateTime(now.year, now.month, now.day, hour, minute);
      
      case 'custom':
        final intervalValue = (frequency['interval'] ?? frequency['intervalValue']) as int?;
        final intervalUnit = (frequency['unit'] ?? frequency['intervalUnit']) as String?;
        
        if (intervalUnit == 'minutes' && intervalValue != null) {
          return now.add(Duration(minutes: intervalValue));
        }
        break;
        
      case 'minutely':
        final minutesFromNow = frequency['minutesFromNow'] as int? ?? 1;
        return now.add(Duration(minutes: minutesFromNow));
    }
    
    // Default fallback
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  // Asynchronously sync reminder to Supabase (non-blocking)
  void _syncReminderToSupabaseAsync(Map<String, dynamic> reminder) {
    // Run in background without blocking the UI
    Future.microtask(() async {
      try {
        await retryOperationWithFeedback(() async {
          final userId = _authService.currentUser?['id'];
          if (userId == null) {
            throw AuthenticationException('No user ID available for sync');
          }

          final supabaseData = Map<String, dynamic>.from(reminder);
          supabaseData['user_id'] = userId;
          
          // Remove local-only fields and the local integer ID
          supabaseData.remove('needsSync');
          supabaseData.remove('id'); // Remove local integer ID - Supabase will generate UUID
          
          // Validate and clean data before database insertion
          if (!_validateDataBeforeInsert(supabaseData)) {
            throw ArgumentError('Invalid data format for database insertion');
          }
          
          // Ensure proper data types for Supabase
          if (supabaseData['frequency'] is Map) {
            supabaseData['frequency'] = supabaseData['frequency'];
          }
          if (supabaseData['selectedAudio'] is Map) {
            supabaseData['selectedAudio'] = supabaseData['selectedAudio'];
          }
          
          // Add timeout to prevent UI freezing
          final supabaseReminder = await _supabaseService.insert(_remindersTable, supabaseData)
              .timeout(Duration(seconds: 30), onTimeout: () {
            throw TimeoutException('Database operation timed out after 30 seconds', Duration(seconds: 30));
          });
          print('ReminderStorageService: Successfully synced reminder ${reminder['id']} to Supabase with UUID: ${supabaseReminder['id']}');
          
          // Update local reminder to remove sync flag and store Supabase UUID for future updates
          await _updateLocalReminderAfterSync(reminder['id'], supabaseReminder);
        }, 
        operationName: 'sync_reminder_to_supabase',
        maxAttempts: 3,
        baseDelayMs: 1000,
        onStatusUpdate: (status) {
          print('ReminderStorageService: Sync status - $status');
        });
        
      } catch (e) {
        print('ReminderStorageService: Failed to sync reminder ${reminder['id']} to Supabase: $e');
        
        // Enhanced error handling with user-friendly messages and recovery options
        final exception = e is Exception ? e : Exception(e.toString());
        await _handleDatabaseErrors(exception, reminder['id'], 'sync_reminder_to_supabase');
        
        // Keep the needsSync flag for retry later
        await _markReminderForRetrySync(reminder['id']);
      }
    });
  }

  // Update local reminder after successful Supabase sync
  Future<void> _updateLocalReminderAfterSync(int localId, Map<String, dynamic> supabaseReminder) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminders = await _getRemindersLocally();
      
      final index = reminders.indexWhere((r) => r['id'] == localId);
      if (index != -1) {
        // Update with Supabase data but keep local ID for consistency
        reminders[index] = {
          ...supabaseReminder,
          'id': localId, // Keep local ID
          'supabase_id': supabaseReminder['id'], // Store Supabase ID separately
        };
        reminders[index].remove('needsSync');
        
        await prefs.setString(_remindersKey, jsonEncode(reminders));
        print('ReminderStorageService: Updated local reminder after sync');
      }
    } catch (e) {
      print('ReminderStorageService: Error updating local reminder after sync: $e');
    }
  }

  // Mark reminder for retry sync
  Future<void> _markReminderForRetrySync(int reminderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminders = await _getRemindersLocally();
      
      final index = reminders.indexWhere((r) => r['id'] == reminderId);
      if (index != -1) {
        reminders[index]['needsSync'] = true;
        reminders[index]['syncRetryCount'] = (reminders[index]['syncRetryCount'] ?? 0) + 1;
        
        await prefs.setString(_remindersKey, jsonEncode(reminders));
      }
    } catch (e) {
      print('ReminderStorageService: Error marking reminder for retry sync: $e');
    }
  }

  // Mark reminder for sync
  Future<void> _markReminderForSync(dynamic reminderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminders = await _getRemindersLocally();
      
      final index = reminders.indexWhere((r) => r['id'] == reminderId);
      if (index != -1) {
        reminders[index]['needsSync'] = true;
        reminders[index]['lastModified'] = DateTime.now().toIso8601String();
        
        await prefs.setString(_remindersKey, jsonEncode(reminders));
      }
    } catch (e) {
      print('ReminderStorageService: Error marking reminder for sync: $e');
    }
  }

  // Asynchronously sync reminder update to Supabase
  void _syncReminderUpdateToSupabaseAsync(dynamic reminderId, Map<String, dynamic> updates) {
    Future.microtask(() async {
      try {
        await retryWithAuth(() async {
          final reminder = await getReminderById(reminderId);
          if (reminder == null) {
            throw Exception('Cannot sync update - reminder not found');
          }

          final supabaseId = reminder['supabase_id'] ?? reminderId;
          final cleanUpdates = Map<String, dynamic>.from(updates);
          cleanUpdates.remove('needsSync');
          cleanUpdates.remove('syncRetryCount');
          cleanUpdates.remove('lastModified');
          cleanUpdates.remove('id'); // Remove local ID
          cleanUpdates.remove('supabase_id'); // Remove supabase_id field

          // Validate data before update
          if (!_validateDataBeforeInsert(cleanUpdates)) {
            throw ArgumentError('Invalid data format for database update');
          }

          await _supabaseService.update(_remindersTable, cleanUpdates, {'id': supabaseId});
          print('ReminderStorageService: Successfully synced update for reminder $reminderId to Supabase');
          
          // Remove sync flag
          await _removeSyncFlag(reminderId);
        }, operationName: 'sync_reminder_update_to_supabase');
        
      } catch (e) {
        print('ReminderStorageService: Failed to sync update for reminder $reminderId to Supabase: $e');
        await _markReminderForRetrySync(reminderId);
      }
    });
  }

  // Asynchronously sync reminder deletion to Supabase
  void _syncReminderDeletionToSupabaseAsync(dynamic reminderId) {
    Future.microtask(() async {
      try {
        await retryWithAuth(() async {
          // We need to find the Supabase ID before deletion
          // Since the reminder is already deleted locally, we'll use the local ID
          await _supabaseService.delete(_remindersTable, {'id': reminderId});
          print('ReminderStorageService: Successfully synced deletion for reminder $reminderId to Supabase');
        }, operationName: 'sync_reminder_deletion_to_supabase');
        
      } catch (e) {
        print('ReminderStorageService: Failed to sync deletion for reminder $reminderId to Supabase: $e');
        // For deletions, we don't retry as the local data is already gone
      }
    });
  }

  // Remove sync flag from reminder
  Future<void> _removeSyncFlag(dynamic reminderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final reminders = await _getRemindersLocally();
      
      final index = reminders.indexWhere((r) => r['id'] == reminderId);
      if (index != -1) {
        reminders[index].remove('needsSync');
        reminders[index].remove('syncRetryCount');
        reminders[index].remove('lastModified');
        
        await prefs.setString(_remindersKey, jsonEncode(reminders));
      }
    } catch (e) {
      print('ReminderStorageService: Error removing sync flag: $e');
    }
  }

  // Asynchronously sync reminders from Supabase (background operation)
  void _syncRemindersFromSupabaseAsync() {
    Future.microtask(() async {
      try {
        await retryWithAuth(() async {
          final userId = _authService.currentUser?['id'];
          if (userId == null) {
            throw AuthenticationException('No user ID available for sync');
          }

          print('ReminderStorageService: Background sync from Supabase started');
          final supabaseReminders = await _supabaseService.select(
            _remindersTable,
            filters: {'user_id': userId},
          );
          
          print('ReminderStorageService: Background sync loaded ${supabaseReminders.length} reminders from Supabase');
          
          // Merge with local reminders (prioritizing local changes)
          await _mergeRemindersWithLocal(supabaseReminders);
          
          // Sync any pending local changes to Supabase
          await _syncPendingChangesToSupabase();
          
          print('ReminderStorageService: Background sync completed');
        }, operationName: 'sync_reminders_from_supabase');
        
      } catch (e) {
        print('ReminderStorageService: Background sync failed: $e');
        // Don't throw - this is a background operation
      }
    });
  }

  // Merge Supabase reminders with local reminders
  Future<void> _mergeRemindersWithLocal(List<Map<String, dynamic>> supabaseReminders) async {
    try {
      final localReminders = await _getRemindersLocally();
      final mergedReminders = <Map<String, dynamic>>[];
      
      // Add all local reminders first (they have priority)
      for (final localReminder in localReminders) {
        mergedReminders.add(localReminder);
      }
      
      // Add Supabase reminders that don't exist locally
      for (final supabaseReminder in supabaseReminders) {
        final existsLocally = localReminders.any((lr) => 
          lr['supabase_id'] == supabaseReminder['id'] || 
          lr['id'] == supabaseReminder['id']
        );
        
        if (!existsLocally) {
          // This is a new reminder from Supabase
          final localId = await _getNextLocalId();
          mergedReminders.add({
            ...supabaseReminder,
            'id': localId,
            'supabase_id': supabaseReminder['id'],
          });
        }
      }
      
      // Save merged reminders
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_remindersKey, jsonEncode(mergedReminders));
      
      print('ReminderStorageService: Merged ${mergedReminders.length} reminders');
    } catch (e) {
      print('ReminderStorageService: Error merging reminders: $e');
    }
  }

  // Sync pending local changes to Supabase
  Future<void> _syncPendingChangesToSupabase() async {
    try {
      final localReminders = await _getRemindersLocally();
      final pendingReminders = localReminders.where((r) => r['needsSync'] == true).toList();
      
      print('ReminderStorageService: Found ${pendingReminders.length} reminders pending sync');
      
      for (final reminder in pendingReminders) {
        try {
          final userId = _authService.currentUser?['id'];
          final supabaseData = Map<String, dynamic>.from(reminder);
          supabaseData['user_id'] = userId;
          supabaseData.remove('needsSync');
          supabaseData.remove('syncRetryCount');
          supabaseData.remove('lastModified');
          
          if (reminder['supabase_id'] != null) {
            // Update existing - remove local-only fields
            supabaseData.remove('id');
            supabaseData.remove('supabase_id');
            
            // Validate data before update
            if (!_validateDataBeforeInsert(supabaseData)) {
              throw ArgumentError('Invalid data format for database update');
            }
            
            await _supabaseService.update(_remindersTable, supabaseData, {'id': reminder['supabase_id']});
          } else {
            // Create new - remove local-only fields
            supabaseData.remove('id'); // Remove local integer ID - Supabase will generate UUID
            
            // Validate data before insert
            if (!_validateDataBeforeInsert(supabaseData)) {
              throw ArgumentError('Invalid data format for database insertion');
            }
            
            final supabaseReminder = await _supabaseService.insert(_remindersTable, supabaseData);
            await _updateLocalReminderAfterSync(reminder['id'], supabaseReminder);
          }
          
          await _removeSyncFlag(reminder['id']);
          print('ReminderStorageService: Synced pending reminder ${reminder['id']}');
        } catch (e) {
          print('ReminderStorageService: Failed to sync pending reminder ${reminder['id']}: $e');
          await _markReminderForRetrySync(reminder['id']);
        }
      }
    } catch (e) {
      print('ReminderStorageService: Error syncing pending changes: $e');
    }
  }

  // Get next local ID
  Future<int> _getNextLocalId() async {
    final prefs = await SharedPreferences.getInstance();
    final nextId = prefs.getInt(_nextIdKey) ?? 1;
    await prefs.setInt(_nextIdKey, nextId + 1);
    return nextId;
  }

  // Authentication validation methods for task 5.1

  /// Validates the current user session and authentication state
  /// Returns true if the user has a valid session, false otherwise
  Future<bool> validateUserSession() async {
    try {
      // Check if user is logged in
      if (!_authService.isLoggedIn) {
        print('ReminderStorageService: User is not logged in');
        return false;
      }

      // For guest users, session is always valid
      if (_authService.isGuestMode) {
        print('ReminderStorageService: Guest mode - session valid');
        return true;
      }

      // For Supabase users, validate session
      if (_authService.isSupabaseUser) {
        if (!_supabaseService.isInitialized) {
          print('ReminderStorageService: Supabase not initialized');
          return false;
        }

        final user = _supabaseService.getCurrentUser();
        final session = _supabaseService.getCurrentSession();

        if (user == null || session == null) {
          print('ReminderStorageService: No valid Supabase user or session');
          return false;
        }

        if (session.isExpired) {
          print('ReminderStorageService: Supabase session expired');
          return false;
        }

        print('ReminderStorageService: Valid Supabase session found');
        return true;
      }

      // For other authentication types, check if we have valid user data
      final currentUser = _authService.currentUser;
      if (currentUser == null || currentUser['id'] == null) {
        print('ReminderStorageService: No valid user data');
        return false;
      }

      print('ReminderStorageService: Valid user session');
      return true;
    } catch (e) {
      print('ReminderStorageService: Error validating user session: $e');
      await _errorHandlingService.logError(
        'AUTH_SESSION_VALIDATION_ERROR',
        'Error validating user session: $e',
        severity: ErrorSeverity.warning,
        stackTrace: StackTrace.current,
      );
      return false;
    }
  }

  /// Wrapper for Supabase operations that includes authentication validation and retry logic
  /// Returns the result of the operation or throws an exception
  Future<T> retryWithAuth<T>(Future<T> Function() operation, {String operationName = 'unknown'}) async {
    int attempts = 0;
    const maxAttempts = 3;
    const baseDelayMs = 1000; // 1 second

    while (attempts < maxAttempts) {
      attempts++;
      
      try {
        // Validate session before attempting operation
        final isValidSession = await validateUserSession();
        if (!isValidSession) {
          throw AuthenticationException('Invalid or expired user session');
        }

        // Attempt the operation
        print('ReminderStorageService: Attempting $operationName (attempt $attempts/$maxAttempts)');
        final result = await operation();
        print('ReminderStorageService: Successfully completed $operationName');
        return result;

      } on AuthenticationException catch (e) {
        print('ReminderStorageService: Authentication error in $operationName: $e');
        
        // Try to refresh auth state
        try {
          await _authService.refreshAuthState();
          final isValidAfterRefresh = await validateUserSession();
          
          if (!isValidAfterRefresh) {
            await _handleAuthErrors(e, operationName);
            throw e; // Don't retry if auth refresh failed
          }
        } catch (refreshError) {
          print('ReminderStorageService: Failed to refresh auth state: $refreshError');
          await _handleAuthErrors(e, operationName);
          throw e;
        }

        // If this was the last attempt, don't retry
        if (attempts >= maxAttempts) {
          await _handleAuthErrors(e, operationName);
          throw e;
        }

        // Wait before retrying with exponential backoff
        final delayMs = baseDelayMs * (1 << (attempts - 1)); // 1s, 2s, 4s
        print('ReminderStorageService: Retrying $operationName in ${delayMs}ms');
        await Future.delayed(Duration(milliseconds: delayMs));

      } catch (e) {
        print('ReminderStorageService: Error in $operationName (attempt $attempts): $e');
        
        // For non-auth errors, only retry if it's the type of error that might be transient
        if (_isRetryableError(e) && attempts < maxAttempts) {
          final delayMs = baseDelayMs * (1 << (attempts - 1));
          print('ReminderStorageService: Retrying $operationName in ${delayMs}ms due to retryable error');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // Log the error and rethrow
        await _errorHandlingService.logError(
          'OPERATION_ERROR',
          'Error in $operationName: $e',
          severity: ErrorSeverity.error,
          stackTrace: StackTrace.current,
        );
        throw e;
      }
    }

    throw Exception('Max retry attempts exceeded for $operationName');
  }

  /// Handles authentication-specific errors with user-friendly feedback
  Future<void> _handleAuthErrors(Exception error, String operation) async {
    try {
      String userMessage;
      String logMessage = 'Authentication error in $operation: $error';

      if (error is AuthenticationException) {
        userMessage = 'Your session has expired. Please log in again to continue.';
      } else {
        userMessage = 'Authentication failed. Please check your connection and try again.';
      }

      // Log the error
      await _errorHandlingService.logError(
        'AUTH_ERROR',
        logMessage,
        severity: ErrorSeverity.error,
        stackTrace: StackTrace.current,
      );

      // Log user-friendly error message
      await _errorHandlingService.logError(
        'AUTH_USER_ERROR',
        userMessage,
        severity: ErrorSeverity.warning,
        stackTrace: StackTrace.current,
      );

    } catch (e) {
      print('ReminderStorageService: Error handling auth error: $e');
    }
  }

  /// Handles database-specific errors with user-friendly feedback and recovery options
  Future<void> _handleDatabaseErrors(Exception error, dynamic reminderId, String operation) async {
    try {
      String userMessage;
      String logMessage = 'Database error in $operation for reminder $reminderId: $error';
      Map<String, dynamic> metadata = {
        'operation': operation,
        'reminderId': reminderId,
        'error': error.toString(),
      };

      // Determine user-friendly message based on error type
      final errorString = error.toString().toLowerCase();
      
      if (errorString.contains('uuid') && errorString.contains('invalid input syntax')) {
        userMessage = 'Data format error occurred. The reminder was saved locally and will sync when the issue is resolved.';
        metadata['errorType'] = 'uuid_format_error';
        metadata['userMessage'] = 'A data format error occurred. Please try again.';
      } else if (errorString.contains('exec_sql') && errorString.contains('not found')) {
        userMessage = 'Database configuration issue detected. The reminder was saved locally and will sync when the issue is resolved.';
        metadata['errorType'] = 'missing_function_error';
        metadata['userMessage'] = 'A database configuration error occurred. Please try again.';
      } else if (errorString.contains('timeout')) {
        userMessage = 'Database operation timed out. The reminder was saved locally and will sync when connection improves.';
        metadata['errorType'] = 'timeout_error';
        metadata['userMessage'] = 'The operation timed out. Please check your connection and try again.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        userMessage = 'Network connection issue. The reminder was saved locally and will sync when connection is restored.';
        metadata['errorType'] = 'network_error';
        metadata['userMessage'] = 'A network error occurred. Please check your connection and try again.';
      } else {
        userMessage = 'A database error occurred. The reminder was saved locally and will sync automatically later.';
        metadata['errorType'] = 'general_database_error';
        metadata['userMessage'] = 'A database error occurred. Please try again.';
      }

      // Log the technical error
      await _errorHandlingService.logError(
        'DATABASE_ERROR',
        logMessage,
        severity: ErrorSeverity.error,
        stackTrace: StackTrace.current,
        metadata: metadata,
      );

      // Log user-friendly error message
      await _errorHandlingService.logError(
        'DATABASE_USER_ERROR',
        userMessage,
        severity: ErrorSeverity.warning,
        metadata: {
          'operation': operation,
          'userMessage': metadata['userMessage'],
        },
      );

    } catch (e) {
      print('ReminderStorageService: Error handling database error: $e');
    }
  }

  /// Determines if an error is retryable
  bool _isRetryableError(dynamic error) {
    if (error is AuthenticationException) {
      return true; // Auth errors are retryable after refresh
    }
    
    // Network-related errors are typically retryable
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('socket') ||
           errorString.contains('http');
  }

  // Enhanced retry logic with exponential backoff for task 5.2

  /// Enhanced wrapper for operations with better retry logic and UI feedback
  /// Includes exponential backoff, auth token refresh, and immediate UI updates
  Future<T> retryOperationWithFeedback<T>(
    Future<T> Function() operation, {
    required String operationName,
    Function(String status)? onStatusUpdate,
    int maxAttempts = 3,
    int baseDelayMs = 1000,
  }) async {
    int attempts = 0;
    Exception? lastException;

    // Provide immediate feedback that operation started
    onStatusUpdate?.call('Starting $operationName...');

    while (attempts < maxAttempts) {
      attempts++;
      
      try {
        // Update status for retry attempts
        if (attempts > 1) {
          onStatusUpdate?.call('Retrying $operationName (attempt $attempts/$maxAttempts)...');
        }

        // Validate session before attempting operation
        final isValidSession = await validateUserSession();
        if (!isValidSession) {
          throw AuthenticationException('Invalid or expired user session');
        }

        // Attempt the operation
        print('ReminderStorageService: Attempting $operationName (attempt $attempts/$maxAttempts)');
        final result = await operation();
        
        // Success feedback
        onStatusUpdate?.call('$operationName completed successfully');
        print('ReminderStorageService: Successfully completed $operationName');
        return result;

      } on AuthenticationException catch (e) {
        lastException = e;
        print('ReminderStorageService: Authentication error in $operationName: $e');
        
        // Update status for auth error
        onStatusUpdate?.call('Authentication issue, refreshing session...');
        
        // Try to refresh auth state
        try {
          await _authService.refreshAuthState();
          final isValidAfterRefresh = await validateUserSession();
          
          if (!isValidAfterRefresh) {
            onStatusUpdate?.call('Authentication failed - please log in again');
            await _handleAuthErrors(e, operationName);
            throw e; // Don't retry if auth refresh failed
          }
          
          onStatusUpdate?.call('Session refreshed, retrying...');
        } catch (refreshError) {
          print('ReminderStorageService: Failed to refresh auth state: $refreshError');
          onStatusUpdate?.call('Failed to refresh session');
          await _handleAuthErrors(e, operationName);
          throw e;
        }

        // If this was the last attempt, don't retry
        if (attempts >= maxAttempts) {
          onStatusUpdate?.call('$operationName failed after $maxAttempts attempts');
          await _handleAuthErrors(e, operationName);
          throw e;
        }

        // Wait before retrying with exponential backoff
        final delayMs = _calculateBackoffDelay(attempts, baseDelayMs);
        onStatusUpdate?.call('Waiting ${delayMs}ms before retry...');
        print('ReminderStorageService: Retrying $operationName in ${delayMs}ms');
        await Future.delayed(Duration(milliseconds: delayMs));

      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        print('ReminderStorageService: Error in $operationName (attempt $attempts): $e');
        
        // For non-auth errors, only retry if it's the type of error that might be transient
        if (_isRetryableError(e) && attempts < maxAttempts) {
          final delayMs = _calculateBackoffDelay(attempts, baseDelayMs);
          onStatusUpdate?.call('Network error, retrying in ${delayMs}ms...');
          print('ReminderStorageService: Retrying $operationName in ${delayMs}ms due to retryable error');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        // Log the error and provide feedback
        onStatusUpdate?.call('$operationName failed: ${_getUserFriendlyErrorMessage(e)}');
        await _errorHandlingService.logError(
          'OPERATION_ERROR',
          'Error in $operationName: $e',
          severity: ErrorSeverity.error,
          stackTrace: StackTrace.current,
        );
        throw lastException!;
      }
    }

    // This should not be reached, but just in case
    onStatusUpdate?.call('$operationName failed after maximum retry attempts');
    throw lastException ?? Exception('Max retry attempts exceeded for $operationName');
  }

  /// Calculate exponential backoff delay with jitter
  int _calculateBackoffDelay(int attempt, int baseDelayMs) {
    // Exponential backoff: baseDelay * 2^(attempt-1)
    // With jitter to avoid thundering herd
    final exponentialDelay = baseDelayMs * (1 << (attempt - 1));
    final jitter = (exponentialDelay * 0.1 * (DateTime.now().millisecond % 100) / 100).round();
    return exponentialDelay + jitter;
  }

  /// Get user-friendly error message
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network connection issue';
    } else if (errorString.contains('timeout')) {
      return 'Operation timed out';
    } else if (errorString.contains('authentication') || errorString.contains('unauthorized')) {
      return 'Authentication required';
    } else if (errorString.contains('permission')) {
      return 'Permission denied';
    } else {
      return 'An unexpected error occurred';
    }
  }

  // Enhanced operation methods with immediate UI feedback

  /// Enhanced toggle reminder status with immediate UI feedback
  Future<void> toggleReminderStatusWithFeedback(
    dynamic reminderId, {
    Function(String status)? onStatusUpdate,
  }) async {
    await retryOperationWithFeedback(
      () async {
        final reminder = await getReminderById(reminderId);
        if (reminder != null) {
          final oldStatus = reminder['status'] as String;
          final newStatus = oldStatus == 'active' ? 'paused' : 'active';
          String nextOccurrence = 'Paused';
          String? nextOccurrenceDateTime;
          
          if (newStatus == 'active') {
            final nextDateTime = _calculateNextOccurrenceDateTime(reminder['frequency'], reminder['time']);
            nextOccurrence = _formatNextOccurrence(nextDateTime);
            nextOccurrenceDateTime = nextDateTime.toIso8601String();
          }
          
          await updateReminder(reminderId, {
            'status': newStatus,
            'nextOccurrence': nextOccurrence,
            'nextOccurrenceDateTime': nextOccurrenceDateTime,
          });
          
          // Handle background notification scheduling based on status change (non-blocking)
          if (newStatus == 'paused') {
            // Cancel background notification when pausing (non-blocking)
            unawaited(
              BackgroundTaskManager.instance.cancelNotification(reminderId).then((_) {
                print('ReminderStorageService: Cancelled background notification for paused reminder $reminderId');
              }).catchError((e) {
                print('ReminderStorageService: Error cancelling background notification for paused reminder $reminderId: $e');
              })
            );
          } else if (newStatus == 'active' && reminder['enableNotifications'] == true) {
            // Schedule background notification when activating (non-blocking)
            unawaited(
              BackgroundTaskManager.instance.rescheduleReminder(reminderId).then((_) {
                print('ReminderStorageService: Scheduled background notification for activated reminder $reminderId');
              }).catchError((e) {
                print('ReminderStorageService: Error scheduling background notification for activated reminder $reminderId: $e');
              })
            );
          }
        }
      },
      operationName: 'toggle reminder status',
      onStatusUpdate: onStatusUpdate,
    );
  }

  /// Enhanced delete reminder with immediate UI feedback
  Future<void> deleteReminderWithFeedback(
    dynamic reminderId, {
    Function(String status)? onStatusUpdate,
  }) async {
    await retryOperationWithFeedback(
      () async {
        // ALWAYS delete locally first for immediate response
        await _deleteReminderLocally(reminderId);
        print('ReminderStorageService: Deleted reminder $reminderId locally');
        
        // Sync deletion to Supabase asynchronously if available
        if (_shouldUseSupabase()) {
          _syncReminderDeletionToSupabaseAsync(reminderId);
        }
        
        // Cancel background notification for the deleted reminder (non-blocking)
        unawaited(
          BackgroundTaskManager.instance.cancelNotification(reminderId).then((_) {
            print('ReminderStorageService: Cancelled background notification for deleted reminder $reminderId');
          }).catchError((e) {
            print('ReminderStorageService: Error cancelling background notification for deleted reminder $reminderId: $e');
            // Continue - the reminder is already deleted from storage
          })
        );
      },
      operationName: 'delete reminder',
      onStatusUpdate: onStatusUpdate,
    );
  }

  /// Enhanced update reminder with immediate UI feedback
  Future<void> updateReminderWithFeedback(
    dynamic reminderId,
    Map<String, dynamic> updates, {
    Function(String status)? onStatusUpdate,
  }) async {
    await retryOperationWithFeedback(
      () async {
        // ALWAYS update locally first for immediate response
        await _updateReminderLocally(reminderId, updates);
        print('ReminderStorageService: Updated reminder $reminderId locally');
        
        // Mark for sync if Supabase is available
        if (_shouldUseSupabase()) {
          await _markReminderForSync(reminderId);
          _syncReminderUpdateToSupabaseAsync(reminderId, updates);
        }
        
        // Get the updated reminder for notification rescheduling
        final updatedReminder = await getReminderById(reminderId);
        if (updatedReminder != null) {
          // Reschedule background notification if reminder properties changed (non-blocking)
          final needsReschedule = _shouldRescheduleNotification({}, updatedReminder, updates);

          if (needsReschedule) {
            // Run in background without awaiting for faster UI response
            unawaited(
              BackgroundTaskManager.instance.rescheduleReminder(reminderId).then((_) {
                print('ReminderStorageService: Rescheduled background notification for updated reminder $reminderId');
              }).catchError((e) {
                print('ReminderStorageService: Error rescheduling background notification for updated reminder $reminderId: $e');
                // Continue without background scheduling - foreground notifications will still work
              })
            );
          }
        }
      },
      operationName: 'update reminder',
      onStatusUpdate: onStatusUpdate,
    );
  }
}

/// Custom exception for authentication-related errors
class AuthenticationException implements Exception {
  final String message;
  
  AuthenticationException(this.message);
  
  @override
  String toString() => 'AuthenticationException: $message';
}