import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Enhanced animated play button with comprehensive visual feedback
/// 
/// Features:
/// - Smooth play/pause state transitions with icon morphing
/// - Pulsing animation during playback
/// - Loading state with spinner
/// - Gradient background with glow effects
/// - Scale animation on press
/// - Color transitions based on state
/// 
/// Requirements implemented: 7.1, 7.2, 7.6

class AnimatedPlayButton extends StatefulWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;
  final bool showPulse;

  const AnimatedPlayButton({
    super.key,
    required this.isPlaying,
    this.isLoading = false,
    this.onPlay,
    this.onPause,
    this.size = 48.0,
    this.primaryColor,
    this.secondaryColor,
    this.showPulse = true,
  });

  @override
  State<AnimatedPlayButton> createState() => _AnimatedPlayButtonState();
}

class _AnimatedPlayButtonState extends State<AnimatedPlayButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _iconController;
  late AnimationController _colorController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _iconAnimation;
  late Animation<Color?> _backgroundColorAnimation;
  late Animation<Color?> _shadowColorAnimation;

  Color get _primaryColor => widget.primaryColor ?? AppTheme.lightTheme.colorScheme.primary;
  Color get _secondaryColor => widget.secondaryColor ?? AppTheme.lightTheme.colorScheme.tertiary;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _scaleController = AnimationController(
      duration: AudioAnimations.quickFeedback,
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _iconController = AnimationController(
      duration: AudioAnimations.stateTransition,
      vsync: this,
    );
    
    _colorController = AnimationController(
      duration: AudioAnimations.stateTransition,
      vsync: this,
    );

    // Create animations
    _scaleAnimation = AudioAnimations.createScaleAnimation(
      _scaleController,
      begin: 1.0,
      end: 0.9,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));
    
    _backgroundColorAnimation = AudioAnimations.createColorAnimation(
      _colorController,
      _primaryColor,
      _secondaryColor,
    );
    
    _shadowColorAnimation = AudioAnimations.createColorAnimation(
      _colorController,
      _primaryColor.withValues(alpha: 0.3),
      _secondaryColor.withValues(alpha: 0.4),
    );

    // Set initial states
    if (widget.isPlaying) {
      _iconController.value = 1.0;
      _colorController.value = 1.0;
      if (widget.showPulse) {
        _pulseController.repeat(reverse: true);
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _iconController.forward();
        _colorController.forward();
        if (widget.showPulse) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        _iconController.reverse();
        _colorController.reverse();
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isLoading) return;
    
    if (widget.isPlaying) {
      widget.onPause?.call();
    } else {
      widget.onPlay?.call();
    }
  }

  void _handleTapDown() {
    if (!widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _handleTapUp() {
    if (!widget.isLoading) {
      _scaleController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isLoading) {
      _scaleController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onTapDown: (_) => _handleTapDown(),
      onTapUp: (_) => _handleTapUp(),
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _pulseAnimation,
          _backgroundColorAnimation,
          _shadowColorAnimation,
        ]),
        builder: (context, child) {
          final pulseScale = widget.isPlaying && widget.showPulse 
              ? _pulseAnimation.value 
              : 1.0;
          
          return Transform.scale(
            scale: _scaleAnimation.value * pulseScale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isLoading
                      ? [
                          AppTheme.lightTheme.colorScheme.outline,
                          AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.8),
                        ]
                      : [
                          _backgroundColorAnimation.value ?? _primaryColor,
                          (_backgroundColorAnimation.value ?? _primaryColor).withValues(alpha: 0.8),
                        ],
                ),
                shape: BoxShape.circle,
                boxShadow: widget.isLoading ? [] : [
                  BoxShadow(
                    color: _shadowColorAnimation.value ?? _primaryColor.withValues(alpha: 0.3),
                    blurRadius: widget.isPlaying ? 16 : 12,
                    offset: const Offset(0, 4),
                    spreadRadius: widget.isPlaying ? 2 : 0,
                  ),
                  if (widget.isPlaying)
                    BoxShadow(
                      color: _shadowColorAnimation.value ?? _primaryColor.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: 4,
                    ),
                ],
              ),
              child: Center(
                child: widget.isLoading
                    ? SizedBox(
                        width: widget.size * 0.4,
                        height: widget.size * 0.4,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _iconAnimation,
                        builder: (context, child) {
                          return AnimatedSwitcher(
                            duration: AudioAnimations.stateTransition,
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: RotationTransition(
                                  turns: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: CustomIconWidget(
                              key: ValueKey(widget.isPlaying),
                              iconName: widget.isPlaying ? 'pause' : 'play_arrow',
                              color: Colors.white,
                              size: widget.size * 0.4,
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Enhanced waveform widget with advanced animations
class AnimatedWaveform extends StatefulWidget {
  final bool isPlaying;
  final double width;
  final double height;
  final Color color;
  final Color? glowColor;
  final int barCount;
  final double strokeWidth;
  final bool showGlow;
  final List<double>? customHeights;

  const AnimatedWaveform({
    super.key,
    required this.isPlaying,
    this.width = 60.0,
    this.height = 40.0,
    required this.color,
    this.glowColor,
    this.barCount = 20,
    this.strokeWidth = 2.0,
    this.showGlow = true,
    this.customHeights,
  });

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AudioAnimations.waveformCycle,
      vsync: this,
    );
    
    _animation = AudioAnimations.createWaveformAnimation(_controller);

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
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
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: EnhancedWaveformPainter(
              color: widget.color,
              glowColor: widget.glowColor,
              isAnimating: widget.isPlaying,
              animationValue: _animation.value,
              barCount: widget.barCount,
              strokeWidth: widget.strokeWidth,
              showGlow: widget.showGlow,
              customHeights: widget.customHeights,
            ),
          );
        },
      ),
    );
  }
}

/// Progress indicator with smooth animations
class AnimatedProgressIndicator extends StatefulWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final bool showGlow;

  const AnimatedProgressIndicator({
    super.key,
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.height = 4.0,
    this.borderRadius,
    this.showGlow = false,
  });

  @override
  State<AnimatedProgressIndicator> createState() => _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  double _currentProgress = 0.0;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AudioAnimations.stateTransition,
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _currentProgress = widget.progress;
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _currentProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      
      _currentProgress = widget.progress;
      _controller.reset();
      _controller.forward();
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
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
                    boxShadow: widget.showGlow ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ] : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}