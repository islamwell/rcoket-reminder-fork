import 'package:flutter/material.dart';

/// Model representing a completion delay option for reminders
class DelayOption {
  final String id;
  final String label;
  final Duration duration;
  final IconData icon;
  final bool isCustom;

  const DelayOption({
    required this.id,
    required this.label,
    required this.duration,
    required this.icon,
    this.isCustom = false,
  });

  /// Predefined delay options
  static const List<DelayOption> presets = [
    DelayOption(
      id: '1min',
      label: '1 minute',
      duration: Duration(minutes: 1),
      icon: Icons.timer,
    ),
    DelayOption(
      id: '5min',
      label: '5 minutes',
      duration: Duration(minutes: 5),
      icon: Icons.timer_3,
    ),
    DelayOption(
      id: '15min',
      label: '15 minutes',
      duration: Duration(minutes: 15),
      icon: Icons.timer_10,
    ),
    DelayOption(
      id: '1hr',
      label: '1 hour',
      duration: Duration(hours: 1),
      icon: Icons.schedule,
    ),
    DelayOption(
      id: 'custom',
      label: 'Custom time',
      duration: Duration.zero, // Will be set by user
      icon: Icons.edit_calendar,
      isCustom: true,
    ),
  ];

  /// Create a custom delay option with user-defined duration
  DelayOption copyWithDuration(Duration newDuration) {
    return DelayOption(
      id: id,
      label: _formatDuration(newDuration),
      duration: newDuration,
      icon: icon,
      isCustom: isCustom,
    );
  }

  /// Format duration for display
  static String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours} hour${hours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return '${duration.inSeconds} second${duration.inSeconds > 1 ? 's' : ''}';
    }
  }

  /// Get formatted display text for the delay
  String get displayText => isCustom && duration == Duration.zero ? label : _formatDuration(duration);

  @override
  String toString() {
    return 'DelayOption(id: $id, label: $label, duration: $duration, isCustom: $isCustom)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DelayOption &&
        other.id == id &&
        other.label == label &&
        other.duration == duration &&
        other.icon == icon &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode {
    return Object.hash(id, label, duration, icon, isCustom);
  }
}