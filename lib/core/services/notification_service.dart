import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'reminder_storage_service.dart';
import 'audio_player_service.dart';
import 'deep_link_handler.dart';
import 'error_handling_service.dart';
import '../models/notification_payload.dart';
import '../models/delay_option.dart';
import '../../presentation/common/widgets/completion_delay_dialog.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  Timer? _reminderCheckTimer;
  bool _isInitialized = false;
  BuildContext? _context;
  
  // Flutter Local Notifications plugin instance
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Track if native notifications are enabled
  bool _nativeNotificationsEnabled = false;

  // Initialize the notification service
  Future<void> initialize(BuildContext context) async {
    _context = context;
    if (!_isInitialized) {
      await _initializeNativeNotifications();
      // Initialize deep link handler
      DeepLinkHandler.instance.initialize(context);
      _isInitialized = true;
      _startReminderChecking();
    }
  }

  // Initialize native notifications
  Future<void> _initializeNativeNotifications() async {
    await ErrorHandlingService.instance.retryOperation(
      'initialize_native_notifications',
      () async {
        try {
          // Initialize timezone data
          tz.initializeTimeZones();

          // Android initialization settings
          const AndroidInitializationSettings initializationSettingsAndroid =
              AndroidInitializationSettings('@mipmap/ic_launcher');

          // iOS initialization settings
          const DarwinInitializationSettings initializationSettingsIOS =
              DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

          // Combined initialization settings
          const InitializationSettings initializationSettings =
              InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

          // Initialize the plugin
          await _flutterLocalNotificationsPlugin.initialize(
            initializationSettings,
            onDidReceiveNotificationResponse: _onNotificationTapped,
          );

          // Create notification channel with proper settings for fullscreen notifications
          await _createNotificationChannel();

          // Request permissions with error handling
          final permissionsGranted = await requestPermissions();
          if (!permissionsGranted) {
            await ErrorHandlingService.instance.handlePermissionDenied(
              PermissionType.notifications,
              _context,
            );
          }

          print('DEBUG: Native notifications initialized successfully');
          print('DEBUG: ✓ Notification channel created with MAX importance');
          print('DEBUG: ✓ Full screen intent enabled');
          print('DEBUG: ✓ Permissions requested: $permissionsGranted');
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'NOTIFICATION_INIT_ERROR',
            'Failed to initialize native notifications: $e',
            severity: ErrorSeverity.error,
            stackTrace: StackTrace.current,
          );

          _nativeNotificationsEnabled = false;

          // Enable fallback mode if initialization fails repeatedly
          if (!ErrorHandlingService.instance.isInFallbackMode) {
            await ErrorHandlingService.instance.setFallbackMode(
              true,
              reason: 'Native notification initialization failed'
            );
          }

          rethrow;
        }
      },
      maxAttempts: 2,
      delay: Duration(seconds: 1),
    );
  }

  // Create notification channel with proper settings
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      try {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'reminder_channel',
          'Reminders',
          description: 'Notifications for scheduled reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
        );

        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        print('DEBUG: Notification channel created successfully');
      } catch (e) {
        print('ERROR: Failed to create notification channel: $e');
        await ErrorHandlingService.instance.logError(
          'CHANNEL_CREATION_ERROR',
          'Failed to create notification channel: $e',
          severity: ErrorSeverity.warning,
          stackTrace: StackTrace.current,
        );
      }
    }
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (payload != null) {
      // Delegate to deep link handler for proper payload validation and navigation
      DeepLinkHandler.instance.handleNotificationTap(payload);
    }
  }

  // Start checking for reminders every minute
  void _startReminderChecking() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkAndTriggerReminders();
    });
    
    // Also check immediately
    _checkAndTriggerReminders();
  }

  // Check for reminders that should trigger now
  Future<void> _checkAndTriggerReminders() async {
    try {
      print('DEBUG: Checking for triggered reminders at ${DateTime.now()}');
      final triggeredReminders = await ReminderStorageService.instance.getTriggeredReminders();
      print('DEBUG: Found ${triggeredReminders.length} triggered reminders');
      
      for (final reminder in triggeredReminders) {
        print('DEBUG: Triggering reminder: ${reminder['title']}');
        await _triggerReminder(reminder);
      }
    } catch (e) {
      print('Error checking reminders: $e');
    }
  }

  // Test method to manually trigger a reminder
  Future<void> testTriggerReminder() async {
    try {
      final allReminders = await ReminderStorageService.instance.getReminders();
      final activeReminders = allReminders.where((r) => r['status'] == 'active').toList();
      
      if (activeReminders.isNotEmpty) {
        print('DEBUG: Manually triggering first active reminder');
        await _triggerReminder(activeReminders.first);
      } else {
        print('DEBUG: No active reminders to trigger');
      }
    } catch (e) {
      print('Error in test trigger: $e');
    }
  }

  // Trigger a specific reminder
  Future<void> _triggerReminder(Map<String, dynamic> reminder) async {
    try {
      final reminderId = reminder['id'] as int;
      
      // Check if app is in foreground
      final isAppInForeground = _context != null && _context!.mounted;
      
      if (isAppInForeground) {
        // App is in foreground - show in-app dialog
        print('DEBUG: App in foreground, showing in-app dialog for reminder $reminderId');
        
        // Play audio if available
        final selectedAudio = reminder['selectedAudio'] as Map<String, dynamic>?;
        if (selectedAudio != null) {
          await _playReminderAudio(selectedAudio);
        } else {
          // Play default system sound
          await SystemSound.play(SystemSoundType.alert);
        }

        // Show notification dialog
        _showReminderDialog(reminder);
        
        // Cancel any scheduled native notification since we're showing in-app dialog
        await cancelNotification(reminderId);
      } else {
        // App is in background - native notification should handle this
        print('DEBUG: App in background, native notification should be displayed for reminder $reminderId');
        
        // If this method is called from notification tap, show the dialog
        // This happens when user taps the native notification
        if (_context != null && _context!.mounted) {
          _showReminderDialog(reminder);
        }
      }

      // Update reminder completion count and next occurrence
      await ReminderStorageService.instance.markReminderCompleted(
        reminder['id'] as int
      );

    } catch (e) {
      print('Error triggering reminder: $e');
    }
  }

  // Play reminder audio
  Future<void> _playReminderAudio(Map<String, dynamic> selectedAudio) async {
    try {
      final audioId = selectedAudio['id'] as String;
      final audioPath = selectedAudio['path'] as String?;
      
      if (audioPath != null) {
        // Use forced playback for reminder notifications to bypass silent mode
        await AudioPlayerService.instance.playAudioForced(audioId, audioPath, bypassSilentMode: true);
      }
    } catch (e) {
      print('Error playing reminder audio: $e');
      // Fallback to system sound
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  // Show reminder notification dialog
  void _showReminderDialog(Map<String, dynamic> reminder) {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => ReminderNotificationDialog(
        reminder: reminder,
        onCompleted: () => _handleReminderCompleted(reminder),
        onCompleteLater: () => _handleReminderCompleteLater(reminder),
        onSkip: () => _handleReminderSkip(reminder),
      ),
    );
  }

  // Handle reminder completion
  void _handleReminderCompleted(Map<String, dynamic> reminder) async {
    // Stop any playing audio
    AudioPlayerService.instance.stopAudio();
    
    // Manually complete the reminder (moves to completed section)
    try {
      await ReminderStorageService.instance.completeReminderManually(
        reminder['id'] as int
      );
      print('DEBUG: Reminder manually completed: ${reminder['title']}');
    } catch (e) {
      print('Error completing reminder: $e');
    }
    
    // Close dialog and navigate to completion feedback
    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pop();
      Navigator.pushNamed(
        _context!,
        '/completion-feedback',
        arguments: reminder,
      );
    }
  }



  // Handle reminder skip
  void _handleReminderSkip(Map<String, dynamic> reminder) {
    // Stop any playing audio
    AudioPlayerService.instance.stopAudio();
    
    // Just close the dialog without marking as completed
    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pop();
    }
  }

  // Request notification permissions
  Future<bool> requestPermissions() async {
    return await ErrorHandlingService.instance.retryOperation(
      'request_notification_permissions',
      () async {
        try {
          bool? result;
          
          // Request permissions based on platform
          if (Platform.isAndroid) {
            result = await _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
                ?.requestNotificationsPermission();
          } else if (Platform.isIOS) {
            result = await _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(
                  alert: true,
                  badge: true,
                  sound: true,
                );
          }
          
          _nativeNotificationsEnabled = result ?? false;
          
          if (!_nativeNotificationsEnabled) {
            await ErrorHandlingService.instance.handlePermissionDenied(
              PermissionType.notifications,
              _context,
            );
          } else {
            await ErrorHandlingService.instance.logError(
              'PERMISSION_GRANTED',
              'Notification permissions granted successfully',
              severity: ErrorSeverity.info,
            );
          }
          
          print('DEBUG: Notification permissions granted: $_nativeNotificationsEnabled');
          return _nativeNotificationsEnabled;
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'PERMISSION_REQUEST_ERROR',
            'Error requesting notification permissions: $e',
            severity: ErrorSeverity.error,
            stackTrace: StackTrace.current,
          );
          
          _nativeNotificationsEnabled = false;
          
          // Handle permission error
          await ErrorHandlingService.instance.handlePermissionDenied(
            PermissionType.notifications,
            _context,
          );
          
          return false;
        }
      },
      maxAttempts: 1, // Don't retry permission requests
    ) ?? false;
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await ErrorHandlingService.instance.retryOperation(
      'check_notification_permissions',
      () async {
        try {
          // Check platform-specific permission status
          if (Platform.isAndroid) {
            final androidImplementation = _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
            final result = await androidImplementation?.areNotificationsEnabled();
            _nativeNotificationsEnabled = result ?? false;
          } else if (Platform.isIOS) {
            final iosImplementation = _flutterLocalNotificationsPlugin
                .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
            final result = await iosImplementation?.checkPermissions();
            _nativeNotificationsEnabled = result?.isEnabled ?? false;
          }
          
          // Log permission status changes
          if (!_nativeNotificationsEnabled && !ErrorHandlingService.instance.isInFallbackMode) {
            await ErrorHandlingService.instance.logError(
              'PERMISSION_STATUS_CHANGED',
              'Notification permissions are no longer enabled',
              severity: ErrorSeverity.warning,
            );
          }
          
          return _nativeNotificationsEnabled;
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'PERMISSION_CHECK_ERROR',
            'Error checking notification permissions: $e',
            severity: ErrorSeverity.warning,
            stackTrace: StackTrace.current,
          );
          return false;
        }
      },
      maxAttempts: 2,
    ) ?? false;
  }

  // Schedule a native notification
  Future<void> scheduleNotification(Map<String, dynamic> reminder) async {
    // Check if we're in fallback mode
    if (ErrorHandlingService.instance.isInFallbackMode) {
      await ErrorHandlingService.instance.logError(
        'NOTIFICATION_SKIPPED_FALLBACK',
        'Skipping native notification scheduling due to fallback mode',
        severity: ErrorSeverity.info,
        metadata: {'reminderId': reminder['id']},
      );
      return;
    }

    if (!_nativeNotificationsEnabled) {
      await ErrorHandlingService.instance.logError(
        'NOTIFICATION_DISABLED',
        'Native notifications not enabled, skipping scheduling',
        severity: ErrorSeverity.warning,
        metadata: {'reminderId': reminder['id']},
      );
      return;
    }

    await ErrorHandlingService.instance.retryOperation(
      'schedule_notification_${reminder['id']}',
      () async {
        try {
          final reminderId = reminder['id'] as int;
          final title = reminder['title'] as String;
          final category = reminder['category'] as String;
          
          // Create structured notification payload
          final notificationPayload = NotificationPayload(
            reminderId: reminderId,
            title: title,
            category: category,
            action: NotificationAction.trigger,
            scheduledTime: reminder['nextOccurrenceDateTime'] != null 
                ? DateTime.parse(reminder['nextOccurrenceDateTime'] as String)
                : null,
            additionalData: {
              'reminderType': reminder['frequency']?['type'] ?? 'once',
              'createdAt': DateTime.now().toIso8601String(),
            },
          );
          
          final payload = notificationPayload.toJson();

          // Android notification details with fullscreen intent
          const AndroidNotificationDetails androidPlatformChannelSpecifics =
              AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Notifications for scheduled reminders',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
            channelShowBadge: true,
            autoCancel: false,
            ongoing: true,
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

          // Calculate when to show the notification
          final nextOccurrenceStr = reminder['nextOccurrenceDateTime'] as String?;
          if (nextOccurrenceStr != null) {
            final scheduledDate = DateTime.parse(nextOccurrenceStr);
            
            // Only schedule if the date is in the future
            if (scheduledDate.isAfter(DateTime.now())) {
              // Convert to timezone-aware date
              final scheduledTZDate = tz.TZDateTime.from(scheduledDate, tz.local);
              
              // Schedule the notification
              await _flutterLocalNotificationsPlugin.zonedSchedule(
                reminderId,
                'Reminder: $title',
                'Time for your $category reminder',
                scheduledTZDate,
                platformChannelSpecifics,
                payload: payload,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
              );

              await ErrorHandlingService.instance.logError(
                'NOTIFICATION_SCHEDULED',
                'Successfully scheduled notification for reminder $reminderId',
                severity: ErrorSeverity.info,
                metadata: {
                  'reminderId': reminderId,
                  'scheduledTime': scheduledTZDate.toIso8601String(),
                },
              );

              print('DEBUG: ✓ Scheduled FULLSCREEN notification for reminder $reminderId');
              print('DEBUG:   - Scheduled time: $scheduledTZDate');
              print('DEBUG:   - Importance: MAX');
              print('DEBUG:   - Priority: MAX');
              print('DEBUG:   - Full screen intent: ENABLED');
              print('DEBUG:   - Category: ALARM');
            } else {
              await ErrorHandlingService.instance.logError(
                'NOTIFICATION_PAST_DATE',
                'Skipping notification scheduling for past date',
                severity: ErrorSeverity.warning,
                metadata: {
                  'reminderId': reminderId,
                  'scheduledDate': scheduledDate.toIso8601String(),
                },
              );
              print('DEBUG: Skipping notification scheduling for past date: $scheduledDate');
            }
          }
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'NOTIFICATION_SCHEDULE_ERROR',
            'Error scheduling native notification: $e',
            severity: ErrorSeverity.error,
            metadata: {'reminderId': reminder['id']},
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      },
      maxAttempts: 3,
      delay: Duration(milliseconds: 500),
    );
  }

  // Cancel a scheduled notification
  Future<void> cancelNotification(int reminderId) async {
    await ErrorHandlingService.instance.retryOperation(
      'cancel_notification_$reminderId',
      () async {
        try {
          await _flutterLocalNotificationsPlugin.cancel(reminderId);
          
          await ErrorHandlingService.instance.logError(
            'NOTIFICATION_CANCELLED',
            'Successfully cancelled notification for reminder $reminderId',
            severity: ErrorSeverity.info,
            metadata: {'reminderId': reminderId},
          );
          
          print('DEBUG: Cancelled native notification for reminder $reminderId');
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'NOTIFICATION_CANCEL_ERROR',
            'Error cancelling notification: $e',
            severity: ErrorSeverity.warning,
            metadata: {'reminderId': reminderId},
            stackTrace: StackTrace.current,
          );
          rethrow;
        }
      },
      maxAttempts: 2,
    );
  }

  // Handle notification tap from background notifications
  void handleNotificationTap(String payload) {
    ErrorHandlingService.instance.retryOperation(
      'handle_notification_tap',
      () async {
        try {
          print('DEBUG: Handling notification tap with payload: $payload');
          
          // Validate and parse payload using structured approach
          NotificationPayload? notificationPayload;
          
          try {
            notificationPayload = NotificationPayload.fromJson(payload);
            print('DEBUG: Successfully parsed structured payload: $notificationPayload');
          } catch (e) {
            print('DEBUG: Failed to parse structured payload, trying legacy format: $e');
            
            // Try legacy format for backward compatibility
            notificationPayload = NotificationPayload.fromLegacyFormat(payload);
            if (notificationPayload != null) {
              print('DEBUG: Successfully parsed legacy payload: $notificationPayload');
            }
          }

          if (notificationPayload == null) {
            throw Exception('Unable to parse notification payload: $payload');
          }

          // Validate payload
          if (!notificationPayload.isValid()) {
            throw Exception('Invalid notification payload data: $notificationPayload');
          }

          // Get the reminder and trigger it
          final reminder = await ReminderStorageService.instance.getReminderById(notificationPayload.reminderId);
          if (reminder != null) {
            await _triggerReminder(reminder);
            
            await ErrorHandlingService.instance.logError(
              'NOTIFICATION_TAP_SUCCESS',
              'Successfully handled notification tap for reminder ${notificationPayload.reminderId}',
              severity: ErrorSeverity.info,
              metadata: {
                'reminderId': notificationPayload.reminderId,
                'action': notificationPayload.action.toString(),
              },
            );
          } else {
            throw Exception('Reminder not found: ${notificationPayload.reminderId}');
          }
          
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'NOTIFICATION_TAP_ERROR',
            'Failed to handle notification tap: $e',
            severity: ErrorSeverity.error,
            metadata: {'payload': payload},
            stackTrace: StackTrace.current,
          );
          
          // Show error to user if context is available
          if (_context != null && _context!.mounted) {
            ScaffoldMessenger.of(_context!).showSnackBar(
              SnackBar(
                content: Text('Failed to open reminder from notification'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          
          rethrow;
        }
      },
      maxAttempts: 2,
    );
  }

  // Stop the notification service
  void dispose() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = null;
    _isInitialized = false;
    _context = null;
    _nativeNotificationsEnabled = false;
  }

  // Show completion delay dialog and return selected delay option
  Future<DelayOption?> showCompletionDelayDialog(String reminderTitle) async {
    if (_context == null || !_context!.mounted) return null;
    
    return await showModalBottomSheet<DelayOption>(
      context: _context!,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return CompletionDelayDialog(
          reminderTitle: reminderTitle,
          onDelaySelected: (delay) {
            Navigator.of(context).pop(delay);
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // Schedule delayed completion with custom delay
  Future<void> scheduleDelayedCompletion(int reminderId, DelayOption delayOption) async {
    await ErrorHandlingService.instance.retryOperation(
      'schedule_delayed_completion_$reminderId',
      () async {
        try {
          // Validate that the delay is in the future
          final scheduledTime = DateTime.now().add(delayOption.duration);
          if (!_validateScheduleTime(scheduledTime)) {
            throw Exception('Invalid schedule time: must be at least 1 minute in the future');
          }

          // Additional validation for reasonable delay limits
          if (delayOption.duration.inDays > 7) {
            throw Exception('Delay cannot exceed 7 days');
          }

          // Get the reminder to ensure it exists
          final reminder = await ReminderStorageService.instance.getReminderById(reminderId);
          if (reminder == null) {
            throw Exception('Reminder not found: $reminderId');
          }

          // Use the storage service to handle delayed completion with background scheduling
          await ReminderStorageService.instance.snoozeReminder(
            reminderId, 
            delayOption.duration.inMinutes,
          );
          
          // Schedule a native notification for the delayed completion if enabled
          if (_nativeNotificationsEnabled && !ErrorHandlingService.instance.isInFallbackMode) {
            await _scheduleDelayedNotification(reminder, scheduledTime);
          }
          
          await ErrorHandlingService.instance.logError(
            'DELAYED_COMPLETION_SCHEDULED',
            'Successfully scheduled delayed completion for reminder $reminderId',
            severity: ErrorSeverity.info,
            metadata: {
              'reminderId': reminderId,
              'delayDuration': delayOption.duration.toString(),
              'scheduledTime': scheduledTime.toIso8601String(),
              'delayLabel': delayOption.displayText,
            },
          );
          
          print('NotificationService: Scheduled delayed completion for reminder $reminderId with delay ${delayOption.displayText}');
          
        } catch (e) {
          await ErrorHandlingService.instance.logError(
            'DELAYED_COMPLETION_ERROR',
            'Error scheduling delayed completion: $e',
            severity: ErrorSeverity.error,
            metadata: {
              'reminderId': reminderId,
              'delayDuration': delayOption.duration.toString(),
            },
            stackTrace: StackTrace.current,
          );
          
          print('NotificationService: Error scheduling delayed completion: $e');
          
          // Fallback to simple timer if background scheduling fails
          Timer(delayOption.duration, () {
            _checkAndTriggerReminders();
          });
          
          rethrow;
        }
      },
      maxAttempts: 2,
      delay: Duration(milliseconds: 500),
    );
  }

  // Get predefined delay options
  List<DelayOption> getDelayPresets() {
    return DelayOption.presets;
  }

  // Validate schedule time (must be at least 1 minute in the future)
  bool _validateScheduleTime(DateTime scheduledTime) {
    final now = DateTime.now();
    final difference = scheduledTime.difference(now);
    
    // Must be at least 1 minute in the future
    if (difference.inMinutes < 1) {
      return false;
    }
    
    // Must not be more than 7 days in the future for delayed completions
    if (difference.inDays > 7) {
      return false;
    }
    
    return true;
  }

  // Validate delay option for scheduling
  bool validateDelayOption(DelayOption delayOption) {
    // Check if duration is valid
    if (delayOption.duration.inSeconds <= 0) {
      return false;
    }
    
    // Check if the scheduled time would be valid
    final scheduledTime = DateTime.now().add(delayOption.duration);
    return _validateScheduleTime(scheduledTime);
  }

  // Schedule a native notification for delayed completion
  Future<void> _scheduleDelayedNotification(Map<String, dynamic> reminder, DateTime scheduledTime) async {
    try {
      final reminderId = reminder['id'] as int;
      final title = reminder['title'] as String;
      final category = reminder['category'] as String;
      
      // Create notification payload for delayed completion
      final notificationPayload = NotificationPayload(
        reminderId: reminderId,
        title: title,
        category: category,
        action: NotificationAction.trigger,
        scheduledTime: scheduledTime,
        additionalData: {
          'reminderType': 'delayed_completion',
          'originalSchedule': reminder['nextOccurrenceDateTime'],
          'delayedAt': DateTime.now().toIso8601String(),
        },
      );
      
      final payload = notificationPayload.toJson();

      // Android notification details with fullscreen intent
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Notifications for scheduled reminders',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        channelShowBadge: true,
        autoCancel: false,
        ongoing: true,
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

      // Convert to timezone-aware date
      final scheduledTZDate = tz.TZDateTime.from(scheduledTime, tz.local);
      
      // Schedule the delayed notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        reminderId,
        'Reminder: $title',
        'Time for your delayed $category reminder',
        scheduledTZDate,
        platformChannelSpecifics,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      await ErrorHandlingService.instance.logError(
        'DELAYED_NOTIFICATION_SCHEDULED',
        'Successfully scheduled delayed notification for reminder $reminderId',
        severity: ErrorSeverity.info,
        metadata: {
          'reminderId': reminderId,
          'scheduledTime': scheduledTZDate.toIso8601String(),
        },
      );
      
      print('DEBUG: Scheduled delayed notification for reminder $reminderId at $scheduledTZDate');
      
    } catch (e) {
      await ErrorHandlingService.instance.logError(
        'DELAYED_NOTIFICATION_ERROR',
        'Error scheduling delayed notification: $e',
        severity: ErrorSeverity.warning,
        metadata: {'reminderId': reminder['id']},
        stackTrace: StackTrace.current,
      );
      
      print('DEBUG: Error scheduling delayed notification: $e');
      // Don't rethrow as this is a fallback feature
    }
  }

  // Handle reminder completion with delay options
  void _handleReminderCompleteLater(Map<String, dynamic> reminder) async {
    // Stop any playing audio
    AudioPlayerService.instance.stopAudio();
    
    try {
      final reminderTitle = reminder['title'] as String;
      final reminderId = reminder['id'] as int;
      
      // Validate reminder exists
      final currentReminder = await ReminderStorageService.instance.getReminderById(reminderId);
      if (currentReminder == null) {
        throw Exception('Reminder not found');
      }
      
      // Show delay options dialog
      final selectedDelay = await showCompletionDelayDialog(reminderTitle);
      
      if (selectedDelay != null) {
        // Validate the selected delay
        if (!validateDelayOption(selectedDelay)) {
          throw Exception('Invalid delay option selected');
        }
        
        // Schedule the delayed completion
        await scheduleDelayedCompletion(reminderId, selectedDelay);
        
        // Show confirmation to user
        if (_context != null && _context!.mounted) {
          final scheduledTime = DateTime.now().add(selectedDelay.duration);
          ScaffoldMessenger.of(_context!).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reminder rescheduled for ${_formatScheduledTime(scheduledTime)}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

            ),
          );
        }
        
        await ErrorHandlingService.instance.logError(
          'REMINDER_DELAYED_SUCCESS',
          'Successfully delayed reminder completion',
          severity: ErrorSeverity.info,
          metadata: {
            'reminderId': reminderId,
            'delayDuration': selectedDelay.duration.toString(),
            'delayLabel': selectedDelay.displayText,
          },
        );
      } else {
        // User cancelled delay selection
        await ErrorHandlingService.instance.logError(
          'REMINDER_DELAY_CANCELLED',
          'User cancelled delay selection',
          severity: ErrorSeverity.info,
          metadata: {'reminderId': reminderId},
        );
      }
      
    } catch (e) {
      await ErrorHandlingService.instance.logError(
        'REMINDER_DELAY_ERROR',
        'Error handling reminder complete later: $e',
        severity: ErrorSeverity.error,
        metadata: {'reminderId': reminder['id']},
        stackTrace: StackTrace.current,
      );
      
      print('Error handling reminder complete later: $e');
      
      // Show error to user
      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to reschedule reminder. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
    
    // Close the reminder dialog
    if (_context != null && _context!.mounted) {
      Navigator.of(_context!).pop();
    }
  }

  // Format scheduled time for user display
  String _formatScheduledTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = dateTime.day == now.day && 
                   dateTime.month == now.month && 
                   dateTime.year == now.year;
    final isTomorrow = dateTime.day == now.day + 1 && 
                      dateTime.month == now.month && 
                      dateTime.year == now.year;

    final timeStr = TimeOfDay.fromDateTime(dateTime).format(_context!);
    
    if (isToday) {
      return 'today at $timeStr';
    } else if (isTomorrow) {
      return 'tomorrow at $timeStr';
    } else {
      return '${dateTime.month}/${dateTime.day} at $timeStr';
    }
  }

  // Get native notifications enabled status
  bool get nativeNotificationsEnabled => _nativeNotificationsEnabled;


}

// Custom dialog widget for reminder notifications
class ReminderNotificationDialog extends StatefulWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback onCompleted;
  final VoidCallback onCompleteLater;
  final VoidCallback onSkip;

  const ReminderNotificationDialog({
    super.key,
    required this.reminder,
    required this.onCompleted,
    required this.onCompleteLater,
    required this.onSkip,
  });

  @override
  State<ReminderNotificationDialog> createState() => _ReminderNotificationDialogState();
}

class _ReminderNotificationDialogState extends State<ReminderNotificationDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _handleDoneWithFeedback() {
    Navigator.pop(context);
    widget.onCompleted();
    // Navigate to completion feedback immediately
    Navigator.pushNamed(
      context,
      '/completion-feedback',
      arguments: widget.reminder,
    );
  }

  void _handleDoneLater() {
    Navigator.pop(context);
    widget.onCompleted();
    // Show confirmation that they can fill feedback later
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reminder completed! You can add feedback anytime from your progress page.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showDoneOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              'Great job completing your reminder!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Would you like to share how it went?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            
            // Fill feedback now button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleDoneWithFeedback,
                icon: Icon(Icons.edit_note, size: 20),
                label: Text('Fill Out Questions Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            SizedBox(height: 12),
            
            // Complete later button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleDoneLater,
                icon: Icon(Icons.schedule, size: 20),
                label: Text('Complete Later'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            
            Text(
              'You can always add feedback later from your progress page',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with animated icon
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Animated icon
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.2 + (_pulseController.value * 0.5)
                                ),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.2 + (_pulseController.value * 0.3)
                                ),
                                blurRadius: 25 + (_pulseController.value * 15),
                                spreadRadius: 3 + (_pulseController.value * 7),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 45,
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Title with animation
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: Curves.easeOutCubic,
                      )),
                      child: FadeTransition(
                        opacity: _slideController,
                        child: Text(
                          '🔔 Reminder Time!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Reminder title
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: Interval(0.2, 1.0, curve: Curves.easeOutCubic),
                      )),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _slideController,
                          curve: Interval(0.2, 1.0),
                        ),
                        child: Text(
                          widget.reminder['title'] as String,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Category badge
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _slideController,
                        curve: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                      )),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _slideController,
                          curve: Interval(0.4, 1.0),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '📂 ${widget.reminder['category'] as String}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Description if available
                    if (widget.reminder['description'] != null && 
                        (widget.reminder['description'] as String).isNotEmpty) ...[
                      SizedBox(height: 16),
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve: Interval(0.6, 1.0, curve: Curves.easeOutCubic),
                        )),
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _slideController,
                            curve: Interval(0.6, 1.0),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.reminder['description'] as String,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action buttons
              Container(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, 0.5),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _slideController,
                    curve: Interval(0.8, 1.0, curve: Curves.easeOutCubic),
                  )),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _slideController,
                      curve: Interval(0.8, 1.0),
                    ),
                    child: Column(
                      children: [
                        // Done button (primary action)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showDoneOptions,
                            icon: Icon(Icons.check_circle_rounded, size: 22),
                            label: Text(
                              'Mark as Done',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                              shadowColor: Colors.green[600]?.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Secondary actions row
                        Row(
                          children: [
                            // Skip button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onSkip();
                                },
                                icon: Icon(Icons.close_rounded, size: 20),
                                label: Text(
                                  'Skip',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey[400]!,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            
                            SizedBox(width: 12),
                            
                            // Complete Later button
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  widget.onCompleteLater();
                                },
                                icon: Icon(Icons.schedule, size: 20),
                                label: Text(
                                  'Later',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange[700],
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: Colors.orange[400]!,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}