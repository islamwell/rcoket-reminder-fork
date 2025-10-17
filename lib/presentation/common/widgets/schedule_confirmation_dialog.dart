import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ScheduleConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final DateTime originalTime;
  final DateTime adjustedTime;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool showTimeComparison;

  const ScheduleConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.originalTime,
    required this.adjustedTime,
    this.confirmText = 'Accept',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.showTimeComparison = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          CustomIconWidget(
            iconName: 'schedule',
            color: theme.colorScheme.primary,
            size: 24,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (showTimeComparison) ...[
            SizedBox(height: 3.h),
            _buildTimeComparison(context, theme),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          child: Text(
            cancelText,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  Widget _buildTimeComparison(BuildContext context, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildTimeRow(
            context,
            theme,
            'Original Time:',
            _formatDateTime(originalTime),
            theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 1.h),
          Icon(
            Icons.arrow_downward,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(height: 1.h),
          _buildTimeRow(
            context,
            theme,
            'Adjusted Time:',
            _formatDateTime(adjustedTime),
            theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    ThemeData theme,
    String label,
    String time,
    Color timeColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          time,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: timeColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    // Format time
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final timeStr = '$displayHour:$minute $period';
    
    // Add relative time info
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      if (minutes <= 0) {
        return '$timeStr (Now)';
      } else if (minutes == 1) {
        return '$timeStr (In 1 minute)';
      } else {
        return '$timeStr (In $minutes minutes)';
      }
    } else if (difference.inDays == 0) {
      return '$timeStr (Today)';
    } else if (difference.inDays == 1) {
      return '$timeStr (Tomorrow)';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $timeStr';
    }
  }

  // Static methods for common use cases
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required DateTime originalTime,
    required DateTime adjustedTime,
    String confirmText = 'Accept',
    String cancelText = 'Cancel',
    bool showTimeComparison = true,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ScheduleConfirmationDialog(
        title: title,
        message: message,
        originalTime: originalTime,
        adjustedTime: adjustedTime,
        confirmText: confirmText,
        cancelText: cancelText,
        showTimeComparison: showTimeComparison,
      ),
    );
  }

  static Future<bool?> showTimeConflictResolution(
    BuildContext context,
    DateTime originalTime,
    DateTime adjustedTime,
  ) {
    return show(
      context,
      title: 'Schedule Adjustment',
      message: 'The requested time has a conflict and needs to be adjusted. Would you like to accept the suggested time?',
      originalTime: originalTime,
      adjustedTime: adjustedTime,
      confirmText: 'Accept Adjustment',
      cancelText: 'Cancel',
    );
  }

  static Future<bool?> showScheduleConfirmation(
    BuildContext context,
    DateTime scheduledTime,
  ) {
    final now = DateTime.now();
    return show(
      context,
      title: 'Confirm Schedule',
      message: 'Please confirm the scheduled time for your reminder.',
      originalTime: now,
      adjustedTime: scheduledTime,
      confirmText: 'Confirm',
      cancelText: 'Cancel',
      showTimeComparison: false,
    );
  }

  static Future<bool?> showBufferTimeAdjustment(
    BuildContext context,
    DateTime originalTime,
    DateTime adjustedTime,
  ) {
    return show(
      context,
      title: 'Minimum Time Buffer',
      message: 'Reminders need at least 1 minute buffer time. The schedule has been adjusted to meet this requirement.',
      originalTime: originalTime,
      adjustedTime: adjustedTime,
      confirmText: 'Accept',
      cancelText: 'Cancel',
    );
  }
}