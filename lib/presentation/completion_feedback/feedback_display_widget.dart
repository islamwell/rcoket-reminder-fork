import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import 'feedback_edit_screen.dart';

class FeedbackDisplayWidget extends StatefulWidget {
  final Map<String, dynamic> feedback;
  final VoidCallback? onFeedbackUpdated;
  final bool showEditButton;
  final bool isCompact;

  const FeedbackDisplayWidget({
    super.key,
    required this.feedback,
    this.onFeedbackUpdated,
    this.showEditButton = true,
    this.isCompact = false,
  });

  @override
  State<FeedbackDisplayWidget> createState() => _FeedbackDisplayWidgetState();
}

class _FeedbackDisplayWidgetState extends State<FeedbackDisplayWidget> {
  late Map<String, dynamic> _currentFeedback;

  @override
  void initState() {
    super.initState();
    _currentFeedback = Map<String, dynamic>.from(widget.feedback);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(widget.isCompact ? 3.w : 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (!widget.isCompact) ...[
            SizedBox(height: 2.h),
            _buildFeedbackContent(context),
          ] else
            _buildCompactContent(context),
          if (widget.showEditButton) ...[
            SizedBox(height: 2.h),
            _buildEditButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        CustomIconWidget(
          iconName: 'feedback',
          color: theme.colorScheme.primary,
          size: 20,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Completion Feedback',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Completed: ${_formatDate(_currentFeedback['createdAt'] as String?)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_currentFeedback['isEdited'] == true)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: 'edit',
                  color: theme.colorScheme.secondary,
                  size: 12,
                ),
                SizedBox(width: 1.w),
                Text(
                  'Edited',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFeedbackContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFeedbackItem(
                context,
                'Rating',
                _buildStarRating(_currentFeedback['rating'] as int? ?? 5),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildFeedbackItem(
                context,
                'Duration',
                '${_currentFeedback['durationMinutes'] ?? 5} minutes',
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildFeedbackItem(
                context,
                'Difficulty',
                _getDifficultyLabel(_currentFeedback['difficultyLevel'] as String? ?? 'moderate'),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildFeedbackItem(
                context,
                'Mood Change',
                '${_getMoodEmoji(_currentFeedback['moodBefore'] as String? ?? 'neutral')} → ${_getMoodEmoji(_currentFeedback['moodAfter'] as String? ?? 'happy')}',
              ),
            ),
          ],
        ),
        if (_currentFeedback['notes'] != null && (_currentFeedback['notes'] as String).isNotEmpty) ...[
          SizedBox(height: 2.h),
          _buildFeedbackItem(
            context,
            'Notes',
            _currentFeedback['notes'] as String,
            isFullWidth: true,
          ),
        ],
        SizedBox(height: 2.h),
        Row(
          children: [
            CustomIconWidget(
              iconName: _currentFeedback['wouldRecommend'] == true ? 'thumb_up' : 'thumb_down',
              color: _currentFeedback['wouldRecommend'] == true 
                  ? AppTheme.successLight 
                  : theme.colorScheme.error,
              size: 16,
            ),
            SizedBox(width: 2.w),
            Text(
              _currentFeedback['wouldRecommend'] == true 
                  ? 'Would recommend to others'
                  : 'Would not recommend to others',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _currentFeedback['wouldRecommend'] == true 
                    ? AppTheme.successLight 
                    : theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactContent(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(top: 1.h),
      child: Row(
        children: [
          _buildStarRating(_currentFeedback['rating'] as int? ?? 5),
          SizedBox(width: 3.w),
          Text(
            '${_currentFeedback['durationMinutes'] ?? 5}min',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 3.w),
          Text(
            _getDifficultyLabel(_currentFeedback['difficultyLevel'] as String? ?? 'moderate'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Spacer(),
          Text(
            '${_getMoodEmoji(_currentFeedback['moodBefore'] as String? ?? 'neutral')} → ${_getMoodEmoji(_currentFeedback['moodAfter'] as String? ?? 'happy')}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(
    BuildContext context,
    String label,
    dynamic value, {
    bool isFullWidth = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          if (value is Widget)
            value
          else
            Text(
              value.toString(),
              style: theme.textTheme.bodyMedium,
              maxLines: isFullWidth ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return CustomIconWidget(
          iconName: index < rating ? 'star' : 'star_border',
          color: AppTheme.completionGold,
          size: 16,
        );
      }),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _editFeedback,
        icon: CustomIconWidget(
          iconName: 'edit',
          color: theme.colorScheme.primary,
          size: 16,
        ),
        label: Text('Edit Feedback'),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Future<void> _editFeedback() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => FeedbackEditScreen(
          feedback: _currentFeedback,
          onFeedbackUpdated: () {
            // Refresh the feedback data
            _refreshFeedback();
          },
        ),
      ),
    );

    // If feedback was updated, refresh the display
    if (result == true) {
      _refreshFeedback();
    }
  }

  Future<void> _refreshFeedback() async {
    try {
      final feedbackId = _currentFeedback['id'] as int;
      final updatedFeedback = await CompletionFeedbackService.instance
          .getFeedbackById(feedbackId);

      if (updatedFeedback != null && mounted) {
        setState(() {
          _currentFeedback = updatedFeedback;
        });

        // Notify parent widget
        widget.onFeedbackUpdated?.call();
      }
    } catch (e) {
      print('Error refreshing feedback: $e');
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
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
}