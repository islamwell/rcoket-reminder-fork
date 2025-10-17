# Design Document

## Overview

The Quick Reminder Templates feature enhances the existing reminder creation flow by adding a template selection mechanism to the reminder title field. This feature integrates seamlessly with the current `CreateReminder` screen by adding an icon button to the title text field that opens a template selection dialog with predefined reminder options.

## Architecture

### Component Structure

The feature follows the existing Flutter architecture pattern used in the app:

```
lib/presentation/create_reminder/
├── create_reminder.dart (modified)
└── widgets/
    ├── quick_template_icon_widget.dart (new)
    └── template_selection_dialog.dart (new)

lib/core/models/
└── reminder_template.dart (new)

lib/core/services/
└── template_service.dart (new)
```

### Integration Points

1. **CreateReminder Screen**: Modified to include the template icon in the title field
2. **Title Text Field**: Enhanced with a suffix icon that triggers template selection
3. **Template Dialog**: New modal dialog for template selection
4. **Template Service**: Manages predefined templates and custom template logic

## Components and Interfaces

### 1. ReminderTemplate Model

```dart
class ReminderTemplate {
  final String id;
  final String title;
  final String category;
  final bool isCustom;
  
  const ReminderTemplate({
    required this.id,
    required this.title,
    required this.category,
    this.isCustom = false,
  });
}
```

### 2. TemplateService

```dart
class TemplateService {
  static List<ReminderTemplate> getPredefinedTemplates();
  static List<ReminderTemplate> getTemplatesByCategory(String category);
  static ReminderTemplate getCustomTemplate();
}
```

### 3. QuickTemplateIconWidget

A reusable widget that displays the template icon in the text field:

```dart
class QuickTemplateIconWidget extends StatelessWidget {
  final VoidCallback onTap;
  final bool isEnabled;
  
  const QuickTemplateIconWidget({
    required this.onTap,
    this.isEnabled = true,
  });
}
```

### 4. TemplateSelectionDialog

A modal dialog that displays template options:

```dart
class TemplateSelectionDialog extends StatefulWidget {
  final Function(ReminderTemplate) onTemplateSelected;
  final String? currentText;
  
  const TemplateSelectionDialog({
    required this.onTemplateSelected,
    this.currentText,
  });
}
```

## Data Models

### Predefined Templates

The system will include approximately 20 predefined templates organized by categories:

**Personal & Family (6 templates)**
- Call mom
- Call dad
- Visit family
- Check on elderly relatives
- Send message to siblings
- Plan family gathering

**Health & Wellness (5 templates)**
- Take medication
- Drink water
- Exercise
- Go for a walk
- Get enough sleep

**Charity & Good Deeds (4 templates)**
- Give food to poor
- Visit the sick
- Help a neighbor
- Donate to charity

**Spiritual & Religious (3 templates)**
- Read Quran
- Make dua
- Pray on time

**Work & Productivity (2 templates)**
- Check emails
- Review daily goals

### Template Data Structure

```dart
static const List<ReminderTemplate> _predefinedTemplates = [
  ReminderTemplate(
    id: 'call_mom',
    title: 'Call mom',
    category: 'personal',
  ),
  ReminderTemplate(
    id: 'visit_sick',
    title: 'Visit the sick',
    category: 'charity',
  ),
  // ... additional templates
  ReminderTemplate(
    id: 'custom',
    title: 'Custom',
    category: 'custom',
    isCustom: true,
  ),
];
```

## User Interface Design

### Title Field Enhancement

The existing title field in `_buildTitleSection()` will be modified to include a suffix icon:

```dart
TextFormField(
  controller: _titleController,
  decoration: InputDecoration(
    hintText: 'e.g., Call my mother, Read Quran, Exercise',
    counterText: '${_titleController.text.length}/50',
    suffixIcon: QuickTemplateIconWidget(
      onTap: _showTemplateDialog,
      isEnabled: true,
    ),
  ),
  // ... existing properties
)
```

### Template Selection Dialog

The dialog will feature:

- **Header**: "Quick Templates" title with close button
- **Template List**: Scrollable list of template options
- **Template Items**: Each template displayed as a list tile with icon and title
- **Custom Option**: Special item at the bottom for custom input
- **Dismissal**: Tap outside or back button to close

### Visual Design Elements

- **Template Icon**: Uses existing `CustomIconWidget` with 'lightbulb' or 'auto_awesome' icon
- **Dialog Styling**: Follows existing app theme with rounded corners and shadows
- **List Items**: Material Design list tiles with hover/tap effects
- **Category Grouping**: Templates grouped by category with subtle dividers

## Error Handling

### Template Loading
- Graceful fallback if predefined templates fail to load
- Default to custom option if template service is unavailable

### Text Field Integration
- Preserve existing text validation logic
- Handle template selection when field already contains text
- Confirm replacement dialog for non-empty fields

### Dialog Management
- Proper dialog lifecycle management
- Handle system back button and outside taps
- Prevent multiple dialogs from opening simultaneously

## Testing Strategy

### Unit Tests
1. **TemplateService Tests**
   - Verify predefined templates are loaded correctly
   - Test template filtering by category
   - Validate custom template creation

2. **Widget Tests**
   - QuickTemplateIconWidget tap behavior
   - TemplateSelectionDialog rendering and selection
   - Title field integration with template icon

3. **Integration Tests**
   - End-to-end template selection flow
   - Template text population in title field
   - Dialog dismissal and state management

### Test Files Structure
```
test/
├── core/
│   ├── models/
│   │   └── reminder_template_test.dart
│   └── services/
│       └── template_service_test.dart
└── presentation/
    └── create_reminder/
        └── widgets/
            ├── quick_template_icon_widget_test.dart
            └── template_selection_dialog_test.dart
```

### User Experience Testing
- Verify smooth animation transitions
- Test scrolling performance with 20+ templates
- Validate accessibility features (screen readers, keyboard navigation)
- Confirm proper focus management after template selection

## Implementation Considerations

### Performance
- Templates loaded once and cached in memory
- Efficient list rendering for template dialog
- Minimal impact on existing reminder creation flow

### Accessibility
- Proper semantic labels for template icon and dialog
- Screen reader support for template list
- Keyboard navigation support

### Localization
- Template titles support for multiple languages
- RTL layout support for Arabic/Hebrew
- Cultural sensitivity in template selection

### State Management
- Template selection state isolated to dialog
- No persistent storage required for templates
- Clean integration with existing form state

## Migration Strategy

This feature is additive and requires no data migration:

1. **Phase 1**: Add new template models and service
2. **Phase 2**: Create template selection widgets
3. **Phase 3**: Integrate with existing CreateReminder screen
4. **Phase 4**: Add comprehensive tests

The implementation maintains full backward compatibility with existing reminder creation functionality.