import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Widget that displays error messages with retry functionality
class ErrorRecoveryWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool isInline;
  final IconData? icon;

  const ErrorRecoveryWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
    this.isInline = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isInline) {
      return _buildInlineError(context);
    }
    return _buildFullError(context);
  }

  Widget _buildInlineError(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: icon?.toString().split('.').last ?? 'error',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              message,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(width: 2.w),
            _buildRetryButton(context, isSmall: true),
          ],
          if (onDismiss != null) ...[
            SizedBox(width: 1.w),
            _buildDismissButton(context, isSmall: true),
          ],
        ],
      ),
    );
  }

  Widget _buildFullError(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: icon?.toString().split('.').last ?? 'error_outline',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 32,
          ),
          SizedBox(height: 2.h),
          Text(
            'Something went wrong',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            message,
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onDismiss != null) ...[
                _buildDismissButton(context),
                if (onRetry != null) SizedBox(width: 3.w),
              ],
              if (onRetry != null) _buildRetryButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context, {bool isSmall = false}) {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: CustomIconWidget(
        iconName: 'refresh',
        color: AppTheme.lightTheme.colorScheme.onPrimary,
        size: isSmall ? 12 : 16,
      ),
      label: Text(
        'Retry',
        style: TextStyle(fontSize: isSmall ? 10.sp : 12.sp),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 2.w : 4.w,
          vertical: isSmall ? 1.h : 1.5.h,
        ),
        minimumSize: Size(0, 0),
      ),
    );
  }

  Widget _buildDismissButton(BuildContext context, {bool isSmall = false}) {
    return TextButton.icon(
      onPressed: onDismiss,
      icon: CustomIconWidget(
        iconName: 'close',
        color: AppTheme.lightTheme.colorScheme.onErrorContainer,
        size: isSmall ? 12 : 16,
      ),
      label: Text(
        'Dismiss',
        style: TextStyle(
          fontSize: isSmall ? 10.sp : 12.sp,
          color: AppTheme.lightTheme.colorScheme.onErrorContainer,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 2.w : 4.w,
          vertical: isSmall ? 1.h : 1.5.h,
        ),
        minimumSize: Size(0, 0),
      ),
    );
  }
}

/// Specialized error widget for operation-specific errors
class OperationErrorWidget extends StatelessWidget {
  final String audioId;
  final String operation;
  final String message;
  final Future<bool> Function() onRetry;
  final VoidCallback onDismiss;

  const OperationErrorWidget({
    super.key,
    required this.audioId,
    required this.operation,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorRecoveryWidget(
      message: message,
      isInline: true,
      icon: _getOperationIcon(),
      onRetry: () async {
        final success = await onRetry();
        if (success) {
          onDismiss();
        }
      },
      onDismiss: onDismiss,
    );
  }

  IconData _getOperationIcon() {
    switch (operation) {
      case 'rename':
        return Icons.edit;
      case 'favorite':
        return Icons.favorite;
      case 'delete':
        return Icons.delete;
      case 'play':
        return Icons.play_arrow;
      default:
        return Icons.error;
    }
  }
}

/// Widget that shows loading state with cancellation option
class LoadingOperationWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onCancel;

  const LoadingOperationWidget({
    super.key,
    required this.message,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              message,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          if (onCancel != null) ...[
            SizedBox(width: 2.w),
            GestureDetector(
              onTap: onCancel,
              child: Container(
                padding: EdgeInsets.all(1.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'close',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}