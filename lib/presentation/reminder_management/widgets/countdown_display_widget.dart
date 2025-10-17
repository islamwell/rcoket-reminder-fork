import 'dart:async';
import 'package:flutter/material.dart';

/// Real-time countdown display widget that shows accurate time remaining
/// until the next reminder occurrence.
/// 
/// Requirements addressed:
/// - 2.1: Display actual time remaining that updates automatically
/// - 2.2: Update display every minute
/// - 2.3-2.7: Smart formatting based on time proximity
class CountdownDisplayWidget extends StatefulWidget {
  final Map<String, dynamic> reminder;
  final TextStyle? textStyle;
  final Color? overrideColor;

  const CountdownDisplayWidget({
    super.key,
    required this.reminder,
    this.textStyle,
    this.overrideColor,
  });

  @override
  State<CountdownDisplayWidget> createState() => _CountdownDisplayWidgetState();
}

class _CountdownDisplayWidgetState extends State<CountdownDisplayWidget> {
  Timer? _updateTimer;
  String _displayText = '';
  Color? _displayColor;

  @override
  void initState() {
    super.initState();
    _updateDisplay();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(CountdownDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update display if reminder data changed
    if (oldWidget.reminder['id'] != widget.reminder['id'] ||
        oldWidget.reminder['nextOccurrenceDateTime'] != widget.reminder['nextOccurrenceDateTime']) {
      _updateDisplay();
    }
  }

  /// Start timer to update display every minute
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _updateDisplay();
      }
    });
  }

  /// Update the display text and color based on current time
  void _updateDisplay() {
    if (!mounted) return;

    final status = widget.reminder['status'] as String;
    
    // Handle non-active reminders
    if (status == 'paused') {
      setState(() {
        _displayText = 'Paused';
        _displayColor = Colors.orange[600];
      });
      return;
    }
    
    if (status == 'completed') {
      setState(() {
        _displayText = 'Completed';
        _displayColor = Colors.green[600];
      });
      return;
    }

    // Get next occurrence DateTime
    final nextOccurrenceDateTimeStr = widget.reminder['nextOccurrenceDateTime'] as String?;
    
    if (nextOccurrenceDateTimeStr == null) {
      // Fallback to legacy nextOccurrence field
      final nextOccurrence = widget.reminder['nextOccurrence'] as String? ?? 'Unknown';
      setState(() {
        _displayText = nextOccurrence;
        _displayColor = _getColorForText(nextOccurrence);
      });
      return;
    }

    try {
      final nextOccurrenceDateTime = DateTime.parse(nextOccurrenceDateTimeStr);
      final now = DateTime.now();
      final difference = nextOccurrenceDateTime.difference(now);

      setState(() {
        _displayText = _formatTimeDifference(difference, nextOccurrenceDateTime);
        _displayColor = _getColorForDifference(difference);
      });
    } catch (e) {
      print('Error parsing nextOccurrenceDateTime: $e');
      setState(() {
        _displayText = 'Error';
        _displayColor = Colors.red[600];
      });
    }
  }

  /// Format time difference into human-readable text
  String _formatTimeDifference(Duration difference, DateTime nextOccurrence) {
    
    // Handle overdue reminders
    if (difference.isNegative) {
      return 'Overdue';
    }
    
    // Less than 1 minute
    if (difference.inMinutes < 1) {
      return 'Now';
    }
    
    // Less than 60 minutes - show exact minutes
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return minutes == 1 ? 'In 1 minute' : 'In $minutes minutes';
    }
    
    // Same day - check if it's within reasonable hours to show "In X hours"
    if (difference.inDays == 0) {
      final hours = difference.inHours;
      if (hours < 12) {
        // Show "In X hours" for up to 12 hours
        return hours == 1 ? 'In 1 hour' : 'In $hours hours';
      } else {
        // Show "Today at time" for later today
        return 'Today at ${_formatTime(nextOccurrence)}';
      }
    }
    
    // Tomorrow
    if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(nextOccurrence)}';
    }
    
    // This week (within 7 days)
    if (difference.inDays < 7) {
      final weekday = _getWeekdayName(nextOccurrence.weekday);
      return '$weekday at ${_formatTime(nextOccurrence)}';
    }
    
    // More than a week away
    return '${nextOccurrence.day}/${nextOccurrence.month}/${nextOccurrence.year} at ${_formatTime(nextOccurrence)}';
  }

  /// Get color based on time difference
  Color? _getColorForDifference(Duration difference) {
    if (widget.overrideColor != null) {
      return widget.overrideColor;
    }

    if (difference.isNegative) {
      return Colors.red[600]; // Overdue
    }
    
    if (difference.inMinutes < 5) {
      return Colors.orange[600]; // Very soon
    }
    
    if (difference.inMinutes < 60) {
      return Colors.blue[600]; // Soon
    }
    
    return Colors.grey[600]; // Later
  }

  /// Get color for legacy text display
  Color? _getColorForText(String text) {
    if (widget.overrideColor != null) {
      return widget.overrideColor;
    }

    if (text.toLowerCase().contains('overdue')) {
      return Colors.red[600];
    }
    
    if (text.toLowerCase().contains('now') || text.toLowerCase().contains('minute')) {
      return Colors.orange[600];
    }
    
    if (text.toLowerCase().contains('hour')) {
      return Colors.blue[600];
    }
    
    return Colors.grey[600];
  }

  /// Format time in 12-hour format
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Get weekday name
  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextStyle = widget.textStyle ?? theme.textTheme.bodySmall;
    final effectiveColor = _displayColor ?? effectiveTextStyle?.color;

    return Text(
      _displayText,
      style: effectiveTextStyle?.copyWith(
        color: effectiveColor,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}