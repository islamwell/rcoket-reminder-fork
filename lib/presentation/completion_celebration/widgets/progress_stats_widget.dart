import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/utils/animation_performance_utils.dart';

class ProgressStatsWidget extends StatefulWidget {
  final Map<String, dynamic> reminderData;

  const ProgressStatsWidget({
    super.key,
    required this.reminderData,
  });

  @override
  State<ProgressStatsWidget> createState() => _ProgressStatsWidgetState();
}

class _ProgressStatsWidgetState extends State<ProgressStatsWidget>
    with TickerProviderStateMixin {
  late AnimationController _counterController;
  late AnimationController _milestoneController;
  late Animation<int> _todayAnimation;
  late Animation<int> _streakAnimation;
  late Animation<int> _totalAnimation;
  late Animation<double> _milestoneScaleAnimation;
  late Animation<double> _milestoneOpacityAnimation;
  
  bool _isFirstCompletion = false;
  bool _isMilestone = false;
  String _milestoneMessage = '';

  @override
  void initState() {
    super.initState();

    // Initialize performance utilities
    AnimationPerformanceUtils.initialize();

    // Create optimized animation controllers using performance utilities
    _counterController = AnimationPerformanceUtils.createOptimizedController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
      debugLabel: 'ProgressCounter',
    );

    _milestoneController = AnimationPerformanceUtils.createOptimizedController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
      debugLabel: 'ProgressMilestone',
    );

    _setupAnimations();
    _checkForMilestones();
    
    _counterController.forward();
    if (_isMilestone) {
      Future.delayed(Duration(milliseconds: 800), () {
        if (mounted) {
          _milestoneController.forward();
        }
      });
    }
  }

  void _setupAnimations() {
    // Handle graceful fallback when stats data is unavailable
    final todayCount = _getSafeIntValue('todayCompletions', 0) + 1;
    final streakCount = _getSafeIntValue('currentStreak', 1);
    final totalCount = _getSafeIntValue('totalCompletions', 0) + 1;

    // Check if this is a first-time completion
    _isFirstCompletion = widget.reminderData['isFirstCompletion'] == true || 
                        totalCount == 1;

    // Modify animation logic for first-time completion scenarios
    final todayBegin = _isFirstCompletion ? 0 : (todayCount - 1);
    final streakBegin = _isFirstCompletion ? 0 : (streakCount - 1);
    final totalBegin = _isFirstCompletion ? 0 : (totalCount - 1);

    // Create performance-optimized animations with curves optimized for device performance
    final baseCurve = _isFirstCompletion ? Curves.easeOutBack : Curves.easeOut;
    final optimizedCurve = AnimationPerformanceUtils.getOptimizedCurve(baseCurve);

    _todayAnimation = IntTween(
      begin: todayBegin,
      end: todayCount,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Interval(0.0, 0.4, curve: optimizedCurve),
    ));

    _streakAnimation = IntTween(
      begin: streakBegin,
      end: streakCount,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Interval(0.2, 0.6, curve: optimizedCurve),
    ));

    _totalAnimation = IntTween(
      begin: totalBegin,
      end: totalCount,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Interval(0.4, 1.0, curve: optimizedCurve),
    ));

    // Create optimized milestone animations
    _milestoneScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(AnimationPerformanceUtils.createOptimizedCurvedAnimation(
      parent: _milestoneController,
      curve: Curves.easeOutBack,
    ));

    _milestoneOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _milestoneController,
      curve: Interval(0.0, 0.5, curve: AnimationPerformanceUtils.getOptimizedCurve(Curves.easeOut)),
    ));
  }

  void _checkForMilestones() {
    final totalCount = _getSafeIntValue('totalCompletions', 0) + 1;
    final streakCount = _getSafeIntValue('currentStreak', 1);

    // Check for milestone achievements
    if (_isFirstCompletion) {
      _isMilestone = true;
      _milestoneMessage = "First Completion! 🎉";
    } else if (totalCount == 7) {
      _isMilestone = true;
      _milestoneMessage = "One Week Strong! 🗓️";
    } else if (totalCount == 30) {
      _isMilestone = true;
      _milestoneMessage = "30 Day Champion! 🏆";
    } else if (totalCount % 50 == 0) {
      _isMilestone = true;
      _milestoneMessage = "$totalCount Completions! 🌟";
    } else if (streakCount == 7) {
      _isMilestone = true;
      _milestoneMessage = "7 Day Streak! 🔥";
    } else if (streakCount == 30) {
      _isMilestone = true;
      _milestoneMessage = "30 Day Streak! 🚀";
    } else if (streakCount % 10 == 0 && streakCount >= 10) {
      _isMilestone = true;
      _milestoneMessage = "$streakCount Day Streak! ⚡";
    }
  }

  int _getSafeIntValue(String key, int defaultValue) {
    try {
      final value = widget.reminderData[key];
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  @override
  void dispose() {
    // Use performance utilities for safe disposal
    AnimationPerformanceUtils.safeDisposeControllers([
      _counterController,
      _milestoneController,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _counterController,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 6.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isFirstCompletion
                      ? [
                          AppTheme.accentLight.withValues(alpha: 0.1),
                          AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05),
                        ]
                      : [
                          AppTheme.lightTheme.colorScheme.surface,
                          AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.8),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: _isFirstCompletion
                    ? Border.all(
                        color: AppTheme.accentLight.withValues(alpha: 0.3),
                        width: 2,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow
                        .withValues(alpha: _isFirstCompletion ? 0.2 : 0.1),
                    blurRadius: _isFirstCompletion ? 15 : 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(
                    'Today',
                    _todayAnimation.value.toString(),
                    CustomIconWidget(
                      iconName: 'today',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 5.w,
                    ),
                    isHighlighted: _isFirstCompletion,
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    'Streak',
                    _streakAnimation.value.toString(),
                    CustomIconWidget(
                      iconName: 'local_fire_department',
                      color: AppTheme.warningLight,
                      size: 5.w,
                    ),
                    isHighlighted: _isFirstCompletion,
                  ),
                  _buildDivider(),
                  _buildStatItem(
                    'Total',
                    _totalAnimation.value.toString(),
                    CustomIconWidget(
                      iconName: 'star',
                      color: AppTheme.accentLight,
                      size: 5.w,
                    ),
                    isHighlighted: _isFirstCompletion,
                  ),
                ],
              ),
            );
          },
        ),
        if (_isMilestone) _buildMilestoneMessage(),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Widget icon, {bool isHighlighted = false}) {
    return Expanded(
      child: Semantics(
        label: '$label: $value',
        hint: isHighlighted ? 'This is your first completion milestone' : 'Your $label progress statistic',
        child: Column(
          children: [
            icon,
            SizedBox(height: 1.h),
            Text(
              value,
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHighlighted 
                    ? AppTheme.accentLight
                    : AppTheme.lightTheme.colorScheme.primary,
                fontSize: isHighlighted ? 24.sp : null,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: isHighlighted
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontWeight: isHighlighted ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneMessage() {
    return AnimatedBuilder(
      animation: _milestoneController,
      builder: (context, child) {
        return Transform.scale(
          scale: _milestoneScaleAnimation.value,
          child: Opacity(
            opacity: _milestoneOpacityAnimation.value,
            child: Semantics(
              label: 'Milestone achievement: $_milestoneMessage',
              hint: 'Congratulations on reaching this special milestone',
              child: Container(
                margin: EdgeInsets.only(top: 2.h, left: 6.w, right: 6.w),
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentLight.withValues(alpha: 0.2),
                      AppTheme.warningLight.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                  border: Border.all(
                    color: AppTheme.accentLight.withValues(alpha: 0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentLight.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'celebration',
                      color: AppTheme.accentLight,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      _milestoneMessage,
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8.h,
      width: 1,
      color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
      margin: EdgeInsets.symmetric(horizontal: 2.w),
    );
  }
}
