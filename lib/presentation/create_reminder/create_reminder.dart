import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../core/models/reminder_template.dart';
import '../../core/services/template_service.dart';
import './widgets/audio_selection_widget.dart';
import './widgets/category_selection_widget.dart';
import './widgets/frequency_selection_widget.dart';
import './widgets/time_selection_widget.dart';
import './widgets/quick_template_icon_widget.dart';
import './widgets/template_selection_dialog.dart';
import '../common/widgets/schedule_confirmation_dialog.dart';

class CreateReminder extends StatefulWidget {
  final Map<String, dynamic>? reminderToEdit;
  
  const CreateReminder({super.key, this.reminderToEdit});

  @override
  State<CreateReminder> createState() => _CreateReminderState();
}

class _CreateReminderState extends State<CreateReminder> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scrollController = ScrollController();
  final _titleFocusNode = FocusNode();

  String? _selectedCategory = 'charity'; // Default to charity
  Map<String, dynamic>? _selectedFrequency = {'id': 'daily', 'title': 'Daily'}; // Default to daily
  TimeOfDay? _selectedTime;
  Map<String, dynamic>? _selectedAudio = {
    'id': 'default_gentle_reminder',
    'name': 'Gentle Reminder',
    'duration': '0:15',
    'type': 'default',
    'description': 'Default gentle reminder sound',
    'path': 'assets/audio/gentle_reminder.mp3',
  };
  bool _isAdvancedExpanded = false;
  bool _enableNotifications = true;
  int _repeatLimit = 0; // 0 means infinite
  bool _isEditMode = false;
  int? _editingReminderId;

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty &&
        _selectedCategory != null &&
        _selectedFrequency != null &&
        _selectedTime != null;
  }

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.reminderToEdit != null) {
      // Edit mode - populate form with existing reminder data
      _isEditMode = true;
      final reminder = widget.reminderToEdit!;
      _editingReminderId = reminder['id'] as int?;
      
      _titleController.text = reminder['title'] as String? ?? 'remind me';
      _descriptionController.text = reminder['description'] as String? ?? '';
      _selectedCategory = reminder['category'] as String?;
      _selectedFrequency = reminder['frequency'] as Map<String, dynamic>?;
      _selectedAudio = reminder['selectedAudio'] as Map<String, dynamic>?;
      _enableNotifications = reminder['enableNotifications'] as bool? ?? true;
      _repeatLimit = reminder['repeatLimit'] as int? ?? 0;
      
      // Parse time
      final timeString = reminder['time'] as String?;
      if (timeString != null) {
        final timeParts = timeString.split(':');
        if (timeParts.length == 2) {
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          _selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    } else {
      // Create mode - set default values with random good deed
      final randomGoodDeed = TemplateService.getRandomGoodDeed();
      _titleController.text = randomGoodDeed.title;
      
      // Set default time to current time + 1 minute
      final now = DateTime.now();
      final defaultTime = now.add(Duration(minutes: 1));
      _selectedTime = TimeOfDay(hour: defaultTime.hour, minute: defaultTime.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _scrollController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(4.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleSection(),
                      SizedBox(height: 4.h),
                      CategorySelectionWidget(
                        selectedCategory: _selectedCategory,
                        onCategorySelected: (category) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                      SizedBox(height: 4.h),
                      FrequencySelectionWidget(
                        selectedFrequency: _selectedFrequency,
                        onFrequencySelected: (frequency) {
                          setState(() => _selectedFrequency = frequency);
                        },
                      ),
                      SizedBox(height: 4.h),
                      TimeSelectionWidget(
                        selectedTime: _selectedTime,
                        onTimeSelected: (time) {
                          setState(() => _selectedTime = time);
                        },
                      ),
                      SizedBox(height: 4.h),
                      AudioSelectionWidget(
                        selectedAudio: _selectedAudio,
                        onAudioSelected: (audio) {
                          setState(() => _selectedAudio = audio);
                        },
                      ),
                      SizedBox(height: 4.h),
                      _buildDescriptionSection(),
                      SizedBox(height: 4.h),
                      _buildAdvancedOptions(),
                      SizedBox(height: 8.h), // Extra space for keyboard
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                ),
              ),
              child: CustomIconWidget(
                iconName: 'close',
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _isEditMode ? 'Edit Reminder' : 'Create Reminder',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: _isFormValid ? _saveReminder : null,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
              decoration: BoxDecoration(
                color: _isFormValid
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _isEditMode ? 'Update' : 'Save',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: _isFormValid
                      ? AppTheme.lightTheme.colorScheme.onPrimary
                      : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder Title',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          decoration: InputDecoration(
            hintText: 'e.g., Call my mother, Read Quran, Exercise',
            counterText: '${_titleController.text.length}/50',
            suffixIcon: QuickTemplateIconWidget(
              onTap: _showTemplateDialog,
              isEnabled: true,
            ),
          ),
          maxLength: 50,
          textInputAction: TextInputAction.next,
          onChanged: (value) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a reminder title';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2.h),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Add more details about this reminder...',
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          maxLength: 200,
          textInputAction: TextInputAction.done,
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: [
            _buildSuggestionChip('May Allah bless this deed'),
            _buildSuggestionChip('For the sake of Allah'),
            _buildSuggestionChip('Seeking barakah'),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        final currentText = _descriptionController.text;
        final newText = currentText.isEmpty ? text : '$currentText $text';
        _descriptionController.text = newText;
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          text,
          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () =>
              setState(() => _isAdvancedExpanded = !_isAdvancedExpanded),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'settings',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Advanced Options',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isAdvancedExpanded ? 0.5 : 0,
                  duration: Duration(milliseconds: 200),
                  child: CustomIconWidget(
                    iconName: 'keyboard_arrow_down',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: _isAdvancedExpanded ? null : 0,
          child:
              _isAdvancedExpanded ? _buildAdvancedContent() : SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildAdvancedContent() {
    return Container(
      margin: EdgeInsets.only(top: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Enable Notifications',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Switch(
                value: _enableNotifications,
                onChanged: (value) =>
                    setState(() => _enableNotifications = value),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Repeat Limit',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: RadioListTile<int>(
                  title: Text('Infinite'),
                  value: 0,
                  groupValue: _repeatLimit,
                  onChanged: (value) =>
                      setState(() => _repeatLimit = value ?? 0),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<int>(
                  title: Text('Custom'),
                  value: 1,
                  groupValue: _repeatLimit,
                  onChanged: (value) =>
                      setState(() => _repeatLimit = value ?? 0),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          if (_repeatLimit == 1) ...[
            SizedBox(height: 2.h),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Number of repetitions',
                hintText: 'e.g., 30',
              ),
              keyboardType: TextInputType.number,
              initialValue: '30',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Show loading
      _showLoadingDialog();

      // Format time
      final timeString = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';

      Map<String, dynamic>? savedReminder;

      if (_isEditMode && _editingReminderId != null) {
        // Update existing reminder - this will automatically reschedule background notifications
        await ReminderStorageService.instance.updateReminder(_editingReminderId!, {
          'title': _titleController.text.trim(),
          'category': _selectedCategory!,
          'frequency': _selectedFrequency!,
          'time': timeString,
          'description': _descriptionController.text.trim(),
          'selectedAudio': _selectedAudio,
          'enableNotifications': _enableNotifications,
          'repeatLimit': _repeatLimit,
        });
        
        // Get the updated reminder for display
        savedReminder = await ReminderStorageService.instance.getReminderById(_editingReminderId!);
        
        if (savedReminder != null) {
          print('CreateReminder: Updated reminder ${_editingReminderId} with background scheduling integration');
        }
      } else {
        // Create new reminder with schedule confirmation - this will automatically schedule background notifications
        print('CreateReminder: About to save reminder with confirmation...');
        savedReminder = await ReminderStorageService.instance.saveReminderWithConfirmation(
          title: _titleController.text.trim(),
          category: _selectedCategory!,
          frequency: _selectedFrequency!,
          time: timeString,
          description: _descriptionController.text.trim(),
          selectedAudio: _selectedAudio,
          enableNotifications: _enableNotifications,
          repeatLimit: _repeatLimit,
          onScheduleConflict: (originalTime, adjustedTime) async {
            // Close loading dialog first
            Navigator.pop(context);
            
            // Show conflict resolution dialog
            final shouldAccept = await ScheduleConfirmationDialog.showTimeConflictResolution(
              context,
              originalTime,
              adjustedTime,
            );
            
            if (shouldAccept == true) {
              // User accepted the adjustment, save with the adjusted time
              _showLoadingDialog();
              final fallbackReminder = await ReminderStorageService.instance.saveReminder(
                title: _titleController.text.trim(),
                category: _selectedCategory!,
                frequency: _selectedFrequency!,
                time: timeString,
                description: _descriptionController.text.trim(),
                selectedAudio: _selectedAudio,
                enableNotifications: _enableNotifications,
                repeatLimit: _repeatLimit,
              );
              Navigator.pop(context); // Close loading dialog
              _showSuccessDialog(fallbackReminder);
            } else {
              // User cancelled, don't save
              return;
            }
          },
          onScheduleConfirmation: (scheduledTime) async {
            // Show confirmation for the scheduled time
            final shouldConfirm = await ScheduleConfirmationDialog.showScheduleConfirmation(
              context,
              scheduledTime,
            );
            
            if (shouldConfirm != true) {
              // User cancelled confirmation
              Navigator.pop(context); // Close loading dialog
              return;
            }
          },
        );
        
        // If savedReminder is null, it means user cancelled during conflict resolution
        if (savedReminder == null) {
          return;
        }
        
        if (savedReminder != null) {
          print('CreateReminder: Created new reminder ${savedReminder['id']} with background scheduling integration');
          print('CreateReminder: Saved reminder data: $savedReminder');
        }
      }

      // Close loading dialog
      Navigator.pop(context);

      // Show success dialog if reminder was saved
      if (savedReminder != null) {
        _showSuccessDialog(savedReminder);
      }
    } catch (e) {
      // Close loading dialog if open
      Navigator.pop(context);
      
      // Show error with background scheduling context
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode 
            ? 'Failed to update reminder and reschedule background notifications: ${e.toString()}'
            : 'Failed to create reminder and schedule background notifications: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Shows loading dialog
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Shows success dialog after reminder is saved
  void _showSuccessDialog(Map<String, dynamic> savedReminder) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'check',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 32,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              _isEditMode ? 'Reminder Updated!' : 'Reminder Created!',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _isEditMode 
                ? 'Your reminder has been updated successfully with schedule confirmation.'
                : 'Your good deed reminder has been set up successfully with schedule confirmation.',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Next reminder:',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    savedReminder['nextOccurrence'] as String? ?? 'Unknown',
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacementNamed(context, '/reminder-management');
              },
              child: Text('View Reminders'),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the template selection dialog
  Future<void> _showTemplateDialog() async {
    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return TemplateSelectionDialog(
            currentText: _titleController.text.trim(),
            onTemplateSelected: _handleTemplateSelection,
          );
        },
      );
    } catch (e) {
      // Handle any errors in showing the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load templates: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  /// Handles template selection from the dialog
  Future<void> _handleTemplateSelection(ReminderTemplate template) async {
    // Handle clear template - clear title and focus on input
    if (template.id == 'clear') {
      setState(() {
        _titleController.clear();
      });
      
      // Focus on the title field and show keyboard
      _titleFocusNode.requestFocus();
      return;
    }

    // If custom template is selected, just close dialog and let user type
    if (template.isCustom) {
      return;
    }

    // Apply the selected template without confirmation
    setState(() {
      _titleController.text = template.title;
    });

    // Show brief feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template applied: ${template.title}'),
        duration: Duration(seconds: 2),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  /// Shows confirmation dialog when replacing existing text
  Future<bool> _showReplaceTextConfirmation(String currentText, String templateText) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Replace existing text?',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have existing text in the title field:',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"$currentText"',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                'Replace it with the selected template:',
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"$templateText"',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTheme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Replace'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
