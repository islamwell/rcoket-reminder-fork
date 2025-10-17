import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/core/services/error_handling_service.dart';

void main() {
  group('ErrorHandlingService', () {
    late ErrorHandlingService errorHandlingService;

    setUp(() async {
      // Initialize SharedPreferences with mock data
      SharedPreferences.setMockInitialValues({});
      errorHandlingService = ErrorHandlingService.instance;
      await errorHandlingService.initialize();
    });

    tearDown(() {
      errorHandlingService.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        expect(errorHandlingService, isNotNull);
        expect(errorHandlingService.isInFallbackMode, isFalse);
      });

      test('should load fallback mode status from storage', () async {
        // Set fallback mode in storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('fallback_mode', true);
        
        // Use singleton instance to test loading
        final newService = ErrorHandlingService.instance;
        await newService.initialize();
        
        expect(newService.isInFallbackMode, isTrue);
        newService.dispose();
      });
    });

    group('Fallback Mode Management', () {
      test('should enable fallback mode with reason', () async {
        await errorHandlingService.setFallbackMode(true, reason: 'Test reason');
        
        expect(errorHandlingService.isInFallbackMode, isTrue);
        
        // Verify it's persisted
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('fallback_mode'), isTrue);
      });

      test('should disable fallback mode', () async {
        await errorHandlingService.setFallbackMode(true, reason: 'Enable test');
        await errorHandlingService.setFallbackMode(false, reason: 'Disable test');
        
        expect(errorHandlingService.isInFallbackMode, isFalse);
        
        // Verify it's persisted
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('fallback_mode'), isFalse);
      });
    });

    group('Permission Handling', () {
      testWidgets('should handle permission denied for notifications', (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await errorHandlingService.handlePermissionDenied(
                      PermissionType.notifications,
                      context,
                    );
                  },
                  child: Text('Test Permission'),
                ),
              );
            },
          ),
        ));

        // Tap the button to trigger permission handling
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Should show permission dialog
        expect(find.text('Permission Required'), findsOneWidget);
        expect(find.text('Notification Permission Denied'), findsOneWidget);
        
        // Should enable fallback mode for notification permissions
        expect(errorHandlingService.isInFallbackMode, isTrue);
      });

      test('should handle permission denied without context', () async {
        final result = await errorHandlingService.handlePermissionDenied(
          PermissionType.backgroundProcessing,
          null,
        );
        
        expect(result, equals(PermissionHandlingResult.handled));
      });
    });

    group('Retry Mechanism', () {
      test('should retry operation and succeed', () async {
        int attemptCount = 0;
        
        final result = await errorHandlingService.retryOperation(
          'test_operation',
          () async {
            attemptCount++;
            if (attemptCount < 3) {
              throw Exception('Test failure');
            }
            return 'success';
          },
          maxAttempts: 3,
        );
        
        expect(result, equals('success'));
        expect(attemptCount, equals(3));
      });

      test('should fail after max attempts', () async {
        int attemptCount = 0;
        
        expect(
          () async => await errorHandlingService.retryOperation(
            'failing_operation',
            () async {
              attemptCount++;
              throw Exception('Always fails');
            },
            maxAttempts: 2,
          ),
          throwsException,
        );
        
        expect(attemptCount, equals(2));
      });

      test('should use exponential backoff', () async {
        final stopwatch = Stopwatch()..start();
        int attemptCount = 0;
        
        try {
          await errorHandlingService.retryOperation(
            'backoff_test',
            () async {
              attemptCount++;
              throw Exception('Test failure');
            },
            maxAttempts: 3,
            delay: Duration(milliseconds: 100),
            exponentialBackoff: true,
          );
        } catch (e) {
          // Expected to fail
        }
        
        stopwatch.stop();
        
        // Should take at least 100ms + 150ms = 250ms for 3 attempts
        expect(stopwatch.elapsedMilliseconds, greaterThan(200));
        expect(attemptCount, equals(3));
      });
    });

    group('Error Logging', () {
      test('should log error with metadata', () async {
        await errorHandlingService.logError(
          'TEST_ERROR',
          'Test error message',
          severity: ErrorSeverity.warning,
          metadata: {'key': 'value'},
        );
        
        final logs = await errorHandlingService.getErrorLogs();
        expect(logs.length, greaterThan(0));
        
        final lastLog = logs.last;
        expect(lastLog.code, equals('TEST_ERROR'));
        expect(lastLog.message, equals('Test error message'));
        expect(lastLog.severity, equals(ErrorSeverity.warning));
        expect(lastLog.metadata['key'], equals('value'));
      });

      test('should limit log entries', () async {
        // Add more than max entries
        for (int i = 0; i < 105; i++) {
          await errorHandlingService.logError(
            'TEST_ERROR_$i',
            'Test message $i',
          );
        }
        
        final logs = await errorHandlingService.getErrorLogs();
        expect(logs.length, lessThanOrEqualTo(100));
      });

      test('should clear error logs', () async {
        await errorHandlingService.logError('TEST', 'Test message');
        
        var logs = await errorHandlingService.getErrorLogs();
        expect(logs.length, greaterThan(0));
        
        await errorHandlingService.clearErrorLogs();
        
        logs = await errorHandlingService.getErrorLogs();
        expect(logs.length, equals(0));
      });
    });

    group('System Health Status', () {
      test('should return healthy status with no errors', () async {
        final status = await errorHandlingService.getSystemHealthStatus();
        
        expect(status.level, equals(HealthLevel.healthy));
        expect(status.isInFallbackMode, isFalse);
        expect(status.recentErrorCount, equals(0));
        expect(status.criticalErrorCount, equals(0));
      });

      test('should return warning status with errors', () async {
        // Add some errors
        await errorHandlingService.logError('ERROR1', 'Error 1', severity: ErrorSeverity.error);
        await errorHandlingService.logError('ERROR2', 'Error 2', severity: ErrorSeverity.warning);
        
        final status = await errorHandlingService.getSystemHealthStatus();
        
        expect(status.level, equals(HealthLevel.warning));
        expect(status.criticalErrorCount, equals(1));
        expect(status.warningCount, equals(1));
      });

      test('should return critical status with many errors', () async {
        // Add many critical errors
        for (int i = 0; i < 6; i++) {
          await errorHandlingService.logError('CRITICAL_$i', 'Critical error $i', severity: ErrorSeverity.error);
        }
        
        final status = await errorHandlingService.getSystemHealthStatus();
        
        expect(status.level, equals(HealthLevel.critical));
        expect(status.criticalErrorCount, equals(6));
      });

      test('should return degraded status in fallback mode', () async {
        await errorHandlingService.setFallbackMode(true, reason: 'Test');
        
        final status = await errorHandlingService.getSystemHealthStatus();
        
        expect(status.level, equals(HealthLevel.degraded));
        expect(status.isInFallbackMode, isTrue);
      });
    });

    group('Error Event Listeners', () {
      test('should notify listeners of error events', () async {
        ErrorEvent? receivedEvent;
        
        final subscription = errorHandlingService.addErrorListener((event) {
          receivedEvent = event;
        });
        
        await errorHandlingService.logError(
          'LISTENER_TEST',
          'Test message for listener',
          severity: ErrorSeverity.info,
        );
        
        // Give some time for the event to be processed
        await Future.delayed(Duration(milliseconds: 10));
        
        expect(receivedEvent, isNotNull);
        expect(receivedEvent!.message, equals('Test message for listener'));
        expect(receivedEvent!.severity, equals(ErrorSeverity.info));
        
        await subscription.cancel();
      });

      test('should notify listeners of fallback mode changes', () async {
        ErrorEvent? receivedEvent;
        
        final subscription = errorHandlingService.addErrorListener((event) {
          if (event.type == ErrorType.fallbackMode) {
            receivedEvent = event;
          }
        });
        
        await errorHandlingService.setFallbackMode(true, reason: 'Test fallback');
        
        // Give some time for the event to be processed
        await Future.delayed(Duration(milliseconds: 10));
        
        expect(receivedEvent, isNotNull);
        expect(receivedEvent!.type, equals(ErrorType.fallbackMode));
        expect(receivedEvent!.metadata?['fallbackMode'], isTrue);
        
        await subscription.cancel();
      });
    });

    group('Error Log Entry Serialization', () {
      test('should serialize and deserialize error log entry', () {
        final originalEntry = ErrorLogEntry(
          code: 'TEST_CODE',
          message: 'Test message',
          severity: ErrorSeverity.warning,
          timestamp: DateTime.now(),
          metadata: {'key': 'value', 'number': 42},
          stackTrace: 'Stack trace here',
        );
        
        final json = originalEntry.toJson();
        final deserializedEntry = ErrorLogEntry.fromJson(json);
        
        expect(deserializedEntry.code, equals(originalEntry.code));
        expect(deserializedEntry.message, equals(originalEntry.message));
        expect(deserializedEntry.severity, equals(originalEntry.severity));
        expect(deserializedEntry.metadata['key'], equals('value'));
        expect(deserializedEntry.metadata['number'], equals(42));
        expect(deserializedEntry.stackTrace, equals(originalEntry.stackTrace));
      });
    });
  });
}