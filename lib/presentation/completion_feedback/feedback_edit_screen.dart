import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import 'feedback_confirmation_dialog.dart';

class FeedbackEditScreen extends StatefulWidget {
  final Map<String, dynamic> feedback;
  final VoidCallback? onFeedbackUpdated;

  const FeedbackEditScreen({
    super.key,
    required this.feedback,
    this.onFeedbackUpdated,
  });

  @override
  State<FeedbackEditScreen> createState() => _FeedbackEditScreenState();
}

class _FeedbackEditScreenState extends State<FeedbackEditScreen> {
  late int _starRating;
  late int _durationMinutes;
  late String _difficultyLevel;
  late String _moodBefore;
  late String _moodAfter;
  late String _notes;
  late bool _wouldRecommend;
  
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _hasChanges = false;
  
  final List<String> _difficultyOptions = ['very_easy', 'easy', 'moderate', 'hard', 'very_hard'];
  final List<String> _moodOptions = ['sad', 'neutral', 'happy', 'excited', 'blessed'];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final feedback = widget.feedback;
    _starRating = feedback['rating'] as int? ?? 5;
    _durationMinutes = feedback['durationMinutes'] as int? ?? 5;
    _difficultyLevel = feedback['difficultyLevel'] as String? ?? 'easy';
    _moodBefore = feedback['moodBefore'] as String? ?? 'neutral';
    _moodAfter = feedback['moodAfter'] as String? ?? 'happy';
    _notes = feedback['notes'] as String? ?? '';
    _wouldRecommend = feedback['wouldRecommend'] as bool? ?? true;
    
    _notesController.text = _notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _markAsChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Edit Feedback'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _handleBackPress,
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: Colors.white,
            size: 20,
          ),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _showSaveConfirmation,
              child: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeedbackInfo(context),
            SizedBox(height: 3.h),
            _buildRatingSection(context),
            SizedBox(height: 3.h),
            _buildDurationSection(context),
            SizedBox(height: 3.h),
            _buildDifficultySection(context),
            SizedBox(height: 3.h),
            _buildMoodSection(context),
            SizedBox(height: 3.h),
            _buildNotesSection(context),
            SizedBox(height: 3.h),
            _buildRecommendationSection(context),
            SizedBox(height: 4.h),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackInfo(BuildContext context) {
    final theme = Theme.of(context);
    final feedback = widget.feedback;
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'edit',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Editing Feedback',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Task: ${feedback['reminderTitle'] ?? 'Unknown Task'}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Completed: ${_formatDate(feedback['createdAt'] as String?)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (feedback['isEdited'] == true) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'history',
                  color: theme.colorScheme.secondary,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Last edited: ${_formatDate(feedback['editedAt'] as String?)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSection(
      context,
      title: 'Overall Rating',
      icon: 'star',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  setState(() => _starRating = index + 1);
                  _markAsChanged();
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 1.w),
                  child: CustomIconWidget(
                    iconName: index < _starRating ? 'star' : 'star_border',
                    color: AppTheme.completionGold,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 1.h),
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

  Widget _buildDurationSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSection(
      context,
      title: 'Duration',
      icon: 'schedule',
      child: Column(
        children: [
          Text(
            '$_durationMinutes minutes',
            style: theme.textTheme.headlineSmall?.copyWith(
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
            onChanged: (value) {
              setState(() => _durationMinutes = value.round());
              _markAsChanged();
            },
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
    );
  }

  Widget _buildDifficultySection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Difficulty Level',
      icon: 'fitness_center',
      child: Column(
        children: _difficultyOptions.map((difficulty) => 
          _buildDifficultyOption(context, difficulty)
        ).toList(),
      ),
    );
  }

  Widget _buildDifficultyOption(BuildContext context, String difficulty) {
    final theme = Theme.of(context);
    final isSelected = _difficultyLevel == difficulty;
    
    return GestureDetector(
      onTap: () {
        setState(() => _difficultyLevel = difficulty);
        _markAsChanged();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
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
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                _getDifficultyLabel(difficulty),
                style: theme.textTheme.bodyMedium?.copyWith(
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
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSection(
      context,
      title: 'Mood',
      icon: 'mood',
      child: Column(
        children: [
          Text(
            'Before the task:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          _buildMoodSelector(_moodBefore, (mood) {
            setState(() => _moodBefore = mood);
            _markAsChanged();
          }),
          SizedBox(height: 2.h),
          Text(
            'After completing it:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          _buildMoodSelector(_moodAfter, (mood) {
            setState(() => _moodAfter = mood);
            _markAsChanged();
          }),
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
            padding: EdgeInsets.all(1.5.w),
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
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 0.5.h),
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

  Widget _buildNotesSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Notes & Reflections',
      icon: 'edit_note',
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        maxLength: 500,
        decoration: InputDecoration(
          hintText: 'Share your thoughts, insights, or reflections...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          _notes = value;
          _markAsChanged();
        },
      ),
    );
  }

  Widget _buildRecommendationSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSection(
      context,
      title: 'Recommendation',
      icon: 'thumb_up',
      child: Row(
        children: [
          Checkbox(
            value: _wouldRecommend,
            onChanged: (value) {
              setState(() => _wouldRecommend = value ?? true);
              _markAsChanged();
            },
          ),
          Expanded(
            child: Text(
              'I would recommend this task to others',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required String icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          child,
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _hasChanges && !_isLoading ? _saveFeedback : null,
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'save',
                    color: theme.colorScheme.onPrimary,
                    size: 20,
                  ),
            label: Text(_isLoading ? 'Saving...' : 'Save Changes'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              backgroundColor: _hasChanges 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainer,
              foregroundColor: _hasChanges 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : _showFeedbackHistory,
            icon: CustomIconWidget(
              iconName: 'history',
              color: theme.colorScheme.secondary,
              size: 20,
            ),
            label: Text('View Edit History'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleBackPress() async {
    if (_hasChanges) {
      final shouldDiscard = await FeedbackConfirmationDialog
          .showDiscardChangesConfirmation(context);
      
      if (shouldDiscard == true) {
        Navigator.of(context).pop(false);
      }
    } else {
      Navigator.of(context).pop(false);
    }
  }

  Future<void> _showSaveConfirmation() async {
    final shouldSave = await FeedbackConfirmationDialog
        .showUpdateConfirmation(context);
    
    if (shouldSave == true) {
      await _saveFeedback();
    }
  }

  Future<void> _saveFeedback() async {
    if (!_hasChanges || _isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final updates = {
        'rating': _starRating,
        'durationMinutes': _durationMinutes,
        'difficultyLevel': _difficultyLevel,
        'moodBefore': _moodBefore,
        'moodAfter': _moodAfter,
        'notes': _notes,
        'wouldRecommend': _wouldRecommend,
      };

      final updatedFeedback = await CompletionFeedbackService.instance
          .updateFeedback(widget.feedback['id'] as int, updates);

      if (updatedFeedback != null) {
        setState(() {
          _hasChanges = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feedback updated successfully!'),
            backgroundColor: AppTheme.successLight,
          ),
        );

        // Call the callback to notify parent widget
        widget.onFeedbackUpdated?.call();

        // Navigate back
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Failed to update feedback');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update feedback: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  Future<void> _showFeedbackHistory() async {
    try {
      final reminderId = widget.feedback['reminderId'] as int?;
      if (reminderId == null) {
        throw Exception('Reminder ID not found');
      }

      final history = await CompletionFeedbackService.instance
          .getFeedbackHistory(reminderId);

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => FeedbackHistorySheet(
          history: history,
          currentFeedbackId: widget.feedback['id'] as int,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load feedback history: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
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

class FeedbackHistorySheet extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  final int currentFeedbackId;

  const FeedbackHistorySheet({
    super.key,
    required this.history,
    required this.currentFeedbackId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: 70.h,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'history',
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                'Feedback History',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          if (history.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'history',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'No edit history available',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final feedback = history[index];
                  final isCurrent = feedback['id'] == currentFeedbackId;
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: 2.h),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: isCurrent 
                          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrent 
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isCurrent) ...[
                              CustomIconWidget(
                                iconName: 'star',
                                color: theme.colorScheme.primary,
                                size: 16,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                'Current Version',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Version ${feedback['version'] ?? 1}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            Spacer(),
                            Text(
                              _formatDate(feedback['editedAt'] as String? ?? 
                                         feedback['createdAt'] as String?),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Row(
                          children: [
                            _buildHistoryItem('Rating', '${feedback['rating']}/5'),
                            SizedBox(width: 4.w),
                            _buildHistoryItem('Duration', '${feedback['durationMinutes']}min'),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        _buildHistoryItem('Difficulty', _getDifficultyLabel(feedback['difficultyLevel'] as String? ?? 'moderate')),
                        if (feedback['notes'] != null && (feedback['notes'] as String).isNotEmpty) ...[
                          SizedBox(height: 1.h),
                          Text(
                            'Notes: ${feedback['notes']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String label, String value) {
    return Expanded(
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
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
}