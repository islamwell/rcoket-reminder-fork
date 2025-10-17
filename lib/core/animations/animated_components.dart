import 'package:flutter/material.dart';
import 'dart:math';

import '../app_export.dart';

/// Animated button widget with comprehensive feedback animations
class AnimatedActionButton extends StatefulWidget {
  final String iconName;
  final VoidCallback? onTap;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;
  final bool isLoading;
  final bool isDisabled;
  final Duration animationDuration;

  const AnimatedActionButton({
    super.key,
    required this.iconName,
    this.onTap,
    this.color,
    this.backgroundColor,
    this.size = 24.0,
    this.tooltip,
    this.isLoading = false,
    this.isDisabled = false,
    this.animationDuration = AudioAnimations.quickFeedback,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = AudioAnimations.createScaleAnimation(_controller);
    
    _colorAnimation = AudioAnimations.createColorAnimation(
      _controller,
      widget.color ?? Colors.grey,
      (widget.color ?? Colors.grey).withValues(alpha: 0.7),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    if (!widget.isDisabled && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp() {
    if (!widget.isDisabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isDisabled && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      onTap: (widget.isDisabled || widget.isLoading) ? null : widget.onTap,
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _colorAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: AudioAnimations.stateTransition,
              width: widget.size + 16,
              height: widget.size + 16,
              decoration: BoxDecoration(
                color: widget.backgroundColor?.withValues(
                  alpha: widget.isDisabled ? 0.3 : 1.0,
                ),
                shape: BoxShape.circle,
                boxShadow: (widget.isDisabled || widget.isLoading) ? [] : [
                  BoxShadow(
                    color: (_colorAnimation.value ?? widget.color ?? Colors.grey)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: widget.size * 0.8,
                        height: widget.size * 0.8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.color ?? Colors.grey,
                          ),
                        ),
                      )
                    : CustomIconWidget(
                        iconName: widget.iconName,
                        size: widget.size,
                        color: widget.isDisabled
                            ? (widget.color ?? Colors.grey).withValues(alpha: 0.5)
                            : _colorAnimation.value ?? widget.color,
                      ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.tooltip != null) {
      child = Tooltip(
        message: widget.tooltip!,
        child: child,
      );
    }

    return child;
  }
}

/// Animated favorite button with elastic feedback
class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback? onToggle;
  final Color favoriteColor;
  final Color unfavoriteColor;
  final double size;
  final bool isLoading;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorite,
    this.onToggle,
    this.favoriteColor = Colors.red,
    this.unfavoriteColor = Colors.grey,
    this.size = 24.0,
    this.isLoading = false,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: AudioAnimations.quickFeedback,
      vsync: this,
    );
    
    _colorController = AnimationController(
      duration: AudioAnimations.stateTransition,
      vsync: this,
    );

    _scaleAnimation = AudioAnimations.createElasticScaleAnimation(_scaleController);
    
    _colorAnimation = AudioAnimations.createColorAnimation(
      _colorController,
      widget.unfavoriteColor,
      widget.favoriteColor,
    );

    // Set initial state
    if (widget.isFavorite) {
      _colorController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isFavorite != oldWidget.isFavorite) {
      if (widget.isFavorite) {
        _colorController.forward();
        _scaleController.forward().then((_) => _scaleController.reverse());
      } else {
        _colorController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onToggle,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _colorAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.size + 16,
              height: widget.size + 16,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                boxShadow: widget.isLoading ? [] : [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: widget.size * 0.8,
                        height: widget.size * 0.8,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.favoriteColor,
                          ),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: AudioAnimations.stateTransition,
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(
                            scale: animation,
                            child: child,
                          );
                        },
                        child: CustomIconWidget(
                          key: ValueKey(widget.isFavorite),
                          iconName: widget.isFavorite ? 'favorite' : 'favorite_border',
                          size: widget.size,
                          color: _colorAnimation.value,
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

/// Enhanced waveform painter with advanced animation effects
class EnhancedWaveformPainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final bool isAnimating;
  final double animationValue;
  final int barCount;
  final double strokeWidth;
  final bool showGlow;
  final List<double>? customHeights;

  EnhancedWaveformPainter({
    required this.color,
    Color? glowColor,
    this.isAnimating = false,
    this.animationValue = 0.0,
    this.barCount = 20,
    this.strokeWidth = 2.0,
    this.showGlow = true,
    this.customHeights,
  }) : glowColor = glowColor ?? color.withValues(alpha: 0.3);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = glowColor
      ..strokeWidth = strokeWidth * 2
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / barCount;
    final heights = customHeights ?? _generateDefaultHeights();

    for (int i = 0; i < barCount && i < heights.length; i++) {
      final x = i * barWidth + barWidth / 2;
      
      // Calculate animated height
      double heightMultiplier = heights[i];
      if (isAnimating) {
        // Create multiple wave effects for more dynamic visualization
        final primaryWave = (animationValue * 2 * pi) + (i * 0.3);
        final secondaryWave = (animationValue * 4 * pi) + (i * 0.15);
        
        final primaryEffect = sin(primaryWave) * 0.4 + 1.0;
        final secondaryEffect = sin(secondaryWave) * 0.2 + 1.0;
        
        heightMultiplier = (heights[i] * primaryEffect * secondaryEffect).clamp(0.1, 1.5);
      }
      
      final barHeight = size.height * heightMultiplier;
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      // Draw glow effect when animating
      if (isAnimating && showGlow) {
        canvas.drawLine(Offset(x, y1), Offset(x, y2), glowPaint);
      }

      // Draw main bar
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  List<double> _generateDefaultHeights() {
    return [
      0.3, 0.7, 0.5, 0.9, 0.4, 0.8, 0.6, 0.2, 0.9, 0.5,
      0.7, 0.3, 0.8, 0.4, 0.6, 0.9, 0.2, 0.7, 0.5, 0.8,
      0.4, 0.6, 0.8, 0.3, 0.9, 0.5, 0.7, 0.2, 0.8, 0.4,
    ];
  }

  @override
  bool shouldRepaint(covariant EnhancedWaveformPainter oldDelegate) {
    return isAnimating != oldDelegate.isAnimating ||
           animationValue != oldDelegate.animationValue ||
           color != oldDelegate.color ||
           glowColor != oldDelegate.glowColor ||
           barCount != oldDelegate.barCount ||
           strokeWidth != oldDelegate.strokeWidth ||
           showGlow != oldDelegate.showGlow;
  }
}

/// Loading indicator with smooth animations
class AnimatedLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final double strokeWidth;
  final LoadingType type;

  const AnimatedLoadingIndicator({
    super.key,
    this.color = Colors.blue,
    this.size = 24.0,
    this.strokeWidth = 2.0,
    this.type = LoadingType.circular,
  });

  @override
  State<AnimatedLoadingIndicator> createState() => _AnimatedLoadingIndicatorState();
}

class _AnimatedLoadingIndicatorState extends State<AnimatedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    switch (widget.type) {
      case LoadingType.circular:
        _animation = AudioAnimations.createRotationAnimation(_controller);
        break;
      case LoadingType.pulse:
        _animation = AudioAnimations.createScaleAnimation(
          _controller,
          begin: 0.8,
          end: 1.2,
          curve: Curves.easeInOut,
        );
        break;
      case LoadingType.fade:
        _animation = AudioAnimations.createFadeAnimation(_controller);
        break;
      case LoadingType.wave:
      case LoadingType.dots:
        _animation = AudioAnimations.createWaveformAnimation(_controller);
        break;
    }

    _controller.repeat(reverse: widget.type != LoadingType.circular);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.type) {
          case LoadingType.circular:
            return Transform.rotate(
              angle: _animation.value,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CircularProgressIndicator(
                  strokeWidth: widget.strokeWidth,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
            );
          case LoadingType.pulse:
            return Transform.scale(
              scale: _animation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          case LoadingType.fade:
            return Opacity(
              opacity: _animation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          case LoadingType.wave:
            return _buildWaveLoader();
          case LoadingType.dots:
            return _buildDotsLoader();
        }
      },
    );
  }

  Widget _buildWaveLoader() {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: WaveLoadingPainter(
          color: widget.color,
          animationValue: _animation.value,
          strokeWidth: widget.strokeWidth,
        ),
      ),
    );
  }

  Widget _buildDotsLoader() {
    return SizedBox(
      width: widget.size,
      height: widget.size / 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          final delay = index * 0.2;
          final animationValue = (_animation.value - delay).clamp(0.0, 1.0);
          return Transform.scale(
            scale: 0.5 + (sin(animationValue * pi) * 0.5),
            child: Container(
              width: widget.size / 6,
              height: widget.size / 6,
              decoration: BoxDecoration(
                color: widget.color.withValues(
                  alpha: 0.3 + (animationValue * 0.7),
                ),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

enum LoadingType {
  circular,
  pulse,
  fade,
  wave,
  dots,
}

/// Selection state animation component
class AnimatedSelectionIndicator extends StatefulWidget {
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final double size;
  final Duration animationDuration;
  final Widget? child;

  const AnimatedSelectionIndicator({
    super.key,
    required this.isSelected,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.size = 24.0,
    this.animationDuration = AudioAnimations.stateTransition,
    this.child,
  });

  @override
  State<AnimatedSelectionIndicator> createState() => _AnimatedSelectionIndicatorState();
}

class _AnimatedSelectionIndicatorState extends State<AnimatedSelectionIndicator>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: AudioAnimations.quickFeedback,
      vsync: this,
    );
    
    _colorController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = AudioAnimations.createElasticScaleAnimation(_scaleController);
    _colorAnimation = AudioAnimations.createColorAnimation(
      _colorController,
      widget.unselectedColor,
      widget.selectedColor,
    );
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.elasticOut,
    ));

    if (widget.isSelected) {
      _colorController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedSelectionIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _colorController.forward();
        _scaleController.forward().then((_) => _scaleController.reverse());
      } else {
        _colorController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _colorAnimation, _checkAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              shape: BoxShape.circle,
              border: Border.all(
                color: _colorAnimation.value ?? widget.unselectedColor,
                width: 2,
              ),
              boxShadow: widget.isSelected ? [
                BoxShadow(
                  color: (_colorAnimation.value ?? widget.selectedColor).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: widget.child ?? (widget.isSelected
                ? Transform.scale(
                    scale: _checkAnimation.value,
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: widget.size * 0.6,
                    ),
                  )
                : null),
          ),
        );
      },
    );
  }
}

/// Animated state transition component for smooth UI changes
class AnimatedStateTransition extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Duration duration;
  final Curve curve;
  final AnimationType animationType;

  const AnimatedStateTransition({
    super.key,
    required this.child,
    required this.trigger,
    this.duration = AudioAnimations.stateTransition,
    this.curve = Curves.easeInOut,
    this.animationType = AnimationType.scale,
  });

  @override
  State<AnimatedStateTransition> createState() => _AnimatedStateTransitionState();
}

class _AnimatedStateTransitionState extends State<AnimatedStateTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    switch (widget.animationType) {
      case AnimationType.scale:
        _animation = AudioAnimations.createScaleAnimation(
          _controller,
          begin: 0.8,
          end: 1.0,
          curve: widget.curve,
        );
        break;
      case AnimationType.fade:
        _animation = AudioAnimations.createFadeAnimation(
          _controller,
          curve: widget.curve,
        );
        break;
      case AnimationType.rotation:
        _animation = AudioAnimations.createRotationAnimation(_controller);
        break;
    }

    if (widget.trigger) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedStateTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.trigger != oldWidget.trigger) {
      if (widget.trigger) {
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        switch (widget.animationType) {
          case AnimationType.scale:
            return Transform.scale(
              scale: _animation.value,
              child: widget.child,
            );
          case AnimationType.fade:
            return Opacity(
              opacity: _animation.value,
              child: widget.child,
            );
          case AnimationType.rotation:
            return Transform.rotate(
              angle: _animation.value,
              child: widget.child,
            );
        }
      },
    );
  }
}

enum AnimationType {
  scale,
  fade,
  rotation,
}

/// Wave loading painter for advanced loading animations
class WaveLoadingPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final double strokeWidth;

  WaveLoadingPainter({
    required this.color,
    required this.animationValue,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw multiple concentric circles with different phases
    for (int i = 0; i < 3; i++) {
      final phase = (animationValue * 2 * pi) + (i * pi / 3);
      final currentRadius = radius * (0.3 + (sin(phase) * 0.3 + 0.3));
      final alpha = (sin(phase) * 0.5 + 0.5).clamp(0.0, 1.0);
      
      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(center, currentRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveLoadingPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
           color != oldDelegate.color ||
           strokeWidth != oldDelegate.strokeWidth;
  }
}