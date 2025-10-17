import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// A comprehensive skeleton loading widget system for the completion celebration screen
/// Provides shimmer effects and loading placeholders that match the final content layout
class SkeletonLoadingWidget extends StatefulWidget {
  final SkeletonType type;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const SkeletonLoadingWidget({
    super.key,
    required this.type,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
    this.padding,
  });

  @override
  State<SkeletonLoadingWidget> createState() => _SkeletonLoadingWidgetState();
}

enum SkeletonType {
  progressStats,
  motivationalMessage,
  completionContext,
  actionButton,
  socialSharing,
  custom,
}

class _SkeletonLoadingWidgetState extends State<SkeletonLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case SkeletonType.progressStats:
        return _buildProgressStatsSkeleton();
      case SkeletonType.motivationalMessage:
        return _buildMotivationalMessageSkeleton();
      case SkeletonType.completionContext:
        return _buildCompletionContextSkeleton();
      case SkeletonType.actionButton:
        return _buildActionButtonSkeleton();
      case SkeletonType.socialSharing:
        return _buildSocialSharingSkeleton();
      case SkeletonType.custom:
        return _buildCustomSkeleton();
    }
  }

  Widget _buildProgressStatsSkeleton() {
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 6.w),
      padding: widget.padding ?? EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItemSkeleton(),
          _buildDividerSkeleton(),
          _buildStatItemSkeleton(),
          _buildDividerSkeleton(),
          _buildStatItemSkeleton(),
        ],
      ),
    );
  }

  Widget _buildStatItemSkeleton() {
    return Expanded(
      child: Column(
        children: [
          // Icon placeholder
          _buildShimmerContainer(
            width: 5.w,
            height: 5.w,
            borderRadius: BorderRadius.circular(2.w),
          ),
          SizedBox(height: 1.h),
          // Value placeholder
          _buildShimmerContainer(
            width: 8.w,
            height: 3.h,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
          SizedBox(height: 0.5.h),
          // Label placeholder
          _buildShimmerContainer(
            width: 12.w,
            height: 2.h,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerSkeleton() {
    return Container(
      height: 8.h,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
      margin: EdgeInsets.symmetric(horizontal: 2.w),
    );
  }

  Widget _buildMotivationalMessageSkeleton() {
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 8.w),
      padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main message placeholder (2 lines)
          _buildShimmerContainer(
            width: double.infinity,
            height: 2.5.h,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
          SizedBox(height: 1.h),
          _buildShimmerContainer(
            width: 70.w,
            height: 2.5.h,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
          SizedBox(height: 2.h),
          // Subtitle placeholder
          _buildShimmerContainer(
            width: 50.w,
            height: 2.h,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionContextSkeleton() {
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 6.w),
      padding: widget.padding ?? EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon placeholder
              _buildShimmerContainer(
                width: 6.w,
                height: 6.w,
                borderRadius: BorderRadius.circular(3.w),
              ),
              SizedBox(width: 3.w),
              // Title placeholder
              Expanded(
                child: _buildShimmerContainer(
                  height: 2.5.h,
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Category and time placeholders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShimmerContainer(
                width: 25.w,
                height: 2.h,
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
              _buildShimmerContainer(
                width: 20.w,
                height: 2.h,
                borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonSkeleton() {
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        children: [
          // Primary button skeleton
          _buildShimmerContainer(
            width: double.infinity,
            height: 6.h,
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          ),
          SizedBox(height: 2.h),
          // Secondary buttons skeleton
          Row(
            children: [
              Expanded(
                child: _buildShimmerContainer(
                  height: 5.h,
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildShimmerContainer(
                  height: 5.h,
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialSharingSkeleton() {
    return Container(
      margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 8.w),
      padding: widget.padding ?? EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) => 
          _buildShimmerContainer(
            width: 12.w,
            height: 5.h,
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSkeleton() {
    return _buildShimmerContainer(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 4.h,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(AppTheme.smallRadius),
    );
  }

  Widget _buildShimmerContainer({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(AppTheme.smallRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + _shimmerAnimation.value, 0.0),
              end: Alignment(1.0 + _shimmerAnimation.value, 0.0),
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Specialized skeleton widgets for specific sections
class ProgressStatsSkeletonWidget extends StatelessWidget {
  const ProgressStatsSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingWidget(
      type: SkeletonType.progressStats,
    );
  }
}

class MotivationalMessageSkeletonWidget extends StatelessWidget {
  const MotivationalMessageSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingWidget(
      type: SkeletonType.motivationalMessage,
    );
  }
}

class CompletionContextSkeletonWidget extends StatelessWidget {
  const CompletionContextSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingWidget(
      type: SkeletonType.completionContext,
    );
  }
}

class ActionButtonsSkeletonWidget extends StatelessWidget {
  const ActionButtonsSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingWidget(
      type: SkeletonType.actionButton,
    );
  }
}

class SocialSharingSkeletonWidget extends StatelessWidget {
  const SocialSharingSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoadingWidget(
      type: SkeletonType.socialSharing,
    );
  }
}