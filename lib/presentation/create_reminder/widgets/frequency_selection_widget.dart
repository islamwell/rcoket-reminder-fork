import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FrequencySelectionWidget extends StatefulWidget {
  final Map<String, dynamic>? selectedFrequency;
  final Function(Map<String, dynamic>) onFrequencySelected;

  const FrequencySelectionWidget({
    super.key,
    this.selectedFrequency,
    required this.onFrequencySelected,
  });

  @override
  State<FrequencySelectionWidget> createState() =>
      _FrequencySelectionWidgetState();
}

class _FrequencySelectionWidgetState extends State<FrequencySelectionWidget> {
  bool _isExpanded = false;
  int _customInterval = 1;
  String _customUnit = 'hours';

  final List<Map<String, dynamic>> frequencyOptions = [
    {
      'id': 'daily',
      'title': 'Daily',
      'subtitle': 'Once every day',
      'icon': 'today',
    },
    {
      'id': 'weekly',
      'title': 'Weekly',
      'subtitle': 'Once every week',
      'icon': 'date_range',
    },
    {
      'id': 'hourly',
      'title': 'Hourly',
      'subtitle': 'Every hour',
      'icon': 'schedule',
    },
    {
      'id': 'custom',
      'title': 'Custom',
      'subtitle': 'Set your own interval',
      'icon': 'tune',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.lightTheme.colorScheme.shadow
                      .withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'repeat',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frequency',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.selectedFrequency != null) ...[
                        SizedBox(height: 0.5.h),
                        Text(
                          _getFrequencyDisplayText(),
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
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
          height: _isExpanded ? null : 0,
          child: _isExpanded ? _buildFrequencyOptions() : SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFrequencyOptions() {
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
        children: [
          ...frequencyOptions.map((option) => _buildFrequencyOption(option)),
          if (widget.selectedFrequency?['id'] == 'custom') ...[
            SizedBox(height: 2.h),
            _buildCustomIntervalSelector(),
          ],
        ],
      ),
    );
  }

  Widget _buildFrequencyOption(Map<String, dynamic> option) {
    final isSelected = widget.selectedFrequency?['id'] == option['id'];

    return GestureDetector(
      onTap: () {
        Map<String, dynamic> frequency = {
          'id': option['id'],
          'title': option['title'],
        };

        if (option['id'] == 'custom') {
          frequency['interval'] = _customInterval;
          frequency['unit'] = _customUnit;
        }

        widget.onFrequencySelected(frequency);
        
        // Close the selection dropdown after selecting an option (except custom which needs the interval selector)
        if (option['id'] != 'custom') {
          setState(() => _isExpanded = false);
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 2.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.lightTheme.colorScheme.primary
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: option['icon'],
              color: isSelected
                  ? AppTheme.lightTheme.colorScheme.primary
                  : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['title'],
                    style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    option['subtitle'],
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomIntervalSelector() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Interval',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: _customInterval.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Every',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                  ),
                  onChanged: (value) {
                    final interval = int.tryParse(value) ?? 1;
                    setState(() => _customInterval = interval);
                    _updateCustomFrequency();
                  },
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _customUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.h),
                  ),
                  items: [
                    DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                    DropdownMenuItem(value: 'hours', child: Text('Hours')),
                    DropdownMenuItem(value: 'days', child: Text('Days')),
                    DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _customUnit = value);
                      _updateCustomFrequency();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateCustomFrequency() {
    if (widget.selectedFrequency?['id'] == 'custom') {
      widget.onFrequencySelected({
        'id': 'custom',
        'title': 'Custom',
        'interval': _customInterval,
        'unit': _customUnit,
      });
    }
  }

  String _getFrequencyDisplayText() {
    if (widget.selectedFrequency == null) return '';

    final frequency = widget.selectedFrequency!;
    if (frequency['id'] == 'custom') {
      return 'Every ${frequency['interval']} ${frequency['unit']}';
    }

    return frequency['title'] ?? '';
  }
}
