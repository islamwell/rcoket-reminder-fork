import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'reminder_storage_service.dart';
import 'notification_service.dart';
import 'error_handling_service.dart';

/// Background Task Manager Service
/// 
/// Manages background notification scheduling and app lifecycle state changes
/// to ensure reminders work even when the app is minimized or in power-saving mode.
/// 
/// Requirements addressed:
/// - 1.1: Reminders trigger when app is minimized
/// - 1.2: Reminders trigger in power-saving mode  
/// - 5.1: Handle device restarts and reschedule reminders
/// - 5.2: Handle system time changes appropriately
class BackgroundTaskManager {
  static BackgroundTaskManager? _instance;
  static BackgroundTaskManager get instance => _instance ??= BackgroundTaskManager._();
  BackgroundTaskManager._();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  AppLifecycleState? _currentAppState;
  Timer? _scheduleCheckTimer;
  
  /// Initialize the background task manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await ErrorHandlingService.instance.retryOperation(
      'initialize_background_task_manager',
      () async {
        try {
          await _initializeNotifications();
          await _setupAppLifecycleListener();
          await scheduleAllActiveReminders();
          _startPeriodicScheduleCheck();
          
          _isInitialized = true;
          
          await ErrorHandlingService.instance.logError(
            'BACKGROUND_MANAGER_INITIALIZED',
            'Background task manager initialized successfully',
            severity: ErrorSeverity.info,
          );
          
          print('BackgroundTaskManager: Initialized successfully');
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'BACKGROUND_MANAGER_INIT_ERROR',
            'Background task manager initialization failed: $e',
            severity: ErrorSeverity.error,
            stackTrace: StackTrace.current,
          );
          
          // Enable fallback mode if initialization fails
          await ErrorHandlingService.instance.setFallbackMode(
            true,
            reason: 'Background task manager initialization failed'
          );
          
          rethrow;
        }
      },
      maxAttempts: 2,
      delay: Duration(seconds: 2),
    );
  }



  /// Initialize native notifications
  Future<void> _initializeNotifications() async {
    // Initialize timezone data for scheduling
    tz.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap events
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (payload != null) {
      print('BackgroundTaskManager: Notification tapped with payload: $payload');
      // Delegate to notification service for handling
      NotificationService.instance.handleNotificationTap(payload);
    }
  }

  /// Set up app lifecycle state monitoring
  Future<void> _setupAppLifecycleListener() async {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(this));
  }

  /// Handle app lifecycle state changes
  /// Made non-blocking to prevent UI freezing during state transitions
  Future<void> handleAppStateChange(AppLifecycleState state) async {
    final previousState = _currentAppState;
    _currentAppState = state;

    print('BackgroundTaskManager: App state changed from $previousState to $state');

    switch (state) {
      case AppLifecycleState.paused:
        // App is going to background - ensure all notifications are scheduled (non-blocking)
        unawaited(
          scheduleAllActiveReminders().then((_) {
            print('BackgroundTaskManager: Background scheduling completed after app pause');
          }).catchError((e) {
            print('BackgroundTaskManager: Error scheduling after pause: $e');
          })
        );
        break;

      case AppLifecycleState.resumed:
        // App is coming to foreground - check for any missed notifications (non-blocking)
        unawaited(
          _handleAppResumed().then((_) {
            print('BackgroundTaskManager: Resume handling completed');
          }).catchError((e) {
            print('BackgroundTaskManager: Error handling resume: $e');
          })
        );
        break;

      case AppLifecycleState.detached:
        // App is being terminated - final cleanup (non-blocking)
        unawaited(
          _handleAppDetached().then((_) {
            print('BackgroundTaskManager: Detach handling completed');
          }).catchError((e) {
            print('BackgroundTaskManager: Error handling detach: $e');
          })
        );
        break;

      default:
        break;
    }
  }

  /// Handle app resuming from background
  Future<void> _handleAppResumed() async {
    try {
      // Cancel any pending notifications that might have been handled by foreground
      await _cancelExpiredNotifications();

      // Reschedule all active reminders to ensure accuracy (non-blocking)
      unawaited(
        scheduleAllActiveReminders().then((_) {
          print('BackgroundTaskManager: App resumed, notifications rescheduled');
        }).catchError((e) {
          print('BackgroundTaskManager: Error rescheduling on resume: $e');
        })
      );
    } catch (e) {
      print('BackgroundTaskManager: Error handling app resume: $e');
    }
  }

  /// Handle app being terminated
  Future<void> _handleAppDetached() async {
    try {
      // Ensure all active reminders have background notifications scheduled (non-blocking)
      unawaited(
        scheduleAllActiveReminders().then((_) {
          print('BackgroundTaskManager: App detached, background notifications ensured');
        }).catchError((e) {
          print('BackgroundTaskManager: Error scheduling on detach: $e');
        })
      );
    } catch (e) {
      print('BackgroundTaskManager: Error handling app detach: $e');
    }
  }

  /// Schedule notifications for all active reminders
  Future<void> scheduleAllActiveReminders() async {
    await ErrorHandlingService.instance.retryOperation(
      'schedule_all_active_reminders',
      () async {
        try {
          // Check if we're in fallback mode
          if (ErrorHandlingService.instance.isInFallbackMode) {
            await ErrorHandlingService.instance.logError(
              'SCHEDULE_SKIPPED_FALLBACK',
              'Skipping background scheduling due to fallback mode',
              severity: ErrorSeverity.info,
            );
            return;
          }

          final reminders = await ReminderStorageService.instance.getReminders();
          final activeReminders = reminders.where((r) => r['status'] == 'active').toList();
          
          await ErrorHandlingService.instance.logError(
            'SCHEDULE_ALL_STARTED',
            'Starting to schedule ${activeReminders.length} active reminders',
            severity: ErrorSeverity.info,
            metadata: {'reminderCount': activeReminders.length},
          );
          
          print('BackgroundTaskManager: Scheduling ${activeReminders.length} active reminders');

          // NOTE: We don't cancel all notifications here to preserve properly scheduled ones
          // Individual reminders will be rescheduled as needed

          int successCount = 0;
          int failureCount = 0;
          
          // Schedule each active reminder
          for (final reminder in activeReminders) {
            try {
              await _scheduleReminderNotification(reminder);
              successCount++;
            } catch (e) {
              failureCount++;
              await ErrorHandlingService.instance.logError(
                'SCHEDULE_REMINDER_ERROR',
                'Failed to schedule reminder ${reminder['id']}: $e',
                severity: ErrorSeverity.warning,
                metadata: {'reminderId': reminder['id']},
              );
            }
          }
          
          await ErrorHandlingService.instance.logError(
            'SCHEDULE_ALL_COMPLETED',
            'Completed scheduling: $successCount successful, $failureCount failed',
            severity: failureCount > 0 ? ErrorSeverity.warning : ErrorSeverity.info,
            metadata: {
              'successCount': successCount,
              'failureCount': failureCount,
              'totalCount': activeReminders.length,
            },
          );
          
          // Enable fallback mode if too many failures
          if (failureCount > activeReminders.length / 2 && activeReminders.isNotEmpty) {
            await ErrorHandlingService.instance.setFallbackMode(
              true,
              reason: 'High failure rate in background scheduling ($failureCount/$activeReminders.length)'
            );
          }
          
          print('BackgroundTaskManager: All active reminders scheduled ($successCount/$activeReminders.length successful)');
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'SCHEDULE_ALL_ERROR',
            'Error scheduling all reminders: $e',
            severity: ErrorSeverity.error,
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      },
      maxAttempts: 2,
      delay: Duration(seconds: 1),
    );
  }

  /// Schedule a notification for a specific reminder
  Future<void> _scheduleReminderNotification(Map<String, dynamic> reminder) async {
    await ErrorHandlingService.instance.retryOperation(
      'schedule_reminder_${reminder['id']}',
      () async {
        try {
          final nextOccurrenceDateTime = _calculateNextOccurrenceDateTime(reminder);
          if (nextOccurrenceDateTime == null) {
            await ErrorHandlingService.instance.logError(
              'NO_VALID_OCCURRENCE',
              'No valid next occurrence for reminder ${reminder['id']}',
              severity: ErrorSeverity.warning,
              metadata: {'reminderId': reminder['id']},
            );
            return;
          }
          
          final notificationId = reminder['id'] as int;
          final title = reminder['title'] as String;
          final category = reminder['category'] as String;
          
          // Create notification payload
          final payload = _createNotificationPayload(reminder);

          // Check if the scheduled time is in the future
          if (nextOccurrenceDateTime.isBefore(DateTime.now())) {
            await ErrorHandlingService.instance.logError(
              'PAST_NOTIFICATION_SKIPPED',
              'Skipping past notification for reminder $notificationId',
              severity: ErrorSeverity.info,
              metadata: {
                'reminderId': notificationId,
                'scheduledTime': nextOccurrenceDateTime.toIso8601String(),
              },
            );
            return;
          }

          // Convert to timezone-aware date
          final scheduledTZDate = tz.TZDateTime.from(nextOccurrenceDateTime, tz.local);

          // Android notification details with FULLSCREEN INTENT for lock screen
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Notifications for scheduled reminders',
            importance: Importance.max,        // CRITICAL: Max importance for lock screen
            priority: Priority.max,            // CRITICAL: Max priority for lock screen
            showWhen: true,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,            // CRITICAL: Shows on lock screen
            category: AndroidNotificationCategory.alarm,  // CRITICAL: Bypasses DND
            visibility: NotificationVisibility.public,    // Shows on lock screen
            autoCancel: false,                 // Persists until user action
            ongoing: true,                     // Cannot be swiped away
          );

          // iOS notification details
          const DarwinNotificationDetails iOSPlatformChannelSpecifics =
              DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

          // Combined notification details
          const NotificationDetails platformChannelSpecifics = NotificationDetails(
            android: androidPlatformChannelSpecifics,
            iOS: iOSPlatformChannelSpecifics,
          );

          // Use zonedSchedule for proper native scheduling that survives app death
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            'Reminder: $title',
            'Time for your $category reminder',
            scheduledTZDate,
            platformChannelSpecifics,
            payload: payload,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,  // Works in Doze mode
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );


          await ErrorHandlingService.instance.logError(
            'REMINDER_SCHEDULED',
            'Scheduled FULLSCREEN notification for reminder ${reminder['id']} at $nextOccurrenceDateTime',
            severity: ErrorSeverity.info,
            metadata: {
              'reminderId': reminder['id'],
              'scheduledTime': scheduledTZDate.toIso8601String(),
              'method': 'zonedSchedule',
              'fullscreenIntent': true,
            },
          );

          print('BackgroundTaskManager: ✓ Scheduled FULLSCREEN notification for reminder ${reminder['id']}');
          print('  - Scheduled time: $scheduledTZDate');
          print('  - Method: zonedSchedule (survives app death)');
          print('  - Importance: MAX');
          print('  - Priority: MAX');
          print('  - Full screen intent: ENABLED');
          print('  - Category: ALARM');
          print('  - Schedule mode: exactAllowWhileIdle (works in Doze)');
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'SCHEDULE_REMINDER_ERROR',
            'Error scheduling reminder ${reminder['id']}: $e',
            severity: ErrorSeverity.error,
            metadata: {'reminderId': reminder['id']},
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      },
      maxAttempts: 2,
      delay: Duration(milliseconds: 500),
    );
  }

  /// Calculate the next occurrence DateTime for a reminder
  DateTime? _calculateNextOccurrenceDateTime(Map<String, dynamic> reminder) {
    final frequency = reminder['frequency'] as Map<String, dynamic>;
    final time = reminder['time'] as String;
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final now = DateTime.now();
    DateTime? nextOccurrence;
    
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
        // Only schedule if it's in the future
        if (nextOccurrence.isBefore(now)) {
          return null;
        }
        break;
        
      case 'daily':
        nextOccurrence = DateTime(now.year, now.month, now.day, hour, minute);
        if (nextOccurrence.isBefore(now) || nextOccurrence.difference(now).inMinutes < 1) {
          nextOccurrence = nextOccurrence.add(const Duration(days: 1));
        }
        break;
        
      case 'weekly':
        final selectedDays = List<int>.from(frequency['selectedDays'] ?? []);
        nextOccurrence = _getNextWeeklyOccurrenceDateTime(now, selectedDays, hour, minute);
        break;
        
      case 'hourly':
        // Schedule for the next hour
        nextOccurrence = DateTime(now.year, now.month, now.day, now.hour + 1, minute);
        if (nextOccurrence.isBefore(now)) {
          nextOccurrence = nextOccurrence.add(const Duration(hours: 1));
        }
        break;
        
      case 'monthly':
        final dayOfMonth = frequency['dayOfMonth'] as int;
        nextOccurrence = DateTime(now.year, now.month, dayOfMonth, hour, minute);
        if (nextOccurrence.isBefore(now)) {
          nextOccurrence = DateTime(now.year, now.month + 1, dayOfMonth, hour, minute);
        }
        break;
        
      case 'custom':
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
            interval = const Duration(hours: 1);
        }
        
        nextOccurrence = now.add(interval);
        break;
        
      case 'minutely':
        final minutesFromNow = frequency['minutesFromNow'] as int? ?? 1;
        nextOccurrence = now.add(Duration(minutes: minutesFromNow));
        break;
        
      default:
        nextOccurrence = now.add(const Duration(hours: 1));
    }
    
    return nextOccurrence;
  }

  /// Get next weekly occurrence DateTime
  DateTime? _getNextWeeklyOccurrenceDateTime(DateTime now, List<int> selectedDays, int hour, int minute) {
    if (selectedDays.isEmpty) return null;
    
    // Find the next occurrence within the next 7 days
    for (int i = 0; i < 7; i++) {
      final checkDate = now.add(Duration(days: i));
      final weekday = checkDate.weekday;
      
      if (selectedDays.contains(weekday)) {
        final occurrence = DateTime(checkDate.year, checkDate.month, checkDate.day, hour, minute);
        if (occurrence.isAfter(now)) {
          return occurrence;
        }
      }
    }
    
    return null;
  }

  /// Create notification payload for a reminder
  String _createNotificationPayload(Map<String, dynamic> reminder) {
    return '${reminder['id']}|${reminder['title']}|${reminder['category']}';
  }

  /// Reschedule a specific reminder
  Future<void> rescheduleReminder(dynamic reminderId) async {
    try {
      final reminder = await ReminderStorageService.instance.getReminderById(reminderId);
      if (reminder == null) {
        print('BackgroundTaskManager: Reminder $reminderId not found for rescheduling');
        return;
      }
      
      // Cancel existing notification
      await cancelNotification(reminderId);
      
      // Schedule new notification if reminder is active
      if (reminder['status'] == 'active') {
        await _scheduleReminderNotification(reminder);
        print('BackgroundTaskManager: Rescheduled reminder $reminderId');
      }
    } catch (e) {
      print('BackgroundTaskManager: Error rescheduling reminder $reminderId: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(dynamic reminderId) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(reminderId);
      print('BackgroundTaskManager: Cancelled notification for reminder $reminderId');
    } catch (e) {
      print('BackgroundTaskManager: Error cancelling notification $reminderId: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('BackgroundTaskManager: Cancelled all notifications');
    } catch (e) {
      print('BackgroundTaskManager: Error cancelling all notifications: $e');
    }
  }

  /// Cancel expired notifications (those that should have already triggered)
  Future<void> _cancelExpiredNotifications() async {
    try {
      final pendingNotifications = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      final now = DateTime.now();
      
      for (final notification in pendingNotifications) {
        // Note: We can't easily get the scheduled time from pending notifications
        // This is a limitation of the flutter_local_notifications plugin
        // For now, we'll rely on the periodic schedule check to handle this
      }
    } catch (e) {
      print('BackgroundTaskManager: Error cancelling expired notifications: $e');
    }
  }

  /// Start periodic check to ensure notifications stay scheduled
  void _startPeriodicScheduleCheck() {
    _scheduleCheckTimer?.cancel();
    _scheduleCheckTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _performScheduleCheck();
    });
  }

  /// Perform periodic schedule check
  Future<void> _performScheduleCheck() async {
    try {
      print('BackgroundTaskManager: Performing periodic schedule check');
      await scheduleAllActiveReminders();
    } catch (e) {
      print('BackgroundTaskManager: Error in periodic schedule check: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled();
      return result ?? false;
    } catch (e) {
      print('BackgroundTaskManager: Error checking notification permissions: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermissions() async {
    try {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return result ?? false;
    } catch (e) {
      print('BackgroundTaskManager: Error requesting notification permissions: $e');
      return false;
    }
  }

  /// Dispose of the background task manager
  void dispose() {
    _scheduleCheckTimer?.cancel();
    _scheduleCheckTimer = null;

    _isInitialized = false;
    print('BackgroundTaskManager: Disposed');
  }
}

/// App lifecycle observer for monitoring app state changes
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final BackgroundTaskManager _taskManager;
  
  _AppLifecycleObserver(this._taskManager);
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _taskManager.handleAppStateChange(state);
  }
}