import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class IslamicPatternWidget extends StatefulWidget {
  const IslamicPatternWidget({super.key});

  @override
  State<IslamicPatternWidget> createState() => _IslamicPatternWidgetState();
}

class _IslamicPatternWidgetState extends State<IslamicPatternWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Optimized animation controllers with reduced duration for better performance
    _rotationController = AnimationController(
      duration: Duration(seconds: 30), // Increased from 20s for smoother rotation on low-end devices
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(seconds: 3), // Increased from 2s for smoother pulsing
      vsync: this,
    );

    // Optimized animations with performance-friendly curves
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear, // Linear is most performance-friendly for continuous rotation
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.9, // Reduced range from 0.8-1.2 to 0.9-1.1 for subtler effect
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut, // Keep easeInOut for smooth pulsing
    ));

    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    // Proper animation disposal and cleanup for better memory management
    if (_rotationController.isAnimating) {
      _rotationController.stop();
    }
    if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 60.w,
              height: 60.w,
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  primaryColor: AppTheme.lightTheme.colorScheme.primary,
                  accentColor: AppTheme.accentLight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class IslamicPatternPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;
  
  // Cache paint objects for better performance
  late final Paint _gradientPaint;
  late final Paint _strokePaint;

  IslamicPatternPainter({
    required this.primaryColor,
    required this.accentColor,
  }) {
    // Pre-create paint objects to avoid recreation on each paint call
    _gradientPaint = Paint()..style = PaintingStyle.fill;
    _strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round; // Smoother line endings
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create gradient shader only once per paint call
    _gradientPaint.shader = RadialGradient(
      colors: [
        primaryColor.withValues(alpha: 0.2), // Reduced opacity for better performance
        accentColor.withValues(alpha: 0.08),
        primaryColor.withValues(alpha: 0.03),
      ],
      stops: [0.0, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Optimized geometric pattern drawing with reduced complexity
    const int lineCount = 6; // Reduced from 8 for better performance
    const double angleStep = 60.0; // 360/6 degrees
    
    for (int i = 0; i < lineCount; i++) {
      final angle = (i * angleStep) * (math.pi / 180);
      final startPoint = Offset(
        center.dx + (radius * 0.35) * math.cos(angle), // Slightly adjusted for better visual balance
        center.dy + (radius * 0.35) * math.sin(angle),
      );
      final endPoint = Offset(
        center.dx + (radius * 0.85) * math.cos(angle), // Slightly reduced for cleaner look
        center.dy + (radius * 0.85) * math.sin(angle),
      );

      // Use separate paint for lines with optimized stroke width
      canvas.drawLine(startPoint, endPoint, _gradientPaint..strokeWidth = 1.5);
    }

    // Optimized concentric circles with reduced count
    const List<double> circleRadii = [0.25, 0.5, 0.75]; // Pre-calculated ratios
    for (final radiusRatio in circleRadii) {
      canvas.drawCircle(
        center,
        radius * radiusRatio,
        _strokePaint..shader = _gradientPaint.shader,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double cos(double radians) => math.cos(radians);
double sin(double radians) => math.sin(radians);

// Import math for trigonometric functions
