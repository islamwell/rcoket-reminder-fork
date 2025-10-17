import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

/// A reusable widget that displays a template icon in text fields
/// to trigger template selection functionality.
class QuickTemplateIconWidget extends StatelessWidget {
  /// Callback function triggered when the icon is tapped
  final VoidCallback onTap;
  
  /// Whether the icon is enabled and can be tapped
  final bool isEnabled;

  const QuickTemplateIconWidget({
    super.key,
    required this.onTap,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return IconButton(
      onPressed: isEnabled ? onTap : null,
      icon: CustomIconWidget(
        iconName: 'auto_awesome',
        size: 24,
        color: isEnabled 
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      tooltip: 'Quick Templates',
      splashRadius: 20,
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
    );
  }
}