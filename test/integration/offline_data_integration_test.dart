import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/core/services/offline_data_manager.dart';

void main() {
  group('Offline Data Integration Tests', () {
    late OfflineDataManager offlineDataManager;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      offlineDataManager = OfflineDataManager.instance;
    });

    tearDown(() async {
      // Clear all cached data after each test
      await offlineDataManager.clearCache();
    });

    test('should handle complete offline workflow', () async {
      // Simulate user going offline and performing operations
      
      // 1. Cache initial user data
      final userData = {
        'id': 'user123',
        'name': 'Test User',
        'email': 'test@example.com',
        'isGuest': false,
      };
      await offlineDataManager.cacheUserData(userData);
      
      // 2. Cache some reminders
      final reminders = [
        {'id': 1, 'title': 'Morning Prayer', 'category': 'Spiritual'},
        {'id': 2, 'title': 'Read Quran', 'category': 'Spiritual'},
      ];
      await offlineDataManager.cacheReminders(reminders);
      
      // 3. Perform offline operations
      await offlineDataManager.addToSyncQueue('insert', 'reminders', 
          {'title': 'New Offline Reminder', 'category': 'Personal'});
      await offlineDataManager.addToSyncQueue('update', 'reminders', 
          {'id': 1, 'title': 'Updated Morning Prayer', 'category': 'Spiritual'});
      await offlineDataManager.addToSyncQueue('delete', 'reminders', 
          {'id': 2});
      
      // 4. Verify offline data is accessible
      final cachedUser = await offlineDataManager.getCachedUserData();
      expect(cachedUser, isNotNull);
      expect(cachedUser!['name'], equals('Test User'));
      
      final cachedReminders = await offlineDataManager.getCachedReminders();
      expect(cachedReminders.length, equals(2));
      
      // 5. Verify sync queue has operations
      final syncStatus = await offlineDataManager.getSyncQueueStatus();
      expect(syncStatus['totalItems'], equals(3));
      expect(syncStatus['pendingInserts'], equals(1));
      expect(syncStatus['pendingUpdates'], equals(1));
      expect(syncStatus['pendingDeletes'], equals(1));
      
      // 6. Simulate coming back online (sync would normally happen here)
      // In a real scenario, processSyncQueue() would be called when online
      expect(await offlineDataManager.needsSync(), isTrue);
    });

    test('should handle conflict resolution scenarios', () async {
      // Test conflict resolution between local and remote data
      final localData = {
        'id': 1,
        'title': 'Local Title',
        'completionCount': 5,
        'status': 'active',
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final remoteData = {
        'id': 1,
        'title': 'Remote Title',
        'category': 'Remote Category',
        'completionCount': 3,
        'status': 'paused',
        'updated_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
      };

      // Test different conflict resolution strategies
      var resolved = await offlineDataManager.resolveConflict(
        localData, remoteData, ConflictResolutionStrategy.useLocal);
      expect(resolved['title'], equals('Local Title'));

      resolved = await offlineDataManager.resolveConflict(
        localData, remoteData, ConflictResolutionStrategy.useRemote);
      expect(resolved['title'], equals('Remote Title'));

      resolved = await offlineDataManager.resolveConflict(
        localData, remoteData, ConflictResolutionStrategy.useLatest);
      expect(resolved['title'], equals('Local Title')); // Local is newer

      resolved = await offlineDataManager.resolveConflict(
        localData, remoteData, ConflictResolutionStrategy.merge);
      expect(resolved['title'], equals('Remote Title')); // Remote base
      expect(resolved['completionCount'], equals(5)); // Local preferred field
      expect(resolved['status'], equals('active')); // Local preferred field
    });

    test('should handle data persistence across sessions', () async {
      // Simulate data being saved in one session
      final sessionData = {
        'reminders': [
          {'id': 1, 'title': 'Session Reminder 1'},
          {'id': 2, 'title': 'Session Reminder 2'},
        ],
        'syncQueue': [
          {
            'operation': 'insert',
            'table': 'reminders',
            'data': {'title': 'Pending Insert'},
          }
        ]
      };

      // Cache data
      await offlineDataManager.cacheReminders(sessionData['reminders'] as List<Map<String, dynamic>>);
      await offlineDataManager.addToSyncQueue('insert', 'reminders', {'title': 'Pending Insert'});

      // Verify data is accessible
      final cachedReminders = await offlineDataManager.getCachedReminders();
      expect(cachedReminders.length, equals(2));

      final syncStatus = await offlineDataManager.getSyncQueueStatus();
      expect(syncStatus['totalItems'], equals(1));

      // Simulate new session - data should still be there
      // (SharedPreferences mock maintains data within test)
      final newSessionReminders = await offlineDataManager.getCachedReminders();
      expect(newSessionReminders.length, equals(2));

      final newSessionSyncStatus = await offlineDataManager.getSyncQueueStatus();
      expect(newSessionSyncStatus['totalItems'], equals(1));
    });

    test('should handle cache expiration correctly', () async {
      // Test user data cache expiration (24 hours)
      final userData = {'id': 'user123', 'name': 'Test User'};
      await offlineDataManager.cacheUserData(userData);

      // Verify data is cached
      expect(await offlineDataManager.getCachedUserData(), isNotNull);

      // Manually set expired timestamp
      final prefs = await SharedPreferences.getInstance();
      final expiredUserData = {
        'id': 'user123',
        'name': 'Test User',
        'cached_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'cache_version': '1.0',
      };
      await prefs.setString('cached_user_data', jsonEncode(expiredUserData));

      // Should return null for expired data
      expect(await offlineDataManager.getCachedUserData(), isNull);

      // Test reminder cache expiration (6 hours)
      final reminders = [{'id': 1, 'title': 'Test Reminder'}];
      await offlineDataManager.cacheReminders(reminders);

      // Verify data is cached
      expect((await offlineDataManager.getCachedReminders()).isNotEmpty, isTrue);

      // Manually set expired timestamp
      final expiredReminderData = {
        'reminders': reminders,
        'cached_at': DateTime.now().subtract(Duration(hours: 7)).toIso8601String(),
        'cache_version': '1.0',
      };
      await prefs.setString('cached_reminders', jsonEncode(expiredReminderData));

      // Should return empty list for expired data
      expect(await offlineDataManager.getCachedReminders(), isEmpty);
    });

    test('should handle sync queue retry logic', () async {
      // Add item to sync queue
      await offlineDataManager.addToSyncQueue('insert', 'reminders', 
          {'title': 'Test Reminder'});

      // Simulate failed sync by manually updating retry count
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString('sync_queue') ?? '[]';
      final queue = List<Map<String, dynamic>>.from(jsonDecode(queueString));
      
      // Update first item with retry information
      queue[0]['retryCount'] = 3;
      queue[0]['lastError'] = 'Network timeout';
      queue[0]['nextRetryAt'] = DateTime.now().add(Duration(minutes: 8)).toIso8601String();
      await prefs.setString('sync_queue', jsonEncode(queue));

      // Check sync status includes failed items
      final status = await offlineDataManager.getSyncQueueStatus();
      expect(status['totalItems'], equals(1));
      expect(status['failedItems'], equals(1));
    });
  });
}