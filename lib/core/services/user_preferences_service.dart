import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'auth_service.dart';
import '../utils/data_validation_utils.dart';

/// Service for managing user preferences with Supabase backend synchronization
/// Handles app settings, notification preferences, and user customizations
class UserPreferencesService {
  static const String _preferencesKey = 'user_preferences';
  static const String _preferencesTable = 'kiro_user_preferences';

  static UserPreferencesService? _instance;
  static UserPreferencesService get instance => _instance ??= UserPreferencesService._();
  UserPreferencesService._();

  // Dependencies
  final SupabaseService _supabaseService = SupabaseService.instance;
  final AuthService _authService = AuthService.instance;

  // Cache for preferences
  Map<String, dynamic>? _cachedPreferences;

  /// Get user preferences with backend synchronization
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      // Try to get from Supabase if user is authenticated and not in guest mode
      if (_shouldUseSupabase()) {
        try {
          final userId = _authService.currentUser?['id'];
          final supabasePreferences = await _supabaseService.select(
            _preferencesTable,
            filters: {'user_id': userId},
          );
          
          if (supabasePreferences.isNotEmpty) {
            final preferences = supabasePreferences.first['preferences'] as Map<String, dynamic>? ?? {};
            print('UserPreferencesService: Loaded preferences from Supabase');
            
            // Cache preferences locally for offline access
            await _cachePreferencesLocally(preferences);
            _cachedPreferences = preferences;
            
            return preferences;
          } else {
            // No preferences found in Supabase, create default preferences
            final defaultPreferences = _getDefaultPreferences();
            await savePreferences(defaultPreferences);
            return defaultPreferences;
          }
        } catch (e) {
          print('UserPreferencesService: Error loading from Supabase, falling back to local storage: $e');
          return await _getPreferencesLocally();
        }
      } else {
        // Get from local storage for guest users or when Supabase is not available
        return await _getPreferencesLocally();
      }
    } catch (e) {
      print('UserPreferencesService: Error loading preferences: $e');
      return _getDefaultPreferences();
    }
  }

  /// Save user preferences with backend synchronization
  Future<void> savePreferences(Map<String, dynamic> preferences) async {
    // Validate preferences data
    if (!_validatePreferencesData(preferences)) {
      throw ArgumentError('Invalid preferences data provided');
    }

    try {
      // Try to save to Supabase if user is authenticated and not in guest mode
      if (_shouldUseSupabase()) {
        try {
          final userId = _authService.currentUser?['id'];
          final supabaseData = {
            'user_id': userId,
            'preferences': preferences,
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          // Check if preferences already exist
          final existingPreferences = await _supabaseService.select(
            _preferencesTable,
            filters: {'user_id': userId},
          );
          
          if (existingPreferences.isNotEmpty) {
            // Update existing preferences
            await _supabaseService.update(
              _preferencesTable,
              supabaseData,
              {'user_id': userId},
            );
          } else {
            // Insert new preferences
            await _supabaseService.insert(_preferencesTable, supabaseData);
          }
          
          print('UserPreferencesService: Saved preferences to Supabase');
          
          // Also cache locally for offline access
          await _cachePreferencesLocally(preferences);
        } catch (e) {
          print('UserPreferencesService: Error saving to Supabase, falling back to local storage: $e');
          await _savePreferencesLocally(preferences);
        }
      } else {
        // Save locally for guest users or when Supabase is not available
        await _savePreferencesLocally(preferences);
      }
      
      _cachedPreferences = preferences;
    } catch (e) {
      print('UserPreferencesService: Error saving preferences: $e');
      throw Exception('Failed to save preferences: $e');
    }
  }

  /// Update specific preference value
  Future<void> updatePreference(String key, dynamic value) async {
    final currentPreferences = await getPreferences();
    currentPreferences[key] = value;
    await savePreferences(currentPreferences);
  }

  /// Get specific preference value with default fallback
  Future<T> getPreference<T>(String key, T defaultValue) async {
    final preferences = await getPreferences();
    return preferences[key] as T? ?? defaultValue;
  }

  /// Sync preferences between Supabase and local storage
  Future<void> syncPreferences() async {
    try {
      if (!_shouldUseSupabase()) {
        return; // No sync needed for guests or when Supabase is not available
      }

      final userId = _authService.currentUser?['id'];
      final supabasePreferences = await _supabaseService.select(
        _preferencesTable,
        filters: {'user_id': userId},
      );
      
      if (supabasePreferences.isNotEmpty) {
        final serverPreferences = supabasePreferences.first['preferences'] as Map<String, dynamic>? ?? {};
        final localPreferences = await _getPreferencesLocally();
        
        // Simple merge strategy: server preferences take precedence
        final mergedPreferences = {...localPreferences, ...serverPreferences};
        
        // Save merged preferences both locally and to server
        await _cachePreferencesLocally(mergedPreferences);
        _cachedPreferences = mergedPreferences;
        
        print('UserPreferencesService: Synced preferences successfully');
      }
    } catch (e) {
      print('UserPreferencesService: Error syncing preferences: $e');
    }
  }

  /// Clear all preferences (reset to defaults)
  Future<void> clearPreferences() async {
    final defaultPreferences = _getDefaultPreferences();
    await savePreferences(defaultPreferences);
  }

  // Private helper methods

  /// Check if Supabase should be used for preferences storage
  bool _shouldUseSupabase() {
    return _authService.isLoggedIn && 
           !_authService.isGuestMode && 
           _supabaseService.isInitialized;
  }

  /// Get preferences from local storage
  Future<Map<String, dynamic>> _getPreferencesLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);
      
      if (preferencesJson == null) {
        return _getDefaultPreferences();
      }
      
      final Map<String, dynamic> preferences = jsonDecode(preferencesJson);
      return preferences;
    } catch (e) {
      print('UserPreferencesService: Error loading preferences locally: $e');
      return _getDefaultPreferences();
    }
  }

  /// Save preferences to local storage
  Future<void> _savePreferencesLocally(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_preferencesKey, jsonEncode(preferences));
    } catch (e) {
      print('UserPreferencesService: Error saving preferences locally: $e');
    }
  }

  /// Cache preferences locally for offline access
  Future<void> _cachePreferencesLocally(Map<String, dynamic> preferences) async {
    await _savePreferencesLocally(preferences);
  }

  /// Get default preferences
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'notifications': {
        'enabled': true,
        'sound': true,
        'vibration': true,
        'showOnLockScreen': true,
      },
      'theme': {
        'darkMode': false,
        'accentColor': '#4CAF50',
      },
      'reminders': {
        'defaultCategory': 'General',
        'defaultTime': '09:00',
        'snoozeMinutes': 5,
      },
      'audio': {
        'defaultVolume': 0.8,
        'enableAudioReminders': true,
      },
      'privacy': {
        'analyticsEnabled': false,
        'crashReportingEnabled': true,
      },
      'version': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  /// Validate preferences data structure
  bool _validatePreferencesData(Map<String, dynamic> preferences) {
    try {
      final isValid = DataValidationUtils.isValidUserPreferences(preferences);
      if (!isValid) {
        print('UserPreferencesService: Preferences validation failed');
      }
      return isValid;
    } catch (e) {
      print('UserPreferencesService: Error validating preferences data: $e');
      return false;
    }
  }
}