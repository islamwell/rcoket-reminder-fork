import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/animation_performance_utils.dart';
import '../../../theme/app_theme.dart';

class ParticleEffectWidget extends StatefulWidget {
  const ParticleEffectWidget({super.key});

  @override
  State<ParticleEffectWidget> createState() => _ParticleEffectWidgetState();
}

class _ParticleEffectWidgetState extends State<ParticleEffectWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Particle> _particles;
  late int _particleCount;

  @override
  void initState() {
    super.initState();

    // Initialize performance utilities and get optimized particle count
    AnimationPerformanceUtils.initialize();
    _particleCount = AnimationPerformanceUtils.getOptimizedParticleCount(12);

    // Create optimized animation controller
    _animationController = AnimationPerformanceUtils.createOptimizedController(
      duration: Duration(seconds: 2),
      vsync: this,
      debugLabel: 'ParticleEffect',
    );

    _initializeParticles();
    _animationController.repeat();
  }

  void _initializeParticles() {
    // Performance-optimized particle initialization with dynamic count
    _particles = List.generate(_particleCount, (index) {
      return Particle(
        x: 50.w,
        y: 50.h,
        vx: (math.Random().nextDouble() - 0.5) * 2.5, // Further reduced velocity for smoother animation
        vy: (math.Random().nextDouble() - 0.5) * 2.5,
        size: math.Random().nextDouble() * 2.5 + 1.0, // Optimized particle size for better performance
        color: index % 2 == 0
            ? AppTheme.lightTheme.colorScheme.primary
            : AppTheme.accentLight,
        life: 1.0,
      );
    });
  }

  @override
  void dispose() {
    // Use performance utilities for safe disposal
    AnimationPerformanceUtils.safeDisposeController(_animationController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        _updateParticles();
        return CustomPaint(
          size: Size(100.w, 100.h),
          painter: ParticlePainter(_particles),
        );
      },
    );
  }

  void _updateParticles() {
    // Optimized particle update with reduced calculations
    for (var particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life -= 0.015; // Slightly slower decay for smoother animation

      if (particle.life <= 0) {
        // Reset particle with optimized random generation
        particle.x = 50.w;
        particle.y = 50.h;
        particle.vx = (math.Random().nextDouble() - 0.5) * 3;
        particle.vy = (math.Random().nextDouble() - 0.5) * 3;
        particle.life = 1.0;
      }
    }
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double life;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.life * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * particle.life,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
