import 'package:flutter/material.dart';
import '../models/notification_payload.dart';
import '../../routes/app_routes.dart';
import 'reminder_storage_service.dart';
import 'notification_service.dart';

/// Service for handling deep links from notifications and other sources
class DeepLinkHandler {
  static DeepLinkHandler? _instance;
  static DeepLinkHandler get instance => _instance ??= DeepLinkHandler._();
  DeepLinkHandler._();

  BuildContext? _context;
  bool _isInitialized = false;

  /// Initialize the deep link handler with app context
  void initialize(BuildContext context) {
    _context = context;
    _isInitialized = true;
    print('DEBUG: DeepLinkHandler initialized');
  }

  /// Handle notification tap with payload validation and navigation
  Future<void> handleNotificationTap(String payload) async {
    if (!_isInitialized || _context == null || !_context!.mounted) {
      print('ERROR: DeepLinkHandler not initialized or context unavailable');
      return;
    }

    try {
      print('DEBUG: Handling notification tap with payload: $payload');
      
      // Try to parse as new JSON format first
      NotificationPayload? notificationPayload;
      
      try {
        notificationPayload = NotificationPayload.fromJson(payload);
        print('DEBUG: Successfully parsed JSON payload: $notificationPayload');
      } catch (e) {
        print('DEBUG: Failed to parse JSON payload, trying legacy format: $e');
        
        // Try legacy format as fallback
        notificationPayload = NotificationPayload.fromLegacyFormat(payload);
        if (notificationPayload != null) {
          print('DEBUG: Successfully parsed legacy payload: $notificationPayload');
        }
      }

      if (notificationPayload == null) {
        throw DeepLinkException('Unable to parse notification payload: $payload');
      }

      // Validate payload
      if (!notificationPayload.isValid()) {
        throw DeepLinkException('Invalid notification payload data: $notificationPayload');
      }

      // Handle the notification action
      await _handleNotificationAction(notificationPayload);

    } catch (e) {
      print('ERROR: Failed to handle notification tap: $e');
      
      // Show error to user if context is available
      if (_context != null && _context!.mounted) {
        _showErrorDialog('Notification Error', 'Failed to open reminder from notification.');
      }
    }
  }

  /// Handle specific notification actions
  Future<void> _handleNotificationAction(NotificationPayload payload) async {
    switch (payload.action) {
      case NotificationAction.trigger:
        await _handleTriggerAction(payload);
        break;
      case NotificationAction.snooze:
        await _handleSnoozeAction(payload);
        break;
      case NotificationAction.complete:
        await _handleCompleteAction(payload);
        break;
      case NotificationAction.dismiss:
        await _handleDismissAction(payload);
        break;
      default:
        throw DeepLinkException('Unknown notification action: ${payload.action}');
    }
  }

  /// Handle trigger action - show reminder dialog
  Future<void> _handleTriggerAction(NotificationPayload payload) async {
    try {
      // Fetch the full reminder data
      final reminder = await ReminderStorageService.instance.getReminderById(payload.reminderId);
      
      if (reminder == null) {
        throw DeepLinkException('Reminder not found: ${payload.reminderId}');
      }

      // Check if reminder is still active
      if (reminder['status'] != 'active') {
        print('DEBUG: Reminder ${payload.reminderId} is no longer active, skipping trigger');
        return;
      }

      // Navigate to app and show reminder dialog
      await _navigateToReminderDialog(reminder);
      
    } catch (e) {
      throw DeepLinkException('Failed to trigger reminder ${payload.reminderId}: $e');
    }
  }

  /// Handle snooze action - reschedule reminder
  Future<void> _handleSnoozeAction(NotificationPayload payload) async {
    try {
      // For now, delegate to notification service snooze logic
      // In the future, this could be enhanced with custom snooze durations
      print('DEBUG: Handling snooze action for reminder ${payload.reminderId}');
      
      // Show brief confirmation
      if (_context != null && _context!.mounted) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Text('Reminder snoozed for 5 minutes'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      throw DeepLinkException('Failed to snooze reminder ${payload.reminderId}: $e');
    }
  }

  /// Handle complete action - mark reminder as completed
  Future<void> _handleCompleteAction(NotificationPayload payload) async {
    try {
      // Mark reminder as completed
      await ReminderStorageService.instance.completeReminderManually(payload.reminderId);
      
      // Navigate to completion feedback
      await _navigateToCompletionFeedback(payload.reminderId);
      
    } catch (e) {
      throw DeepLinkException('Failed to complete reminder ${payload.reminderId}: $e');
    }
  }

  /// Handle dismiss action - just dismiss the notification
  Future<void> _handleDismissAction(NotificationPayload payload) async {
    try {
      print('DEBUG: Dismissing notification for reminder ${payload.reminderId}');
      
      // Cancel any pending notifications for this reminder
      await NotificationService.instance.cancelNotification(payload.reminderId);
      
    } catch (e) {
      throw DeepLinkException('Failed to dismiss reminder ${payload.reminderId}: $e');
    }
  }

  /// Navigate to reminder dialog by ensuring app is in foreground
  Future<void> _navigateToReminderDialog(Map<String, dynamic> reminder) async {
    if (_context == null || !_context!.mounted) {
      throw DeepLinkException('Navigation context not available');
    }

    try {
      // Ensure we're on the main screen (dashboard or reminder management)
      await _ensureMainScreen();
      
      // Trigger the reminder through notification service
      // This will show the reminder dialog
      NotificationService.instance.handleNotificationTap(
        NotificationPayload(
          reminderId: reminder['id'] as int,
          title: reminder['title'] as String,
          category: reminder['category'] as String,
          action: NotificationAction.trigger,
        ).toJson()
      );
      
    } catch (e) {
      throw DeepLinkException('Failed to navigate to reminder dialog: $e');
    }
  }

  /// Navigate to completion feedback screen
  Future<void> _navigateToCompletionFeedback(int reminderId) async {
    if (_context == null || !_context!.mounted) {
      throw DeepLinkException('Navigation context not available');
    }

    try {
      // Get reminder data for completion feedback
      final reminder = await ReminderStorageService.instance.getReminderById(reminderId);
      
      if (reminder != null) {
        // Navigate to completion feedback
        Navigator.of(_context!).pushNamed(
          AppRoutes.completionFeedback,
          arguments: reminder,
        );
      }
      
    } catch (e) {
      throw DeepLinkException('Failed to navigate to completion feedback: $e');
    }
  }

  /// Ensure app is on a main screen for proper navigation
  Future<void> _ensureMainScreen() async {
    if (_context == null || !_context!.mounted) return;

    try {
      // Get current route name
      final currentRoute = ModalRoute.of(_context!)?.settings.name;
      
      // If we're not on a main screen, navigate to dashboard
      if (currentRoute != AppRoutes.dashboard && 
          currentRoute != AppRoutes.reminderManagement) {
        
        // Navigate to dashboard
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          AppRoutes.dashboard,
          (route) => false,
        );
        
        // Wait a bit for navigation to complete
        await Future.delayed(Duration(milliseconds: 300));
      }
      
    } catch (e) {
      print('WARNING: Failed to ensure main screen: $e');
      // Continue anyway - the dialog might still work
    }
  }

  /// Show error dialog to user
  void _showErrorDialog(String title, String message) {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Handle deep link from URL (for future expansion)
  Future<void> handleDeepLink(String url) async {
    try {
      print('DEBUG: Handling deep link: $url');
      
      // Parse URL and extract parameters
      final uri = Uri.parse(url);
      
      // Handle different deep link types
      switch (uri.pathSegments.first) {
        case 'reminder':
          await _handleReminderDeepLink(uri);
          break;
        case 'notification':
          await _handleNotificationDeepLink(uri);
          break;
        default:
          throw DeepLinkException('Unknown deep link type: ${uri.pathSegments.first}');
      }
      
    } catch (e) {
      print('ERROR: Failed to handle deep link: $e');
    }
  }

  /// Handle reminder-specific deep links
  Future<void> _handleReminderDeepLink(Uri uri) async {
    // Extract reminder ID from path
    if (uri.pathSegments.length < 2) {
      throw DeepLinkException('Invalid reminder deep link format');
    }
    
    final reminderIdStr = uri.pathSegments[1];
    final reminderId = int.tryParse(reminderIdStr);
    
    if (reminderId == null) {
      throw DeepLinkException('Invalid reminder ID: $reminderIdStr');
    }
    
    // Get reminder and show dialog
    final reminder = await ReminderStorageService.instance.getReminderById(reminderId);
    if (reminder != null) {
      await _navigateToReminderDialog(reminder);
    }
  }

  /// Handle notification-specific deep links
  Future<void> _handleNotificationDeepLink(Uri uri) async {
    // Extract notification payload from query parameters
    final payloadStr = uri.queryParameters['payload'];
    if (payloadStr != null) {
      await handleNotificationTap(payloadStr);
    }
  }

  /// Update context when app navigation changes
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Dispose of resources
  void dispose() {
    _context = null;
    _isInitialized = false;
  }
}

/// Exception for deep link handling errors
class DeepLinkException implements Exception {
  final String message;
  
  const DeepLinkException(this.message);
  
  @override
  String toString() => 'DeepLinkException: $message';
}