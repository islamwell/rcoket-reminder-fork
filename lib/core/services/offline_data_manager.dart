import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'auth_service.dart';

/// Manages offline data caching and synchronization between local storage and Supabase
class OfflineDataManager {
  static const String _cachedUserDataKey = 'cached_user_data';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _pendingSyncDataKey = 'pending_sync_data';
  static const String _offlineModeKey = 'offline_mode';
  static const String _syncQueueKey = 'sync_queue';
  static const String _conflictResolutionKey = 'conflict_resolution';
  static const String _cachedRemindersKey = 'cached_reminders';

  static OfflineDataManager? _instance;
  static OfflineDataManager get instance => _instance ??= OfflineDataManager._();
  OfflineDataManager._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  final AuthService _authService = AuthService.instance;

  /// Cache user data locally for offline access
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Add caching metadata
      final cachedData = {
        ...userData,
        'cached_at': DateTime.now().toIso8601String(),
        'cache_version': '1.0',
      };
      
      await prefs.setString(_cachedUserDataKey, jsonEncode(cachedData));
      print('OfflineDataManager: User data cached successfully');
    } catch (e) {
      print('OfflineDataManager: Error caching user data: $e');
    }
  }

  /// Retrieve cached user data
  Future<Map<String, dynamic>?> getCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDataString = prefs.getString(_cachedUserDataKey);
      
      if (cachedDataString != null) {
        final cachedData = jsonDecode(cachedDataString) as Map<String, dynamic>;
        
        // Check if cache is still valid (within 24 hours)
        final cachedAt = DateTime.tryParse(cachedData['cached_at'] ?? '');
        if (cachedAt != null) {
          final cacheAge = DateTime.now().difference(cachedAt);
          if (cacheAge.inHours < 24) {
            return cachedData;
          } else {
            print('OfflineDataManager: Cached user data expired');
            await prefs.remove(_cachedUserDataKey);
          }
        }
      }
      
      return null;
    } catch (e) {
      print('OfflineDataManager: Error retrieving cached user data: $e');
      return null;
    }
  }

  /// Cache critical user data for offline access
  Future<void> cacheCriticalUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Extract only critical data to minimize storage
      final criticalData = {
        'id': userData['id'],
        'name': userData['name'],
        'email': userData['email'],
        'isGuest': userData['isGuest'] ?? false,
        'supabaseUser': userData['supabaseUser'] ?? false,
        'cached_at': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_cachedUserDataKey, jsonEncode(criticalData));
      print('OfflineDataManager: Critical user data cached');
    } catch (e) {
      print('OfflineDataManager: Error caching critical user data: $e');
    }
  }

  /// Add operation to sync queue for later processing
  Future<void> addToSyncQueue(String operation, String table, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_syncQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueString));
      
      final syncItem = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'operation': operation, // 'insert', 'update', 'delete'
        'table': table,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'retryCount': 0,
      };
      
      queue.add(syncItem);
      await prefs.setString(_syncQueueKey, jsonEncode(queue));
      
      print('OfflineDataManager: Added $operation operation to sync queue for table $table');
    } catch (e) {
      print('OfflineDataManager: Error adding to sync queue: $e');
    }
  }

  /// Process sync queue when connectivity is restored
  Future<void> processSyncQueue() async {
    if (!_supabaseService.isInitialized || !await _isOnline()) {
      print('OfflineDataManager: Cannot process sync queue - offline or Supabase not available');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_syncQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueString));
      
      if (queue.isEmpty) {
        print('OfflineDataManager: Sync queue is empty');
        return;
      }

      print('OfflineDataManager: Processing ${queue.length} items in sync queue');
      
      final processedItems = <String>[];
      final failedItems = <Map<String, dynamic>>[];
      
      for (final item in queue) {
        try {
          final operation = item['operation'] as String;
          final table = item['table'] as String;
          final data = item['data'] as Map<String, dynamic>;
          final itemId = item['id'] as String;
          
          // Check for conflicts before processing
          if (operation == 'update' || operation == 'delete') {
            final conflicts = await _detectConflicts(table, data);
            if (conflicts.isNotEmpty) {
              print('OfflineDataManager: Conflicts detected for $operation on $table');
              final resolvedData = await _resolveConflictsAutomatically(data, conflicts);
              if (resolvedData != null) {
                data.addAll(resolvedData);
              } else {
                // Skip this item if conflicts cannot be resolved automatically
                item['retryCount'] = (item['retryCount'] as int) + 1;
                item['conflictReason'] = 'Unresolvable conflicts detected';
                failedItems.add(item);
                continue;
              }
            }
          }
          
          switch (operation) {
            case 'insert':
              await _supabaseService.insert(table, data);
              break;
            case 'update':
              final filters = {'id': data['id']};
              await _supabaseService.update(table, data, filters);
              break;
            case 'delete':
              final filters = {'id': data['id']};
              await _supabaseService.delete(table, filters);
              break;
          }
          
          processedItems.add(itemId);
          print('OfflineDataManager: Successfully processed $operation for $table');
          
        } catch (e) {
          print('OfflineDataManager: Error processing sync item: $e');
          
          // Increment retry count with exponential backoff
          item['retryCount'] = (item['retryCount'] as int) + 1;
          item['lastError'] = e.toString();
          item['nextRetryAt'] = DateTime.now()
              .add(Duration(minutes: _calculateBackoffDelay(item['retryCount'] as int)))
              .toIso8601String();
          
          // Remove item if it has failed too many times
          if (item['retryCount'] >= 5) {
            processedItems.add(item['id'] as String);
            print('OfflineDataManager: Removing failed sync item after 5 retries');
            
            // Store failed item for manual review
            await _storeFailedSyncItem(item);
          } else {
            failedItems.add(item);
          }
        }
      }
      
      // Update queue with failed items and remove processed items
      final updatedQueue = failedItems.where((item) => 
          !processedItems.contains(item['id'])).toList();
      await prefs.setString(_syncQueueKey, jsonEncode(updatedQueue));
      
      print('OfflineDataManager: Sync queue processing completed. ${processedItems.length} items processed, ${updatedQueue.length} remaining');
      
    } catch (e) {
      print('OfflineDataManager: Error processing sync queue: $e');
    }
  }

  /// Sync data when connectivity is restored
  Future<void> syncWhenOnline() async {
    if (!await _isOnline()) {
      print('OfflineDataManager: Device is offline, skipping sync');
      return;
    }

    if (!_supabaseService.isInitialized) {
      print('OfflineDataManager: Supabase not initialized, skipping sync');
      return;
    }

    if (!_authService.isLoggedIn || _authService.isGuestMode) {
      print('OfflineDataManager: User not authenticated or in guest mode, skipping sync');
      return;
    }

    try {
      print('OfflineDataManager: Starting online sync');
      
      // Process any pending sync operations
      await processSyncQueue();
      
      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncTimeKey, DateTime.now().toIso8601String());
      
      print('OfflineDataManager: Online sync completed');
      
    } catch (e) {
      print('OfflineDataManager: Error during online sync: $e');
    }
  }

  /// Handle conflict resolution between offline and online data
  Future<Map<String, dynamic>> resolveConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    ConflictResolutionStrategy strategy,
  ) async {
    try {
      switch (strategy) {
        case ConflictResolutionStrategy.useLocal:
          print('OfflineDataManager: Resolving conflict using local data');
          return localData;
          
        case ConflictResolutionStrategy.useRemote:
          print('OfflineDataManager: Resolving conflict using remote data');
          return remoteData;
          
        case ConflictResolutionStrategy.useLatest:
          final localTimestamp = DateTime.tryParse(localData['updated_at'] ?? localData['createdAt'] ?? '');
          final remoteTimestamp = DateTime.tryParse(remoteData['updated_at'] ?? remoteData['created_at'] ?? '');
          
          if (localTimestamp != null && remoteTimestamp != null) {
            if (localTimestamp.isAfter(remoteTimestamp)) {
              print('OfflineDataManager: Resolving conflict using local data (newer)');
              return localData;
            } else {
              print('OfflineDataManager: Resolving conflict using remote data (newer)');
              return remoteData;
            }
          }
          
          // Fallback to remote if timestamps are not available
          print('OfflineDataManager: Resolving conflict using remote data (fallback)');
          return remoteData;
          
        case ConflictResolutionStrategy.merge:
          print('OfflineDataManager: Resolving conflict by merging data');
          return _mergeData(localData, remoteData);
      }
    } catch (e) {
      print('OfflineDataManager: Error resolving conflict: $e');
      // Fallback to remote data on error
      return remoteData;
    }
  }

  /// Merge local and remote data intelligently
  Map<String, dynamic> _mergeData(Map<String, dynamic> localData, Map<String, dynamic> remoteData) {
    final merged = Map<String, dynamic>.from(remoteData);
    
    // Preserve local changes for specific fields
    final localPreferredFields = ['completionCount', 'lastCompleted', 'status'];
    
    for (final field in localPreferredFields) {
      if (localData.containsKey(field)) {
        merged[field] = localData[field];
      }
    }
    
    // Use latest timestamp
    final localTimestamp = DateTime.tryParse(localData['updated_at'] ?? '');
    final remoteTimestamp = DateTime.tryParse(remoteData['updated_at'] ?? '');
    
    if (localTimestamp != null && remoteTimestamp != null) {
      merged['updated_at'] = localTimestamp.isAfter(remoteTimestamp) 
          ? localData['updated_at'] 
          : remoteData['updated_at'];
    }
    
    return merged;
  }

  /// Check if device is online
  Future<bool> _isOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncString = prefs.getString(_lastSyncTimeKey);
      
      if (lastSyncString != null) {
        return DateTime.tryParse(lastSyncString);
      }
      
      return null;
    } catch (e) {
      print('OfflineDataManager: Error getting last sync time: $e');
      return null;
    }
  }

  /// Check if data needs sync (based on last sync time)
  Future<bool> needsSync() async {
    final lastSync = await getLastSyncTime();
    
    if (lastSync == null) {
      return true; // Never synced
    }
    
    final timeSinceSync = DateTime.now().difference(lastSync);
    return timeSinceSync.inHours >= 1; // Sync if more than 1 hour since last sync
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_cachedUserDataKey);
      await prefs.remove(_lastSyncTimeKey);
      await prefs.remove(_pendingSyncDataKey);
      await prefs.remove(_syncQueueKey);
      await prefs.remove(_conflictResolutionKey);
      await prefs.remove(_cachedRemindersKey);
      
      print('OfflineDataManager: All cached data cleared');
    } catch (e) {
      print('OfflineDataManager: Error clearing cache: $e');
    }
  }

  /// Get sync queue status
  Future<Map<String, dynamic>> getSyncQueueStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_syncQueueKey) ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueString));
      
      return {
        'totalItems': queue.length,
        'pendingInserts': queue.where((item) => item['operation'] == 'insert').length,
        'pendingUpdates': queue.where((item) => item['operation'] == 'update').length,
        'pendingDeletes': queue.where((item) => item['operation'] == 'delete').length,
        'oldestItem': queue.isNotEmpty ? queue.first['timestamp'] : null,
        'failedItems': queue.where((item) => (item['retryCount'] as int? ?? 0) > 0).length,
      };
    } catch (e) {
      print('OfflineDataManager: Error getting sync queue status: $e');
      return {
        'totalItems': 0,
        'pendingInserts': 0,
        'pendingUpdates': 0,
        'pendingDeletes': 0,
        'oldestItem': null,
        'failedItems': 0,
      };
    }
  }

  /// Detect conflicts between local and remote data
  Future<List<Map<String, dynamic>>> _detectConflicts(String table, Map<String, dynamic> localData) async {
    try {
      if (!localData.containsKey('id')) {
        return []; // No conflicts for data without ID
      }

      final remoteData = await _supabaseService.select(table, 
          filters: {'id': localData['id']});
      
      if (remoteData.isEmpty) {
        return []; // No remote data to conflict with
      }

      final remote = remoteData.first;
      final conflicts = <Map<String, dynamic>>[];

      // Check for timestamp conflicts
      final localTimestamp = DateTime.tryParse(localData['updated_at'] ?? '');
      final remoteTimestamp = DateTime.tryParse(remote['updated_at'] ?? '');

      if (localTimestamp != null && remoteTimestamp != null) {
        if (remoteTimestamp.isAfter(localTimestamp)) {
          conflicts.add({
            'type': 'timestamp_conflict',
            'field': 'updated_at',
            'localValue': localData['updated_at'],
            'remoteValue': remote['updated_at'],
            'remoteData': remote,
          });
        }
      }

      // Check for field-level conflicts
      for (final key in localData.keys) {
        if (key == 'id' || key == 'created_at') continue;
        
        if (remote.containsKey(key) && localData[key] != remote[key]) {
          conflicts.add({
            'type': 'field_conflict',
            'field': key,
            'localValue': localData[key],
            'remoteValue': remote[key],
            'remoteData': remote,
          });
        }
      }

      return conflicts;
    } catch (e) {
      print('OfflineDataManager: Error detecting conflicts: $e');
      return [];
    }
  }

  /// Automatically resolve conflicts using predefined strategies
  Future<Map<String, dynamic>?> _resolveConflictsAutomatically(
      Map<String, dynamic> localData, List<Map<String, dynamic>> conflicts) async {
    try {
      if (conflicts.isEmpty) return null;

      // Get the remote data from the first conflict
      final remoteData = conflicts.first['remoteData'] as Map<String, dynamic>;
      
      // Use merge strategy for automatic resolution
      return _mergeData(localData, remoteData);
    } catch (e) {
      print('OfflineDataManager: Error resolving conflicts automatically: $e');
      return null;
    }
  }

  /// Calculate exponential backoff delay in minutes
  int _calculateBackoffDelay(int retryCount) {
    // Exponential backoff: 1, 2, 4, 8, 16 minutes
    return (1 << (retryCount - 1)).clamp(1, 16);
  }

  /// Store failed sync item for manual review
  Future<void> _storeFailedSyncItem(Map<String, dynamic> item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final failedItemsString = prefs.getString('failed_sync_items') ?? '[]';
      final failedItems = List<Map<String, dynamic>>.from(jsonDecode(failedItemsString));
      
      failedItems.add({
        ...item,
        'failedAt': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString('failed_sync_items', jsonEncode(failedItems));
      print('OfflineDataManager: Stored failed sync item for manual review');
    } catch (e) {
      print('OfflineDataManager: Error storing failed sync item: $e');
    }
  }

  /// Cache reminders data for offline access
  Future<void> cacheReminders(List<Map<String, dynamic>> reminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final cachedData = {
        'reminders': reminders,
        'cached_at': DateTime.now().toIso8601String(),
        'cache_version': '1.0',
      };
      
      await prefs.setString(_cachedRemindersKey, jsonEncode(cachedData));
      print('OfflineDataManager: Cached ${reminders.length} reminders');
    } catch (e) {
      print('OfflineDataManager: Error caching reminders: $e');
    }
  }

  /// Get cached reminders
  Future<List<Map<String, dynamic>>> getCachedReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDataString = prefs.getString(_cachedRemindersKey);
      
      if (cachedDataString != null) {
        final cachedData = jsonDecode(cachedDataString) as Map<String, dynamic>;
        
        // Check if cache is still valid (within 6 hours)
        final cachedAt = DateTime.tryParse(cachedData['cached_at'] ?? '');
        if (cachedAt != null) {
          final cacheAge = DateTime.now().difference(cachedAt);
          if (cacheAge.inHours < 6) {
            return List<Map<String, dynamic>>.from(cachedData['reminders'] ?? []);
          } else {
            print('OfflineDataManager: Cached reminders expired');
            await prefs.remove(_cachedRemindersKey);
          }
        }
      }
      
      return [];
    } catch (e) {
      print('OfflineDataManager: Error retrieving cached reminders: $e');
      return [];
    }
  }

  /// Force sync all cached data
  Future<bool> forceSyncAll() async {
    try {
      if (!await _isOnline() || !_supabaseService.isInitialized) {
        print('OfflineDataManager: Cannot force sync - offline or Supabase not available');
        return false;
      }

      print('OfflineDataManager: Starting force sync of all data');
      
      // Process sync queue
      await processSyncQueue();
      
      // Sync user data if authenticated
      if (_authService.isLoggedIn && !_authService.isGuestMode) {
        await _syncUserDataFromRemote();
      }
      
      // Update last sync time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncTimeKey, DateTime.now().toIso8601String());
      
      print('OfflineDataManager: Force sync completed successfully');
      return true;
    } catch (e) {
      print('OfflineDataManager: Error during force sync: $e');
      return false;
    }
  }

  /// Sync user data from remote
  Future<void> _syncUserDataFromRemote() async {
    try {
      final currentUser = _supabaseService.getCurrentUser();
      if (currentUser == null) return;

      final profile = await _supabaseService.getUserProfile(currentUser.id);
      if (profile != null) {
        final userData = {
          'id': currentUser.id,
          'email': currentUser.email ?? '',
          'name': profile['name'] ?? profile['display_name'] ?? '',
          'supabaseUser': true,
          'isGuest': false,
          'lastSyncAt': DateTime.now().toIso8601String(),
        };
        
        await cacheUserData(userData);
        print('OfflineDataManager: User data synced from remote');
      }
    } catch (e) {
      print('OfflineDataManager: Error syncing user data from remote: $e');
    }
  }
}

/// Enum for conflict resolution strategies
enum ConflictResolutionStrategy {
  useLocal,
  useRemote,
  useLatest,
  merge,
} 