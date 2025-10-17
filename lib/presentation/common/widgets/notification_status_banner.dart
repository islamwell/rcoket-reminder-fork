import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/error_handling_service.dart';

class NotificationStatusBanner extends StatefulWidget {
  final bool showOnlyWhenDisabled;
  final VoidCallback? onTap;

  const NotificationStatusBanner({
    super.key,
    this.showOnlyWhenDisabled = true,
    this.onTap,
  });

  @override
  State<NotificationStatusBanner> createState() => _NotificationStatusBannerState();
}

class _NotificationStatusBannerState extends State<NotificationStatusBanner> {
  bool _notificationsEnabled = true;
  bool _isInFallbackMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final enabled = await NotificationService.instance.areNotificationsEnabled();
      final fallbackMode = ErrorHandlingService.instance.isInFallbackMode;
      
      if (mounted) {
        setState(() {
          _notificationsEnabled = enabled;
          _isInFallbackMode = fallbackMode;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notificationsEnabled = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox.shrink();
    }

    // Show banner if notifications are disabled or in fallback mode
    final shouldShow = !_notificationsEnabled || _isInFallbackMode;
    
    if (widget.showOnlyWhenDisabled && !shouldShow) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ?? () {
            Navigator.pushNamed(context, '/notification-settings');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getBackgroundColor(),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor(),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIcon(),
                  color: _getIconColor(),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getTextColor(),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _getSubtitle(),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getTextColor().withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: _getIconColor(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!_notificationsEnabled) {
      return Colors.red.withValues(alpha: 0.1);
    } else if (_isInFallbackMode) {
      return Colors.orange.withValues(alpha: 0.1);
    } else {
      return Colors.green.withValues(alpha: 0.1);
    }
  }

  Color _getBorderColor() {
    if (!_notificationsEnabled) {
      return Colors.red.withValues(alpha: 0.3);
    } else if (_isInFallbackMode) {
      return Colors.orange.withValues(alpha: 0.3);
    } else {
      return Colors.green.withValues(alpha: 0.3);
    }
  }

  IconData _getIcon() {
    if (!_notificationsEnabled) {
      return Icons.notifications_off;
    } else if (_isInFallbackMode) {
      return Icons.warning;
    } else {
      return Icons.notifications_active;
    }
  }

  Color _getIconColor() {
    if (!_notificationsEnabled) {
      return Colors.red;
    } else if (_isInFallbackMode) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Color _getTextColor() {
    if (!_notificationsEnabled) {
      return Colors.red[800]!;
    } else if (_isInFallbackMode) {
      return Colors.orange[800]!;
    } else {
      return Colors.green[800]!;
    }
  }

  String _getTitle() {
    if (!_notificationsEnabled) {
      return 'Notifications Disabled';
    } else if (_isInFallbackMode) {
      return 'Limited Functionality';
    } else {
      return 'Notifications Active';
    }
  }

  String _getSubtitle() {
    if (!_notificationsEnabled) {
      return 'Tap to enable notifications for reliable reminders';
    } else if (_isInFallbackMode) {
      return 'App is in fallback mode - some features may be limited';
    } else {
      return 'All notification features are working properly';
    }
  }
}