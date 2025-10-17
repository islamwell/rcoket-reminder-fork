import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class for optimizing animations based on device performance
class AnimationPerformanceUtils {
  static bool _isLowEndDevice = false;
  static bool _initialized = false;

  /// Initialize performance detection
  static void initialize() {
    if (_initialized) return;
    
    _initialized = true;
    _detectDevicePerformance();
  }

  /// Detect if the device is low-end for animation optimization
  static void _detectDevicePerformance() {
    // In debug mode, assume medium performance
    if (kDebugMode) {
      _isLowEndDevice = false;
      return;
    }

    // Simple heuristic based on platform
    // In a real app, you might use device_info_plus package for more detailed detection
    if (Platform.isAndroid) {
      // Assume older Android devices might be lower performance
      _isLowEndDevice = false; // Default to false, can be enhanced with device_info
    } else if (Platform.isIOS) {
      // iOS devices generally have good performance
      _isLowEndDevice = false;
    } else {
      _isLowEndDevice = false;
    }
  }

  /// Get optimized animation duration based on device performance
  static Duration getOptimizedDuration(Duration baseDuration) {
    initialize();
    
    if (_isLowEndDevice) {
      // Reduce animation duration by 25% for low-end devices
      return Duration(milliseconds: (baseDuration.inMilliseconds * 0.75).round());
    }
    
    return baseDuration;
  }

  /// Get optimized animation curve for better performance
  static Curve getOptimizedCurve(Curve baseCurve) {
    initialize();
    
    if (_isLowEndDevice) {
      // Use simpler curves for better performance on low-end devices
      if (baseCurve == Curves.elasticOut || baseCurve == Curves.bounceOut) {
        return Curves.easeOutBack;
      }
      if (baseCurve == Curves.elasticIn || baseCurve == Curves.bounceIn) {
        return Curves.easeInBack;
      }
      if (baseCurve == Curves.elasticInOut || baseCurve == Curves.bounceInOut) {
        return Curves.easeInOutBack;
      }
    }
    
    return baseCurve;
  }

  /// Get optimized particle count for particle effects
  static int getOptimizedParticleCount(int baseCount) {
    initialize();
    
    if (_isLowEndDevice) {
      // Reduce particle count by 40% for low-end devices
      return (baseCount * 0.6).round().clamp(3, baseCount);
    }
    
    return baseCount;
  }

  /// Get optimized frame rate for continuous animations
  static Duration getOptimizedFrameRate() {
    initialize();
    
    if (_isLowEndDevice) {
      // 30 FPS for low-end devices
      return Duration(milliseconds: 33);
    }
    
    // 60 FPS for normal devices
    return Duration(milliseconds: 16);
  }

  /// Check if device should use reduced motion
  static bool shouldUseReducedMotion(BuildContext context) {
    initialize();
    
    // Check system accessibility settings
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations) {
      return true;
    }
    
    return _isLowEndDevice;
  }

  /// Get optimized opacity for overlay effects
  static double getOptimizedOpacity(double baseOpacity) {
    initialize();
    
    if (_isLowEndDevice) {
      // Reduce opacity slightly for better performance
      return (baseOpacity * 0.9).clamp(0.0, 1.0);
    }
    
    return baseOpacity;
  }

  /// Get optimized blur radius for backdrop filters
  static double getOptimizedBlurRadius(double baseRadius) {
    initialize();
    
    if (_isLowEndDevice) {
      // Reduce blur radius for better performance
      return (baseRadius * 0.7).clamp(1.0, baseRadius);
    }
    
    return baseRadius;
  }

  /// Check if complex animations should be enabled
  static bool shouldEnableComplexAnimations() {
    initialize();
    return !_isLowEndDevice;
  }

  /// Get optimized animation controller settings
  static AnimationController createOptimizedController({
    required Duration duration,
    required TickerProvider vsync,
    String? debugLabel,
  }) {
    initialize();
    
    return AnimationController(
      duration: getOptimizedDuration(duration),
      vsync: vsync,
      debugLabel: debugLabel,
    );
  }

  /// Create optimized curved animation
  static CurvedAnimation createOptimizedCurvedAnimation({
    required AnimationController parent,
    required Curve curve,
    Curve? reverseCurve,
  }) {
    initialize();
    
    return CurvedAnimation(
      parent: parent,
      curve: getOptimizedCurve(curve),
      reverseCurve: reverseCurve != null ? getOptimizedCurve(reverseCurve) : null,
    );
  }

  /// Dispose animation controller safely
  static void safeDisposeController(AnimationController? controller) {
    if (controller != null) {
      if (controller.isAnimating) {
        controller.stop();
      }
      controller.dispose();
    }
  }

  /// Dispose multiple animation controllers safely
  static void safeDisposeControllers(List<AnimationController?> controllers) {
    for (final controller in controllers) {
      safeDisposeController(controller);
    }
  }
}