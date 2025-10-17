import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/models/reminder_template.dart';
import '../../../core/services/template_service.dart';
import '../../../widgets/custom_icon_widget.dart';

/// A modal dialog widget for selecting reminder templates
class TemplateSelectionDialog extends StatefulWidget {
  final Function(ReminderTemplate) onTemplateSelected;
  final String? currentText;

  const TemplateSelectionDialog({
    super.key,
    required this.onTemplateSelected,
    this.currentText,
  });

  @override
  State<TemplateSelectionDialog> createState() => _TemplateSelectionDialogState();
}

class _TemplateSelectionDialogState extends State<TemplateSelectionDialog> {
  late List<ReminderTemplate> _templates;
  late ReminderTemplate _customTemplate;
  late ReminderTemplate _clearTemplate;

  @override
  void initState() {
    super.initState();
    _templates = TemplateService.getPredefinedTemplates();
    _customTemplate = TemplateService.getCustomTemplate();
    _clearTemplate = TemplateService.getClearTemplate();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 70.h,
          maxWidth: 90.w,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: _buildTemplateList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Quick Templates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const CustomIconWidget(
              iconName: 'close',
              size: 24,
            ),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: _templates.length + 2, // +1 for clear template, +1 for custom template
      itemBuilder: (context, index) {
        if (index == 0) {
          // First item is always the clear template
          return _buildClearTemplateItem();
        } else if (index <= _templates.length) {
          // Regular templates
          return _buildTemplateItem(_templates[index - 1]);
        } else {
          // Last item is custom template
          return _buildCustomTemplateItem();
        }
      },
    );
  }

  Widget _buildTemplateItem(ReminderTemplate template) {
    return ListTile(
      leading: _getTemplateIcon(template.category),
      title: Text(
        template.title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        _getCategoryDisplayName(template.category),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
        ),
      ),
      onTap: () => _handleTemplateSelection(template),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    );
  }

  Widget _buildClearTemplateItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        leading: const CustomIconWidget(
          iconName: 'clear',
          size: 24,
        ),
        title: Text(
          _clearTemplate.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        subtitle: Text(
          'Clear the title and start typing',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        onTap: () => _handleTemplateSelection(_clearTemplate),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }

  Widget _buildCustomTemplateItem() {
    return Container(
      margin: EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: ListTile(
        leading: const CustomIconWidget(
          iconName: 'edit',
          size: 24,
        ),
        title: Text(
          _customTemplate.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Create your own reminder',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
          ),
        ),
        onTap: () => _handleTemplateSelection(_customTemplate),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      ),
    );
  }

  Widget _getTemplateIcon(String category) {
    String iconName;
    switch (category) {
      case TemplateCategory.personal:
        iconName = 'family_restroom';
        break;
      case TemplateCategory.health:
        iconName = 'favorite';
        break;
      case TemplateCategory.charity:
        iconName = 'volunteer_activism';
        break;
      case TemplateCategory.spiritual:
        iconName = 'auto_awesome';
        break;
      case TemplateCategory.work:
        iconName = 'work';
        break;
      default:
        iconName = 'lightbulb';
    }

    return CustomIconWidget(
      iconName: iconName,
      size: 24,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case TemplateCategory.personal:
        return 'Personal & Family';
      case TemplateCategory.health:
        return 'Health & Wellness';
      case TemplateCategory.charity:
        return 'Charity & Good Deeds';
      case TemplateCategory.spiritual:
        return 'Spiritual & Religious';
      case TemplateCategory.work:
        return 'Work & Productivity';
      default:
        return 'Other';
    }
  }

  void _handleTemplateSelection(ReminderTemplate template) {
    Navigator.of(context).pop();
    widget.onTemplateSelected(template);
  }
}