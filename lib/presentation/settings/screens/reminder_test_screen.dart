import 'package:flutter/material.dart';
import '../../../core/services/reminder_test_helper.dart';

/// Screen for testing reminder and notification functionality
/// This screen provides UI controls to test fullscreen reminders
class ReminderTestScreen extends StatefulWidget {
  const ReminderTestScreen({super.key});

  @override
  State<ReminderTestScreen> createState() => _ReminderTestScreenState();
}

class _ReminderTestScreenState extends State<ReminderTestScreen> {
  final _testHelper = ReminderTestHelper.instance;
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _notificationStatus;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking notification status...';
    });

    try {
      final status = await _testHelper.checkNotificationStatus();
      setState(() {
        _notificationStatus = status;
        _statusMessage = 'Status updated';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestReminder(int delaySeconds) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating test reminder...';
    });

    try {
      final reminder = await _testHelper.createTestReminder(
        title: 'Test Fullscreen Reminder',
        category: 'Test',
        description: 'This is a test to verify fullscreen notifications work properly',
        delaySeconds: delaySeconds,
      );

      if (reminder != null) {
        setState(() {
          _statusMessage = 'Test reminder created! Will trigger in ${delaySeconds}s';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test reminder will trigger in ${delaySeconds} seconds'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        setState(() {
          _statusMessage = 'Failed to create test reminder';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerReminder() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Triggering reminder...';
    });

    try {
      await _testHelper.triggerFirstActiveReminder();
      setState(() {
        _statusMessage = 'Reminder triggered!';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reminder triggered manually'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Requesting permissions...';
    });

    try {
      final granted = await _testHelper.requestPermissions();
      setState(() {
        _statusMessage = granted ? 'Permissions granted' : 'Permissions denied';
      });

      await _checkStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? 'Permissions granted!' : 'Permissions denied'),
          backgroundColor: granted ? Colors.green : Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTestReminders() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting test reminders...';
    });

    try {
      await _testHelper.deleteAllTestReminders();
      setState(() {
        _statusMessage = 'All test reminders deleted';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test reminders deleted'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _printTestReport() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating test report...';
    });

    try {
      await _testHelper.printTestReport();
      setState(() {
        _statusMessage = 'Test report printed to console';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check console for test report'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Reminder Test Utilities'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: theme.colorScheme.primary),
                          SizedBox(width: 8),
                          Text(
                            'Notification Status',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 24),
                      if (_notificationStatus != null) ...[
                        _buildStatusRow(
                          'Notifications Enabled',
                          _notificationStatus!['notificationsEnabled'] ?? false,
                        ),
                        _buildStatusRow(
                          'Native Notifications',
                          _notificationStatus!['nativeNotificationsEnabled'] ?? false,
                        ),
                        _buildStatusRow(
                          'Fallback Mode',
                          _notificationStatus!['isInFallbackMode'] ?? false,
                          isWarning: true,
                        ),
                      ] else ...[
                        Center(
                          child: CircularProgressIndicator(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Test Actions Section
              Text(
                'Test Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),

              // Create Test Reminder Buttons
              _buildActionCard(
                icon: Icons.alarm_add,
                title: 'Create Test Reminder',
                description: 'Create a reminder that will trigger after a delay',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _createTestReminder(10),
                          child: Text('10s'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _createTestReminder(30),
                          child: Text('30s'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _createTestReminder(60),
                          child: Text('60s'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Trigger Reminder
              _buildActionCard(
                icon: Icons.notifications_active,
                title: 'Trigger Reminder Now',
                description: 'Manually trigger the first active reminder',
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _triggerReminder,
                      icon: Icon(Icons.play_arrow),
                      label: Text('Trigger Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Request Permissions
              _buildActionCard(
                icon: Icons.security,
                title: 'Request Permissions',
                description: 'Request notification and full screen intent permissions',
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _requestPermissions,
                      icon: Icon(Icons.check_circle),
                      label: Text('Request Permissions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Cleanup Actions
              _buildActionCard(
                icon: Icons.cleaning_services,
                title: 'Cleanup',
                description: 'Delete all test reminders',
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _deleteTestReminders,
                      icon: Icon(Icons.delete_sweep),
                      label: Text('Delete Test Reminders'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Print Report
              _buildActionCard(
                icon: Icons.analytics,
                title: 'Test Report',
                description: 'Generate and print comprehensive test report to console',
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _printTestReport,
                      icon: Icon(Icons.print),
                      label: Text('Print Report'),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Status Message
              if (_statusMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (_isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(Icons.info, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 24),

              // Instructions
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline, color: Colors.blue[700]),
                          SizedBox(width: 8),
                          Text(
                            'Testing Instructions',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Check notification status is enabled\n'
                        '2. Create a test reminder (10s recommended)\n'
                        '3. Lock your device or put app in background\n'
                        '4. Wait for the reminder to trigger\n'
                        '5. Verify fullscreen notification appears\n'
                        '6. Clean up test reminders when done',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value, {bool isWarning = false}) {
    final color = isWarning
        ? (value ? Colors.orange : Colors.green)
        : (value ? Colors.green : Colors.red);
    final icon = value ? Icons.check_circle : Icons.cancel;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value ? 'Yes' : 'No',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
