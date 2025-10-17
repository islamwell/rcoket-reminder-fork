import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class FeedbackConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const FeedbackConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
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
            iconName: isDestructive ? 'warning' : 'info',
            color: isDestructive 
                ? theme.colorScheme.error 
                : theme.colorScheme.primary,
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
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
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
            backgroundColor: isDestructive 
                ? theme.colorScheme.error 
                : theme.colorScheme.primary,
            foregroundColor: isDestructive 
                ? theme.colorScheme.onError 
                : theme.colorScheme.onPrimary,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => FeedbackConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
      ),
    );
  }

  static Future<bool?> showUpdateConfirmation(BuildContext context) {
    return show(
      context,
      title: 'Update Feedback',
      message: 'Are you sure you want to save these changes to your feedback?',
      confirmText: 'Save Changes',
      cancelText: 'Cancel',
    );
  }

  static Future<bool?> showDiscardChangesConfirmation(BuildContext context) {
    return show(
      context,
      title: 'Discard Changes',
      message: 'You have unsaved changes. Are you sure you want to leave without saving?',
      confirmText: 'Discard',
      cancelText: 'Keep Editing',
      isDestructive: true,
    );
  }
}