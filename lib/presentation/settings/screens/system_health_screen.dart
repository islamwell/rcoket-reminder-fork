import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/services/error_handling_service.dart';

/// System Health Screen
/// 
/// Displays system health status, error logs, and provides options
/// to manage fallback mode and troubleshoot issues.
/// 
/// Requirements addressed:
/// - 3.2: User-friendly messaging about system status
/// - 3.4: Management of fallback mode
/// - 5.3: Error monitoring and troubleshooting
class SystemHealthScreen extends StatefulWidget {
  const SystemHealthScreen({super.key});

  @override
  State<SystemHealthScreen> createState() => _SystemHealthScreenState();
}

class _SystemHealthScreenState extends State<SystemHealthScreen> {
  SystemHealthStatus? _healthStatus;
  List<ErrorLogEntry> _errorLogs = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final healthStatus = await ErrorHandlingService.instance.getSystemHealthStatus();
      final errorLogs = await ErrorHandlingService.instance.getErrorLogs();
      
      if (mounted) {
        setState(() {
          _healthStatus = healthStatus;
          _errorLogs = errorLogs.take(50).toList(); // Show last 50 entries
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load system health data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _toggleFallbackMode() async {
    if (_healthStatus == null) return;

    try {
      final newMode = !_healthStatus!.isInFallbackMode;
      await ErrorHandlingService.instance.setFallbackMode(
        newMode,
        reason: newMode ? 'Manually enabled by user' : 'Manually disabled by user',
      );
      
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newMode 
              ? 'Fallback mode enabled - reminders will only work when app is open'
              : 'Fallback mode disabled - background reminders restored'
          ),
          backgroundColor: newMode ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle fallback mode'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearErrorLogs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Error Logs'),
        content: Text('Are you sure you want to clear all error logs? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ErrorHandlingService.instance.clearErrorLogs();
        await _loadData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logs cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear error logs'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getHealthColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.healthy:
        return Colors.green;
      case HealthLevel.degraded:
        return Colors.yellow.shade700;
      case HealthLevel.warning:
        return Colors.orange;
      case HealthLevel.critical:
        return Colors.red;
    }
  }

  IconData _getHealthIcon(HealthLevel level) {
    switch (level) {
      case HealthLevel.healthy:
        return Icons.check_circle;
      case HealthLevel.degraded:
        return Icons.info;
      case HealthLevel.warning:
        return Icons.warning;
      case HealthLevel.critical:
        return Icons.error;
    }
  }

  String _getHealthDescription(HealthLevel level) {
    switch (level) {
      case HealthLevel.healthy:
        return 'All systems are functioning normally';
      case HealthLevel.degraded:
        return 'Some features may have reduced functionality';
      case HealthLevel.warning:
        return 'Issues detected that may affect performance';
      case HealthLevel.critical:
        return 'Critical issues require immediate attention';
    }
  }

  Color _getSeverityColor(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('System Health'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHealthStatusCard(theme),
                    SizedBox(height: 16),
                    _buildFallbackModeCard(theme),
                    SizedBox(height: 16),
                    _buildErrorLogsSection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthStatusCard(ThemeData theme) {
    if (_healthStatus == null) return SizedBox.shrink();

    final healthColor = _getHealthColor(_healthStatus!.level);
    final healthIcon = _getHealthIcon(_healthStatus!.level);
    final healthDescription = _getHealthDescription(_healthStatus!.level);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  healthIcon,
                  color: healthColor,
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Health',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _healthStatus!.level.toString().split('.').last.toUpperCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: healthColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              healthDescription,
              style: theme.textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  'Recent Errors',
                  _healthStatus!.recentErrorCount.toString(),
                  _healthStatus!.recentErrorCount > 0 ? Colors.red : Colors.green,
                ),
                SizedBox(width: 8),
                _buildStatChip(
                  'Critical',
                  _healthStatus!.criticalErrorCount.toString(),
                  _healthStatus!.criticalErrorCount > 0 ? Colors.red : Colors.grey,
                ),
                SizedBox(width: 8),
                _buildStatChip(
                  'Warnings',
                  _healthStatus!.warningCount.toString(),
                  _healthStatus!.warningCount > 0 ? Colors.orange : Colors.grey,
                ),
              ],
            ),
            if (_healthStatus!.lastErrorTime != null) ...[
              SizedBox(height: 12),
              Text(
                'Last error: ${_formatDateTime(_healthStatus!.lastErrorTime!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackModeCard(ThemeData theme) {
    if (_healthStatus == null) return SizedBox.shrink();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _healthStatus!.isInFallbackMode ? Icons.warning : Icons.check_circle,
                  color: _healthStatus!.isInFallbackMode ? Colors.orange : Colors.green,
                ),
                SizedBox(width: 8),
                Text(
                  'Fallback Mode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Switch(
                  value: _healthStatus!.isInFallbackMode,
                  onChanged: (_) => _toggleFallbackMode(),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              _healthStatus!.isInFallbackMode
                  ? 'Background reminders are disabled. Reminders will only work when the app is open.'
                  : 'Background reminders are enabled and working normally.',
              style: theme.textTheme.bodyMedium,
            ),
            if (_healthStatus!.isInFallbackMode) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To restore background reminders:',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Check notification permissions in device settings\n'
                      '• Disable battery optimization for this app\n'
                      '• Ensure background app refresh is enabled',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorLogsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Error Logs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Spacer(),
            if (_errorLogs.isNotEmpty)
              TextButton(
                onPressed: _clearErrorLogs,
                child: Text('Clear All'),
              ),
          ],
        ),
        SizedBox(height: 8),
        if (_errorLogs.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No errors recorded',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Your system is running smoothly',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ..._errorLogs.map((log) => _buildErrorLogCard(log, theme)).toList(),
      ],
    );
  }

  Widget _buildErrorLogCard(ErrorLogEntry log, ThemeData theme) {
    final severityColor = _getSeverityColor(log.severity);
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          _getErrorIcon(log.severity),
          color: severityColor,
        ),
        title: Text(
          log.code,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Text(
              _formatDateTime(log.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (log.metadata.isNotEmpty) ...[
                  Text(
                    'Metadata:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.metadata.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],
                if (log.stackTrace != null) ...[
                  Text(
                    'Stack Trace:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      log.stackTrace!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      maxLines: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info;
      case ErrorSeverity.warning:
        return Icons.warning;
      case ErrorSeverity.error:
        return Icons.error;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}