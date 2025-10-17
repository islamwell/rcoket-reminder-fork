import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class CompletionFeedback extends StatefulWidget {
  final Map<String, dynamic> reminder;

  const CompletionFeedback({
    super.key,
    required this.reminder,
  });

  @override
  State<CompletionFeedback> createState() => _CompletionFeedbackState();
}

class _CompletionFeedbackState extends State<CompletionFeedback>
    with TickerProviderStateMixin {
  late AnimationController _celebrationController;
  late AnimationController _slideController;
  
  // Form data
  int _starRating = 5;
  int _durationMinutes = 5;
  String _difficultyLevel = 'easy';
  String _moodBefore = 'neutral';
  String _moodAfter = 'happy';
  String _notes = '';
  bool _wouldRecommend = true;
  
  final _notesController = TextEditingController();
  final _pageController = PageController();
  int _currentPage = 0;
  
  final List<String> _difficultyOptions = ['very_easy', 'easy', 'moderate', 'hard', 'very_hard'];
  final List<String> _moodOptions = ['sad', 'neutral', 'happy', 'excited', 'blessed'];

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _celebrationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _slideController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildCelebrationPage(context),
                  _buildRatingPage(context),
                  _buildDurationPage(context),
                  _buildDifficultyPage(context),
                  _buildMoodPage(context),
                  _buildNotesPage(context),
                  _buildSummaryPage(context),
                ],
              ),
            ),
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            GestureDetector(
              onTap: _previousPage,
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'arrow_back',
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Task Completed! 🎉',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: (_currentPage + 1) / 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
          if (_currentPage < 6)
            GestureDetector(
              onTap: _nextPage,
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'arrow_forward',
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCelebrationPage(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + (_celebrationController.value * 0.2),
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.successLight,
                        AppTheme.successLight.withValues(alpha: 0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.successLight.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Alhamdulillah!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successLight,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'You completed:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.reminder['title'] as String,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'May Allah accept your good deed and grant you barakah!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4.h),
              ElevatedButton.icon(
                onPressed: _nextPage,
                icon: CustomIconWidget(
                  iconName: 'arrow_forward',
                  color: theme.colorScheme.onPrimary,
                  size: 20,
                ),
                label: Text('Tell us about your experience'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingPage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'star',
            color: AppTheme.completionGold,
            size: 48,
          ),
          SizedBox(height: 3.h),
          Text(
            'How was your experience?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'Rate your overall satisfaction',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _starRating = index + 1),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  child: CustomIconWidget(
                    iconName: index < _starRating ? 'star' : 'star_border',
                    color: AppTheme.completionGold,
                    size: 40,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 2.h),
          Text(
            _getRatingText(_starRating),
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.completionGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'schedule',
            color: theme.colorScheme.primary,
            size: 48,
          ),
          SizedBox(height: 3.h),
          Text(
            'How long did it take?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'This helps us understand task complexity',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '$_durationMinutes minutes',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 2.h),
                Slider(
                  value: _durationMinutes.toDouble(),
                  min: 1,
                  max: 120,
                  divisions: 119,
                  onChanged: (value) => setState(() => _durationMinutes = value.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 min', style: theme.textTheme.bodySmall),
                    Text('2 hours', style: theme.textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyPage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'fitness_center',
            color: theme.colorScheme.secondary,
            size: 48,
          ),
          SizedBox(height: 3.h),
          Text(
            'How challenging was it?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'Help us understand the effort required',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4.h),
          ...(_difficultyOptions.map((difficulty) => _buildDifficultyOption(context, difficulty))),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(BuildContext context, String difficulty) {
    final theme = Theme.of(context);
    final isSelected = _difficultyLevel == difficulty;
    
    return GestureDetector(
      onTap: () => setState(() => _difficultyLevel = difficulty),
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: _getDifficultyIcon(difficulty),
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                _getDifficultyLabel(difficulty),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check_circle',
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodPage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'mood',
            color: theme.colorScheme.tertiary,
            size: 48,
          ),
          SizedBox(height: 3.h),
          Text(
            'How did you feel?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            'Before the task:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMoodSelector(_moodBefore, (mood) => setState(() => _moodBefore = mood)),
          SizedBox(height: 4.h),
          Text(
            'After completing it:',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          _buildMoodSelector(_moodAfter, (mood) => setState(() => _moodAfter = mood)),
        ],
      ),
    );
  }

  Widget _buildMoodSelector(String selectedMood, Function(String) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _moodOptions.map((mood) {
        final isSelected = selectedMood == mood;
        return GestureDetector(
          onTap: () => onChanged(mood),
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _getMoodEmoji(mood),
                  style: TextStyle(fontSize: 32),
                ),
                SizedBox(height: 1.h),
                Text(
                  _getMoodLabel(mood),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesPage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'edit_note',
            color: theme.colorScheme.primary,
            size: 48,
          ),
          SizedBox(height: 3.h),
          Text(
            'Any additional thoughts?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            'Share your reflections or insights (optional)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          TextField(
            controller: _notesController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'What did you learn? How did it make you feel? Any challenges?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => _notes = value,
          ),
          SizedBox(height: 3.h),
          Row(
            children: [
              Checkbox(
                value: _wouldRecommend,
                onChanged: (value) => setState(() => _wouldRecommend = value ?? true),
              ),
              Expanded(
                child: Text(
                  'I would recommend this task to others',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(6.w),
      child: Column(
        children: [
          SizedBox(height: 2.h),
          Text(
            'Summary',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSummaryItem('Task', widget.reminder['title'] as String),
                  _buildSummaryItem('Rating', '$_starRating/5 stars'),
                  _buildSummaryItem('Duration', '$_durationMinutes minutes'),
                  _buildSummaryItem('Difficulty', _getDifficultyLabel(_difficultyLevel)),
                  _buildSummaryItem('Mood Before', _getMoodLabel(_moodBefore)),
                  _buildSummaryItem('Mood After', _getMoodLabel(_moodAfter)),
                  if (_notes.isNotEmpty)
                    _buildSummaryItem('Notes', _notes),
                  _buildSummaryItem('Would Recommend', _wouldRecommend ? 'Yes' : 'No'),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveFeedback,
              icon: CustomIconWidget(
                iconName: 'save',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: Text('Save & Continue'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 2.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                child: Text('Previous'),
              ),
            ),
          if (_currentPage > 0) SizedBox(width: 4.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _currentPage == 6 ? _saveFeedback : _nextPage,
              child: Text(_currentPage == 6 ? 'Finish' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveFeedback() async {
    try {
      // Create feedback data
      final feedbackData = {
        'reminderId': widget.reminder['id'],
        'reminderTitle': widget.reminder['title'],
        'reminderCategory': widget.reminder['category'],
        'completedAt': DateTime.now().toIso8601String(),
        'rating': _starRating,
        'durationMinutes': _durationMinutes,
        'difficultyLevel': _difficultyLevel,
        'moodBefore': _moodBefore,
        'moodAfter': _moodAfter,
        'notes': _notes,
        'wouldRecommend': _wouldRecommend,
      };

      // Save feedback using storage service
      await CompletionFeedbackService.instance.saveFeedback(feedbackData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thank you for your feedback! May Allah reward you.'),
          backgroundColor: AppTheme.successLight,
        ),
      );

      // Navigate back to reminders
      Navigator.pushReplacementNamed(context, '/reminder-management');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save feedback: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return 'Good';
    }
  }

  String _getDifficultyIcon(String difficulty) {
    switch (difficulty) {
      case 'very_easy': return 'sentiment_very_satisfied';
      case 'easy': return 'sentiment_satisfied';
      case 'moderate': return 'sentiment_neutral';
      case 'hard': return 'sentiment_dissatisfied';
      case 'very_hard': return 'sentiment_very_dissatisfied';
      default: return 'sentiment_neutral';
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'very_easy': return 'Very Easy';
      case 'easy': return 'Easy';
      case 'moderate': return 'Moderate';
      case 'hard': return 'Hard';
      case 'very_hard': return 'Very Hard';
      default: return 'Moderate';
    }
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'sad': return '😢';
      case 'neutral': return '😐';
      case 'happy': return '😊';
      case 'excited': return '🤩';
      case 'blessed': return '🤲';
      default: return '😊';
    }
  }

  String _getMoodLabel(String mood) {
    switch (mood) {
      case 'sad': return 'Sad';
      case 'neutral': return 'Neutral';
      case 'happy': return 'Happy';
      case 'excited': return 'Excited';
      case 'blessed': return 'Blessed';
      default: return 'Happy';
    }
  }
}