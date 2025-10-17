import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import 'countdown_display_widget.dart';

class ReminderCardWidget extends StatelessWidget {
  final Map<String, dynamic> reminder;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onShare;
  final VoidCallback? onPause;
  final VoidCallback? onDelete;
  final VoidCallback? onViewHistory;
  final VoidCallback? onChangeAudio;
  final VoidCallback? onResetProgress;

  const ReminderCardWidget({
    super.key,
    required this.reminder,
    this.onTap,
    this.onToggle,
    this.onEdit,
    this.onDuplicate,
    this.onShare,
    this.onPause,
    this.onDelete,
    this.onViewHistory,
    this.onChangeAudio,
    this.onResetProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = (reminder["status"] as String) == "active";

    return Dismissible(
      key: Key('reminder_${reminder["id"]}'),
      background: _buildSwipeBackground(context, isLeft: false),
      secondaryBackground: _buildSwipeBackground(context, isLeft: true),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          // Right swipe - Edit/Duplicate/Share actions
          _showQuickActions(context);
        } else {
          // Left swipe - Pause/Delete actions
          _showDeleteActions(context);
        }
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surface.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCategoryIcon(context),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder["title"] as String,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              Flexible(child: _buildFrequencyBadge(context)),
                              SizedBox(width: 2.w),
                              Flexible(child: _buildStatusBadge(context)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (_) => onToggle?.call(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildCountdownDisplay(context),
                    ),
                    Spacer(),
                    if (reminder["audioFile"] != null) ...[
                      CustomIconWidget(
                        iconName: 'volume_up',
                        color: AppTheme.audioBlue,
                        size: 16,
                      ),
                      SizedBox(width: 1.w),
                    ],
                    CustomIconWidget(
                      iconName: 'more_vert',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    final theme = Theme.of(context);
    final categoryIcons = {
      'spiritual': 'mosque',
      'family': 'family_restroom',
      'charity': 'volunteer_activism',
      'health': 'fitness_center',
      'work': 'work',
      'personal': 'person',
    };

    final iconName = categoryIcons[reminder["category"]] ?? 'notifications';

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: CustomIconWidget(
        iconName: iconName,
        color: theme.colorScheme.primary,
        size: 20,
      ),
    );
  }

  Widget _buildFrequencyBadge(BuildContext context) {
    final theme = Theme.of(context);
    final frequency = reminder["frequency"];
    
    String frequencyText;
    if (frequency is String) {
      frequencyText = frequency;
    } else if (frequency is Map<String, dynamic>) {
      frequencyText = _getFrequencyDisplayText(frequency);
    } else {
      frequencyText = 'Unknown';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: Text(
        frequencyText.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  String _getFrequencyDisplayText(Map<String, dynamic> frequency) {
    // Handle both 'type' and 'id' fields for backward compatibility
    final type = (frequency['type'] ?? frequency['id']) as String?;
    switch (type) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'hourly':
        return 'Hourly';
      case 'monthly':
        return 'Monthly';
      case 'once':
        return 'Once';
      case 'custom':
        final interval = frequency['interval'] ?? frequency['intervalValue'];
        final unit = frequency['unit'] ?? frequency['intervalUnit'];
        if (interval != null && unit != null) {
          return '$interval $unit';
        }
        return 'Custom';
      case 'test':
        return 'Test';
      default:
        return 'Custom';
    }
  }

  Widget _buildStatusBadge(BuildContext context) {
    final theme = Theme.of(context);
    final status = reminder["status"] as String;

    Color badgeColor;
    String statusText;

    switch (status) {
      case 'active':
        badgeColor = AppTheme.successLight;
        statusText = 'ACTIVE';
        break;
      case 'paused':
        badgeColor = AppTheme.warningLight;
        statusText = 'PAUSED';
        break;
      case 'completed':
        badgeColor = AppTheme.completionGold;
        statusText = 'DONE';
        break;
      default:
        badgeColor = theme.colorScheme.onSurfaceVariant;
        statusText = status.toUpperCase();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCountdownDisplay(BuildContext context) {
    final theme = Theme.of(context);
    final status = reminder["status"] as String;
    
    // Handle paused and completed reminders
    if (status == 'paused') {
      return Row(
        children: [
          CustomIconWidget(
            iconName: 'pause',
            color: AppTheme.warningLight,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Text(
            'Paused',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.warningLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    if (status == 'completed') {
      return Row(
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            color: AppTheme.completionGold,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Text(
            'Completed',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.completionGold,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    // For active reminders, use the countdown display widget
    final nextOccurrenceDateTimeStr = reminder["nextOccurrenceDateTime"] as String?;
    
    if (nextOccurrenceDateTimeStr == null) {
      // Fallback to static display if no DateTime available
      return Row(
        children: [
          CustomIconWidget(
            iconName: 'schedule',
            color: theme.colorScheme.primary,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Text(
            'Next: ${reminder["nextOccurrence"] ?? "Unknown"}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
    
    try {
      return CountdownDisplayWidget(
        reminder: reminder,
        textStyle: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    } catch (e) {
      // Fallback to static display if parsing fails
      return Row(
        children: [
          CustomIconWidget(
            iconName: 'schedule',
            color: theme.colorScheme.primary,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Text(
            'Next: ${reminder["nextOccurrence"] ?? "Unknown"}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSwipeBackground(BuildContext context, {required bool isLeft}) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLeft
              ? [
                  AppTheme.errorLight.withValues(alpha: 0.8),
                  AppTheme.errorLight
                ]
              : [
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                  theme.colorScheme.primary
                ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Align(
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: isLeft
                ? [
                    CustomIconWidget(
                      iconName: 'pause',
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: 'delete',
                      color: Colors.white,
                      size: 20,
                    ),
                  ]
                : [
                    CustomIconWidget(
                      iconName: 'edit',
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: 'content_copy',
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    CustomIconWidget(
                      iconName: 'share',
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: Text('Edit Reminder'),
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: Text('Duplicate'),
              onTap: () {
                Navigator.pop(context);
                onDuplicate?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'share',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: Text('Share'),
              onTap: () {
                Navigator.pop(context);
                onShare?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CustomIconWidget(
                iconName: 'pause',
                color: AppTheme.warningLight,
                size: 24,
              ),
              title: Text('Pause Reminder'),
              onTap: () {
                Navigator.pop(context);
                onPause?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'delete',
                color: AppTheme.errorLight,
                size: 24,
              ),
              title: Text('Delete Reminder'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'history',
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              title: Text('View History'),
              onTap: () {
                Navigator.pop(context);
                onViewHistory?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'audiotrack',
                color: AppTheme.audioBlue,
                size: 24,
              ),
              title: Text('Change Audio'),
              onTap: () {
                Navigator.pop(context);
                onChangeAudio?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'refresh',
                color: AppTheme.warningLight,
                size: 24,
              ),
              title: Text('Reset Progress'),
              onTap: () {
                Navigator.pop(context);
                onResetProgress?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Reminder'),
        content: Text(
            'Are you sure you want to delete "${reminder["title"]}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorLight,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }
}
