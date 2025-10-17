import 'dart:convert';

/// Data structure for notification payloads containing reminder information
class NotificationPayload {
  final int reminderId;
  final String title;
  final String category;
  final String action;
  final DateTime? scheduledTime;
  final Map<String, dynamic>? additionalData;

  const NotificationPayload({
    required this.reminderId,
    required this.title,
    required this.category,
    required this.action,
    this.scheduledTime,
    this.additionalData,
  });

  /// Convert payload to JSON string for notification
  String toJson() {
    try {
      final Map<String, dynamic> data = {
        'id': reminderId,
        'title': title,
        'category': category,
        'action': action,
        'version': 1, // For future compatibility
      };

      if (scheduledTime != null) {
        data['scheduledTime'] = scheduledTime!.toIso8601String();
      }

      if (additionalData != null && additionalData!.isNotEmpty) {
        data['additionalData'] = additionalData;
      }

      return jsonEncode(data);
    } catch (e) {
      throw NotificationPayloadException('Failed to serialize payload: $e');
    }
  }

  /// Create payload from JSON string
  static NotificationPayload fromJson(String jsonString) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);
      return NotificationPayload.fromMap(data);
    } catch (e) {
      throw NotificationPayloadException('Failed to parse JSON payload: $e');
    }
  }

  /// Create payload from Map
  static NotificationPayload fromMap(Map<String, dynamic> data) {
    try {
      // Validate required fields
      final reminderId = data['id'];
      final title = data['title'];
      final category = data['category'];
      final action = data['action'];

      if (reminderId == null || reminderId is! int) {
        throw NotificationPayloadException('Invalid or missing reminder ID');
      }

      if (title == null || title is! String || title.isEmpty) {
        throw NotificationPayloadException('Invalid or missing title');
      }

      if (category == null || category is! String || category.isEmpty) {
        throw NotificationPayloadException('Invalid or missing category');
      }

      if (action == null || action is! String || action.isEmpty) {
        throw NotificationPayloadException('Invalid or missing action');
      }

      // Validate action type
      if (!NotificationAction.isValid(action)) {
        throw NotificationPayloadException('Invalid action type: $action');
      }

      // Parse optional scheduled time
      DateTime? scheduledTime;
      final scheduledTimeStr = data['scheduledTime'] as String?;
      if (scheduledTimeStr != null) {
        try {
          scheduledTime = DateTime.parse(scheduledTimeStr);
        } catch (e) {
          throw NotificationPayloadException('Invalid scheduled time format: $scheduledTimeStr');
        }
      }

      // Extract additional data
      final additionalData = data['additionalData'] as Map<String, dynamic>?;

      return NotificationPayload(
        reminderId: reminderId,
        title: title,
        category: category,
        action: action,
        scheduledTime: scheduledTime,
        additionalData: additionalData,
      );
    } catch (e) {
      if (e is NotificationPayloadException) {
        rethrow;
      }
      throw NotificationPayloadException('Failed to create payload from map: $e');
    }
  }

  /// Create payload for legacy format support (backward compatibility)
  static NotificationPayload? fromLegacyFormat(String payload) {
    try {
      // Legacy format: "id|title|category"
      final parts = payload.split('|');
      if (parts.length >= 3) {
        final reminderId = int.tryParse(parts[0]);
        if (reminderId != null && parts[1].isNotEmpty && parts[2].isNotEmpty) {
          return NotificationPayload(
            reminderId: reminderId,
            title: parts[1],
            category: parts[2],
            action: NotificationAction.trigger, // Default action for legacy
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validate payload data integrity
  bool isValid() {
    return reminderId > 0 &&
           title.isNotEmpty &&
           category.isNotEmpty &&
           NotificationAction.isValid(action);
  }

  @override
  String toString() {
    return 'NotificationPayload(id: $reminderId, title: $title, category: $category, action: $action)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationPayload &&
           other.reminderId == reminderId &&
           other.title == title &&
           other.category == category &&
           other.action == action &&
           other.scheduledTime == scheduledTime;
  }

  @override
  int get hashCode {
    return Object.hash(reminderId, title, category, action, scheduledTime);
  }
}

/// Supported notification actions
class NotificationAction {
  static const String trigger = 'trigger';
  static const String snooze = 'snooze';
  static const String complete = 'complete';
  static const String dismiss = 'dismiss';

  static const List<String> _validActions = [trigger, snooze, complete, dismiss];

  /// Check if action is valid
  static bool isValid(String action) {
    return _validActions.contains(action);
  }

  /// Get all valid actions
  static List<String> get validActions => List.unmodifiable(_validActions);
}

/// Exception for notification payload errors
class NotificationPayloadException implements Exception {
  final String message;
  
  const NotificationPayloadException(this.message);
  
  @override
  String toString() => 'NotificationPayloadException: $message';
}