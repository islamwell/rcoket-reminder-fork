import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/error_handling_service.dart';

/// Fallback Mode Banner Widget
/// 
/// Displays a banner to inform users when the app is running in fallback mode
/// due to permission issues or background processing failures.
/// 
/// Requirements addressed:
/// - 3.2: User-friendly messaging about permission issues
/// - 3.4: Clear indication of fallback mode status
class FallbackModeBanner extends StatefulWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onSettings;

  const FallbackModeBanner({
    super.key,
    this.onDismiss,
    this.onSettings,
  });

  @override
  State<FallbackModeBanner> createState() => _FallbackModeBannerState();
}

class _FallbackModeBannerState extends State<FallbackModeBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _checkFallbackMode();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkFallbackMode() {
    final isInFallbackMode = ErrorHandlingService.instance.isInFallbackMode;
    if (isInFallbackMode && !_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();
    } else if (!isInFallbackMode && _isVisible) {
      _animationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  void _handleDismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
        widget.onDismiss?.call();
      }
    });
  }

  void _handleSettings() {
    widget.onSettings?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return SizedBox.shrink();
    }

    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade100,
                    Colors.orange.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade800,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Limited Reminder Mode',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Background reminders are disabled. Reminders will only work when the app is open.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _handleDismiss,
                          icon: Icon(
                            Icons.close,
                            color: Colors.orange.shade600,
                            size: 20,
                          ),
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'To enable background reminders, please check your notification permissions and battery optimization settings.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _handleDismiss,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                          ),
                          child: Text('Dismiss'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _handleSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            elevation: 2,
                          ),
                          child: Text('Fix Settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// System Health Status Widget
/// 
/// Shows the current health status of the reminder system
class SystemHealthStatusWidget extends StatefulWidget {
  const SystemHealthStatusWidget({super.key});

  @override
  State<SystemHealthStatusWidget> createState() => _SystemHealthStatusWidgetState();
}

class _SystemHealthStatusWidgetState extends State<SystemHealthStatusWidget> {
  SystemHealthStatus? _healthStatus;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadHealthStatus();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadHealthStatus() async {
    try {
      final status = await ErrorHandlingService.instance.getSystemHealthStatus();
      if (mounted) {
        setState(() {
          _healthStatus = status;
        });
      }
    } catch (e) {
      print('Error loading health status: $e');
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _loadHealthStatus();
    });
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

  String _getHealthText(HealthLevel level) {
    switch (level) {
      case HealthLevel.healthy:
        return 'System Healthy';
      case HealthLevel.degraded:
        return 'Degraded Performance';
      case HealthLevel.warning:
        return 'System Warning';
      case HealthLevel.critical:
        return 'Critical Issues';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_healthStatus == null) {
      return SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final healthColor = _getHealthColor(_healthStatus!.level);
    final healthIcon = _getHealthIcon(_healthStatus!.level);
    final healthText = _getHealthText(_healthStatus!.level);

    // Only show if there are issues
    if (_healthStatus!.level == HealthLevel.healthy && !_healthStatus!.isInFallbackMode) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: healthColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            healthIcon,
            color: healthColor,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  healthText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: healthColor,
                  ),
                ),
                if (_healthStatus!.recentErrorCount > 0) ...[
                  SizedBox(height: 2),
                  Text(
                    '${_healthStatus!.recentErrorCount} recent issues',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: healthColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_healthStatus!.isInFallbackMode)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Fallback Mode',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}