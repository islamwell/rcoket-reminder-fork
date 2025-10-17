import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/models/completion_context.dart';

/// Widget that displays contextual information about a completed reminder
/// Shows reminder title, category, completion time, and optional notes
class CompletionContextWidget extends StatefulWidget {
  final CompletionContext? context;
  final bool showAnimation;

  const CompletionContextWidget({
    super.key,
    this.context,
    this.showAnimation = true,
  });

  @override
  State<CompletionContextWidget> createState() =>
      _CompletionContextWidgetState();
}

class _CompletionContextWidgetState extends State<CompletionContextWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    if (widget.showAnimation) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completionContext = widget.context ?? CompletionContext.defaultContext();

    return Semantics(
      label: 'Completed reminder: ${completionContext.reminderTitle}',
      hint: 'Details about your completed ${completionContext.reminderCategory} reminder at ${completionContext.formattedCompletionTime}',
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 6.w),
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.surfaceLight,
                AppTheme.secondaryVariantLight,
              ],
            ),
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            border: Border.all(
              color: AppTheme.accentLight.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowLight,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with completion indicator
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    ),
                    child: CustomIconWidget(
                      iconName: 'check_circle',
                      color: AppTheme.successLight,
                      size: 5.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completed',
                          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.successLight,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          completionContext.formattedCompletionTime,
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceLight.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 3.h),

              // Reminder title
              Text(
                completionContext.reminderTitle,
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),

              SizedBox(height: 1.h),

              // Category with icon
              Row(
                children: [
                  CustomIconWidget(
                    iconName: _getCategoryIcon(completionContext.reminderCategory),
                    color: AppTheme.accentLight,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      border: Border.all(
                        color: AppTheme.accentLight.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      completionContext.reminderCategory,
                      style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Duration if available
              if (completionContext.actualDuration != null) ...[
                SizedBox(height: 2.h),
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'schedule',
                      color: AppTheme.primaryLight.withValues(alpha: 0.7),
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      _formatDuration(completionContext.actualDuration!),
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceLight.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Completion notes if available
              if (completionContext.completionNotes != null &&
                  completionContext.completionNotes!.isNotEmpty) ...[
                SizedBox(height: 2.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'note',
                            color: AppTheme.primaryLight.withValues(alpha: 0.7),
                            size: 4.w,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Notes',
                            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        completionContext.completionNotes!,
                        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceLight.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Fallback message for incomplete context
              if (!completionContext.hasCompleteInfo) ...[
                SizedBox(height: 2.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: AppTheme.warningLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                    border: Border.all(
                      color: AppTheme.warningLight.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'info',
                        color: AppTheme.warningLight,
                        size: 4.w,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Text(
                          'Some details may be missing, but your achievement still counts!',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceLight.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }

  /// Get appropriate icon for reminder category
  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'prayer':
      case 'salah':
        return 'mosque';
      case 'quran':
      case 'reading':
        return 'menu_book';
      case 'dhikr':
      case 'remembrance':
        return 'favorite';
      case 'charity':
      case 'sadaqah':
        return 'volunteer_activism';
      case 'fasting':
      case 'sawm':
        return 'restaurant';
      case 'study':
      case 'learning':
        return 'school';
      case 'meditation':
      case 'reflection':
        return 'self_improvement';
      case 'spiritual':
        return 'auto_awesome';
      case 'worship':
        return 'place';
      case 'general':
      default:
        return 'task_alt';
    }
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}