import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RecordingWidget extends StatefulWidget {
  final VoidCallback onRecordingComplete;
  final VoidCallback onCancel;

  const RecordingWidget({
    super.key,
    required this.onRecordingComplete,
    required this.onCancel,
  });

  @override
  State<RecordingWidget> createState() => _RecordingWidgetState();
}

class _RecordingWidgetState extends State<RecordingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  Timer? _durationTimer;
  Duration _recordingDuration = Duration.zero;
  bool _isRecording = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _startRecording();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await AudioRecordingService.instance.startRecording();
      setState(() {
        _isRecording = true;
      });
      
      _pulseController.repeat();
      _waveController.repeat();
      
      _durationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted && _isRecording && !_isPaused) {
          setState(() {
            _recordingDuration = Duration(seconds: _recordingDuration.inSeconds + 1);
          });
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: ${e.toString()}')),
      );
      widget.onCancel();
    }
  }

  Future<void> _stopRecording() async {
    try {
      _durationTimer?.cancel();
      _pulseController.stop();
      _waveController.stop();
      
      await AudioRecordingService.instance.stopRecording();
      setState(() {
        _isRecording = false;
      });
      
      widget.onRecordingComplete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: ${e.toString()}')),
      );
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await AudioRecordingService.instance.pauseRecording();
      setState(() {
        _isPaused = true;
      });
      _pulseController.stop();
      _waveController.stop();
    } catch (e) {
      // Pause might not be supported on all platforms
      print('Pause not supported: $e');
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await AudioRecordingService.instance.resumeRecording();
      setState(() {
        _isPaused = false;
      });
      _pulseController.repeat();
      _waveController.repeat();
    } catch (e) {
      // Resume might not be supported on all platforms
      print('Resume not supported: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _durationTimer?.cancel();
      _pulseController.stop();
      _waveController.stop();
      
      await AudioRecordingService.instance.cancelRecording();
      widget.onCancel();
    } catch (e) {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.lightTheme.colorScheme.surface,
            AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.extraLargeRadius)),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          SizedBox(height: 4.h),
          _buildRecordingIndicator(),
          SizedBox(height: 3.h),
          _buildDurationDisplay(),
          SizedBox(height: 4.h),
          _buildWaveform(),
          SizedBox(height: 4.h),
          _buildControls(),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 12.w,
      height: 0.5.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.lightTheme.colorScheme.tertiary,
                    AppTheme.lightTheme.colorScheme.tertiary.withValues(alpha: 0.3),
                  ],
                  stops: [0.3, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.tertiary
                        .withValues(alpha: 0.3 + (_pulseController.value * 0.3)),
                    blurRadius: 20 + (_pulseController.value * 10),
                    spreadRadius: 5 + (_pulseController.value * 5),
                  ),
                ],
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: _isPaused ? 'pause' : 'mic',
                  color: Colors.white,
                  size: 32,
                ),
              ),
            );
          },
        ),
        SizedBox(height: 2.h),
        Text(
          _isPaused ? 'Recording Paused' : 'Recording...',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildDurationDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        _formatDuration(_recordingDuration),
        style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.lightTheme.colorScheme.primary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 8.h,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return CustomPaint(
            painter: RecordingWaveformPainter(
              color: AppTheme.lightTheme.colorScheme.tertiary,
              animationValue: _waveController.value,
              isActive: _isRecording && !_isPaused,
            ),
            size: Size(double.infinity, 8.h),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          iconName: 'close',
          color: AppTheme.errorLight,
          onTap: _cancelRecording,
          label: 'Cancel',
        ),
        if (_isRecording) ...[
          _buildControlButton(
            iconName: _isPaused ? 'play_arrow' : 'pause',
            color: AppTheme.lightTheme.colorScheme.secondary,
            onTap: _isPaused ? _resumeRecording : _pauseRecording,
            label: _isPaused ? 'Resume' : 'Pause',
          ),
        ],
        _buildControlButton(
          iconName: 'check',
          color: AppTheme.lightTheme.colorScheme.primary,
          onTap: _stopRecording,
          label: 'Save',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required String iconName,
    required Color color,
    required VoidCallback onTap,
    required String label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color,
                  color.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: iconName,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class RecordingWaveformPainter extends CustomPainter {
  final Color color;
  final double animationValue;
  final bool isActive;

  RecordingWaveformPainter({
    required this.color,
    required this.animationValue,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isActive ? 1.0 : 0.5)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barCount = 30;
    final barWidth = size.width / barCount;
    
    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth + barWidth / 2;
      
      // Create wave effect
      final wave = (animationValue * 2 * 3.14159) + (i * 0.3);
      final baseHeight = 0.2 + (0.6 * (1 + sin(wave)) / 2);
      
      // Add some randomness for more natural look
      final randomFactor = 0.8 + (0.4 * sin(i * 0.7 + animationValue * 4));
      final barHeight = size.height * baseHeight * randomFactor;
      
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}