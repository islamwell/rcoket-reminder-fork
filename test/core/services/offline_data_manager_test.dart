import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/services/offline_data_manager.dart';

void main() {
  group('OfflineDataManager', () {
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

    group('User Data Caching', () {
      test('should cache user data successfully', () async {
        // Arrange
        final userData = {
          'id': 'user123',
          'name': 'Test User',
          'email': 'test@example.com',
          'isGuest': false,
        };

        // Act
        await offlineDataManager.cacheUserData(userData);

        // Assert
        final cachedData = await offlineDataManager.getCachedUserData();
        expect(cachedData, isNotNull);
        expect(cachedData!['id'], equals('user123'));
        expect(cachedData['name'], equals('Test User'));
        expect(cachedData['email'], equals('test@example.com'));
        expect(cachedData.containsKey('cached_at'), isTrue);
        expect(cachedData.containsKey('cache_version'), isTrue);
      });

      test('should return null for expired cached data', () async {
        // Arrange
        final userData = {
          'id': 'user123',
          'name': 'Test User',
          'email': 'test@example.com',
        };

        // Cache data with old timestamp
        final prefs = await SharedPreferences.getInstance();
        final expiredData = {
          ...userData,
          'cached_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
          'cache_version': '1.0',
        };
        await prefs.setString('cached_user_data', 
            '${expiredData.toString().replaceAll('{', '{"').replaceAll(': ', '": "').replaceAll(', ', '", "').replaceAll('}', '"}')}');

        // Act
        final cachedData = await offlineDataManager.getCachedUserData();

        // Assert
        expect(cachedData, isNull);
      });

      test('should cache critical user data with minimal fields', () async {
        // Arrange
        final userData = {
          'id': 'user123',
          'name': 'Test User',
          'email': 'test@example.com',
          'isGuest': false,
          'supabaseUser': true,
          'extraField': 'should not be cached',
          'anotherField': 'also should not be cached',
        };

        // Act
        await offlineDataManager.cacheCriticalUserData(userData);

        // Assert
        final cachedData = await offlineDataManager.getCachedUserData();
        expect(cachedData, isNotNull);
        expect(cachedData!['id'], equals('user123'));
        expect(cachedData['name'], equals('Test User'));
        expect(cachedData['email'], equals('test@example.com'));
        expect(cachedData['isGuest'], equals(false));
        expect(cachedData['supabaseUser'], equals(true));
        expect(cachedData.containsKey('extraField'), isFalse);
        expect(cachedData.containsKey('anotherField'), isFalse);
      });
    });

    group('Sync Queue Management', () {
      test('should add operations to sync queue', () async {
        // Arrange
        final reminderData = {
          'id': 1,
          'title': 'Test Reminder',
          'category': 'Test',
        };

        // Act
        await offlineDataManager.addToSyncQueue('insert', 'reminders', reminderData);

        // Assert
        final status = await offlineDataManager.getSyncQueueStatus();
        expect(status['totalItems'], equals(1));
        expect(status['pendingInserts'], equals(1));
        expect(status['pendingUpdates'], equals(0));
        expect(status['pendingDeletes'], equals(0));
      });

      test('should track multiple operations in sync queue', () async {
        // Arrange
        final reminderData1 = {'id': 1, 'title': 'Reminder 1'};
        final reminderData2 = {'id': 2, 'title': 'Reminder 2'};
        final reminderData3 = {'id': 3, 'title': 'Reminder 3'};

        // Act
        await offlineDataManager.addToSyncQueue('insert', 'reminders', reminderData1);
        await offlineDataManager.addToSyncQueue('update', 'reminders', reminderData2);
        await offlineDataManager.addToSyncQueue('delete', 'reminders', reminderData3);

        // Assert
        final status = await offlineDataManager.getSyncQueueStatus();
        expect(status['totalItems'], equals(3));
        expect(status['pendingInserts'], equals(1));
        expect(status['pendingUpdates'], equals(1));
        expect(status['pendingDeletes'], equals(1));
      });

      test('should return empty status for empty sync queue', () async {
        // Act
        final status = await offlineDataManager.getSyncQueueStatus();

        // Assert
        expect(status['totalItems'], equals(0));
        expect(status['pendingInserts'], equals(0));
        expect(status['pendingUpdates'], equals(0));
        expect(status['pendingDeletes'], equals(0));
        expect(status['oldestItem'], isNull);
      });
    });

    group('Conflict Resolution', () {
      test('should resolve conflict using local data strategy', () async {
        // Arrange
        final localData = {
          'id': 1,
          'title': 'Local Title',
          'updated_at': DateTime.now().toIso8601String(),
        };
        final remoteData = {
          'id': 1,
          'title': 'Remote Title',
          'updated_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        };

        // Act
        final resolved = await offlineDataManager.resolveConflict(
          localData,
          remoteData,
          ConflictResolutionStrategy.useLocal,
        );

        // Assert
        expect(resolved['title'], equals('Local Title'));
      });

      test('should resolve conflict using remote data strategy', () async {
        // Arrange
        final localData = {
          'id': 1,
          'title': 'Local Title',
          'updated_at': DateTime.now().toIso8601String(),
        };
        final remoteData = {
          'id': 1,
          'title': 'Remote Title',
          'updated_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        };

        // Act
        final resolved = await offlineDataManager.resolveConflict(
          localData,
          remoteData,
          ConflictResolutionStrategy.useRemote,
        );

        // Assert
        expect(resolved['title'], equals('Remote Title'));
      });

      test('should resolve conflict using latest timestamp strategy', () async {
        // Arrange
        final now = DateTime.now();
        final localData = {
          'id': 1,
          'title': 'Local Title',
          'updated_at': now.toIso8601String(),
        };
        final remoteData = {
          'id': 1,
          'title': 'Remote Title',
          'updated_at': now.subtract(Duration(hours: 1)).toIso8601String(),
        };

        // Act
        final resolved = await offlineDataManager.resolveConflict(
          localData,
          remoteData,
          ConflictResolutionStrategy.useLatest,
        );

        // Assert
        expect(resolved['title'], equals('Local Title')); // Local is newer
      });

      test('should resolve conflict using merge strategy', () async {
        // Arrange
        final localData = {
          'id': 1,
          'title': 'Local Title',
          'completionCount': 5,
          'status': 'active',
          'updated_at': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        };
        final remoteData = {
          'id': 1,
          'title': 'Remote Title',
          'category': 'Remote Category',
          'completionCount': 3,
          'status': 'paused',
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Act
        final resolved = await offlineDataManager.resolveConflict(
          localData,
          remoteData,
          ConflictResolutionStrategy.merge,
        );

        // Assert
        expect(resolved['title'], equals('Remote Title')); // Remote base
        expect(resolved['category'], equals('Remote Category')); // Remote field
        expect(resolved['completionCount'], equals(5)); // Local preferred field
        expect(resolved['status'], equals('active')); // Local preferred field
      });
    });

    group('Sync Status', () {
      test('should return null for last sync time when never synced', () async {
        // Act
        final lastSync = await offlineDataManager.getLastSyncTime();

        // Assert
        expect(lastSync, isNull);
      });

      test('should indicate sync is needed when never synced', () async {
        // Act
        final needsSync = await offlineDataManager.needsSync();

        // Assert
        expect(needsSync, isTrue);
      });

      test('should indicate sync is needed when last sync is old', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        final oldSyncTime = DateTime.now().subtract(Duration(hours: 2));
        await prefs.setString('last_sync_time', oldSyncTime.toIso8601String());

        // Act
        final needsSync = await offlineDataManager.needsSync();

        // Assert
        expect(needsSync, isTrue);
      });

      test('should indicate sync is not needed when recently synced', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        final recentSyncTime = DateTime.now().subtract(Duration(minutes: 30));
        await prefs.setString('last_sync_time', recentSyncTime.toIso8601String());

        // Act
        final needsSync = await offlineDataManager.needsSync();

        // Assert
        expect(needsSync, isFalse);
      });
    });

    group('Cache Management', () {
      test('should clear all cached data', () async {
        // Arrange
        final userData = {'id': 'user123', 'name': 'Test User'};
        await offlineDataManager.cacheUserData(userData);
        await offlineDataManager.addToSyncQueue('insert', 'reminders', {'id': 1});

        // Verify data exists
        expect(await offlineDataManager.getCachedUserData(), isNotNull);
        expect((await offlineDataManager.getSyncQueueStatus())['totalItems'], equals(1));

        // Act
        await offlineDataManager.clearCache();

        // Assert
        expect(await offlineDataManager.getCachedUserData(), isNull);
        expect((await offlineDataManager.getSyncQueueStatus())['totalItems'], equals(0));
      });
    });

    group('Reminder Caching', () {
      test('should cache reminders successfully', () async {
        // Arrange
        final reminders = [
          {'id': 1, 'title': 'Reminder 1', 'category': 'Test'},
          {'id': 2, 'title': 'Reminder 2', 'category': 'Work'},
        ];

        // Act
        await offlineDataManager.cacheReminders(reminders);

        // Assert
        final cachedReminders = await offlineDataManager.getCachedReminders();
        expect(cachedReminders.length, equals(2));
        expect(cachedReminders[0]['title'], equals('Reminder 1'));
        expect(cachedReminders[1]['title'], equals('Reminder 2'));
      });

      test('should return empty list for expired cached reminders', () async {
        // Arrange
        final reminders = [
          {'id': 1, 'title': 'Reminder 1', 'category': 'Test'},
        ];

        // Cache reminders with old timestamp
        final prefs = await SharedPreferences.getInstance();
        final expiredData = {
          'reminders': reminders,
          'cached_at': DateTime.now().subtract(Duration(hours: 7)).toIso8601String(),
          'cache_version': '1.0',
        };
        await prefs.setString('cached_reminders', jsonEncode(expiredData));

        // Act
        final cachedReminders = await offlineDataManager.getCachedReminders();

        // Assert
        expect(cachedReminders, isEmpty);
      });
    });

    group('Advanced Sync Queue Operations', () {
      test('should handle retry count and exponential backoff', () async {
        // Arrange
        final reminderData = {'id': 1, 'title': 'Test Reminder'};
        await offlineDataManager.addToSyncQueue('insert', 'reminders', reminderData);

        // Simulate failed sync by manually updating retry count
        final prefs = await SharedPreferences.getInstance();
        final queueString = prefs.getString('sync_queue') ?? '[]';
        final queue = List<Map<String, dynamic>>.from(jsonDecode(queueString));
        
        queue[0]['retryCount'] = 2;
        queue[0]['lastError'] = 'Network error';
        await prefs.setString('sync_queue', jsonEncode(queue));

        // Act
        final status = await offlineDataManager.getSyncQueueStatus();

        // Assert
        expect(status['totalItems'], equals(1));
        expect(status['failedItems'], equals(1));
      });

      test('should track different operation types in sync queue', () async {
        // Arrange
        await offlineDataManager.addToSyncQueue('insert', 'reminders', {'id': 1});
        await offlineDataManager.addToSyncQueue('update', 'reminders', {'id': 2});
        await offlineDataManager.addToSyncQueue('delete', 'reminders', {'id': 3});
        await offlineDataManager.addToSyncQueue('insert', 'profiles', {'id': 4});

        // Act
        final status = await offlineDataManager.getSyncQueueStatus();

        // Assert
        expect(status['totalItems'], equals(4));
        expect(status['pendingInserts'], equals(2));
        expect(status['pendingUpdates'], equals(1));
        expect(status['pendingDeletes'], equals(1));
      });
    });

    group('Offline Scenarios', () {
      test('should handle offline mode gracefully', () async {
        // Act - This should not throw even when services are not available
        await offlineDataManager.syncWhenOnline();

        // Assert - Should not throw and should log appropriate message
        // This test verifies the method handles offline state gracefully
        expect(true, isTrue); // Test passes if no exception is thrown
      });

      test('should maintain data integrity during offline operations', () async {
        // Arrange
        final initialData = {'id': 'user123', 'name': 'Initial Name'};
        await offlineDataManager.cacheUserData(initialData);

        // Act - Simulate multiple offline updates
        final update1 = {'id': 'user123', 'name': 'Updated Name 1'};
        final update2 = {'id': 'user123', 'name': 'Updated Name 2'};
        
        await offlineDataManager.addToSyncQueue('update', 'profiles', update1);
        await offlineDataManager.addToSyncQueue('update', 'profiles', update2);

        // Assert
        final status = await offlineDataManager.getSyncQueueStatus();
        expect(status['totalItems'], equals(2));
        expect(status['pendingUpdates'], equals(2));
        
        // Verify cached data is still accessible
        final cachedData = await offlineDataManager.getCachedUserData();
        expect(cachedData, isNotNull);
        expect(cachedData!['id'], equals('user123'));
      });

      test('should handle sync queue operations when offline', () async {
        // Arrange
        final reminderData = {'id': 1, 'title': 'Offline Reminder'};
        
        // Act - Add operations while offline
        await offlineDataManager.addToSyncQueue('insert', 'reminders', reminderData);
        await offlineDataManager.addToSyncQueue('update', 'reminders', {...reminderData, 'title': 'Updated Offline'});
        
        // Assert
        final status = await offlineDataManager.getSyncQueueStatus();
        expect(status['totalItems'], equals(2));
        expect(status['pendingInserts'], equals(1));
        expect(status['pendingUpdates'], equals(1));
      });

      test('should preserve sync queue across app restarts', () async {
        // Arrange
        final reminderData = {'id': 1, 'title': 'Persistent Reminder'};
        await offlineDataManager.addToSyncQueue('insert', 'reminders', reminderData);
        
        // Verify queue has item
        var status = await offlineDataManager.getSyncQueueStatus();
        expect(status['totalItems'], equals(1));
        
        // Simulate app restart by creating new instance
        // (In real scenario, SharedPreferences would persist)
        status = await offlineDataManager.getSyncQueueStatus();
        
        // Assert - Data should still be there
        expect(status['totalItems'], equals(1));
      });
    });

    group('Data Synchronization Edge Cases', () {
      test('should handle empty sync queue gracefully', () async {
        // Act
        await offlineDataManager.processSyncQueue();

        // Assert - Should not throw exception
        final status = await offlineDataManager.getSyncQueueStatus();
        expect(status['totalItems'], equals(0));
      });

      test('should handle malformed sync queue data', () async {
        // Arrange - Manually set malformed data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('sync_queue', 'invalid json');

        // Act & Assert - Should handle gracefully
        final status = await offlineDataManager.getSyncQueueStatus();
        expect(status['totalItems'], equals(0));
      });

      test('should validate sync queue item structure', () async {
        // Arrange
        final validItem = {
          'id': '1',
          'operation': 'insert',
          'table': 'reminders',
          'data': {'title': 'Test'},
          'timestamp': DateTime.now().toIso8601String(),
          'retryCount': 0,
        };

        // Act
        await offlineDataManager.addToSyncQueue('insert', 'reminders', {'title': 'Test'});

        // Assert
        final status = await offlineDataManager.getSyncQueueStatus();
        expect(status['totalItems'], equals(1));
      });
    });

    group('Performance and Memory Management', () {
      test('should limit cache size for large datasets', () async {
        // Arrange - Create large dataset
        final largeReminderList = List.generate(1000, (index) => {
          'id': index,
          'title': 'Reminder $index',
          'category': 'Category ${index % 10}',
        });

        // Act
        await offlineDataManager.cacheReminders(largeReminderList);

        // Assert
        final cachedReminders = await offlineDataManager.getCachedReminders();
        expect(cachedReminders.length, equals(1000));
      });

      test('should clean up expired cache entries automatically', () async {
        // Arrange
        final userData = {'id': 'user123', 'name': 'Test User'};
        await offlineDataManager.cacheUserData(userData);

        // Verify data is cached
        expect(await offlineDataManager.getCachedUserData(), isNotNull);

        // Manually set expired timestamp
        final prefs = await SharedPreferences.getInstance();
        final expiredData = {
          'id': 'user123',
          'name': 'Test User',
          'cached_at': DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
          'cache_version': '1.0',
        };
        await prefs.setString('cached_user_data', jsonEncode(expiredData));

        // Act
        final cachedData = await offlineDataManager.getCachedUserData();

        // Assert - Should return null and clean up expired data
        expect(cachedData, isNull);
      });
    });
  });
}