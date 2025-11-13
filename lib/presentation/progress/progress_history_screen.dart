import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../common/widgets/shimmer_loading.dart';

/// Modern Progress History Screen
/// Shows completed reminders with feedback in card or calendar view
class ProgressHistoryScreen extends StatefulWidget {
  const ProgressHistoryScreen({super.key});

  @override
  State<ProgressHistoryScreen> createState() => _ProgressHistoryScreenState();
}

class _ProgressHistoryScreenState extends State<ProgressHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _viewModeController;

  // Data
  List<Map<String, dynamic>> _completions = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  // Filter state
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _completionsByDate = {};

  // View mode: 0 = Cards, 1 = Calendar
  int _viewMode = 0;

  @override
  void initState() {
    super.initState();
    _viewModeController = TabController(length: 2, vsync: this);
    _viewModeController.addListener(() {
      if (_viewModeController.index != _viewMode) {
        setState(() => _viewMode = _viewModeController.index);
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _viewModeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load completions from CompletionTrackingService
      final completions = await CompletionTrackingService.instance.getCompletionHistory(
        category: _selectedCategory,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Load stats
      final stats = await CompletionTrackingService.instance.getCompletionStats(
        startDate: _startDate,
        endDate: _endDate,
      );

      // Group completions by date for calendar view
      final completionsByDate = <DateTime, List<Map<String, dynamic>>>{};
      for (final completion in completions) {
        final completedAt = DateTime.parse(completion['completed_at'] as String);
        final dateKey = DateTime(completedAt.year, completedAt.month, completedAt.day);

        if (!completionsByDate.containsKey(dateKey)) {
          completionsByDate[dateKey] = [];
        }
        completionsByDate[dateKey]!.add(completion);
      }

      setState(() {
        _completions = completions;
        _stats = stats;
        _completionsByDate = completionsByDate;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCompletions {
    if (_searchQuery.isEmpty) return _completions;

    return _completions.where((completion) {
      final title = (completion['reminder_title'] as String? ?? '').toLowerCase();
      final notes = (completion['completion_notes'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();

      return title.contains(query) || notes.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildViewModeTabs(),
            if (!_isLoading) _buildStatsOverview(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _viewMode == 0
                      ? _buildCardView()
                      : _buildCalendarView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: 3,
        onTap: (index) {
          // Handle navigation
          if (index != 3) {
            final routes = [
              AppRoutes.dashboard,
              AppRoutes.audioLibrary,
              AppRoutes.reminderManagement,
              AppRoutes.progressHistory,
            ];
            Navigator.pushReplacementNamed(context, routes[index]);
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 28,
              ),
              SizedBox(width: 3.w),
              Text(
                'Progress & History',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.filter_list_rounded),
                onPressed: _showFilterDialog,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search completions...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear_rounded, size: 20),
              onPressed: () => setState(() => _searchQuery = ''),
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildViewModeTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _viewModeController,
        indicator: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            icon: Icon(Icons.view_agenda_rounded, size: 20),
            text: 'Cards',
          ),
          Tab(
            icon: Icon(Icons.calendar_month_rounded, size: 20),
            text: 'Calendar',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            AppTheme.lightTheme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.check_circle_rounded,
            _stats['totalCompletions']?.toString() ?? '0',
            'Completed',
            AppTheme.lightTheme.colorScheme.primary,
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.star_rounded,
            (_stats['averageRating'] as num?)?.toStringAsFixed(1) ?? '0.0',
            'Avg Rating',
            AppTheme.accentLight,
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.timer_rounded,
            '${(_stats['averageDuration'] as num?)?.round() ?? 0}m',
            'Avg Time',
            AppTheme.warningLight,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 6.h,
      width: 1,
      color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 5,
      itemBuilder: (context, index) => ShimmerLoading(
        isLoading: true,
        child: Container(
          height: 120,
          margin: EdgeInsets.only(bottom: 2.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildCardView() {
    if (_filteredCompletions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _filteredCompletions.length,
        itemBuilder: (context, index) {
          final completion = _filteredCompletions[index];
          return _buildCompletionCard(completion);
        },
      ),
    );
  }

  Widget _buildCompletionCard(Map<String, dynamic> completion) {
    final completedAt = DateTime.parse(completion['completed_at'] as String);
    final title = completion['reminder_title'] as String? ?? 'Unknown';
    final category = completion['reminder_category'] as String? ?? 'general';
    final notes = completion['completion_notes'] as String?;
    final rating = completion['satisfaction_rating'] as int?;
    final mood = completion['mood'] as String?;
    final duration = completion['actual_duration_minutes'] as int?;

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCompletionDetails(completion),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        color: _getCategoryColor(category),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            _formatDate(completedAt),
                            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (rating != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, color: AppTheme.accentLight, size: 16),
                            SizedBox(width: 1.w),
                            Text(
                              rating.toString(),
                              style: TextStyle(
                                color: AppTheme.accentLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (notes != null && notes.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      notes,
                      style: AppTheme.lightTheme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (mood != null || duration != null) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      if (mood != null) ...[
                        _buildChip(
                          _getMoodIcon(mood),
                          mood,
                          _getMoodColor(mood),
                        ),
                        SizedBox(width: 2.w),
                      ],
                      if (duration != null)
                        _buildChip(
                          Icons.timer_rounded,
                          '${duration}m',
                          AppTheme.warningLight,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          SizedBox(width: 1.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(Duration(days: 365)),
            lastDay: DateTime.now(),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTheme.lightTheme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppTheme.lightTheme.colorScheme.primary),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppTheme.lightTheme.colorScheme.primary),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: AppTheme.accentLight,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            eventLoader: (day) {
              final dateKey = DateTime(day.year, day.month, day.day);
              return _completionsByDate[dateKey] ?? [];
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
        SizedBox(height: 2.h),
        Expanded(
          child: _selectedDay != null
              ? _buildSelectedDayCompletions()
              : _buildCalendarEmptyState(),
        ),
      ],
    );
  }

  Widget _buildSelectedDayCompletions() {
    final dateKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    final dayCompletions = _completionsByDate[dateKey] ?? [];

    if (dayCompletions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 2.h),
            Text(
              'No completions on this day',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      itemCount: dayCompletions.length,
      itemBuilder: (context, index) {
        return _buildCompletionCard(dayCompletions[index]);
      },
    );
  }

  Widget _buildCalendarEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 48,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            'Select a date to view completions',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: 2.h),
          Text(
            'No completed reminders yet',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Complete reminders to see your progress here',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Completions',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 3.h),
            // Category filter
            Text(
              'Category',
              style: AppTheme.lightTheme.textTheme.titleSmall,
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: ['All', 'family', 'work', 'personal', 'health', 'spiritual']
                  .map((category) => FilterChip(
                        label: Text(category == 'All' ? 'All' : category),
                        selected: _selectedCategory == (category == 'All' ? null : category),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category == 'All' ? null : category;
                          });
                          _loadData();
                          Navigator.pop(context);
                        },
                      ))
                  .toList(),
            ),
            SizedBox(height: 3.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _startDate = null;
                      _endDate = null;
                    });
                    _loadData();
                    Navigator.pop(context);
                  },
                  child: Text('Clear Filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDetails(Map<String, dynamic> completion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final completedAt = DateTime.parse(completion['completed_at'] as String);
        final title = completion['reminder_title'] as String? ?? 'Unknown';
        final category = completion['reminder_category'] as String? ?? 'general';
        final notes = completion['completion_notes'] as String?;
        final rating = completion['satisfaction_rating'] as int?;
        final mood = completion['mood'] as String?;
        final duration = completion['actual_duration_minutes'] as int?;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: _getCategoryColor(category),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          _formatDate(completedAt),
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              if (rating != null) ...[
                Text('Rating', style: AppTheme.lightTheme.textTheme.titleSmall),
                SizedBox(height: 1.h),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppTheme.accentLight,
                      size: 28,
                    );
                  }),
                ),
                SizedBox(height: 2.h),
              ],
              if (mood != null) ...[
                Text('Mood', style: AppTheme.lightTheme.textTheme.titleSmall),
                SizedBox(height: 1.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: _getMoodColor(mood).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getMoodIcon(mood), color: _getMoodColor(mood), size: 24),
                      SizedBox(width: 2.w),
                      Text(
                        mood,
                        style: TextStyle(
                          color: _getMoodColor(mood),
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 2.h),
              ],
              if (duration != null) ...[
                Text('Duration', style: AppTheme.lightTheme.textTheme.titleSmall),
                SizedBox(height: 1.h),
                Text(
                  '$duration minutes',
                  style: AppTheme.lightTheme.textTheme.bodyLarge,
                ),
                SizedBox(height: 2.h),
              ],
              if (notes != null && notes.isNotEmpty) ...[
                Text('Notes', style: AppTheme.lightTheme.textTheme.titleSmall),
                SizedBox(height: 1.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    notes,
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ),
                SizedBox(height: 2.h),
              ],
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 2.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today at ${_formatTime(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'family':
        return Icons.family_restroom_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'personal':
        return Icons.person_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'spiritual':
        return Icons.mosque_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'family':
        return Colors.purple;
      case 'work':
        return Colors.blue;
      case 'personal':
        return Colors.green;
      case 'health':
        return Colors.red;
      case 'spiritual':
        return AppTheme.lightTheme.colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'excellent':
        return Icons.sentiment_very_satisfied_rounded;
      case 'good':
        return Icons.sentiment_satisfied_rounded;
      case 'neutral':
        return Icons.sentiment_neutral_rounded;
      case 'poor':
        return Icons.sentiment_dissatisfied_rounded;
      default:
        return Icons.mood_rounded;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'neutral':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
