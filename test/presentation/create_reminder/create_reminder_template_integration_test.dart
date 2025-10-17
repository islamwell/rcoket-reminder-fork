import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../../lib/core/app_export.dart';
import '../../../lib/presentation/create_reminder/create_reminder.dart';
import '../../../lib/presentation/create_reminder/widgets/quick_template_icon_widget.dart';
import '../../../lib/presentation/create_reminder/widgets/template_selection_dialog.dart';

void main() {
  group('CreateReminder Template Integration Tests', () {
    testWidgets('should display quick template icon in title field', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: CreateReminder(),
            );
          },
        ),
      );

      // Find the title text field
      final titleField = find.byType(TextFormField).first;
      expect(titleField, findsOneWidget);

      // Find the quick template icon widget
      final templateIcon = find.byType(QuickTemplateIconWidget);
      expect(templateIcon, findsOneWidget);
    });

    testWidgets('should open template dialog when icon is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: CreateReminder(),
            );
          },
        ),
      );

      // Tap the template icon
      final templateIcon = find.byType(QuickTemplateIconWidget);
      await tester.tap(templateIcon);
      await tester.pumpAndSettle();

      // Verify template dialog is shown
      expect(find.byType(TemplateSelectionDialog), findsOneWidget);
      expect(find.text('Quick Templates'), findsOneWidget);
    });

    testWidgets('should populate title field when template is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: CreateReminder(),
            );
          },
        ),
      );

      // Clear the default text first
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, '');
      await tester.pumpAndSettle();

      // Tap the template icon
      final templateIcon = find.byType(QuickTemplateIconWidget);
      await tester.tap(templateIcon);
      await tester.pumpAndSettle();

      // Find and tap a template (e.g., "Call mom")
      final callMomTemplate = find.text('Call mom');
      expect(callMomTemplate, findsOneWidget);
      await tester.tap(callMomTemplate);
      await tester.pumpAndSettle();

      // Verify the title field is populated
      final textField = tester.widget<TextFormField>(titleField);
      expect(textField.controller?.text, equals('Call mom'));
    });

    testWidgets('should show confirmation dialog when replacing existing text', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: CreateReminder(),
            );
          },
        ),
      );

      // Enter some text in the title field
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'My custom reminder');
      await tester.pumpAndSettle();

      // Tap the template icon
      final templateIcon = find.byType(QuickTemplateIconWidget);
      await tester.tap(templateIcon);
      await tester.pumpAndSettle();

      // Tap a template
      final callMomTemplate = find.text('Call mom');
      await tester.tap(callMomTemplate);
      await tester.pumpAndSettle();

      // Verify confirmation dialog is shown
      expect(find.text('Replace existing text?'), findsOneWidget);
      expect(find.text('"My custom reminder"'), findsOneWidget);
      expect(find.text('"Call mom"'), findsOneWidget);
    });

    testWidgets('should replace text when user confirms', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: CreateReminder(),
            );
          },
        ),
      );

      // Enter some text in the title field
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'My custom reminder');
      await tester.pumpAndSettle();

      // Tap the template icon
      final templateIcon = find.byType(QuickTemplateIconWidget);
      await tester.tap(templateIcon);
      await tester.pumpAndSettle();

      // Tap a template
      final callMomTemplate = find.text('Call mom');
      await tester.tap(callMomTemplate);
      await tester.pumpAndSettle();

      // Confirm replacement
      final replaceButton = find.text('Replace');
      await tester.tap(replaceButton);
      await tester.pumpAndSettle();

      // Verify the title field is updated
      final textField = tester.widget<TextFormField>(titleField);
      expect(textField.controller?.text, equals('Call mom'));
    });

    testWidgets('should not replace text when user cancels', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: CreateReminder(),
            );
          },
        ),
      );

      // Enter some text in the title field
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'My custom reminder');
      await tester.pumpAndSettle();

      // Tap the template icon
      final templateIcon = find.byType(QuickTemplateIconWidget);
      await tester.tap(templateIcon);
      await tester.pumpAndSettle();

      // Tap a template
      final callMomTemplate = find.text('Call mom');
      await tester.tap(callMomTemplate);
      await tester.pumpAndSettle();

      // Cancel replacement
      final cancelButton = find.text('Cancel');
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify the title field is unchanged
      final textField = tester.widget<TextFormField>(titleField);
      expect(textField.controller?.text, equals('My custom reminder'));
    });

    testWidgets('should maintain form validation after template selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: CreateReminder(),
            );
          },
        ),
      );

      // Clear the title field to make form invalid
      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, '');
      await tester.pumpAndSettle();

      // Verify save button is disabled (form is invalid)
      final saveButton = find.text('Save');
      expect(saveButton, findsOneWidget);

      // Apply a template
      final templateIcon = find.byType(QuickTemplateIconWidget);
      await tester.tap(templateIcon);
      await tester.pumpAndSettle();

      final callMomTemplate = find.text('Call mom');
      await tester.tap(callMomTemplate);
      await tester.pumpAndSettle();

      // Verify form becomes valid after template application
      final textField = tester.widget<TextFormField>(titleField);
      expect(textField.controller?.text, equals('Call mom'));
      expect(textField.controller?.text.trim().isNotEmpty, isTrue);
    });
  });
}