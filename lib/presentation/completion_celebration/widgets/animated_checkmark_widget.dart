import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/animation_performance_utils.dart';

class AnimatedCheckmarkWidget extends StatefulWidget {
  final VoidCallback? onAnimationComplete;

  const AnimatedCheckmarkWidget({
    super.key,
    this.onAnimationComplete,
  });

  @override
  State<AnimatedCheckmarkWidget> createState() =>
      _AnimatedCheckmarkWidgetState();
}

class _AnimatedCheckmarkWidgetState extends State<AnimatedCheckmarkWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize performance utilities
    AnimationPerformanceUtils.initialize();

    // Create optimized animation controllers using performance utilities
    _scaleController = AnimationPerformanceUtils.createOptimizedController(
      duration: Duration(milliseconds: 400),
      vsync: this,
      debugLabel: 'CheckmarkScale',
    );

    _rotationController = AnimationPerformanceUtils.createOptimizedController(
      duration: Duration(milliseconds: 300),
      vsync: this,
      debugLabel: 'CheckmarkRotation',
    );

    // Create performance-optimized animations with smoother curves
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(AnimationPerformanceUtils.createOptimizedCurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(AnimationPerformanceUtils.createOptimizedCurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    // Trigger haptic feedback
    HapticFeedback.mediumImpact();

    // Start scale animation
    await _scaleController.forward();

    // Start rotation animation
    await _rotationController.forward();

    // Notify completion
    widget.onAnimationComplete?.call();
  }

  @override
  void dispose() {
    // Use performance utilities for safe disposal
    AnimationPerformanceUtils.safeDisposeControllers([
      _scaleController,
      _rotationController,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Completion checkmark',
      hint: 'Visual confirmation of your successful completion',
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 0.5,
              child: Container(
                width: 25.w,
                height: 25.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.lightTheme.colorScheme.primary,
                      AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightTheme.colorScheme.primary
                          .withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'check',
                    color: Colors.white,
                    size: 8.w,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
