import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../core/services/celebration_fallback_data.dart';
import '../../../core/models/completion_context.dart';
import '../../../core/utils/animation_performance_utils.dart';

class MotivationalMessageWidget extends StatefulWidget {
  final int currentStreak;
  final int? totalCompletions;
  final CompletionContext? completionContext;
  final bool isFirstCompletion;

  const MotivationalMessageWidget({
    super.key,
    required this.currentStreak,
    this.totalCompletions,
    this.completionContext,
    this.isFirstCompletion = false,
  });

  @override
  State<MotivationalMessageWidget> createState() =>
      _MotivationalMessageWidgetState();
}

class _MotivationalMessageWidgetState extends State<MotivationalMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String _currentMessage = '';
  String _contextualSubtitle = '';

  final List<String> _islamicMessages = [
    "Alhamdulillahi Rabbil Alameen! 🤲",
    "May Allah accept your good deeds! ✨",
    "Barakallahu feeki! Keep going! 🌟",
    "Your consistency is beautiful! 💚",
    "SubhanAllah Allah is Perfect! Another step closer! 🕌",
    "May this deed be heavy on your scale! ⚖️",
    "Allah loves those who are consistent! 💫",
    "Your effort is seen and appreciated! 👁️",
  ];

  final List<String> _streakMessages = [
    "Amazing! You're building great habits! 🔥",
    "Your dedication is inspiring! 💪",
    "Consistency is the key to success! 🗝️",
    "There Hereafter is better and remains more! Keep it up! 🚀",
    "Every day counts! Well done! 📈",
    "Your commitment is admirable! 🏆",
    "Building momentum beautifully! ⚡",
    "Excellence through persistence! 🎯",
  ];

  @override
  void initState() {
    super.initState();

    // Initialize performance utilities
    AnimationPerformanceUtils.initialize();

    // Create optimized animation controller using performance utilities
    _fadeController = AnimationPerformanceUtils.createOptimizedController(
      duration: Duration(milliseconds: 600),
      vsync: this,
      debugLabel: 'MotivationalFade',
    );

    // Create optimized animation with performance-friendly curve
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(AnimationPerformanceUtils.createOptimizedCurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _selectContextualMessage();
    _fadeController.forward();
  }

  void _selectContextualMessage() {
    final random = math.Random();

    // First-completion celebration messaging - highest priority
    if (widget.isFirstCompletion) {
      final firstCompletionMessages = CelebrationFallbackData.getNewUserEncouragingMessages();
      _currentMessage = firstCompletionMessages[random.nextInt(firstCompletionMessages.length)];
      _contextualSubtitle = _getFirstCompletionSubtitle();
      return;
    }

    // Milestone-based messaging - second priority
    if (widget.totalCompletions != null) {
      final milestoneMessages = CelebrationFallbackData.getMilestoneMessages(widget.totalCompletions!);
      if (milestoneMessages.isNotEmpty && _isMilestone(widget.totalCompletions!)) {
        _currentMessage = milestoneMessages[random.nextInt(milestoneMessages.length)];
        _contextualSubtitle = _getMilestoneSubtitle(widget.totalCompletions!);
        return;
      }
    }

    // Category-specific motivational content with enhanced context awareness
    if (widget.completionContext != null) {
      final categoryMessages = CelebrationFallbackData.getCategorySpecificMessages(
        widget.completionContext!.reminderCategory
      );
      _currentMessage = _enhanceMessageWithContext(
        categoryMessages[random.nextInt(categoryMessages.length)]
      );
      _contextualSubtitle = _getCategorySubtitle(widget.completionContext!.reminderCategory);
      return;
    }

    // Streak-based messaging for consistent users
    if (widget.currentStreak >= 7) {
      _currentMessage = _getStreakSpecificMessage(widget.currentStreak);
      _contextualSubtitle = _getStreakSubtitle(widget.currentStreak);
      return;
    }

    // Fallback to general messages with context enhancement
    List<String> availableMessages = [..._islamicMessages];

    if (widget.currentStreak >= 3) {
      availableMessages.addAll(_streakMessages);
    }

    _currentMessage = availableMessages[random.nextInt(availableMessages.length)];
    _contextualSubtitle = _getGeneralSubtitle();
  }

  String _getFirstCompletionSubtitle() {
    if (widget.completionContext != null) {
      final category = widget.completionContext!.reminderCategory.toLowerCase();
      switch (category) {
        case 'prayer':
        case 'spiritual':
          return "Your spiritual journey begins with prayer! 🤲";
        case 'meditation':
        case 'mindfulness':
          return "Your mindfulness practice starts today! 🧘‍♀️";
        case 'gratitude':
          return "Your grateful heart journey begins! 🙏";
        case 'charity':
        case 'kindness':
          return "Your compassionate journey starts here! 💖";
        case 'quran':
        case 'reading':
          return "Your journey with sacred wisdom begins! 📖";
        case 'dhikr':
        case 'remembrance':
          return "Your remembrance of Allah starts now! ✨";
        default:
          return "Welcome to your spiritual journey!";
      }
    }
    return "Welcome to your spiritual journey!";
  }

  bool _isMilestone(int completions) {
    // Enhanced milestone detection with more granular milestones
    if (completions <= 10) {
      // Early milestones for encouragement
      return completions == 1 || completions == 3 || completions == 5 || completions == 7 || completions == 10;
    } else if (completions <= 30) {
      // Weekly milestones
      return completions == 14 || completions == 21 || completions == 30;
    } else if (completions <= 100) {
      // Monthly and significant milestones
      return completions == 50 || completions == 75 || completions == 100;
    } else {
      // Major milestones for long-term users
      return completions == 200 || completions == 365 || completions == 500 || completions == 1000 || completions % 100 == 0;
    }
  }

  String _getMilestoneSubtitle(int completions) {
    // Enhanced milestone subtitles with more specific messaging
    if (completions == 1) {
      return "Your spiritual journey begins! 🌟";
    } else if (completions == 3) {
      return "Building momentum beautifully! ⚡";
    } else if (completions == 5) {
      return "Five days of dedication! 🙏";
    } else if (completions == 7) {
      return "One week of spiritual growth! 📅";
    } else if (completions == 10) {
      return "Double digits achieved! 🎯";
    } else if (completions == 14) {
      return "Two weeks of consistency! 💪";
    } else if (completions == 21) {
      return "Three weeks of beautiful practice! ✨";
    } else if (completions == 30) {
      return "One month of spiritual transformation! 🌱";
    } else if (completions == 50) {
      return "Fifty moments of connection! 🕊️";
    } else if (completions == 75) {
      return "Incredible dedication milestone! 🏆";
    } else if (completions == 100) {
      return "A century of spiritual moments! 💯";
    } else if (completions == 200) {
      return "Two hundred blessings completed! 🌟";
    } else if (completions == 365) {
      return "A full year of spiritual practice! 🎊";
    } else if (completions == 500) {
      return "Five hundred moments of grace! 👑";
    } else if (completions == 1000) {
      return "One thousand spiritual connections! 🌌";
    } else if (completions % 100 == 0) {
      return "Incredible century milestone! 🏅";
    } else if (completions % 50 == 0) {
      return "Amazing fifty-milestone achieved! 🎖️";
    } else if (completions % 25 == 0) {
      return "Quarter-century milestone reached! 🎯";
    }
    return "Celebrating your beautiful progress! 🎉";
  }

  String _enhanceMessageWithContext(String baseMessage) {
    if (widget.completionContext == null) return baseMessage;
    
    final context = widget.completionContext!;
    final timeOfDay = context.completionTime.hour;
    
    // Add time-based context enhancement
    if (timeOfDay >= 5 && timeOfDay < 12) {
      // Morning completion
      if (context.reminderCategory.toLowerCase().contains('prayer')) {
        return "$baseMessage Start your day blessed! 🌅";
      }
    } else if (timeOfDay >= 12 && timeOfDay < 17) {
      // Afternoon completion
      return "$baseMessage Perfect midday reflection! ☀️";
    } else if (timeOfDay >= 17 && timeOfDay < 21) {
      // Evening completion
      return "$baseMessage Beautiful evening practice! 🌆";
    } else {
      // Night completion
      return "$baseMessage Peaceful night reflection! 🌙";
    }
    
    return baseMessage;
  }

  String _getStreakSpecificMessage(int streak) {
    final random = math.Random();
    
    if (streak >= 30) {
      final messages = [
        "30+ days of consistency! You're unstoppable! 🔥",
        "Your dedication is truly inspiring! 🌟",
        "A month of spiritual growth! Amazing! 📈",
      ];
      return messages[random.nextInt(messages.length)];
    } else if (streak >= 14) {
      final messages = [
        "Two weeks of beautiful consistency! 💪",
        "Your spiritual discipline is remarkable! ⭐",
        "14+ days of growth! Keep shining! ✨",
      ];
      return messages[random.nextInt(messages.length)];
    } else if (streak >= 7) {
      final messages = [
        "One week strong! You're building something beautiful! 🌱",
        "Seven days of dedication! Incredible! 🎯",
        "Your weekly consistency is inspiring! 📅",
      ];
      return messages[random.nextInt(messages.length)];
    }
    
    return _streakMessages[random.nextInt(_streakMessages.length)];
  }

  String _getStreakSubtitle(int streak) {
    if (streak >= 30) {
      return "Your consistency is a beautiful habit! 🌟";
    } else if (streak >= 14) {
      return "Two weeks of spiritual dedication! 💫";
    } else if (streak >= 7) {
      return "One week of consistent practice! 🔥";
    }
    return "Building momentum beautifully! ⚡";
  }

  String _getGeneralSubtitle() {
    if (widget.currentStreak >= 3) {
      return "Your consistency is growing! 📈";
    }
    return "Every step matters on your journey! 👣";
  }

  bool _shouldShowCompletionTime() {
    if (widget.completionContext == null) return false;
    
    final now = DateTime.now();
    final completionTime = widget.completionContext!.completionTime;
    final difference = now.difference(completionTime);
    
    // Show time context if completed within the last 24 hours
    return difference.inHours < 24;
  }

  String _getCompletionTimeMessage() {
    if (widget.completionContext == null) return '';
    
    final completionTime = widget.completionContext!.completionTime;
    final hour = completionTime.hour;
    final now = DateTime.now();
    final difference = now.difference(completionTime);
    
    String timeContext = '';
    if (hour >= 5 && hour < 12) {
      timeContext = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeContext = 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      timeContext = 'evening';
    } else {
      timeContext = 'night';
    }
    
    if (difference.inMinutes < 5) {
      return 'Completed just now this $timeContext';
    } else if (difference.inHours < 1) {
      return 'Completed ${difference.inMinutes} minutes ago this $timeContext';
    } else if (difference.inHours < 24) {
      return 'Completed ${difference.inHours} hours ago this $timeContext';
    }
    
    return 'Completed this $timeContext';
  }

  String _getCategorySubtitle(String category) {
    final baseSubtitle = _getBaseCategorySubtitle(category);
    
    // Add context-aware enhancements
    if (widget.completionContext != null) {
      final timeOfDay = widget.completionContext!.completionTime.hour;
      final dayOfWeek = widget.completionContext!.completionTime.weekday;
      
      // Add time-based context
      if (timeOfDay >= 5 && timeOfDay < 12) {
        return "$baseSubtitle - Perfect morning start! 🌅";
      } else if (timeOfDay >= 21 || timeOfDay < 5) {
        return "$baseSubtitle - Peaceful night reflection! 🌙";
      } else if (dayOfWeek == DateTime.friday && category.toLowerCase().contains('prayer')) {
        return "$baseSubtitle - Blessed Friday practice! 🕌";
      }
    }
    
    // Add streak-based enhancement
    if (widget.currentStreak >= 7) {
      return "$baseSubtitle - Your consistency shines! ✨";
    } else if (widget.currentStreak >= 3) {
      return "$baseSubtitle - Building beautiful habits! 🌱";
    }
    
    return baseSubtitle;
  }

  String _getBaseCategorySubtitle(String category) {
    switch (category.toLowerCase()) {
      case 'prayer':
      case 'spiritual':
        return "Strengthening your spiritual connection";
      case 'meditation':
      case 'mindfulness':
        return "Cultivating inner peace and awareness";
      case 'gratitude':
        return "Nurturing a grateful heart";
      case 'charity':
      case 'kindness':
        return "Spreading compassion and kindness";
      case 'quran':
      case 'reading':
        return "Enriching your soul with wisdom";
      case 'dhikr':
      case 'remembrance':
        return "Remembering Allah in all moments";
      case 'fasting':
      case 'sawm':
        return "Purifying body and soul through discipline";
      case 'dua':
      case 'supplication':
        return "Connecting with Allah through prayer";
      case 'study':
      case 'learning':
        return "Growing in knowledge and wisdom";
      case 'reflection':
      case 'contemplation':
        return "Deepening your spiritual understanding";
      default:
        return "Growing in faith and practice";
    }
  }

  @override
  void dispose() {
    // Proper animation disposal and cleanup for better memory management
    if (_fadeController.isAnimating) {
      _fadeController.stop();
    }
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Motivational message: $_currentMessage',
      hint: _contextualSubtitle.isNotEmpty ? _contextualSubtitle : 'Encouraging message for your achievement',
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 8.w),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
          decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isFirstCompletion
                ? [
                    AppTheme.accentLight.withValues(alpha: 0.2),
                    AppTheme.warningLight.withValues(alpha: 0.1),
                  ]
                : [
                    AppTheme.accentLight.withValues(alpha: 0.1),
                    AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05),
                  ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          border: Border.all(
            color: widget.isFirstCompletion
                ? AppTheme.accentLight.withValues(alpha: 0.4)
                : AppTheme.accentLight.withValues(alpha: 0.2),
            width: widget.isFirstCompletion ? 2 : 1,
          ),
          boxShadow: widget.isFirstCompletion
              ? [
                  BoxShadow(
                    color: AppTheme.accentLight.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Main motivational message
            Text(
              _currentMessage,
              textAlign: TextAlign.center,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                height: 1.4,
                fontSize: widget.isFirstCompletion ? 18.sp : null,
              ),
            ),
            
            // Contextual subtitle
            if (_contextualSubtitle.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Text(
                _contextualSubtitle,
                textAlign: TextAlign.center,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Completion context display with enhanced information
            if (widget.completionContext != null) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: _getCategoryIcon(widget.completionContext!.reminderCategory),
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 4.w,
                        ),
                        SizedBox(width: 2.w),
                        Flexible(
                          child: Text(
                            widget.completionContext!.reminderTitle,
                            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Add completion time context
                    if (_shouldShowCompletionTime()) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        _getCompletionTimeMessage(),
                        style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Streak display for significant streaks
            if (widget.currentStreak >= 7) ...[
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'local_fire_department',
                      color: AppTheme.warningLight,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${widget.currentStreak} Day Streak!',
                      style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
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
    );
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'prayer':
      case 'spiritual':
        return 'mosque';
      case 'meditation':
      case 'mindfulness':
        return 'self_improvement';
      case 'gratitude':
        return 'favorite';
      case 'charity':
      case 'kindness':
        return 'volunteer_activism';
      case 'quran':
      case 'reading':
        return 'menu_book';
      case 'dhikr':
      case 'remembrance':
        return 'psychology';
      case 'fasting':
      case 'sawm':
        return 'restaurant';
      case 'dua':
      case 'supplication':
        return 'pan_tool';
      case 'study':
      case 'learning':
        return 'school';
      case 'reflection':
      case 'contemplation':
        return 'lightbulb';
      case 'exercise':
      case 'fitness':
        return 'fitness_center';
      case 'nature':
      case 'outdoor':
        return 'nature';
      default:
        return 'star';
    }
  }
}
