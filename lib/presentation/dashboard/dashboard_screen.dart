import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../common/widgets/notification_status_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Map<String, int> _stats = {
    'totalReminders': 0,
    'activeReminders': 0,
    'completedToday': 0,
    'weeklyStreak': 0,
  };
  
  List<Map<String, dynamic>> _recentActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadDashboardData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load reminders data
      final reminders = await ReminderStorageService.instance.getReminders();
      
      // Calculate stats
      final activeReminders = reminders.where((r) => r['status'] == 'active').length;
      final completedToday = reminders.where((r) {
        final lastCompleted = r['lastCompleted'] as String?;
        if (lastCompleted != null) {
          final completedDate = DateTime.parse(lastCompleted);
          final today = DateTime.now();
          return completedDate.year == today.year &&
                 completedDate.month == today.month &&
                 completedDate.day == today.day;
        }
        return false;
      }).length;
      
      // Load completion feedback data for streak calculation
      final completionData = await CompletionFeedbackService.instance.getAllFeedback();
      final weeklyStreak = _calculateWeeklyStreak(completionData);
      
      // Generate recent activity
      final recentActivity = _generateRecentActivity(reminders, completionData);
      
      setState(() {
        _stats = {
          'totalReminders': reminders.length,
          'activeReminders': activeReminders,
          'completedToday': completedToday,
          'weeklyStreak': weeklyStreak,
        };
        _recentActivity = recentActivity;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() => _isLoading = false);
    }
  }

  int _calculateWeeklyStreak(List<Map<String, dynamic>> completions) {
    if (completions.isEmpty) return 0;
    
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < 7; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final hasCompletion = completions.any((completion) {
        final completionDate = DateTime.parse(completion['completedAt']);
        return completionDate.year == checkDate.year &&
               completionDate.month == checkDate.month &&
               completionDate.day == checkDate.day;
      });
      
      if (hasCompletion) {
        streak++;
      } else if (i > 0) {
        break; // Break streak if no completion found (except for today)
      }
    }
    
    return streak;
  }

  List<Map<String, dynamic>> _generateRecentActivity(
    List<Map<String, dynamic>> reminders,
    List<Map<String, dynamic>> completions,
  ) {
    List<Map<String, dynamic>> activities = [];
    
    // Add recent completions with enhanced reminder data for navigation
    for (final completion in completions.take(5)) {
      // Find the corresponding reminder for this completion
      final reminderId = completion['reminderId'];
      final correspondingReminder = reminders.firstWhere(
        (reminder) => reminder['id'] == reminderId,
        orElse: () => <String, dynamic>{},
      );
      
      // Enhanced completion data structure for detail screen display
      final enhancedCompletionData = _enhanceCompletionData(completion);
      
      // Create comprehensive activity item with all necessary data for reminder details
      activities.add({
        'type': 'completion',
        'title': 'Completed: ${completion['reminderTitle'] ?? 'Unknown Reminder'}',
        'subtitle': _buildCompletionSubtitle(enhancedCompletionData),
        'time': completion['completedAt'] ?? DateTime.now().toIso8601String(),
        'icon': Icons.check_circle,
        'color': Colors.green,
        'reminderId': reminderId,
        'reminderData': correspondingReminder.isNotEmpty ? correspondingReminder : null,
        'completionData': enhancedCompletionData,
        // Additional fields for detail screen navigation
        'hasDetailData': correspondingReminder.isNotEmpty,
        'completionSummary': _buildCompletionSummary(enhancedCompletionData),
      });
    }
    
    // Add recent reminder creations with enhanced reminder data for navigation
    for (final reminder in reminders.take(3)) {
      if (reminder['createdAt'] != null) {
        // Enhanced reminder data for detail screen
        final enhancedReminderData = _enhanceReminderData(reminder);
        
        activities.add({
          'type': 'creation',
          'title': 'Created: ${reminder['title'] ?? 'Untitled Reminder'}',
          'subtitle': 'Category: ${reminder['category'] ?? 'General'}',
          'time': reminder['createdAt'],
          'icon': Icons.add_circle,
          'color': Colors.blue,
          'reminderId': reminder['id'],
          'reminderData': enhancedReminderData,
          'completionData': null,
          // Additional fields for detail screen navigation
          'hasDetailData': true,
          'completionSummary': null,
        });
      }
    }
    
    // Sort by time (most recent first) with safe date parsing
    activities.sort((a, b) {
      try {
        final timeA = DateTime.parse(a['time']);
        final timeB = DateTime.parse(b['time']);
        return timeB.compareTo(timeA);
      } catch (e) {
        print('Error parsing activity times for sorting: $e');
        return 0; // Keep original order if parsing fails
      }
    });
    
    return activities.take(8).toList();
  }

  /// Enhance completion data with all necessary fields for detail screen display
  Map<String, dynamic> _enhanceCompletionData(Map<String, dynamic> completion) {
    final enhanced = Map<String, dynamic>.from(completion);
    
    // Ensure all required fields exist with proper defaults
    enhanced['rating'] = completion['rating'] ?? 0;
    enhanced['mood'] = completion['mood'] ?? 0;
    enhanced['moodBefore'] = completion['moodBefore'] ?? 'neutral';
    enhanced['moodAfter'] = completion['moodAfter'] ?? 'neutral';
    enhanced['comments'] = completion['comments'] ?? '';
    enhanced['difficultyLevel'] = completion['difficultyLevel'] ?? 'moderate';
    enhanced['durationMinutes'] = completion['durationMinutes'] ?? 0;
    enhanced['wouldRecommend'] = completion['wouldRecommend'] ?? false;
    enhanced['completedAt'] = completion['completedAt'] ?? DateTime.now().toIso8601String();
    enhanced['reminderTitle'] = completion['reminderTitle'] ?? 'Unknown Reminder';
    enhanced['reminderCategory'] = completion['reminderCategory'] ?? 'General';
    
    // Add computed fields for better display
    enhanced['hasComments'] = (completion['comments'] as String?)?.isNotEmpty ?? false;
    enhanced['hasRating'] = (completion['rating'] as int?) != null && (completion['rating'] as int) > 0;
    enhanced['moodImprovement'] = _calculateMoodImprovement(
      completion['moodBefore'] as String?,
      completion['moodAfter'] as String?,
    );
    enhanced['formattedDuration'] = _formatDuration(completion['durationMinutes'] as int?);
    enhanced['ratingStars'] = _generateRatingStars(completion['rating'] as int?);
    
    return enhanced;
  }

  /// Enhance reminder data with additional fields for detail screen
  Map<String, dynamic> _enhanceReminderData(Map<String, dynamic> reminder) {
    final enhanced = Map<String, dynamic>.from(reminder);
    
    // Ensure all required fields exist with proper defaults
    enhanced['title'] = reminder['title'] ?? 'Untitled Reminder';
    enhanced['category'] = reminder['category'] ?? 'General';
    enhanced['description'] = reminder['description'] ?? '';
    enhanced['status'] = reminder['status'] ?? 'active';
    enhanced['createdAt'] = reminder['createdAt'] ?? DateTime.now().toIso8601String();
    enhanced['completedCount'] = reminder['completedCount'] ?? 0;
    enhanced['streak'] = reminder['streak'] ?? 0;
    enhanced['successRate'] = reminder['successRate'] ?? 0;
    enhanced['isPaused'] = reminder['isPaused'] ?? false;
    enhanced['completionHistory'] = reminder['completionHistory'] ?? <Map<String, dynamic>>[];
    
    // Add computed fields for better display
    enhanced['hasDescription'] = (reminder['description'] as String?)?.isNotEmpty ?? false;
    enhanced['isActive'] = reminder['status'] == 'active';
    enhanced['formattedCreatedAt'] = _formatDateTime(reminder['createdAt'] as String?);
    enhanced['completionSummary'] = _buildReminderCompletionSummary(enhanced);
    
    return enhanced;
  }

  /// Build subtitle for completion activity items
  String _buildCompletionSubtitle(Map<String, dynamic> completionData) {
    final rating = completionData['rating'] as int? ?? 0;
    final mood = completionData['mood'] as int? ?? 0;
    
    if (rating > 0 && mood > 0) {
      return 'Rating: $rating/5 • Mood: $mood/5';
    } else if (rating > 0) {
      return 'Rating: $rating/5';
    } else if (mood > 0) {
      return 'Mood: $mood/5';
    } else {
      return 'Completed successfully';
    }
  }

  /// Build completion summary for activity items
  String _buildCompletionSummary(Map<String, dynamic> completionData) {
    final parts = <String>[];
    
    final rating = completionData['rating'] as int? ?? 0;
    if (rating > 0) {
      parts.add('Rated $rating/5');
    }
    
    final moodBefore = completionData['moodBefore'] as String?;
    final moodAfter = completionData['moodAfter'] as String?;
    if (moodBefore != null && moodAfter != null && moodBefore != moodAfter) {
      parts.add('Mood: $moodBefore → $moodAfter');
    }
    
    final duration = completionData['durationMinutes'] as int? ?? 0;
    if (duration > 0) {
      parts.add('${duration}min');
    }
    
    final hasComments = completionData['hasComments'] as bool? ?? false;
    if (hasComments) {
      parts.add('Has notes');
    }
    
    return parts.isNotEmpty ? parts.join(' • ') : 'Completed';
  }

  /// Build completion summary for reminder items
  String _buildReminderCompletionSummary(Map<String, dynamic> reminderData) {
    final completedCount = reminderData['completedCount'] as int? ?? 0;
    final streak = reminderData['streak'] as int? ?? 0;
    
    if (completedCount > 0 && streak > 0) {
      return '$completedCount completions • $streak day streak';
    } else if (completedCount > 0) {
      return '$completedCount completions';
    } else if (streak > 0) {
      return '$streak day streak';
    } else {
      return 'New reminder';
    }
  }

  /// Calculate mood improvement between before and after states
  double _calculateMoodImprovement(String? moodBefore, String? moodAfter) {
    final moodValues = {
      'sad': 1.0,
      'neutral': 2.0,
      'happy': 3.0,
      'excited': 4.0,
      'blessed': 5.0,
    };
    
    final beforeValue = moodValues[moodBefore] ?? 2.0;
    final afterValue = moodValues[moodAfter] ?? 3.0;
    
    return afterValue - beforeValue;
  }

  /// Format duration in minutes to human-readable string
  String _formatDuration(int? minutes) {
    if (minutes == null || minutes <= 0) return '0 min';
    
    if (minutes < 60) {
      return '${minutes} min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}m';
      }
    }
  }

  /// Generate rating stars string for display
  String _generateRatingStars(int? rating) {
    if (rating == null || rating <= 0) return '';
    
    final stars = '★' * rating;
    final emptyStars = '☆' * (5 - rating);
    return stars + emptyStars;
  }

  /// Format DateTime string to human-readable format
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: NotificationStatusBanner()),
              SliverToBoxAdapter(child: _buildWelcomeSection()),
              SliverToBoxAdapter(child: _buildStatsGrid()),
              SliverToBoxAdapter(child: _buildQuickActions()),
              SliverToBoxAdapter(child: _buildRecentActivity()),
              SliverToBoxAdapter(child: SizedBox(height: 92.3)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.darkGreenStart,
                AppTheme.darkGreenEnd,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, '/settings'),
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              boxShadow: AppTheme.buttonShadows,
            ),
            child: Icon(Icons.settings, color: Colors.white),
          ),
        ),
        SizedBox(width: 16),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkGreenStart.withValues(alpha: 0.1),
            AppTheme.darkGreenEnd.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.extraLargeRadius),
        border: Border.all(color: AppTheme.darkGreenStart.withValues(alpha: 0.2)),
        boxShadow: AppTheme.containerShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting text positioned at the top, closer to settings area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assalamo alaykum',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.darkGreenStart, AppTheme.darkGreenEnd],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                  boxShadow: AppTheme.cardShadows,
                ),
                child: Icon(
                  AuthService.instance.isGuestMode ? Icons.person : Icons.person_outline,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AuthService.instance.userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[900],
                      ),
                    ),
                    if (AuthService.instance.isGuestMode)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                        ),
                        child: Text(
                          'Guest Mode',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Keep up the great work with your spiritual journey!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) {
      return Container(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: [
          _buildStatCard(
            'Total Reminders',
            _stats['totalReminders'].toString(),
            Icons.notifications,
            Color(0xFF667EEA),
          ),
          _buildStatCard(
            'Active Now',
            _stats['activeReminders'].toString(),
            Icons.play_circle_filled,
            Color(0xFF10B981),
          ),
          _buildStatCard(
            'Completed Today',
            _stats['completedToday'].toString(),
            Icons.check_circle,
            Color(0xFF8B5CF6),
          ),
          _buildStatCard(
            'Weekly Streak',
            '${_stats['weeklyStreak']} days',
            Icons.local_fire_department,
            Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
        boxShadow: AppTheme.cardShadows,
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Create Reminder',
                  Icons.add_circle,
                  Color(0xFF667EEA),
                  () async {
                    await Navigator.pushNamed(context, '/create-reminder');
                    // Refresh dashboard data when returning from create reminder
                    _loadDashboardData();
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'View All',
                  Icons.list,
                  Color(0xFF10B981),
                  () async {
                    await Navigator.pushNamed(context, '/reminder-management');
                    // Refresh dashboard data when returning from reminder management
                    _loadDashboardData();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Audio Library',
                  Icons.library_music,
                  Color(0xFF8B5CF6),
                  () => Navigator.pushNamed(context, '/audio-library'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'Progress',
                  Icons.analytics,
                  Color(0xFFF59E0B),
                  () => Navigator.pushNamed(context, '/completion-celebration'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.largeRadius),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: AppTheme.buttonShadows,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      margin: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
          ),
          SizedBox(height: 16),
          if (_isLoading)
            Container(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recentActivity.isEmpty)
            Container(
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                boxShadow: AppTheme.cardShadows,
              ),
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Start creating reminders to see your activity here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                boxShadow: AppTheme.containerShadows,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _recentActivity.length,
                separatorBuilder: (context, index) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final activity = _recentActivity[index];
                  final time = DateTime.parse(activity['time']);
                  final timeAgo = _getTimeAgo(time);
                  
                  return ListTile(
                    onTap: () => _handleActivityItemTap(activity),
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: activity['color'].withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      ),
                      child: Icon(
                        activity['icon'],
                        color: activity['color'],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      activity['title'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    subtitle: Text(
                      activity['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return CustomBottomBar(
      currentIndex: 0, // Dashboard is index 0 (Create tab)
      onTap: (index) {
        // Handle navigation based on index
        switch (index) {
          case 0:
            // Already on dashboard, do nothing
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/audio-library');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/reminder-management');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/completion-celebration');
            break;
        }
      },
    );
  }

  Future<void> _handleActivityItemTap(Map<String, dynamic> activity) async {
    try {
      final reminderData = activity['reminderData'] as Map<String, dynamic>?;
      final completionData = activity['completionData'] as Map<String, dynamic>?;
      
      // Check if we have reminder data to navigate with
      if (reminderData != null && reminderData.isNotEmpty) {
        // Prepare the reminder data for the detail screen
        final detailScreenData = _prepareReminderDetailData(reminderData, completionData);
        
        // Navigate to reminder detail screen
        await Navigator.pushNamed(
          context,
          '/reminder-detail',
          arguments: detailScreenData,
        );
        // Refresh dashboard data when returning from reminder detail
        _loadDashboardData();
      } else {
        // Handle case where reminder details are unavailable
        _showReminderUnavailableDialog(activity);
      }
    } catch (e) {
      print('Error handling activity item tap: $e');
      _showErrorDialog('Unable to open reminder details. Please try again.');
    }
  }

  Map<String, dynamic> _prepareReminderDetailData(
    Map<String, dynamic> reminderData,
    Map<String, dynamic>? completionData,
  ) {
    // Create a comprehensive data structure for the reminder detail screen
    final detailData = Map<String, dynamic>.from(reminderData);
    
    // Add completion history if we have completion data
    if (completionData != null) {
      final completionHistory = detailData['completionHistory'] as List<Map<String, dynamic>>? ?? [];
      
      // Add the current completion data if it's not already in the history
      final completionExists = completionHistory.any((completion) => 
        completion['id'] == completionData['id']);
      
      if (!completionExists) {
        // Ensure completion data has all required fields for detail display
        final enhancedCompletion = Map<String, dynamic>.from(completionData);
        enhancedCompletion['displayRating'] = completionData['rating'] ?? 0;
        enhancedCompletion['displayMood'] = completionData['mood'] ?? 0;
        enhancedCompletion['displayComments'] = completionData['comments'] ?? '';
        enhancedCompletion['displayMoodBefore'] = completionData['moodBefore'] ?? 'neutral';
        enhancedCompletion['displayMoodAfter'] = completionData['moodAfter'] ?? 'neutral';
        enhancedCompletion['displayDifficulty'] = completionData['difficultyLevel'] ?? 'moderate';
        enhancedCompletion['displayDuration'] = completionData['formattedDuration'] ?? '0 min';
        enhancedCompletion['displayRatingStars'] = completionData['ratingStars'] ?? '';
        enhancedCompletion['displayMoodImprovement'] = completionData['moodImprovement'] ?? 0.0;
        
        completionHistory.add(enhancedCompletion);
      }
      
      detailData['completionHistory'] = completionHistory;
      
      // Add latest completion data for quick access in detail screen
      detailData['latestCompletion'] = completionData;
      detailData['hasRecentCompletion'] = true;
    } else {
      detailData['hasRecentCompletion'] = false;
    }
    
    // Ensure required fields exist with defaults for detail screen display
    detailData['completedCount'] = detailData['completedCount'] ?? 0;
    detailData['streak'] = detailData['streak'] ?? 0;
    detailData['successRate'] = detailData['successRate'] ?? 0;
    detailData['isPaused'] = detailData['isPaused'] ?? false;
    detailData['title'] = detailData['title'] ?? 'Untitled Reminder';
    detailData['description'] = detailData['description'] ?? '';
    detailData['category'] = detailData['category'] ?? 'General';
    detailData['status'] = detailData['status'] ?? 'active';
    
    // Add computed fields for detail screen display
    detailData['hasCompletionHistory'] = (detailData['completionHistory'] as List?)?.isNotEmpty ?? false;
    detailData['averageRating'] = _calculateAverageRating(detailData['completionHistory'] as List<Map<String, dynamic>>? ?? []);
    detailData['averageMoodImprovement'] = _calculateAverageMoodImprovement(detailData['completionHistory'] as List<Map<String, dynamic>>? ?? []);
    detailData['totalDuration'] = _calculateTotalDuration(detailData['completionHistory'] as List<Map<String, dynamic>>? ?? []);
    detailData['mostCommonDifficulty'] = _findMostCommonDifficulty(detailData['completionHistory'] as List<Map<String, dynamic>>? ?? []);
    
    return detailData;
  }

  /// Calculate average rating from completion history
  double _calculateAverageRating(List<Map<String, dynamic>> completionHistory) {
    if (completionHistory.isEmpty) return 0.0;
    
    final ratings = completionHistory
        .map((completion) => completion['rating'] as int? ?? 0)
        .where((rating) => rating > 0)
        .toList();
    
    if (ratings.isEmpty) return 0.0;
    
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  /// Calculate average mood improvement from completion history
  double _calculateAverageMoodImprovement(List<Map<String, dynamic>> completionHistory) {
    if (completionHistory.isEmpty) return 0.0;
    
    final improvements = completionHistory
        .map((completion) => completion['moodImprovement'] as double? ?? 0.0)
        .toList();
    
    if (improvements.isEmpty) return 0.0;
    
    return improvements.reduce((a, b) => a + b) / improvements.length;
  }

  /// Calculate total duration from completion history
  int _calculateTotalDuration(List<Map<String, dynamic>> completionHistory) {
    if (completionHistory.isEmpty) return 0;
    
    return completionHistory
        .map((completion) => completion['durationMinutes'] as int? ?? 0)
        .reduce((a, b) => a + b);
  }

  /// Find most common difficulty level from completion history
  String _findMostCommonDifficulty(List<Map<String, dynamic>> completionHistory) {
    if (completionHistory.isEmpty) return 'moderate';
    
    final difficultyCount = <String, int>{};
    
    for (final completion in completionHistory) {
      final difficulty = completion['difficultyLevel'] as String? ?? 'moderate';
      difficultyCount[difficulty] = (difficultyCount[difficulty] ?? 0) + 1;
    }
    
    if (difficultyCount.isEmpty) return 'moderate';
    
    return difficultyCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  void _showReminderUnavailableDialog(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reminder Unavailable'),
        content: Text(
          'The details for this reminder are no longer available. This may happen if the reminder was deleted or if there was a data synchronization issue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}