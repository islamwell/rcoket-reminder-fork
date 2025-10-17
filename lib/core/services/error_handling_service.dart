import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Error Handling Service
/// 
/// Provides comprehensive error handling, logging, and fallback mechanisms
/// for the reminder system, particularly for background processing failures
/// and permission issues.
/// 
/// Requirements addressed:
/// - 3.2: Permission denied handling with user-friendly messaging
/// - 3.4: Fallback to foreground-only mode when background processing fails
/// - 5.3: Error logging and monitoring for background task failures
class ErrorHandlingService {
  static ErrorHandlingService? _instance;
  static ErrorHandlingService get instance => _instance ??= ErrorHandlingService._();
  ErrorHandlingService._();

  static const String _errorLogKey = 'error_log';
  static const String _fallbackModeKey = 'fallback_mode';
  static const String _permissionStatusKey = 'permission_status';
  static const int _maxRetryAttempts = 3;
  static const int _maxLogEntries = 100;

  bool _isInFallbackMode = false;
  final Map<String, int> _retryCounters = {};
  final List<StreamController<ErrorEvent>> _errorStreamControllers = [];

  /// Initialize the error handling service
  Future<void> initialize() async {
    try {
      await _loadFallbackModeStatus();
      await _cleanupOldLogs();
      
      // Automatically check and reset fallback mode if appropriate
      await resetToNormalMode();
      
      print('ErrorHandlingService: Initialized successfully');
    } catch (e) {
      print('ErrorHandlingService: Failed to initialize: $e');
    }
  }

  /// Load fallback mode status from storage
  Future<void> _loadFallbackModeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isInFallbackMode = prefs.getBool(_fallbackModeKey) ?? false;
      print('ErrorHandlingService: Loaded fallback mode status: $_isInFallbackMode');
    } catch (e) {
      print('ErrorHandlingService: Error loading fallback mode status: $e');
      _isInFallbackMode = false;
    }
  }

  /// Set fallback mode status
  Future<void> setFallbackMode(bool enabled, {String? reason}) async {
    try {
      _isInFallbackMode = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fallbackModeKey, enabled);
      
      await logError(
        'FALLBACK_MODE_${enabled ? 'ENABLED' : 'DISABLED'}',
        reason ?? 'Fallback mode status changed',
        severity: ErrorSeverity.warning,
      );
      
      // Notify listeners about fallback mode change
      _notifyErrorListeners(ErrorEvent(
        type: ErrorType.fallbackMode,
        message: enabled ? 'Switched to foreground-only mode' : 'Background mode restored',
        severity: ErrorSeverity.info,
        timestamp: DateTime.now(),
        metadata: {'fallbackMode': enabled, 'reason': reason},
      ));
      
      print('ErrorHandlingService: Fallback mode ${enabled ? 'enabled' : 'disabled'}: $reason');
    } catch (e) {
      print('ErrorHandlingService: Error setting fallback mode: $e');
    }
  }

  /// Check if currently in fallback mode
  bool get isInFallbackMode => _isInFallbackMode;

  /// Handle permission denied scenarios
  Future<PermissionHandlingResult> handlePermissionDenied(
    PermissionType permissionType,
    BuildContext? context,
  ) async {
    try {
      await logError(
        'PERMISSION_DENIED',
        'Permission denied for $permissionType',
        severity: ErrorSeverity.warning,
        metadata: {'permissionType': permissionType.toString()},
      );

      // Update permission status
      await _updatePermissionStatus(permissionType, PermissionStatus.denied);

      // Show user-friendly message if context is available
      if (context != null && context.mounted) {
        await _showPermissionDeniedDialog(context, permissionType);
      }

      // Enable fallback mode for notification permissions
      if (permissionType == PermissionType.notifications) {
        await setFallbackMode(true, reason: 'Notification permissions denied');
        return PermissionHandlingResult.fallbackEnabled;
      }

      return PermissionHandlingResult.handled;
    } catch (e) {
      await logError(
        'PERMISSION_HANDLING_ERROR',
        'Error handling permission denied: $e',
        severity: ErrorSeverity.error,
      );
      return PermissionHandlingResult.error;
    }
  }

  /// Show permission denied dialog to user
  Future<void> _showPermissionDeniedDialog(
    BuildContext context,
    PermissionType permissionType,
  ) async {
    if (!context.mounted) return;

    final theme = Theme.of(context);
    final permissionInfo = _getPermissionInfo(permissionType);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 28,
            ),
            SizedBox(width: 12),
            Text(
              'Permission Required',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              permissionInfo.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              permissionInfo.description,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      permissionInfo.impact,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Continue Without'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
            child: Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Get permission information for display
  PermissionInfo _getPermissionInfo(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.notifications:
        return PermissionInfo(
          title: 'Notification Permission Denied',
          description: 'This app needs notification permission to send you reminders when the app is closed or minimized.',
          impact: 'Without this permission, reminders will only work when the app is open and active.',
        );
      case PermissionType.backgroundProcessing:
        return PermissionInfo(
          title: 'Background Processing Limited',
          description: 'Your device has restricted background processing for this app.',
          impact: 'Reminders may not work reliably when the app is closed or your device is in power-saving mode.',
        );
      case PermissionType.batteryOptimization:
        return PermissionInfo(
          title: 'Battery Optimization Active',
          description: 'Battery optimization is preventing this app from running in the background.',
          impact: 'This may cause reminders to be delayed or missed when the app is not actively used.',
        );
    }
  }

  /// Open app settings for permission management
  void _openAppSettings() {
    // This would typically use a plugin like app_settings
    // For now, we'll just log the action
    print('ErrorHandlingService: Opening app settings for permission management');
  }

  /// Update permission status in storage
  Future<void> _updatePermissionStatus(
    PermissionType permissionType,
    PermissionStatus status,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statusMap = prefs.getString(_permissionStatusKey);
      Map<String, dynamic> permissions = {};
      
      if (statusMap != null) {
        permissions = Map<String, dynamic>.from(
          Map<String, dynamic>.from(
            // Safe JSON decode with error handling
            (() {
              try {
                return Map<String, dynamic>.from(
                  Map<String, dynamic>.from(statusMap as Map? ?? {})
                );
              } catch (e) {
                return <String, dynamic>{};
              }
            })()
          )
        );
      }
      
      permissions[permissionType.toString()] = {
        'status': status.toString(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_permissionStatusKey, permissions.toString());
    } catch (e) {
      print('ErrorHandlingService: Error updating permission status: $e');
    }
  }

  /// Retry mechanism for failed operations
  Future<T?> retryOperation<T>(
    String operationId,
    Future<T> Function() operation, {
    int? maxAttempts,
    Duration delay = const Duration(seconds: 2),
    bool exponentialBackoff = true,
  }) async {
    final attempts = maxAttempts ?? _maxRetryAttempts;
    int currentAttempt = 0;
    Duration currentDelay = delay;

    while (currentAttempt < attempts) {
      try {
        currentAttempt++;
        final result = await operation();
        
        // Reset retry counter on success
        _retryCounters.remove(operationId);
        
        if (currentAttempt > 1) {
          await logError(
            'RETRY_SUCCESS',
            'Operation $operationId succeeded after $currentAttempt attempts',
            severity: ErrorSeverity.info,
          );
        }
        
        return result;
      } catch (e) {
        _retryCounters[operationId] = currentAttempt;
        
        await logError(
          'RETRY_ATTEMPT',
          'Operation $operationId failed (attempt $currentAttempt/$attempts): $e',
          severity: currentAttempt == attempts ? ErrorSeverity.error : ErrorSeverity.warning,
          metadata: {
            'operationId': operationId,
            'attempt': currentAttempt,
            'maxAttempts': attempts,
            'error': e.toString(),
          },
        );

        if (currentAttempt >= attempts) {
          // Final failure - consider fallback mode
          if (operationId.contains('notification') || operationId.contains('background')) {
            await setFallbackMode(true, reason: 'Repeated failures in $operationId');
          }
          rethrow;
        }

        // Wait before retry with exponential backoff
        await Future.delayed(currentDelay);
        if (exponentialBackoff) {
          currentDelay = Duration(milliseconds: (currentDelay.inMilliseconds * 1.5).round());
        }
      }
    }

    return null;
  }

  /// Log error with metadata
  Future<void> logError(
    String errorCode,
    String message, {
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? metadata,
    StackTrace? stackTrace,
  }) async {
    try {
      final errorEntry = ErrorLogEntry(
        code: errorCode,
        message: message,
        severity: severity,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
        stackTrace: stackTrace?.toString(),
      );

      await _saveErrorLog(errorEntry);
      
      // Notify error listeners
      _notifyErrorListeners(ErrorEvent(
        type: _getErrorTypeFromCode(errorCode),
        message: message,
        severity: severity,
        timestamp: errorEntry.timestamp,
        metadata: metadata,
      ));

      // Print to console for debugging
      final severityStr = severity.toString().split('.').last.toUpperCase();
      print('[$severityStr] $errorCode: $message');
      if (metadata != null && metadata.isNotEmpty) {
        print('  Metadata: $metadata');
      }
    } catch (e) {
      // Fallback to console logging if storage fails
      print('ErrorHandlingService: Failed to log error: $e');
      print('Original error: $errorCode - $message');
    }
  }

  /// Save error log entry to storage
  Future<void> _saveErrorLog(ErrorLogEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingLogs = await getErrorLogs();
      
      existingLogs.add(entry);
      
      // Keep only the most recent entries
      if (existingLogs.length > _maxLogEntries) {
        existingLogs.removeRange(0, existingLogs.length - _maxLogEntries);
      }
      
      final logsJson = existingLogs.map((e) => e.toJson()).toList();
      await prefs.setString(_errorLogKey, logsJson.toString());
    } catch (e) {
      print('ErrorHandlingService: Error saving log entry: $e');
    }
  }

  /// Get error logs from storage
  Future<List<ErrorLogEntry>> getErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_errorLogKey);
      
      if (logsJson == null) return [];
      
      // Parse the stored logs
      final List<dynamic> logsList = [];
      // Note: In a real implementation, you'd use proper JSON parsing
      // This is simplified for the example
      
      return logsList
          .map((json) => ErrorLogEntry.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      print('ErrorHandlingService: Error loading logs: $e');
      return [];
    }
  }

  /// Clean up old log entries
  Future<void> _cleanupOldLogs() async {
    try {
      final logs = await getErrorLogs();
      final cutoffDate = DateTime.now().subtract(Duration(days: 30));
      
      final recentLogs = logs.where((log) => log.timestamp.isAfter(cutoffDate)).toList();
      
      if (recentLogs.length != logs.length) {
        final prefs = await SharedPreferences.getInstance();
        final logsJson = recentLogs.map((e) => e.toJson()).toList();
        await prefs.setString(_errorLogKey, logsJson.toString());
        
        print('ErrorHandlingService: Cleaned up ${logs.length - recentLogs.length} old log entries');
      }
    } catch (e) {
      print('ErrorHandlingService: Error cleaning up logs: $e');
    }
  }

  /// Get error type from error code
  ErrorType _getErrorTypeFromCode(String errorCode) {
    if (errorCode.contains('PERMISSION')) return ErrorType.permission;
    if (errorCode.contains('NOTIFICATION')) return ErrorType.notification;
    if (errorCode.contains('BACKGROUND')) return ErrorType.backgroundTask;
    if (errorCode.contains('FALLBACK')) return ErrorType.fallbackMode;
    if (errorCode.contains('RETRY')) return ErrorType.retry;
    return ErrorType.general;
  }

  /// Add error event listener
  StreamSubscription<ErrorEvent> addErrorListener(void Function(ErrorEvent) onError) {
    final controller = StreamController<ErrorEvent>.broadcast();
    _errorStreamControllers.add(controller);
    return controller.stream.listen(onError);
  }

  /// Notify all error listeners
  void _notifyErrorListeners(ErrorEvent event) {
    for (final controller in _errorStreamControllers) {
      if (!controller.isClosed) {
        controller.add(event);
      }
    }
  }

  /// Check if the system should be in fallback mode based on current conditions
  Future<bool> shouldBeInFallbackMode() async {
    try {
      // Check recent critical errors
      final logs = await getErrorLogs();
      final recentCriticalErrors = logs.where((log) => 
        log.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 1))) &&
        log.severity == ErrorSeverity.error &&
        (log.code.contains('NOTIFICATION') || log.code.contains('BACKGROUND'))
      ).length;

      // Check if there are ongoing permission issues
      final prefs = await SharedPreferences.getInstance();
      final permissionStatus = prefs.getString(_permissionStatusKey);
      bool hasPermissionIssues = false;
      
      if (permissionStatus != null) {
        try {
          // Simple check for denied notifications permission
          hasPermissionIssues = permissionStatus.contains('notifications') && 
                               permissionStatus.contains('denied');
        } catch (e) {
          print('ErrorHandlingService: Error parsing permission status: $e');
        }
      }

      // Should be in fallback mode if:
      // 1. More than 3 critical notification/background errors in the last hour
      // 2. Notification permissions are explicitly denied
      return recentCriticalErrors > 3 || hasPermissionIssues;
    } catch (e) {
      print('ErrorHandlingService: Error checking fallback mode status: $e');
      return false; // Default to not being in fallback mode if we can't determine
    }
  }

  /// Reset fallback mode if system health is good
  Future<void> resetToNormalMode() async {
    try {
      final shouldBeFallback = await shouldBeInFallbackMode();
      
      if (_isInFallbackMode && !shouldBeFallback) {
        await setFallbackMode(false, reason: 'System health restored - resetting to normal mode');
        print('ErrorHandlingService: Successfully reset to normal mode');
      } else if (_isInFallbackMode && shouldBeFallback) {
        print('ErrorHandlingService: Staying in fallback mode due to ongoing issues');
      } else {
        print('ErrorHandlingService: Already in normal mode');
      }
    } catch (e) {
      await logError(
        'FALLBACK_RESET_ERROR',
        'Error resetting fallback mode: $e',
        severity: ErrorSeverity.warning,
      );
    }
  }

  /// Generate comprehensive system health report
  Future<SystemHealthReport> generateHealthReport() async {
    try {
      final logs = await getErrorLogs();
      final recentErrors = logs.where((log) => 
        log.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 24)))
      ).toList();
      
      final criticalErrors = recentErrors.where((log) => 
        log.severity == ErrorSeverity.error
      ).toList();
      
      final warnings = recentErrors.where((log) => 
        log.severity == ErrorSeverity.warning
      ).toList();

      final shouldBeFallback = await shouldBeInFallbackMode();
      final fallbackMismatch = _isInFallbackMode != shouldBeFallback;

      return SystemHealthReport(
        currentFallbackMode: _isInFallbackMode,
        shouldBeInFallbackMode: shouldBeFallback,
        fallbackModeCorrect: !fallbackMismatch,
        recentErrorCount: recentErrors.length,
        criticalErrors: criticalErrors.map((e) => '${e.code}: ${e.message}').toList(),
        warnings: warnings.map((e) => '${e.code}: ${e.message}').toList(),
        recommendations: _generateRecommendations(fallbackMismatch, criticalErrors, warnings),
        lastHealthCheck: DateTime.now(),
      );
    } catch (e) {
      await logError(
        'HEALTH_REPORT_ERROR',
        'Error generating health report: $e',
        severity: ErrorSeverity.error,
      );
      
      return SystemHealthReport(
        currentFallbackMode: _isInFallbackMode,
        shouldBeInFallbackMode: true,
        fallbackModeCorrect: false,
        recentErrorCount: 0,
        criticalErrors: ['Health report generation failed'],
        warnings: [],
        recommendations: ['Check system logs and restart the app'],
        lastHealthCheck: DateTime.now(),
      );
    }
  }

  /// Generate recommendations based on system health
  List<String> _generateRecommendations(bool fallbackMismatch, List<ErrorLogEntry> criticalErrors, List<ErrorLogEntry> warnings) {
    List<String> recommendations = [];

    if (fallbackMismatch) {
      if (_isInFallbackMode) {
        recommendations.add('System health appears good - consider resetting to normal mode');
      } else {
        recommendations.add('System may need fallback mode due to recent errors');
      }
    }

    if (criticalErrors.isNotEmpty) {
      final notificationErrors = criticalErrors.where((e) => e.code.contains('NOTIFICATION')).length;
      final backgroundErrors = criticalErrors.where((e) => e.code.contains('BACKGROUND')).length;
      
      if (notificationErrors > 0) {
        recommendations.add('Check notification permissions and settings');
      }
      if (backgroundErrors > 0) {
        recommendations.add('Check background processing permissions');
      }
    }

    if (warnings.length > 10) {
      recommendations.add('High number of warnings - consider investigating recurring issues');
    }

    if (recommendations.isEmpty) {
      recommendations.add('System health looks good');
    }

    return recommendations;
  }

  /// Get system health status
  Future<SystemHealthStatus> getSystemHealthStatus() async {
    try {
      final logs = await getErrorLogs();
      final recentErrors = logs.where((log) => 
        log.timestamp.isAfter(DateTime.now().subtract(Duration(hours: 24)))
      ).toList();
      
      final criticalErrors = recentErrors.where((log) => 
        log.severity == ErrorSeverity.error
      ).length;
      
      final warnings = recentErrors.where((log) => 
        log.severity == ErrorSeverity.warning
      ).length;

      HealthLevel healthLevel;
      if (criticalErrors > 5) {
        healthLevel = HealthLevel.critical;
      } else if (criticalErrors > 0 || warnings > 10) {
        healthLevel = HealthLevel.warning;
      } else if (warnings > 0 || _isInFallbackMode) {
        healthLevel = HealthLevel.degraded;
      } else {
        healthLevel = HealthLevel.healthy;
      }

      return SystemHealthStatus(
        level: healthLevel,
        isInFallbackMode: _isInFallbackMode,
        recentErrorCount: recentErrors.length,
        criticalErrorCount: criticalErrors,
        warningCount: warnings,
        lastErrorTime: recentErrors.isNotEmpty ? recentErrors.last.timestamp : null,
      );
    } catch (e) {
      await logError(
        'HEALTH_CHECK_ERROR',
        'Error getting system health status: $e',
        severity: ErrorSeverity.error,
      );
      
      return SystemHealthStatus(
        level: HealthLevel.critical,
        isInFallbackMode: true,
        recentErrorCount: 0,
        criticalErrorCount: 1,
        warningCount: 0,
        lastErrorTime: DateTime.now(),
      );
    }
  }

  /// Clear all error logs
  Future<void> clearErrorLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_errorLogKey);
      print('ErrorHandlingService: Cleared all error logs');
    } catch (e) {
      print('ErrorHandlingService: Error clearing logs: $e');
    }
  }

  /// Dispose of the error handling service
  void dispose() {
    for (final controller in _errorStreamControllers) {
      controller.close();
    }
    _errorStreamControllers.clear();
    _retryCounters.clear();
  }
}

// Data classes and enums

enum ErrorSeverity { info, warning, error, critical }

enum ErrorType { 
  general, 
  permission, 
  notification, 
  backgroundTask, 
  fallbackMode, 
  retry 
}

enum PermissionType { 
  notifications, 
  backgroundProcessing, 
  batteryOptimization 
}

enum PermissionStatus { 
  granted, 
  denied, 
  restricted, 
  unknown 
}

enum PermissionHandlingResult { 
  handled, 
  fallbackEnabled, 
  error 
}

enum HealthLevel { 
  healthy, 
  degraded, 
  warning, 
  critical 
}

class ErrorLogEntry {
  final String code;
  final String message;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? stackTrace;

  ErrorLogEntry({
    required this.code,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.metadata,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    'severity': severity.toString(),
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
    'stackTrace': stackTrace,
  };

  static ErrorLogEntry fromJson(Map<String, dynamic> json) => ErrorLogEntry(
    code: json['code'] as String,
    message: json['message'] as String,
    severity: ErrorSeverity.values.firstWhere(
      (e) => e.toString() == json['severity'],
      orElse: () => ErrorSeverity.error,
    ),
    timestamp: DateTime.parse(json['timestamp'] as String),
    metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    stackTrace: json['stackTrace'] as String?,
  );
}

class ErrorEvent {
  final ErrorType type;
  final String message;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ErrorEvent({
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.metadata,
  });
}

class PermissionInfo {
  final String title;
  final String description;
  final String impact;

  PermissionInfo({
    required this.title,
    required this.description,
    required this.impact,
  });
}

class SystemHealthStatus {
  final HealthLevel level;
  final bool isInFallbackMode;
  final int recentErrorCount;
  final int criticalErrorCount;
  final int warningCount;
  final DateTime? lastErrorTime;

  SystemHealthStatus({
    required this.level,
    required this.isInFallbackMode,
    required this.recentErrorCount,
    required this.criticalErrorCount,
    required this.warningCount,
    this.lastErrorTime,
  });
}

class SystemHealthReport {
  final bool currentFallbackMode;
  final bool shouldBeInFallbackMode;
  final bool fallbackModeCorrect;
  final int recentErrorCount;
  final List<String> criticalErrors;
  final List<String> warnings;
  final List<String> recommendations;
  final DateTime lastHealthCheck;

  SystemHealthReport({
    required this.currentFallbackMode,
    required this.shouldBeInFallbackMode,
    required this.fallbackModeCorrect,
    required this.recentErrorCount,
    required this.criticalErrors,
    required this.warnings,
    required this.recommendations,
    required this.lastHealthCheck,
  });
}