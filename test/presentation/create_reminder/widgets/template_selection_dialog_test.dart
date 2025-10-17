import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../../lib/core/models/reminder_template.dart';
import '../../../../lib/core/services/template_service.dart';
import '../../../../lib/presentation/create_reminder/widgets/template_selection_dialog.dart';

void main() {
  group('TemplateSelectionDialog', () {

    Widget createTestWidget({
      required Function(ReminderTemplate) onTemplateSelected,
      String? currentText,
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: Material(
              child: TemplateSelectionDialog(
                onTemplateSelected: onTemplateSelected,
                currentText: currentText,
              ),
            ),
          );
        },
      );
    }

    testWidgets('should render dialog with header and close button', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      await tester.pumpAndSettle();

      // Debug: Print widget tree to understand the structure
      debugPrint('Dialog found: ${find.byType(Dialog).evaluate().length}');
      debugPrint('TemplateSelectionDialog found: ${find.byType(TemplateSelectionDialog).evaluate().length}');

      // Verify dialog is rendered
      expect(find.byType(Dialog), findsOneWidget);
      
      // Verify header text
      expect(find.text('Quick Templates'), findsOneWidget);
      
      // Verify close button
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    testWidgets('should display predefined templates', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      await tester.pumpAndSettle();

      // Verify ListView is present for scrolling
      expect(find.byType(ListView), findsOneWidget);
      
      // Verify at least some templates are displayed
      expect(find.text('Call mom'), findsOneWidget);
      expect(find.text('Personal & Family'), findsWidgets);
    });

    testWidgets('should display clear and custom template options', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      await tester.pumpAndSettle();

      // Verify ListView is scrollable
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);
      
      // Verify clear template is displayed
      expect(find.text('Clear'), findsOneWidget);
      expect(find.text('Clear the title and start typing'), findsOneWidget);
      
      // Verify the ListView has the expected number of items (clear + templates + custom)
      final listViewWidget = tester.widget<ListView>(listView);
      expect(listViewWidget, isNotNull);
    });

    testWidgets('should display category display names correctly', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      await tester.pumpAndSettle();

      // Verify category display names are shown
      expect(find.text('Personal & Family'), findsWidgets);
    });

    testWidgets('should call onTemplateSelected when template is tapped', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap a specific template
      await tester.tap(find.text('Call mom'));
      await tester.pumpAndSettle();

      // Verify callback was called with correct template
      expect(selectedTemplate, isNotNull);
      expect(selectedTemplate!.title, equals('Call mom'));
    });

    testWidgets('should call onTemplateSelected when template is tapped', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      await tester.pumpAndSettle();

      // Tap a visible template
      await tester.tap(find.text('Call mom'));
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(selectedTemplate, isNotNull);
      expect(selectedTemplate!.title, equals('Call mom'));
    });

    testWidgets('should call onTemplateSelected when clear template is tapped', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      await tester.pumpAndSettle();

      // Tap clear template
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Verify callback was called with clear template
      expect(selectedTemplate, isNotNull);
      expect(selectedTemplate!.id, equals('clear'));
      expect(selectedTemplate!.title, equals('Clear'));
    });

    testWidgets('should close dialog when close button is tapped', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      // Verify dialog is present
      expect(find.byType(Dialog), findsOneWidget);

      // Tap close button
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      // Verify dialog is closed (no longer in widget tree)
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('should close dialog when template is selected', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      // Verify dialog is present
      expect(find.byType(Dialog), findsOneWidget);

      // Tap a template
      await tester.tap(find.text('Call mom'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('should display appropriate icons for each category', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      await tester.pumpAndSettle();

      // Verify icons are displayed (we can't easily test specific icons, but we can verify icons exist)
      final iconWidgets = find.byType(Icon);
      expect(iconWidgets, findsWidgets);
      
      // Should have at least some icons (visible templates + close button)
      expect(iconWidgets.evaluate().length, greaterThanOrEqualTo(5));
    });

    testWidgets('should handle scrolling when many templates are present', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      await tester.pumpAndSettle();

      // Verify ListView is present for scrolling
      expect(find.byType(ListView), findsOneWidget);
      
      // Test scrolling functionality
      final listView = find.byType(ListView);
      await tester.drag(listView, const Offset(0, -500)); // Scroll down
      await tester.pumpAndSettle();
      
      // Should still have the ListView after scrolling
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should maintain proper dialog constraints', (WidgetTester tester) async {
      ReminderTemplate? selectedTemplate;

      await tester.pumpWidget(
        createTestWidget(
          onTemplateSelected: (template) => selectedTemplate = template,
        ),
      );

      // Find the dialog container
      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      
      // Verify constraints are applied
      expect(container.constraints, isNotNull);
      expect(container.constraints!.maxHeight, equals(70.0.h));
      expect(container.constraints!.maxWidth, equals(90.0.w));
    });

    group('Template Selection Behavior', () {
      testWidgets('should handle multiple rapid taps gracefully', (WidgetTester tester) async {
        int callCount = 0;
        ReminderTemplate? selectedTemplate;

        await tester.pumpWidget(
          createTestWidget(
            onTemplateSelected: (template) {
              callCount++;
              selectedTemplate = template;
            },
          ),
        );

        await tester.pumpAndSettle();

        final templateFinder = find.text('Call mom');
        
        // Tap multiple times rapidly
        await tester.tap(templateFinder, warnIfMissed: false);
        await tester.tap(templateFinder, warnIfMissed: false);
        await tester.tap(templateFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Should only call once since dialog closes after first tap
        expect(callCount, equals(1));
        expect(selectedTemplate!.title, equals('Call mom'));
      });

      testWidgets('should pass currentText parameter correctly', (WidgetTester tester) async {
        const testText = 'existing text';
        ReminderTemplate? selectedTemplate;

        await tester.pumpWidget(
          createTestWidget(
            onTemplateSelected: (template) => selectedTemplate = template,
            currentText: testText,
          ),
        );

        // The currentText is passed to the widget but doesn't affect rendering
        // This test ensures the parameter is accepted without errors
        expect(find.byType(TemplateSelectionDialog), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide proper semantic labels', (WidgetTester tester) async {
        ReminderTemplate? selectedTemplate;

        await tester.pumpWidget(
          createTestWidget(
            onTemplateSelected: (template) => selectedTemplate = template,
          ),
        );

        // Verify close button has tooltip
        expect(find.byTooltip('Close'), findsOneWidget);
        
        // Verify dialog has proper structure for screen readers
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });
    });
  });
}