import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/error_handling_service.dart';

/// Backend Error Handler for Supabase operations
/// 
/// Provides comprehensive error handling, retry logic with exponential backoff,
/// and user-friendly error messages for Supabase authentication and database operations.
/// 
/// Requirements addressed:
/// - 2.1: Backend error handling for Supabase operations
/// - 2.2: User-friendly error messages for authentication failures
class BackendErrorHandler {
  static BackendErrorHandler? _instance;
  static BackendErrorHandler get instance => _instance ??= BackendErrorHandler._();
  BackendErrorHandler._();

  static const int _defaultMaxRetries = 3;
  static const Duration _baseDelay = Duration(seconds: 1);
  static const Duration _maxDelay = Duration(seconds: 30);
  static const double _backoffMultiplier = 2.0;
  static const double _jitterFactor = 0.1;

  final ErrorHandlingService _errorService = ErrorHandlingService.instance;

  /// Handle Supabase operation with comprehensive error handling and retry logic
  /// 
  /// [operation] - The Supabase operation to execute
  /// [operationName] - Name of the operation for logging purposes
  /// [maxRetries] - Maximum number of retry attempts (default: 3)
  /// [enableRetry] - Whether to enable retry logic (default: true)
  /// [fallbackValue] - Value to return if operation fails completely
  /// 
  /// Returns the result of the operation or fallback value if provided
  /// Throws [BackendException] with user-friendly message if operation fails
  Future<T> handleSupabaseOperation<T>(
    Future<T> Function() operation,
    String operationName, {
    int maxRetries = _defaultMaxRetries,
    bool enableRetry = true,
    T? fallbackValue,
  }) async {
    int attempt = 0;
    Duration delay = _baseDelay;
    Exception? lastException;

    while (attempt <= maxRetries) {
      try {
        attempt++;
        
        // Log retry attempts (except first attempt)
        if (attempt > 1) {
          await _errorService.logError(
            'BACKEND_RETRY_ATTEMPT',
            'Retrying $operationName (attempt $attempt/${maxRetries + 1})',
            severity: ErrorSeverity.info,
            metadata: {
              'operation': operationName,
              'attempt': attempt,
              'maxRetries': maxRetries,
            },
          );
        }

        final result = await operation();
        
        // Log successful retry
        if (attempt > 1) {
          await _errorService.logError(
            'BACKEND_RETRY_SUCCESS',
            '$operationName succeeded after $attempt attempts',
            severity: ErrorSeverity.info,
            metadata: {
              'operation': operationName,
              'attempts': attempt,
            },
          );
        }

        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Check if we should retry
        if (!enableRetry || attempt > maxRetries || !_shouldRetry(e)) {
          break;
        }

        // Log retry decision
        await _errorService.logError(
          'BACKEND_OPERATION_FAILED',
          '$operationName failed (attempt $attempt/${maxRetries + 1}): ${_getErrorMessage(e)}',
          severity: attempt > maxRetries ? ErrorSeverity.error : ErrorSeverity.warning,
          metadata: {
            'operation': operationName,
            'attempt': attempt,
            'maxRetries': maxRetries,
            'error': e.toString(),
            'errorType': e.runtimeType.toString(),
            'willRetry': attempt <= maxRetries,
          },
        );

        // Wait before retry with exponential backoff and jitter
        if (attempt <= maxRetries) {
          await _waitWithBackoff(delay, attempt);
          delay = _calculateNextDelay(delay);
        }
      }
    }

    // All retries exhausted, handle final failure
    final backendException = _createBackendException(lastException!, operationName);
    
    await _errorService.logError(
      'BACKEND_OPERATION_FINAL_FAILURE',
      '$operationName failed after ${attempt} attempts: ${backendException.userMessage}',
      severity: ErrorSeverity.error,
      metadata: {
        'operation': operationName,
        'totalAttempts': attempt,
        'finalError': lastException.toString(),
        'userMessage': backendException.userMessage,
      },
    );

    // Return fallback value if provided, otherwise throw exception
    if (fallbackValue != null) {
      await _errorService.logError(
        'BACKEND_FALLBACK_USED',
        'Using fallback value for $operationName',
        severity: ErrorSeverity.warning,
        metadata: {
          'operation': operationName,
          'fallbackValue': fallbackValue.toString(),
        },
      );
      return fallbackValue;
    }

    throw backendException;
  }

  /// Determine if an error should trigger a retry
  bool _shouldRetry(dynamic error) {
    // Don't retry authentication errors (user credentials issues)
    if (error is AuthException) {
      final authError = error as AuthException;
      // Retry on network/server errors, not on credential errors
      return _isNetworkOrServerError(authError);
    }

    // Don't retry database constraint violations or permission errors
    if (error is PostgrestException) {
      final dbError = error as PostgrestException;
      return _isRetryablePostgrestError(dbError);
    }

    // Retry on general network/timeout errors
    if (error is TimeoutException || 
        error.toString().contains('network') ||
        error.toString().contains('connection') ||
        error.toString().contains('timeout')) {
      return true;
    }

    // Don't retry on argument errors or other client-side errors
    if (error is ArgumentError || error is FormatException) {
      return false;
    }

    // Default to not retrying unknown errors
    return false;
  }

  /// Check if AuthException is a network or server error (retryable)
  bool _isNetworkOrServerError(AuthException error) {
    final message = error.message.toLowerCase();
    
    // Network/connection errors (retryable)
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('server error') ||
        message.contains('internal server error') ||
        message.contains('service unavailable') ||
        message.contains('bad gateway') ||
        message.contains('gateway timeout')) {
      return true;
    }

    // Authentication/credential errors (not retryable)
    if (message.contains('invalid login credentials') ||
        message.contains('email not confirmed') ||
        message.contains('invalid email') ||
        message.contains('weak password') ||
        message.contains('user already registered') ||
        message.contains('email already registered')) {
      return false;
    }

    // Default to not retrying auth errors
    return false;
  }

  /// Check if PostgrestException is retryable
  bool _isRetryablePostgrestError(PostgrestException error) {
    final code = error.code;
    final message = error.message.toLowerCase();

    // Server errors (5xx) are generally retryable
    if (code != null && code.startsWith('5')) {
      return true;
    }

    // Network/connection errors
    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return true;
    }

    // Client errors (4xx) are generally not retryable
    if (code != null && code.startsWith('4')) {
      return false;
    }

    // Constraint violations, permission errors (not retryable)
    if (message.contains('duplicate key') ||
        message.contains('foreign key') ||
        message.contains('check constraint') ||
        message.contains('permission denied') ||
        message.contains('insufficient privilege')) {
      return false;
    }

    // Default to not retrying database errors
    return false;
  }

  /// Wait with exponential backoff and jitter
  Future<void> _waitWithBackoff(Duration delay, int attempt) async {
    // Add jitter to prevent thundering herd
    final jitter = delay.inMilliseconds * _jitterFactor * Random().nextDouble();
    final jitteredDelay = Duration(
      milliseconds: delay.inMilliseconds + jitter.round(),
    );

    await Future.delayed(jitteredDelay);
  }

  /// Calculate next delay with exponential backoff
  Duration _calculateNextDelay(Duration currentDelay) {
    final nextDelayMs = (currentDelay.inMilliseconds * _backoffMultiplier).round();
    return Duration(
      milliseconds: min(nextDelayMs, _maxDelay.inMilliseconds),
    );
  }

  /// Create user-friendly BackendException from various error types
  BackendException _createBackendException(Exception error, String operationName) {
    if (error is AuthException) {
      return _createAuthBackendException(error, operationName);
    }

    if (error is PostgrestException) {
      return _createDatabaseBackendException(error, operationName);
    }

    if (error is TimeoutException) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.timeout,
        userMessage: 'The operation timed out. Please check your internet connection and try again.',
        technicalMessage: error.toString(),
        isRetryable: true,
      );
    }

    // Generic network/connection errors
    final errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('network') || 
        errorMessage.contains('connection') ||
        errorMessage.contains('internet') ||
        errorMessage.contains('socketexception') ||
        errorMessage.contains('handshakeexception') ||
        errorMessage.contains('failed to connect') ||
        errorMessage.contains('no internet') ||
        errorMessage.contains('unreachable') ||
        errorMessage.contains('dns')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.network,
        userMessage: 'Please check your internet connection and try again.',
        technicalMessage: error.toString(),
        isRetryable: true,
      );
    }

    // Generic server error
    return BackendException(
      originalError: error,
      operationName: operationName,
      errorType: BackendErrorType.server,
      userMessage: 'A server error occurred. Please try again later.',
      technicalMessage: error.toString(),
      isRetryable: false,
    );
  }

  /// Create BackendException for AuthException
  BackendException _createAuthBackendException(AuthException error, String operationName) {
    final message = error.message.toLowerCase();

    // Check for network/connection issues first (before credential errors)
    if (message.contains('network') || 
        message.contains('connection') || 
        message.contains('timeout') ||
        message.contains('failed to connect') ||
        message.contains('no internet') ||
        message.contains('unreachable') ||
        message.contains('dns') ||
        message.contains('socket') ||
        error.toString().toLowerCase().contains('socketexception') ||
        error.toString().toLowerCase().contains('handshakeexception')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.network,
        userMessage: 'Please check your internet connection and try again.',
        technicalMessage: error.message,
        isRetryable: true,
      );
    }

    if (message.contains('invalid login credentials')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.authentication,
        userMessage: 'Invalid email or password. Please check your credentials and try again.',
        technicalMessage: error.message,
        isRetryable: false,
      );
    }

    if (message.contains('email not confirmed')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.authentication,
        userMessage: 'Please check your email and click the confirmation link before signing in.',
        technicalMessage: error.message,
        isRetryable: false,
      );
    }

    if (message.contains('user already registered') || message.contains('email already registered')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.authentication,
        userMessage: 'An account with this email already exists. Please sign in instead.',
        technicalMessage: error.message,
        isRetryable: false,
      );
    }

    if (message.contains('weak password')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.validation,
        userMessage: 'Password is too weak. Please use at least 8 characters with a mix of letters and numbers.',
        technicalMessage: error.message,
        isRetryable: false,
      );
    }

    if (message.contains('invalid email')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.validation,
        userMessage: 'Please enter a valid email address.',
        technicalMessage: error.message,
        isRetryable: false,
      );
    }

    if (message.contains('network') || message.contains('connection') || message.contains('timeout')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.network,
        userMessage: 'Unable to connect to the authentication server. Please check your internet connection.',
        technicalMessage: error.message,
        isRetryable: true,
      );
    }

    // Generic auth error
    return BackendException(
      originalError: error,
      operationName: operationName,
      errorType: BackendErrorType.authentication,
      userMessage: 'Authentication failed. Please try again.',
      technicalMessage: error.message,
      isRetryable: false,
    );
  }

  /// Create BackendException for PostgrestException
  BackendException _createDatabaseBackendException(PostgrestException error, String operationName) {
    final message = error.message.toLowerCase();
    final code = error.code;

    if (message.contains('duplicate key')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.validation,
        userMessage: 'This information already exists. Please use different values.',
        technicalMessage: error.message,
        isRetryable: false,
      );
    }

    if (message.contains('foreign key')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.validation,
        userMessage: 'Unable to complete the operation due to data dependencies.',
        technicalMessage: error.message,
        isRetryable: false,
      );
    }

    if (message.contains('permission denied') || message.contains('insufficient privilege')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.permission,
        userMessage: 'You do not have permission to perform this action.',
        technicalMessage: error.message,
        isRetryable: false,
      );
    }

    if (code == 'PGRST116') {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.notFound,
        userMessage: 'The requested information was not found.',
        technicalMessage: error.message,
        isRetryable: false,
      );
    }

    if (message.contains('network') || message.contains('connection') || message.contains('timeout')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.network,
        userMessage: 'Unable to connect to the database. Please check your internet connection.',
        technicalMessage: error.message,
        isRetryable: true,
      );
    }

    // Server errors (5xx)
    if (code != null && code.startsWith('5')) {
      return BackendException(
        originalError: error,
        operationName: operationName,
        errorType: BackendErrorType.server,
        userMessage: 'A server error occurred. Please try again later.',
        technicalMessage: error.message,
        isRetryable: true,
      );
    }

    // Generic database error
    return BackendException(
      originalError: error,
      operationName: operationName,
      errorType: BackendErrorType.database,
      userMessage: 'A database error occurred. Please try again.',
      technicalMessage: error.message,
      isRetryable: false,
    );
  }

  /// Get user-friendly error message from any exception
  String _getErrorMessage(dynamic error) {
    if (error is BackendException) {
      return error.userMessage;
    }

    if (error is AuthException) {
      return _createAuthBackendException(error, 'operation').userMessage;
    }

    if (error is PostgrestException) {
      return _createDatabaseBackendException(error, 'operation').userMessage;
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Get user-friendly error message for display in UI
  static String getUserFriendlyMessage(dynamic error) {
    return BackendErrorHandler.instance._getErrorMessage(error);
  }

  /// Check if an error is retryable
  static bool isRetryable(dynamic error) {
    if (error is BackendException) {
      return error.isRetryable;
    }

    return BackendErrorHandler.instance._shouldRetry(error);
  }
}

/// Custom exception for backend operations with user-friendly messages
class BackendException implements Exception {
  final Exception originalError;
  final String operationName;
  final BackendErrorType errorType;
  final String userMessage;
  final String technicalMessage;
  final bool isRetryable;

  const BackendException({
    required this.originalError,
    required this.operationName,
    required this.errorType,
    required this.userMessage,
    required this.technicalMessage,
    required this.isRetryable,
  });

  @override
  String toString() {
    return 'BackendException: $userMessage (Operation: $operationName, Type: $errorType)';
  }
}

/// Types of backend errors for categorization
enum BackendErrorType {
  authentication,
  database,
  network,
  timeout,
  server,
  validation,
  permission,
  notFound,
  unknown,
}