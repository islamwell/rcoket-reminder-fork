import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Loading overlay with smooth animations for audio operations
/// 
/// Features:
/// - Smooth fade in/out animations
/// - Multiple loading indicator types
/// - Customizable messages and colors
/// - Backdrop blur effect
/// - Progress indication support
/// 
/// Requirements implemented: 7.4, 7.5

class LoadingOverlay extends StatefulWidget {
  final bool isVisible;
  final String message;
  final LoadingType loadingType;
  final Color? color;
  final double? progress;
  final VoidCallback? onCancel;
  final Duration animationDuration;

  const LoadingOverlay({
    super.key,
    required this.isVisible,
    this.message = 'Loading...',
    this.loadingType = LoadingType.circular,
    this.color,
    this.progress,
    this.onCancel,
    this.animationDuration = AudioAnimations.stateTransition,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _fadeAnimation = AudioAnimations.createFadeAnimation(_controller);
    _scaleAnimation = AudioAnimations.createScaleAnimation(
      _controller,
      begin: 0.8,
      end: 1.0,
    );

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLoadingIndicator(),
                      SizedBox(height: 3.h),
                      Text(
                        widget.message,
                        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.progress != null) ...[
                        SizedBox(height: 2.h),
                        _buildProgressIndicator(),
                      ],
                      if (widget.onCancel != null) ...[
                        SizedBox(height: 3.h),
                        _buildCancelButton(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return AnimatedLoadingIndicator(
      color: widget.color ?? AppTheme.lightTheme.colorScheme.primary,
      size: 12.w,
      strokeWidth: 3.0,
      type: widget.loadingType,
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            widthFactor: (widget.progress ?? 0.0).clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color ?? AppTheme.lightTheme.colorScheme.primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          '${((widget.progress ?? 0.0) * 100).toInt()}%',
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return AnimatedActionButton(
      iconName: 'close',
      onTap: widget.onCancel,
      color: AppTheme.lightTheme.colorScheme.error,
      backgroundColor: AppTheme.lightTheme.colorScheme.errorContainer,
      size: 16,
      tooltip: 'Cancel operation',
    );
  }
}

/// Success feedback overlay with checkmark animation
class SuccessOverlay extends StatefulWidget {
  final bool isVisible;
  final String message;
  final Color? color;
  final Duration displayDuration;
  final VoidCallback? onComplete;

  const SuccessOverlay({
    super.key,
    required this.isVisible,
    this.message = 'Success!',
    this.color,
    this.displayDuration = const Duration(seconds: 2),
    this.onComplete,
  });

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _checkController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: AudioAnimations.stateTransition,
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = AudioAnimations.createFadeAnimation(_fadeController);
    _scaleAnimation = AudioAnimations.createScaleAnimation(
      _fadeController,
      begin: 0.8,
      end: 1.0,
    );
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));

    if (widget.isVisible) {
      _showSuccess();
    }
  }

  @override
  void didUpdateWidget(SuccessOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible && widget.isVisible) {
      _showSuccess();
    }
  }

  void _showSuccess() async {
    await _fadeController.forward();
    await _checkController.forward();
    
    await Future.delayed(widget.displayDuration);
    
    await _fadeController.reverse();
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _fadeController.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation, _checkAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 15.w),
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: _checkAnimation.value,
                        child: Container(
                          width: 15.w,
                          height: 15.w,
                          decoration: BoxDecoration(
                            color: widget.color ?? AppTheme.lightTheme.colorScheme.tertiary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (widget.color ?? AppTheme.lightTheme.colorScheme.tertiary)
                                    .withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        widget.message,
                        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: widget.color ?? AppTheme.lightTheme.colorScheme.tertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Error feedback overlay with shake animation
class ErrorOverlay extends StatefulWidget {
  final bool isVisible;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final Duration displayDuration;

  const ErrorOverlay({
    super.key,
    required this.isVisible,
    required this.message,
    this.actionText,
    this.onAction,
    this.onDismiss,
    this.displayDuration = const Duration(seconds: 4),
  });

  @override
  State<ErrorOverlay> createState() => _ErrorOverlayState();
}

class _ErrorOverlayState extends State<ErrorOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: AudioAnimations.stateTransition,
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = AudioAnimations.createFadeAnimation(_fadeController);
    _scaleAnimation = AudioAnimations.createScaleAnimation(
      _fadeController,
      begin: 0.8,
      end: 1.0,
    );
    
    _shakeAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    if (widget.isVisible) {
      _showError();
    }
  }

  @override
  void didUpdateWidget(ErrorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible && widget.isVisible) {
      _showError();
    }
  }

  void _showError() async {
    await _fadeController.forward();
    await _shakeController.forward();
    _shakeController.reverse();
    
    if (widget.onDismiss == null) {
      await Future.delayed(widget.displayDuration);
      await _fadeController.reverse();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible && _fadeController.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation, _shakeAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.translate(
                  offset: Offset(_shakeAnimation.value * 10, 0),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.w),
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                      border: Border.all(
                        color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppTheme.lightTheme.colorScheme.error,
                          size: 12.w,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.message,
                          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.actionText != null && widget.onAction != null) ...[
                          SizedBox(height: 3.h),
                          ElevatedButton(
                            onPressed: widget.onAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightTheme.colorScheme.error,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(widget.actionText!),
                          ),
                        ],
                        if (widget.onDismiss != null) ...[
                          SizedBox(height: 2.h),
                          TextButton(
                            onPressed: () {
                              _fadeController.reverse().then((_) {
                                widget.onDismiss?.call();
                              });
                            },
                            child: Text('Dismiss'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}