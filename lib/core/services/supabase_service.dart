import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../utils/backend_error_handler.dart';

/// Service class for handling Supabase backend operations
/// Provides authentication, user management, and database operations
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  final BackendErrorHandler _errorHandler = BackendErrorHandler.instance;

  // Get Supabase client
  SupabaseClient get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw Exception('Supabase is not initialized. Call Supabase.initialize() first.');
    }
  }

  // Check if Supabase is initialized and configured
  bool get isInitialized {
    try {
      return AppConfig.isSupabaseConfigured && 
             Supabase.instance.client != null;
    } catch (e) {
      // Supabase is not initialized
      return false;
    }
  }

  // Authentication methods
  /// Sign in user with email and password
  /// Throws [BackendException] with user-friendly error messages
  Future<AuthResponse> signIn(String email, String password) async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'signIn',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }
    
    if (email.isEmpty || password.isEmpty) {
      throw BackendException(
        originalError: Exception('Email and password cannot be empty'),
        operationName: 'signIn',
        errorType: BackendErrorType.validation,
        userMessage: 'Please enter both email and password.',
        technicalMessage: 'Email and password cannot be empty',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        final response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        return response;
      },
      'signIn',
      maxRetries: 2, // Fewer retries for auth operations
    );
  }

  /// Sign up new user with email, password and name
  /// Throws [BackendException] with user-friendly error messages
  Future<AuthResponse> signUp(String email, String password, String name) async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'signUp',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }
    
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw BackendException(
        originalError: Exception('Email, password, and name cannot be empty'),
        operationName: 'signUp',
        errorType: BackendErrorType.validation,
        userMessage: 'Please fill in all required fields.',
        technicalMessage: 'Email, password, and name cannot be empty',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        final response = await client.auth.signUp(
          email: email,
          password: password,
          data: {
            'name': name,
            'display_name': name,
          },
          emailRedirectTo: 'https://jslerlyixschpaefyaft.supabase.co/auth/v1/callback',
        );
        return response;
      },
      'signUp',
      maxRetries: 2, // Fewer retries for auth operations
    );
  }

  /// Reset password for user
  /// Throws [BackendException] with user-friendly error messages
  Future<void> resetPassword(String email) async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'resetPassword',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }
    
    if (email.isEmpty) {
      throw BackendException(
        originalError: Exception('Email cannot be empty'),
        operationName: 'resetPassword',
        errorType: BackendErrorType.validation,
        userMessage: 'Please enter your email address.',
        technicalMessage: 'Email cannot be empty',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        await client.auth.resetPasswordForEmail(
          email,
          redirectTo: 'https://jslerlyixschpaefyaft.supabase.co/auth/v1/callback',
        );
      },
      'resetPassword',
      maxRetries: 2,
    );
  }

  /// Sign out current user
  /// Throws [BackendException] with user-friendly error messages
  Future<void> signOut() async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'signOut',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        await client.auth.signOut();
      },
      'signOut',
      maxRetries: 1, // Single retry for sign out
    );
  }

  // User data retrieval methods
  /// Get current authenticated user
  /// Returns null if no user is authenticated or if an error occurs
  User? getCurrentUser() {
    if (!isInitialized) {
      _logError('Cannot get current user: Supabase is not initialized');
      return null;
    }

    try {
      return client.auth.currentUser;
    } catch (e) {
      _logError('Error getting current user: $e');
      return null;
    }
  }

  /// Get current user session
  /// Returns null if no session exists or if an error occurs
  Session? getCurrentSession() {
    if (!isInitialized) {
      _logError('Cannot get current session: Supabase is not initialized');
      return null;
    }

    try {
      return client.auth.currentSession;
    } catch (e) {
      _logError('Error getting current session: $e');
      return null;
    }
  }

  /// Listen to authentication state changes
  /// Returns stream of auth state changes
  Stream<AuthState> get authStateChanges {
    if (!isInitialized) {
      throw Exception('Supabase is not initialized');
    }
    try {
      return client.auth.onAuthStateChange;
    } catch (e) {
      throw Exception('Error accessing auth state changes: $e');
    }
  }

  // User profile management methods
  /// Get user profile data from profiles table
  /// Returns null if profile not found
  /// Throws [BackendException] for other errors
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'getUserProfile',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }
    
    if (userId.isEmpty) {
      throw BackendException(
        originalError: Exception('User ID cannot be empty'),
        operationName: 'getUserProfile',
        errorType: BackendErrorType.validation,
        userMessage: 'Invalid user information.',
        technicalMessage: 'User ID cannot be empty',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        final response = await client
            .from('kiro_profiles')
            .select()
            .eq('id', userId)
            .single();
        return response;
      },
      'getUserProfile',
      fallbackValue: null, // Return null if profile not found or table doesn't exist
      maxRetries: 0, // Don't retry profile queries to speed up login
    );
  }

  /// Update user profile in profiles table
  /// Throws [BackendException] with user-friendly error messages
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'updateUserProfile',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }
    
    if (userId.isEmpty) {
      throw BackendException(
        originalError: Exception('User ID cannot be empty'),
        operationName: 'updateUserProfile',
        errorType: BackendErrorType.validation,
        userMessage: 'Invalid user information.',
        technicalMessage: 'User ID cannot be empty',
        isRetryable: false,
      );
    }
    
    if (updates.isEmpty) {
      throw BackendException(
        originalError: Exception('Updates cannot be empty'),
        operationName: 'updateUserProfile',
        errorType: BackendErrorType.validation,
        userMessage: 'No changes to save.',
        technicalMessage: 'Updates cannot be empty',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        await client
            .from('kiro_profiles')
            .update(updates)
            .eq('id', userId);
      },
      'updateUserProfile',
      maxRetries: 0, // Don't retry profile updates to speed up registration
    );
  }

  // Generic database operations
  /// Select data from a table with optional filters
  /// Throws [BackendException] with user-friendly error messages
  Future<List<Map<String, dynamic>>> select(String table, {
    String? select,
    Map<String, dynamic>? filters,
  }) async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'select',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }
    
    if (table.isEmpty) {
      throw BackendException(
        originalError: Exception('Table name cannot be empty'),
        operationName: 'select',
        errorType: BackendErrorType.validation,
        userMessage: 'Invalid data request.',
        technicalMessage: 'Table name cannot be empty',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        var query = client.from(table).select(select ?? '*');
        
        if (filters != null) {
          filters.forEach((key, value) {
            query = query.eq(key, value);
          });
        }
        
        final response = await query;
        return List<Map<String, dynamic>>.from(response);
      },
      'select from $table',
    );
  }

  /// Insert data into a table
  /// Returns the inserted record
  /// Throws [BackendException] with user-friendly error messages
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> data) async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'insert',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }
    
    if (table.isEmpty) {
      throw BackendException(
        originalError: Exception('Table name cannot be empty'),
        operationName: 'insert',
        errorType: BackendErrorType.validation,
        userMessage: 'Invalid data request.',
        technicalMessage: 'Table name cannot be empty',
        isRetryable: false,
      );
    }
    
    if (data.isEmpty) {
      throw BackendException(
        originalError: Exception('Data cannot be empty'),
        operationName: 'insert',
        errorType: BackendErrorType.validation,
        userMessage: 'No data to save.',
        technicalMessage: 'Data cannot be empty',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        final response = await client
            .from(table)
            .insert(data)
            .select()
            .single();
        return response;
      },
      'insert into $table',
    );
  }

  /// Update data in a table with filters
  /// Throws [BackendException] with user-friendly error messages
  Future<void> update(String table, Map<String, dynamic> data, Map<String, dynamic> filters) async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'update',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }
    
    if (table.isEmpty) {
      throw BackendException(
        originalError: Exception('Table name cannot be empty'),
        operationName: 'update',
        errorType: BackendErrorType.validation,
        userMessage: 'Invalid data request.',
        technicalMessage: 'Table name cannot be empty',
        isRetryable: false,
      );
    }
    
    if (data.isEmpty) {
      throw BackendException(
        originalError: Exception('Data cannot be empty'),
        operationName: 'update',
        errorType: BackendErrorType.validation,
        userMessage: 'No changes to save.',
        technicalMessage: 'Data cannot be empty',
        isRetryable: false,
      );
    }
    
    if (filters.isEmpty) {
      throw BackendException(
        originalError: Exception('Filters cannot be empty'),
        operationName: 'update',
        errorType: BackendErrorType.validation,
        userMessage: 'Invalid update request.',
        technicalMessage: 'Filters cannot be empty',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        var query = client.from(table).update(data);
        
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
        
        await query;
      },
      'update $table',
    );
  }

  /// Delete data from a table with filters
  /// Throws [BackendException] with user-friendly error messages
  Future<void> delete(String table, Map<String, dynamic> filters) async {
    if (!isInitialized) {
      throw BackendException(
        originalError: Exception('Supabase is not initialized'),
        operationName: 'delete',
        errorType: BackendErrorType.server,
        userMessage: 'Service is not available. Please try again later.',
        technicalMessage: 'Supabase is not initialized',
        isRetryable: false,
      );
    }
    
    if (table.isEmpty) {
      throw BackendException(
        originalError: Exception('Table name cannot be empty'),
        operationName: 'delete',
        errorType: BackendErrorType.validation,
        userMessage: 'Invalid data request.',
        technicalMessage: 'Table name cannot be empty',
        isRetryable: false,
      );
    }
    
    if (filters.isEmpty) {
      throw BackendException(
        originalError: Exception('Filters cannot be empty'),
        operationName: 'delete',
        errorType: BackendErrorType.validation,
        userMessage: 'Invalid delete request.',
        technicalMessage: 'Filters cannot be empty',
        isRetryable: false,
      );
    }

    return await _errorHandler.handleSupabaseOperation(
      () async {
        var query = client.from(table).delete();
        
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
        
        await query;
      },
      'delete from $table',
    );
  }

  // Private helper methods
  void _logError(String message) {
    if (AppConfig.isDebug) {
      print('[SupabaseService] $message');
    }
  }
}