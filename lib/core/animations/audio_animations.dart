import 'package:flutter/material.dart';
import 'dart:math';

/// Comprehensive animation system for audio-related UI components
/// 
/// Provides reusable animation components for:
/// - Button feedback animations (scale, color transitions)
/// - State transition animations (play/pause, favorite toggles)
/// - Loading states and progress indicators
/// - Waveform visualization during audio playback
/// 
/// Requirements implemented: 7.1, 7.2, 7.6

class AudioAnimations {
  // Animation durations
  static const Duration quickFeedback = Duration(milliseconds: 150);
  static const Duration stateTransition = Duration(milliseconds: 300);
  static const Duration playbackAnimation = Duration(milliseconds: 500);
  static const Duration waveformCycle = Duration(milliseconds: 1500);
  
  // Animation curves
  static const Curve buttonFeedback = Curves.easeInOut;
  static const Curve stateChange = Curves.easeInOut;
  static const Curve elasticFeedback = Curves.elasticOut;
  static const Curve smoothTransition = Curves.easeInOutCubic;

  /// Creates a scale animation for button press feedback
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 1.0,
    double end = 0.95,
    Curve curve = buttonFeedback,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Creates a color transition animation
  static Animation<Color?> createColorAnimation(
    AnimationController controller,
    Color beginColor,
    Color endColor, {
    Curve curve = stateChange,
  }) {
    return ColorTween(
      begin: beginColor,
      end: endColor,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Creates a waveform animation for audio playback visualization
  static Animation<double> createWaveformAnimation(
    AnimationController controller, {
    Curve curve = Curves.easeInOut,
  }) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Creates an elastic scale animation for favorite toggle
  static Animation<double> createElasticScaleAnimation(
    AnimationController controller, {
    double begin = 1.0,
    double end = 1.3,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: elasticFeedback,
    ));
  }

  /// Creates a rotation animation for loading indicators
  static Animation<double> createRotationAnimation(
    AnimationController controller,
  ) {
    return Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.linear,
    ));
  }

  /// Creates a fade animation for smooth transitions
  static Animation<double> createFadeAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
    Curve curve = smoothTransition,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Creates a slide animation for smooth transitions
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
    Curve curve = smoothTransition,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Creates a bounce animation for playful feedback
  static Animation<double> createBounceAnimation(
    AnimationController controller, {
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.bounceOut,
    ));
  }

  /// Creates a shake animation for error feedback
  static Animation<double> createShakeAnimation(
    AnimationController controller, {
    double amplitude = 10.0,
  }) {
    return Tween<double>(
      begin: -amplitude,
      end: amplitude,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticIn,
    ));
  }

  /// Creates a ripple animation for touch feedback
  static Animation<double> createRippleAnimation(
    AnimationController controller,
  ) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
  }

  /// Creates a morphing animation between two values
  static Animation<double> createMorphAnimation(
    AnimationController controller, {
    required double begin,
    required double end,
    Curve curve = smoothTransition,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: curve,
    ));
  }

  /// Creates a staggered animation for multiple elements
  static List<Animation<double>> createStaggeredAnimations(
    AnimationController controller,
    int count, {
    Duration staggerDelay = const Duration(milliseconds: 100),
    Curve curve = smoothTransition,
  }) {
    final animations = <Animation<double>>[];
    final totalDuration = controller.duration!.inMilliseconds;
    final delayMs = staggerDelay.inMilliseconds;
    
    for (int i = 0; i < count; i++) {
      final startTime = (i * delayMs) / totalDuration;
      final endTime = ((i * delayMs) + (totalDuration - (count - 1) * delayMs)) / totalDuration;
      
      animations.add(
        Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: controller,
          curve: Interval(
            startTime.clamp(0.0, 1.0),
            endTime.clamp(0.0, 1.0),
            curve: curve,
          ),
        )),
      );
    }
    
    return animations;
  }
}