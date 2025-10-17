import 'package:flutter/material.dart';
import '../../../core/models/delay_option.dart';

/// Dialog for selecting completion delay options
class CompletionDelayDialog extends StatefulWidget {
  final String reminderTitle;
  final Function(DelayOption) onDelaySelected;
  final VoidCallback onCancel;

  const CompletionDelayDialog({
    super.key,
    required this.reminderTitle,
    required this.onDelaySelected,
    required this.onCancel,
  });

  @override
  State<CompletionDelayDialog> createState() => _CompletionDelayDialogState();
}

class _CompletionDelayDialogState extends State<CompletionDelayDialog>
    with TickerProviderStateMixin {
  DelayOption? _selectedOption;
  late AnimationController _slideController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _handleOptionSelected(DelayOption option) {
    setState(() {
      _selectedOption = option;
    });

    if (option.isCustom) {
      _showCustomTimePicker();
    } else {
      _confirmSelection(option);
    }
  }

  void _showCustomTimePicker() async {
    final now = DateTime.now();
    final initialTime = TimeOfDay.fromDateTime(now.add(Duration(minutes: 30)));
    
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Select completion time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
              hourMinuteTextColor: Theme.of(context).colorScheme.onSurface,
              dayPeriodTextColor: Theme.of(context).colorScheme.onSurface,
              dialHandColor: Theme.of(context).colorScheme.primary,
              dialTextColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      // If selected time is in the past, move to tomorrow
      final finalDateTime = selectedDateTime.isBefore(now)
          ? selectedDateTime.add(Duration(days: 1))
          : selectedDateTime;

      final duration = finalDateTime.difference(now);
      
      // Validate minimum delay (1 minute)
      if (duration.inMinutes < 1) {
        _showValidationError('Please select a time at least 1 minute in the future');
        return;
      }

      final customOption = _selectedOption!.copyWithDuration(duration);
      _confirmSelection(customOption);
    } else {
      // User cancelled time picker, reset selection
      setState(() {
        _selectedOption = null;
      });
    }
  }

  void _confirmSelection(DelayOption option) {
    final scheduledTime = DateTime.now().add(option.duration);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.schedule,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('Confirm Delay'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminder will be rescheduled:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.reminderTitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Delayed by: ${option.displayText}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'New time: ${_formatDateTime(scheduledTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation
              setState(() {
                _selectedOption = null;
              });
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close confirmation
              Navigator.pop(context); // Close delay dialog
              widget.onDelaySelected(option);
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final isToday = dateTime.day == now.day && 
                   dateTime.month == now.month && 
                   dateTime.year == now.year;
    final isTomorrow = dateTime.day == now.day + 1 && 
                      dateTime.month == now.month && 
                      dateTime.year == now.year;

    final timeStr = TimeOfDay.fromDateTime(dateTime).format(context);
    
    if (isToday) {
      return 'Today at $timeStr';
    } else if (isTomorrow) {
      return 'Tomorrow at $timeStr';
    } else {
      return '${dateTime.month}/${dateTime.day} at $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(
        opacity: _fadeController,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Complete Later',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onCancel,
                          icon: Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When would you like to be reminded again?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Delay options
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: DelayOption.presets.map((option) {
                    final isSelected = _selectedOption?.id == option.id;
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _handleOptionSelected(option),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    option.icon,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.surface,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option.displayText,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.onPrimaryContainer
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Function to show the completion delay dialog
Future<DelayOption?> showCompletionDelayDialog({
  required BuildContext context,
  required String reminderTitle,
}) async {
  DelayOption? selectedOption;
  
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => CompletionDelayDialog(
      reminderTitle: reminderTitle,
      onDelaySelected: (option) {
        selectedOption = option;
      },
      onCancel: () {
        Navigator.pop(context);
      },
    ),
  );
  
  return selectedOption;
}