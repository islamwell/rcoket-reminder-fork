import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../utils/backend_error_handler.dart';

class AuthService {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _isGuestKey = 'is_guest_mode';

  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  // Dependencies
  final SupabaseService _supabaseService = SupabaseService.instance;

  // Current user data
  Map<String, dynamic>? _currentUser;
  bool _isLoggedIn = false;
  bool _isGuestMode = false;

  // Getters
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isGuestMode => _isGuestMode;
  String get userName => _currentUser?['name'] ?? '';
  String get userEmail => _currentUser?['email'] ?? '';

  // Initialize auth service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    _isGuestMode = prefs.getBool(_isGuestKey) ?? false;
    
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      try {
        _currentUser = jsonDecode(userData);
        
        // Check Supabase session if user was authenticated through Supabase
        if (_currentUser?['supabaseUser'] == true && _supabaseService.isInitialized) {
          try {
            final supabaseUser = _supabaseService.getCurrentUser();
            final session = _supabaseService.getCurrentSession();
            
            if (supabaseUser == null || session == null) {
              // Supabase session expired, clear local auth
              print('Supabase session expired, clearing local authentication');
              await logout();
              return;
            }
            
            // Sync user data if session is valid
            await syncUserData();
          } catch (e) {
            print('Warning: Could not verify Supabase session: $e');
            // Continue with local data but mark for potential re-authentication
          }
        }
      } catch (e) {
        print('Error loading user data: $e');
        await logout();
      }
    }
  }

  // Login with email and password
  /// Returns AuthResult with success status and error message
  Future<AuthResult> login(String email, String password) async {
    try {
      // Validate input
      if (email.isEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'Please enter your email address.',
          errorType: AuthErrorType.validation,
        );
      }
      
      if (password.length < 6) {
        return AuthResult(
          success: false,
          errorMessage: 'Password must be at least 6 characters long.',
          errorType: AuthErrorType.validation,
        );
      }

      // Try Supabase authentication if configured
      if (_supabaseService.isInitialized) {
        try {
          final response = await _supabaseService.signIn(email, password);
          
          if (response.user != null) {
            // Get additional user profile data (skip if table doesn't exist)
            Map<String, dynamic>? profileData;
            try {
              profileData = await _supabaseService.getUserProfile(response.user!.id);
            } catch (e) {
              print('Warning: Could not fetch user profile (this is normal if profiles table does not exist): $e');
              // Continue without profile data - this is not critical for login
            }

            final userData = {
              'id': response.user!.id,
              'name': profileData?['name'] ?? 
                     response.user!.userMetadata?['name'] ?? 
                     '',
              'email': response.user!.email ?? email,
              'loginTime': DateTime.now().toIso8601String(),
              'profilePicture': profileData?['profile_picture'],
              'supabaseUser': true,
            };

            await _saveUserData(userData, false);
            return AuthResult(success: true);
          }
        } on BackendException catch (e) {
          return AuthResult(
            success: false,
            errorMessage: e.userMessage,
            errorType: _mapBackendErrorType(e.errorType),
            isRetryable: e.isRetryable,
          );
        } catch (e) {
          return AuthResult(
            success: false,
            errorMessage: BackendErrorHandler.getUserFriendlyMessage(e),
            errorType: AuthErrorType.unknown,
            isRetryable: BackendErrorHandler.isRetryable(e),
          );
        }
      }

      // No backend service available
      return AuthResult(
        success: false,
        errorMessage: 'Authentication service is not available. Please try again later.',
        errorType: AuthErrorType.service,
        isRetryable: true,
      );
    } catch (e) {
      print('Login error: $e');
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
        errorType: AuthErrorType.unknown,
        isRetryable: true,
      );
    }
  }

  // Reset password
  /// Returns AuthResult with success status and error message
  Future<AuthResult> resetPassword(String email) async {
    try {
      // Validate input
      if (email.isEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'Please enter your email address.',
          errorType: AuthErrorType.validation,
        );
      }

      // Try Supabase password reset if configured
      if (_supabaseService.isInitialized) {
        try {
          await _supabaseService.resetPassword(email);
          return AuthResult(
            success: true,
            errorMessage: 'Password reset email sent. Please check your inbox.',
          );
        } on BackendException catch (e) {
          return AuthResult(
            success: false,
            errorMessage: e.userMessage,
            errorType: _mapBackendErrorType(e.errorType),
            isRetryable: e.isRetryable,
          );
        } catch (e) {
          return AuthResult(
            success: false,
            errorMessage: BackendErrorHandler.getUserFriendlyMessage(e),
            errorType: AuthErrorType.unknown,
            isRetryable: BackendErrorHandler.isRetryable(e),
          );
        }
      }

      // No backend service available
      return AuthResult(
        success: false,
        errorMessage: 'Password reset service is not available. Please try again later.',
        errorType: AuthErrorType.service,
        isRetryable: true,
      );
    } catch (e) {
      print('Password reset error: $e');
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
        errorType: AuthErrorType.unknown,
        isRetryable: true,
      );
    }
  }

  // Register new user
  /// Returns AuthResult with success status and error message
  Future<AuthResult> register(String name, String email, String password) async {
    try {
      // Validate input
      if (name.isEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'Please enter your full name.',
          errorType: AuthErrorType.validation,
        );
      }
      
      if (email.isEmpty) {
        return AuthResult(
          success: false,
          errorMessage: 'Please enter your email address.',
          errorType: AuthErrorType.validation,
        );
      }
      
      if (password.length < 6) {
        return AuthResult(
          success: false,
          errorMessage: 'Password must be at least 6 characters long.',
          errorType: AuthErrorType.validation,
        );
      }

      // Try Supabase registration if configured
      if (_supabaseService.isInitialized) {
        try {
          final response = await _supabaseService.signUp(email, password, name);
          
          if (response.user != null) {
            // Create user profile data
            final userData = {
              'id': response.user!.id,
              'name': name,
              'email': response.user!.email ?? email,
              'registrationTime': DateTime.now().toIso8601String(),
              'profilePicture': null,
              'supabaseUser': true,
            };

            await _saveUserData(userData, false);
            
            // Try to create/update user profile in Supabase (skip if table doesn't exist)
            try {
              await _supabaseService.updateUserProfile(response.user!.id, {
                'name': name,
                'email': email,
                'created_at': DateTime.now().toIso8601String(),
              });
            } catch (e) {
              print('Warning: Could not create user profile (this is normal if profiles table does not exist): $e');
              // Continue without creating profile - this is not critical for registration
            }

            return AuthResult(success: true);
          }
        } on BackendException catch (e) {
          return AuthResult(
            success: false,
            errorMessage: e.userMessage,
            errorType: _mapBackendErrorType(e.errorType),
            isRetryable: e.isRetryable,
          );
        } catch (e) {
          return AuthResult(
            success: false,
            errorMessage: BackendErrorHandler.getUserFriendlyMessage(e),
            errorType: AuthErrorType.unknown,
            isRetryable: BackendErrorHandler.isRetryable(e),
          );
        }
      }

      // No backend service available
      return AuthResult(
        success: false,
        errorMessage: 'Registration service is not available. Please try again later.',
        errorType: AuthErrorType.service,
        isRetryable: true,
      );
    } catch (e) {
      print('Registration error: $e');
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
        errorType: AuthErrorType.unknown,
        isRetryable: true,
      );
    }
  }

  // Continue as guest
  /// Returns AuthResult with success status and error message
  Future<AuthResult> continueAsGuest() async {
    try {
      // Clear any existing user data to ensure guest mode isolation
      await _clearUserData();
      
      final guestData = {
        'id': 'guest_${DateTime.now().millisecondsSinceEpoch}',
        'name': '',
        'email': '',
        'isGuest': true,
        'guestStartTime': DateTime.now().toIso8601String(),
      };

      await _saveUserData(guestData, true);
      
      // Clear reminder data to ensure guest mode doesn't see previous user's data
      await _clearReminderData();
      
      return AuthResult(success: true);
    } catch (e) {
      print('Guest mode error: $e');
      return AuthResult(
        success: false,
        errorMessage: 'Failed to start guest mode. Please try again.',
        errorType: AuthErrorType.unknown,
        isRetryable: true,
      );
    }
  }

  // Save user data
  Future<void> _saveUserData(Map<String, dynamic> userData, bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    
    _currentUser = userData;
    _isLoggedIn = true;
    _isGuestMode = isGuest;
    
    await prefs.setString(_userKey, jsonEncode(userData));
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setBool(_isGuestKey, isGuest);
  }

  // Logout
  Future<void> logout() async {
    try {
      // Sign out from Supabase if user was authenticated through Supabase
      if (_currentUser?['supabaseUser'] == true && _supabaseService.isInitialized) {
        try {
          await _supabaseService.signOut();
        } catch (e) {
          print('Warning: Supabase sign out error: $e');
        }
      }
    } catch (e) {
      print('Error during logout: $e');
    }

    // Clear local data
    final prefs = await SharedPreferences.getInstance();
    
    _currentUser = null;
    _isLoggedIn = false;
    _isGuestMode = false;
    
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.setBool(_isGuestKey, false);
  }

  // Update user profile
  Future<bool> updateProfile(String name, String email) async {
    try {
      if (_currentUser != null) {
        // Update Supabase profile if user is authenticated through Supabase
        if (_currentUser!['supabaseUser'] == true && _supabaseService.isInitialized) {
          try {
            await _supabaseService.updateUserProfile(_currentUser!['id'], {
              'name': name,
              'email': email,
              'updated_at': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            print('Warning: Could not update Supabase profile: $e');
            // Continue with local update even if Supabase fails
          }
        }

        // Update local data
        _currentUser!['name'] = name;
        _currentUser!['email'] = email;
        _currentUser!['lastUpdated'] = DateTime.now().toIso8601String();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(_currentUser));
        return true;
      }
      return false;
    } catch (e) {
      print('Profile update error: $e');
      return false;
    }
  }

  // Sync user data between Supabase and local storage
  Future<void> syncUserData() async {
    try {
      if (!_isLoggedIn || _isGuestMode) {
        return; // No sync needed for guests or unauthenticated users
      }

      if (_currentUser?['supabaseUser'] == true && _supabaseService.isInitialized) {
        try {
          // Get latest user data from Supabase auth (not profiles table)
          final supabaseUser = _supabaseService.getCurrentUser();
          if (supabaseUser != null) {
            // Update with auth data (always available)
            _currentUser!['email'] = supabaseUser.email ?? _currentUser!['email'];
            _currentUser!['lastSynced'] = DateTime.now().toIso8601String();
            
            // Try to get profile data if available (optional)
            try {
              final profileData = await _supabaseService.getUserProfile(supabaseUser.id);
              if (profileData != null) {
                _currentUser!['name'] = profileData['name'] ?? _currentUser!['name'];
                _currentUser!['profilePicture'] = profileData['profile_picture'];
              }
            } catch (e) {
              print('Info: Profile data not available (this is normal if profiles table does not exist): $e');
              // Continue without profile data - not critical
            }

            // Save updated data locally
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_userKey, jsonEncode(_currentUser));
          }
        } catch (e) {
          print('Warning: Could not sync user data from Supabase: $e');
        }
      }
    } catch (e) {
      print('Error during user data sync: $e');
    }
  }



  // Check if user needs to login
  bool get needsAuthentication => !_isLoggedIn;

  // Check if user is authenticated through Supabase
  bool get isSupabaseUser => _currentUser?['supabaseUser'] == true;

  // Get Supabase user if available
  User? get supabaseUser => isSupabaseUser && _supabaseService.isInitialized 
      ? _supabaseService.getCurrentUser() 
      : null;

  // Check if user has valid session
  bool get hasValidSession {
    if (_isGuestMode) return true; // Guest mode is always valid
    if (!_isLoggedIn) return false;
    
    // For Supabase users, check if session exists
    if (isSupabaseUser && _supabaseService.isInitialized) {
      final session = _supabaseService.getCurrentSession();
      return session != null && !session.isExpired;
    }
    
    // For local users, always valid if logged in
    return true;
  }

  // Force refresh authentication state
  Future<void> refreshAuthState() async {
    if (isSupabaseUser && _supabaseService.isInitialized) {
      try {
        final user = _supabaseService.getCurrentUser();
        final session = _supabaseService.getCurrentSession();
        
        if (user == null || session == null || session.isExpired) {
          await logout();
        } else {
          await syncUserData();
        }
      } catch (e) {
        print('Error refreshing auth state: $e');
      }
    }
  }

  // Clear user data
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.setBool(_isGuestKey, false);
    
    _currentUser = null;
    _isLoggedIn = false;
    _isGuestMode = false;
  }
  
  // Clear reminder data for guest mode isolation
  Future<void> _clearReminderData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('reminders');
      await prefs.remove('next_reminder_id');
      await prefs.remove('completion_feedback');
      await prefs.remove('completions');
      await prefs.remove('ratings');
      print('AuthService: Cleared reminder data for guest mode isolation');
    } catch (e) {
      print('AuthService: Error clearing reminder data: $e');
    }
  }

  // Helper method to map BackendErrorType to AuthErrorType
  AuthErrorType _mapBackendErrorType(BackendErrorType backendType) {
    switch (backendType) {
      case BackendErrorType.authentication:
        return AuthErrorType.authentication;
      case BackendErrorType.validation:
        return AuthErrorType.validation;
      case BackendErrorType.network:
        return AuthErrorType.network;
      case BackendErrorType.timeout:
        return AuthErrorType.network;
      case BackendErrorType.server:
        return AuthErrorType.service;
      case BackendErrorType.permission:
        return AuthErrorType.authentication;
      case BackendErrorType.database:
        return AuthErrorType.service;
      case BackendErrorType.notFound:
        return AuthErrorType.authentication;
      case BackendErrorType.unknown:
        return AuthErrorType.unknown;
    }
  }
}

/// Result of authentication operations
class AuthResult {
  final bool success;
  final String? errorMessage;
  final AuthErrorType? errorType;
  final bool isRetryable;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.errorType,
    this.isRetryable = false,
  });

  @override
  String toString() {
    return 'AuthResult(success: $success, errorMessage: $errorMessage, errorType: $errorType, isRetryable: $isRetryable)';
  }
}

/// Types of authentication errors
enum AuthErrorType {
  validation,
  authentication,
  network,
  service,
  unknown,
}