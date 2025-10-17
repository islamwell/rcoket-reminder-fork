import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/error_handling_service.dart';
import '../widgets/permission_request_flow.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  bool _isInFallbackMode = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final enabled = await NotificationService.instance.areNotificationsEnabled();
      final fallbackMode = ErrorHandlingService.instance.isInFallbackMode;
      
      setState(() {
        _notificationsEnabled = enabled;
        _isInFallbackMode = fallbackMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check notification status: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestFlow(
        onPermissionGranted: () {
          _checkNotificationStatus();
          _showSuccessMessage('Notification permissions granted successfully!');
        },
        onPermissionDenied: () {
          _checkNotificationStatus();
        },
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }





  void _showTroubleshootingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Troubleshooting Guide'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTroubleshootingSection(
                'Android Users:',
                [
                  '1. Open device Settings',
                  '2. Go to Apps & notifications',
                  '3. Find "Reminder App"',
                  '4. Tap Notifications',
                  '5. Enable "Allow notifications"',
                  '6. For Android 13+: Enable "Show notifications"',
                ],
              ),
              SizedBox(height: 16),
              _buildTroubleshootingSection(
                'iOS Users:',
                [
                  '1. Open device Settings',
                  '2. Scroll down to "Reminder App"',
                  '3. Tap Notifications',
                  '4. Enable "Allow Notifications"',
                  '5. Choose notification style preferences',
                ],
              ),
              SizedBox(height: 16),
              _buildTroubleshootingSection(
                'Battery Optimization:',
                [
                  '• Disable battery optimization for this app',
                  '• Add app to "Never sleeping apps" list',
                  '• Enable "Background app refresh" (iOS)',
                ],
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After changing settings, restart the app for changes to take effect.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkNotificationStatus();
            },
            child: Text('Recheck Status'),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection(String title, List<String> steps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        ...steps.map((step) => Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Text(
            step,
            style: TextStyle(fontSize: 14),
          ),
        )),
      ],
    );
  }

  void _testNotification() async {
    try {
      await NotificationService.instance.testTriggerReminder();
      _showSuccessMessage('Test notification sent!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send test notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[900],
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  SizedBox(height: 24),
                  _buildPermissionCard(),
                  SizedBox(height: 24),
                  _buildTestingCard(),
                  SizedBox(height: 24),
                  _buildTroubleshootingCard(),
                  if (_errorMessage != null) ...[
                    SizedBox(height: 24),
                    _buildErrorCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _notificationsEnabled ? Icons.check_circle : Icons.error,
                color: _notificationsEnabled ? Colors.green : Colors.red,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Notification Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildStatusItem(
            'Notifications Enabled',
            _notificationsEnabled ? 'Yes' : 'No',
            _notificationsEnabled ? Colors.green : Colors.red,
          ),
          _buildStatusItem(
            'Background Processing',
            _isInFallbackMode ? 'Limited' : 'Available',
            _isInFallbackMode ? Colors.orange : Colors.green,
          ),
          _buildStatusItem(
            'App Mode',
            _isInFallbackMode ? 'Fallback Mode' : 'Full Functionality',
            _isInFallbackMode ? Colors.orange : Colors.green,
          ),
          if (_isInFallbackMode) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'App is running in fallback mode. Some reminder features may be limited.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permission Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Notification permissions are required for reminders to work when the app is minimized or your device is in power-saving mode.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          if (!_notificationsEnabled) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _requestPermissions,
                icon: Icon(Icons.notifications),
                label: Text('Request Permissions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notification permissions are granted and working properly.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 12),
          TextButton.icon(
            onPressed: _checkNotificationStatus,
            icon: Icon(Icons.refresh),
            label: Text('Refresh Status'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF667EEA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Test if notifications are working properly by triggering a sample reminder.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _notificationsEnabled ? _testNotification : null,
              icon: Icon(Icons.play_arrow),
              label: Text('Send Test Notification'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF667EEA),
                side: BorderSide(color: Color(0xFF667EEA)),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (!_notificationsEnabled) ...[
            SizedBox(height: 8),
            Text(
              'Enable notifications first to test functionality.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTroubleshootingCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Troubleshooting',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Having issues with notifications? Get help with common problems.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showTroubleshootingDialog,
              icon: Icon(Icons.help_outline),
              label: Text('View Troubleshooting Guide'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[800],
            ),
          ),
          SizedBox(height: 16),
          TextButton.icon(
            onPressed: _checkNotificationStatus,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}