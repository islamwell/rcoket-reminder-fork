import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/models/completion_context.dart';
import '../../core/services/celebration_fallback_data.dart';
import '../../core/utils/animation_performance_utils.dart';
import './widgets/animated_checkmark_widget.dart';
import './widgets/completion_context_widget.dart';
import './widgets/islamic_pattern_widget.dart';
import './widgets/motivational_message_widget.dart';
import './widgets/particle_effect_widget.dart';
import './widgets/progress_stats_widget.dart';
import './widgets/skeleton_loading_widget.dart';
import './widgets/social_sharing_widget.dart';

class CompletionCelebration extends StatefulWidget {
  const CompletionCelebration({super.key});

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with TickerProviderStateMixin {
  late AnimationController _overlayController;
  late AnimationController _contentController;
  late Animation<double> _overlayAnimation;
  late Animation<double> _contentAnimation;
  // Dashboard data with enhanced state management
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoading = true;
  bool _hasDataLoadingFailed = false;

  
  // Completion context for displaying reminder information
  CompletionContext? _completionContext;

  @override
  void initState() {
    super.initState();
    _loadDashboardDataWithFallback();

    // Initialize performance utilities
    AnimationPerformanceUtils.initialize();

    // Create optimized animation controllers using performance utilities
    _overlayController = AnimationPerformanceUtils.createOptimizedController(
      duration: Duration(milliseconds: 250),
      vsync: this,
      debugLabel: 'CelebrationOverlay',
    );

    _contentController = AnimationPerformanceUtils.createOptimizedController(
      duration: Duration(milliseconds: 400),
      vsync: this,
      debugLabel: 'CelebrationContent',
    );

    // Create optimized animations with performance-friendly curves
    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(AnimationPerformanceUtils.createOptimizedCurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeOut,
    ));

    _contentAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(AnimationPerformanceUtils.createOptimizedCurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutBack,
    ));

    _startCelebration();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeCompletionContext();
  }

  void _initializeCompletionContext() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      try {
        _completionContext = CompletionContext.fromNavigation(args);
      } catch (e) {
        // If context creation fails, use default context
        _completionContext = CompletionContext.defaultContext();
        print('Failed to create completion context from navigation args: $e');
      }
    } else {
      // No arguments provided, use default context
      _completionContext = CompletionContext.defaultContext();
    }
  }

  void _startCelebration() async {
    await _overlayController.forward();
    await _contentController.forward();
  }



  void _dismissCelebration() async {
    // Optimized dismissal with proper animation cleanup
    if (_contentController.isAnimating) {
      _contentController.stop();
    }
    if (_overlayController.isAnimating) {
      _overlayController.stop();
    }
    
    // Faster reverse animations for better UX
    await Future.wait([
      _contentController.reverse(),
      _overlayController.reverse(),
    ]);
    
    if (mounted) {
      // Navigate to dashboard as the primary action
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  @override
  void dispose() {
    // Use performance utilities for safe disposal
    AnimationPerformanceUtils.safeDisposeControllers([
      _overlayController,
      _contentController,
    ]);
    super.dispose();
  }

  // Enhanced data loading with fallback and proper error handling
  Future<void> _loadDashboardDataWithFallback() async {
    setState(() {
      _isLoading = true;
      _hasDataLoadingFailed = false;
    });

    try {
      // Use the enhanced service methods with retry logic
      final stats = await CompletionFeedbackService.instance.getDashboardStatsWithRetry();
      final streaks = await CompletionFeedbackService.instance.getCompletionStreaksWithRetry();
      
      setState(() {
        _dashboardStats = {
          ...stats,
          ...streaks,
        };
        _isLoading = false;
        _hasDataLoadingFailed = false;
      });
    } catch (e) {
      // Silent fallback to encouraging content - no error messages shown to user
      setState(() {
        _dashboardStats = CelebrationFallbackData.getExistingUserFallbackStats();
        _isLoading = false;
        _hasDataLoadingFailed = true;
      });
      
      // Log error for debugging but don't expose to user
      print('Dashboard data loading failed, using fallback: $e');
    }
  }

  // Retry method for users who want to try loading data again
  Future<void> _retryDataLoading() async {
    await _loadDashboardDataWithFallback();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _dismissCelebration();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: _overlayAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Optimized blur background with performance considerations
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AnimationPerformanceUtils.getOptimizedBlurRadius(_overlayAnimation.value * 10),
                    sigmaY: AnimationPerformanceUtils.getOptimizedBlurRadius(_overlayAnimation.value * 10),
                  ),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: AnimationPerformanceUtils.getOptimizedOpacity(_overlayAnimation.value * 0.5),
                    ),
                  ),
                ),

                // Particle effects with performance optimization
                if (_overlayAnimation.value > 0.5 && AnimationPerformanceUtils.shouldEnableComplexAnimations())
                  Positioned.fill(
                    child: ParticleEffectWidget(),
                  ),

                // Main content
                AnimatedBuilder(
                  animation: _contentAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _contentAnimation.value,
                      child: Opacity(
                        opacity: _contentAnimation.value.clamp(0.0, 1.0),
                        child: _buildCelebrationContent(),
                      ),
                    );
                  },
                ),

                // Close button with accessibility improvements
                Positioned(
                  top: 8.h,
                  right: 4.w,
                  child: Semantics(
                    label: 'Close celebration screen',
                    hint: 'Double tap to close the celebration and return to dashboard',
                    button: true,
                    child: GestureDetector(
                      onTap: _dismissCelebration,
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: 'close',
                          color: Colors.white,
                          size: 5.w,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCelebrationContent() {
    return SafeArea(
      child: Semantics(
        label: 'Completion celebration screen',
        hint: 'Celebrating your achievement with progress statistics and motivational messages',
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              SizedBox(height: 8.h),

              // Islamic pattern background
              Stack(
                alignment: Alignment.center,
                children: [
                  IslamicPatternWidget(),
                  AnimatedCheckmarkWidget(
                    onAnimationComplete: () {
                      // Trigger additional haptic feedback
                      HapticFeedback.heavyImpact();
                    },
                  ),
                ],
              ),

              SizedBox(height: 4.h),

              // Completion context information with loading state
              _buildCompletionContextSection(),

              SizedBox(height: 4.h),

              // Progress statistics with loading state
              _buildProgressSection(),

              SizedBox(height: 3.h),

              // Motivational message with loading state
              _buildMotivationalSection(),

              SizedBox(height: 4.h),

              // Social sharing options with loading state
              _buildSocialSharingSection(),

              SizedBox(height: 4.h),

              // Action buttons
              _buildActionButtons(),

              SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildProgressSection() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _isLoading
          ? ProgressStatsSkeletonWidget(key: ValueKey('progress_skeleton'))
          : Column(
              key: ValueKey('progress_content'),
              children: [
                ProgressStatsWidget(reminderData: _dashboardStats),
                if (_hasDataLoadingFailed) _buildRetryOption(),
              ],
            ),
    );
  }

  Widget _buildMotivationalSection() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _isLoading
          ? MotivationalMessageSkeletonWidget(key: ValueKey('motivational_skeleton'))
          : MotivationalMessageWidget(
              key: ValueKey('motivational_content'),
              currentStreak: _dashboardStats['currentStreak'] as int? ?? 1,
              totalCompletions: (_dashboardStats['totalCompletions'] as int? ?? 0) + 1,
              completionContext: _completionContext,
              isFirstCompletion: _dashboardStats['isFirstCompletion'] == true,
            ),
    );
  }



  Widget _buildCompletionContextSection() {
    // Completion context doesn't depend on dashboard data loading, so show immediately
    return CompletionContextWidget(
      context: _completionContext,
      showAnimation: true,
    );
  }

  Widget _buildSocialSharingSection() {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _isLoading
          ? SocialSharingSkeletonWidget(key: ValueKey('social_skeleton'))
          : SocialSharingWidget(
              key: ValueKey('social_content'),
              reminderData: _dashboardStats,
            ),
    );
  }

  Widget _buildRetryOption() {
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      child: Semantics(
        label: 'Refresh progress data',
        hint: 'Double tap to retry loading your progress statistics',
        button: true,
        child: TextButton.icon(
          onPressed: _retryDataLoading,
          icon: CustomIconWidget(
            iconName: 'refresh',
            color: Colors.white.withValues(alpha: 0.7),
            size: 4.w,
          ),
          label: Text(
            'Refresh Progress',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildActionButtons() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        children: [
          // Primary continue button with accessibility improvements
          Semantics(
            label: 'Continue to dashboard',
            hint: 'Primary action button. Double tap to continue to your dashboard',
            button: true,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _dismissCelebration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                  ),
                  elevation: 4,
                  shadowColor: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: 'arrow_forward',
                      color: Colors.white,
                      size: 5.w,
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Secondary action buttons
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'View progress',
                  hint: 'Double tap to view detailed progress statistics',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () {
                      // Use pushNamed to allow back navigation to celebration
                      Navigator.pushNamed(context, AppRoutes.reminderManagement);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side:
                          BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.mediumRadius),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'trending_up',
                          color: Colors.white,
                          size: 4.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'View Progress',
                          style:
                              AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Semantics(
                  label: 'Set new goal',
                  hint: 'Double tap to create a new reminder or goal',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () {
                      // Use pushNamed to allow back navigation to celebration
                      Navigator.pushNamed(context, AppRoutes.createReminder);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side:
                          BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.mediumRadius),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'flag',
                          color: Colors.white,
                          size: 4.w,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Set Goal',
                          style:
                              AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


}
