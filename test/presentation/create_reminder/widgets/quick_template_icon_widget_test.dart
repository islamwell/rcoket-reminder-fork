import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../lib/presentation/create_reminder/widgets/quick_template_icon_widget.dart';
import '../../../../lib/widgets/custom_icon_widget.dart';
import '../../../../lib/theme/app_theme.dart';

void main() {
  group('QuickTemplateIconWidget', () {
    testWidgets('renders correctly with enabled state', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: QuickTemplateIconWidget(
              onTap: () => tapped = true,
              isEnabled: true,
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(QuickTemplateIconWidget), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(CustomIconWidget), findsOneWidget);

      // Verify the icon is correct
      final customIconWidget = tester.widget<CustomIconWidget>(
        find.byType(CustomIconWidget),
      );
      expect(customIconWidget.iconName, equals('auto_awesome'));
      expect(customIconWidget.size, equals(24));
      expect(customIconWidget.color, equals(AppTheme.lightTheme.colorScheme.primary));

      // Verify tap functionality
      await tester.tap(find.byType(IconButton));
      expect(tapped, isTrue);
    });

    testWidgets('renders correctly with disabled state', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: QuickTemplateIconWidget(
              onTap: () => tapped = true,
              isEnabled: false,
            ),
          ),
        ),
      );

      // Verify the widget renders
      expect(find.byType(QuickTemplateIconWidget), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byType(CustomIconWidget), findsOneWidget);

      // Verify the icon has disabled color
      final customIconWidget = tester.widget<CustomIconWidget>(
        find.byType(CustomIconWidget),
      );
      expect(customIconWidget.color, 
        equals(AppTheme.lightTheme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)));

      // Verify tap is disabled
      await tester.tap(find.byType(IconButton));
      expect(tapped, isFalse);
    });

    testWidgets('has correct tooltip', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: QuickTemplateIconWidget(
              onTap: () {},
              isEnabled: true,
            ),
          ),
        ),
      );

      // Verify tooltip
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, equals('Quick Templates'));
    });

    testWidgets('has correct constraints and splash radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: QuickTemplateIconWidget(
              onTap: () {},
              isEnabled: true,
            ),
          ),
        ),
      );

      // Verify button properties
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.splashRadius, equals(20));
      expect(iconButton.constraints, equals(const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      )));
    });

    testWidgets('calls onTap when enabled and tapped', (WidgetTester tester) async {
      int tapCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: QuickTemplateIconWidget(
              onTap: () => tapCount++,
              isEnabled: true,
            ),
          ),
        ),
      );

      // Tap multiple times
      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));
      await tester.tap(find.byType(IconButton));

      expect(tapCount, equals(3));
    });

    testWidgets('does not call onTap when disabled', (WidgetTester tester) async {
      int tapCount = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: QuickTemplateIconWidget(
              onTap: () => tapCount++,
              isEnabled: false,
            ),
          ),
        ),
      );

      // Try to tap
      await tester.tap(find.byType(IconButton));
      
      expect(tapCount, equals(0));
    });

    testWidgets('uses theme colors from context', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: QuickTemplateIconWidget(
              onTap: () {},
              isEnabled: true,
            ),
          ),
        ),
      );

      // Verify the widget renders and uses theme colors
      expect(find.byType(QuickTemplateIconWidget), findsOneWidget);
      expect(find.byType(CustomIconWidget), findsOneWidget);
      
      final customIconWidget = tester.widget<CustomIconWidget>(
        find.byType(CustomIconWidget),
      );
      expect(customIconWidget.color, isNotNull);
    });

    testWidgets('has proper accessibility semantics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: QuickTemplateIconWidget(
              onTap: () {},
              isEnabled: true,
            ),
          ),
        ),
      );

      // Verify the button is accessible
      expect(find.byType(IconButton), findsOneWidget);
      
      // The IconButton should be focusable and have semantic properties
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, isNotNull);
      expect(iconButton.tooltip, equals('Quick Templates'));
    });
  });
}