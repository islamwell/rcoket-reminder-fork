import 'dart:convert';

/// Utility class for data validation across the application
/// Provides common validation methods for backend operations
class DataValidationUtils {
  
  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  static bool isValidPassword(String password) {
    if (password.length < 6) return false;
    
    // Check for at least one letter and one number
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    
    return hasLetter && hasNumber;
  }

  /// Validate user name
  static bool isValidUserName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.length > 100) return false;
    
    // Allow letters, numbers, spaces, and common punctuation
    final nameRegex = RegExp(r'^[a-zA-Z0-9\s\-_.]+$');
    return nameRegex.hasMatch(name.trim());
  }

  /// Validate time format (HH:mm)
  static bool isValidTimeFormat(String time) {
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  /// Validate ISO 8601 date string
  static bool isValidISODate(String dateString) {
    try {
      DateTime.parse(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate UUID format
  static bool isValidUUID(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(uuid);
  }

  /// Validate text length within bounds
  static bool isValidTextLength(String? text, {int minLength = 0, int maxLength = 1000}) {
    if (text == null) return minLength == 0;
    return text.length >= minLength && text.length <= maxLength;
  }

  /// Validate numeric range
  static bool isValidNumericRange(num? value, {num? min, num? max}) {
    if (value == null) return false;
    if (min != null && value < min) return false;
    if (max != null && value > max) return false;
    return true;
  }

  /// Validate color hex code
  static bool isValidHexColor(String color) {
    final hexColorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexColorRegex.hasMatch(color);
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Validate phone number (basic format)
  static bool isValidPhoneNumber(String phone) {
    if (phone.isEmpty) return false;
    
    // Remove common formatting characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    // Check if it's all digits and reasonable length
    final phoneRegex = RegExp(r'^\d{7,15}$');
    return phoneRegex.hasMatch(cleanPhone);
  }

  /// Validate that a map contains required keys
  static bool hasRequiredKeys(Map<String, dynamic> data, List<String> requiredKeys) {
    for (final key in requiredKeys) {
      if (!data.containsKey(key) || data[key] == null) {
        return false;
      }
    }
    return true;
  }

  /// Validate that a value is one of the allowed values
  static bool isValidEnum<T>(T value, List<T> allowedValues) {
    return allowedValues.contains(value);
  }

  /// Sanitize text input by removing potentially harmful characters
  static String sanitizeText(String input) {
    // Remove null bytes and control characters except newlines and tabs
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// Validate JSON structure
  static bool isValidJson(String jsonString) {
    try {
      // Try to decode the JSON
      final decoded = jsonDecode(jsonString);
      return decoded != null;
    } catch (e) {
      return false;
    }
  }

  /// Validate file extension
  static bool isValidFileExtension(String filename, List<String> allowedExtensions) {
    if (filename.isEmpty) return false;
    
    final extension = filename.split('.').last.toLowerCase();
    return allowedExtensions.map((e) => e.toLowerCase()).contains(extension);
  }

  /// Validate that a date is within a reasonable range
  static bool isValidDateRange(DateTime date, {DateTime? minDate, DateTime? maxDate}) {
    if (minDate != null && date.isBefore(minDate)) return false;
    if (maxDate != null && date.isAfter(maxDate)) return false;
    return true;
  }

  /// Validate reminder frequency data structure
  static bool isValidReminderFrequency(Map<String, dynamic> frequency) {
    try {
      print('DataValidationUtils: Validating frequency: $frequency');
      final type = frequency['type'] ?? frequency['id'];
      
      if (type == null || type is! String) {
        print('DataValidationUtils: Invalid frequency type: $type');
        return false;
      }

      switch (type) {
        case 'once':
          final date = frequency['date'];
          if (date is! String || !isValidISODate(date)) {
            return false;
          }
          // Check if date is not too far in the past
          try {
            final dateTime = DateTime.parse(date);
            final now = DateTime.now();
            return dateTime.isAfter(now.subtract(Duration(days: 1)));
          } catch (e) {
            return false;
          }
        case 'daily':
        case 'hourly':
        case 'minutely':
          return true;
        case 'weekly':
          final selectedDays = frequency['selectedDays'];
          print('DataValidationUtils: Weekly selectedDays: $selectedDays (type: ${selectedDays.runtimeType})');
          if (selectedDays is! List || selectedDays.isEmpty) {
            print('DataValidationUtils: Weekly validation failed - selectedDays is not a non-empty list');
            return false;
          }
          // Validate that all selected days are valid weekday numbers (1-7)
          for (final day in selectedDays) {
            if (day is! int || day < 1 || day > 7) {
              print('DataValidationUtils: Weekly validation failed - invalid day: $day (type: ${day.runtimeType})');
              return false;
            }
          }
          print('DataValidationUtils: Weekly validation passed');
          return true;
        case 'monthly':
          final dayOfMonth = frequency['dayOfMonth'];
          return dayOfMonth is int && dayOfMonth >= 1 && dayOfMonth <= 31;
        case 'custom':
          final interval = frequency['interval'] ?? frequency['intervalValue'];
          final unit = frequency['unit'] ?? frequency['intervalUnit'];
          if (interval is! int || interval <= 0) {
            return false;
          }
          if (unit is! String) {
            return false;
          }
          final validUnits = ['minutes', 'hours', 'days', 'weeks', 'months'];
          return validUnits.contains(unit);
        default:
          return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Validate user preferences data structure
  static bool isValidUserPreferences(Map<String, dynamic> preferences) {
    try {
      // Check if preferences is a valid map
      if (preferences.isEmpty) {
        return false;
      }

      // Validate required sections exist
      final requiredSections = ['notifications', 'theme', 'reminders', 'audio', 'privacy'];
      for (final section in requiredSections) {
        if (!preferences.containsKey(section) || preferences[section] is! Map<String, dynamic>) {
          return false;
        }
      }

      // Validate notifications section
      final notifications = preferences['notifications'] as Map<String, dynamic>;
      final notificationKeys = ['enabled', 'sound', 'vibration', 'showOnLockScreen'];
      for (final key in notificationKeys) {
        if (!notifications.containsKey(key) || notifications[key] is! bool) {
          return false;
        }
      }

      // Validate theme section
      final theme = preferences['theme'] as Map<String, dynamic>;
      if (!theme.containsKey('darkMode') || theme['darkMode'] is! bool) {
        return false;
      }
      if (!theme.containsKey('accentColor') || theme['accentColor'] is! String) {
        return false;
      }
      if (!isValidHexColor(theme['accentColor'])) {
        return false;
      }

      // Validate reminders section
      final reminders = preferences['reminders'] as Map<String, dynamic>;
      if (!reminders.containsKey('defaultCategory') || reminders['defaultCategory'] is! String) {
        return false;
      }
      if (!reminders.containsKey('defaultTime') || reminders['defaultTime'] is! String) {
        return false;
      }
      if (!isValidTimeFormat(reminders['defaultTime'])) {
        return false;
      }
      if (!reminders.containsKey('snoozeMinutes') || reminders['snoozeMinutes'] is! int) {
        return false;
      }
      if (!isValidNumericRange(reminders['snoozeMinutes'], min: 1, max: 60)) {
        return false;
      }

      // Validate audio section
      final audio = preferences['audio'] as Map<String, dynamic>;
      if (!audio.containsKey('defaultVolume') || audio['defaultVolume'] is! num) {
        return false;
      }
      if (!isValidNumericRange(audio['defaultVolume'], min: 0.0, max: 1.0)) {
        return false;
      }
      if (!audio.containsKey('enableAudioReminders') || audio['enableAudioReminders'] is! bool) {
        return false;
      }

      // Validate privacy section
      final privacy = preferences['privacy'] as Map<String, dynamic>;
      if (!privacy.containsKey('analyticsEnabled') || privacy['analyticsEnabled'] is! bool) {
        return false;
      }
      if (!privacy.containsKey('crashReportingEnabled') || privacy['crashReportingEnabled'] is! bool) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}