import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../lib/presentation/auth/login_screen.dart';

void main() {
  group('LoginScreen Icon Display Tests', () {
    testWidgets('should display custom SVG icon with correct properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should find SvgPicture widget
      expect(find.byType(SvgPicture), findsOneWidget);

      // Get the SvgPicture widget
      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));

      // Verify SVG asset path
      expect(svgPicture.pictureProvider.toString(), contains('img_app_logo.svg'));

      // Verify dimensions
      expect(svgPicture.width, equals(120));
      expect(svgPicture.height, equals(120));

      // Verify fit property
      expect(svgPicture.fit, equals(BoxFit.contain));

      // Verify placeholder builder is provided for PNG fallback
      expect(svgPicture.placeholderBuilder, isNotNull);
    });

    testWidgets('should have PNG fallback configured correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Get the SvgPicture widget
      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));

      // Verify placeholder builder exists
      expect(svgPicture.placeholderBuilder, isNotNull);

      // Test the placeholder builder
      final placeholderWidget = svgPicture.placeholderBuilder!(
        tester.element(find.byType(SvgPicture)),
      );

      // Should return an Image widget for PNG fallback
      expect(placeholderWidget, isA<Image>());

      final imageWidget = placeholderWidget as Image;
      expect(imageWidget.image, isA<AssetImage>());

      final assetImage = imageWidget.image as AssetImage;
      expect(assetImage.assetName, equals('assets/images/reminder app icon.png'));

      // Verify fallback image dimensions
      expect(imageWidget.width, equals(120));
      expect(imageWidget.height, equals(120));
      expect(imageWidget.fit, equals(BoxFit.contain));
    });

    testWidgets('should display icon within styled container', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find the container that wraps the icon
      final iconContainers = find.byType(Container).evaluate().where((element) {
        final widget = element.widget as Container;
        return widget.width == 120 && widget.height == 120;
      });

      expect(iconContainers, hasLength(1));

      final iconContainer = iconContainers.first.widget as Container;

      // Verify container dimensions
      expect(iconContainer.width, equals(120));
      expect(iconContainer.height, equals(120));

      // Verify container decoration
      expect(iconContainer.decoration, isA<BoxDecoration>());

      final decoration = iconContainer.decoration as BoxDecoration;

      // Verify border radius
      expect(decoration.borderRadius, isA<BorderRadius>());
      final borderRadius = decoration.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, equals(30));

      // Verify background color with transparency
      expect(decoration.color, isNotNull);
      expect(decoration.color.toString(), contains('0.2')); // Alpha value

      // Verify box shadow
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.boxShadow, hasLength(1));

      final boxShadow = decoration.boxShadow!.first;
      expect(boxShadow.blurRadius, equals(20));
      expect(boxShadow.offset, equals(Offset(0, 10)));
    });

    testWidgets('should have ClipRRect for proper border radius clipping', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should find ClipRRect widget
      expect(find.byType(ClipRRect), findsAtLeastNWidgets(1));

      // Find the ClipRRect that contains the SVG
      final clipRRects = find.byType(ClipRRect).evaluate();
      bool foundIconClipRRect = false;

      for (final element in clipRRects) {
        final clipRRect = element.widget as ClipRRect;
        if (clipRRect.borderRadius != null) {
          final borderRadius = clipRRect.borderRadius as BorderRadius;
          if (borderRadius.topLeft.x == 30) {
            foundIconClipRRect = true;
            break;
          }
        }
      }

      expect(foundIconClipRRect, isTrue);
    });

    testWidgets('should maintain icon aspect ratio and sizing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Get the SVG widget
      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));

      // Verify aspect ratio is maintained with BoxFit.contain
      expect(svgPicture.fit, equals(BoxFit.contain));
      expect(svgPicture.width, equals(svgPicture.height)); // Square aspect ratio

      // Verify size is appropriate for mobile screens
      expect(svgPicture.width, equals(120));
      expect(svgPicture.height, equals(120));
    });

    testWidgets('should display icon with proper visual hierarchy', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Icon should be displayed before the app title
      final iconFinder = find.byType(SvgPicture);
      final titleFinder = find.text('Good Deeds Reminder');

      expect(iconFinder, findsOneWidget);
      expect(titleFinder, findsOneWidget);

      // Get positions to verify visual hierarchy
      final iconPosition = tester.getTopLeft(iconFinder);
      final titlePosition = tester.getTopLeft(titleFinder);

      // Icon should be above the title
      expect(iconPosition.dy, lessThan(titlePosition.dy));
    });

    testWidgets('should handle icon loading states gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // The SVG should be present immediately (even if not loaded)
      expect(find.byType(SvgPicture), findsOneWidget);

      // Container should be present to provide visual structure while loading
      final iconContainers = find.byType(Container).evaluate().where((element) {
        final widget = element.widget as Container;
        return widget.width == 120 && widget.height == 120;
      });

      expect(iconContainers, hasLength(1));

      // Should not crash during loading
      await tester.pumpAndSettle();
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('should maintain consistent styling across different screen sizes', (WidgetTester tester) async {
      // Test with mobile screen size
      await tester.binding.setSurfaceSize(Size(375, 667));

      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify icon is displayed
      expect(find.byType(SvgPicture), findsOneWidget);
      
      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svgPicture.width, equals(120));
      expect(svgPicture.height, equals(120));

      // Test with tablet screen size
      await tester.binding.setSurfaceSize(Size(768, 1024));
      await tester.pumpAndSettle();

      // Icon should maintain same size
      final svgPictureTablet = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svgPictureTablet.width, equals(120));
      expect(svgPictureTablet.height, equals(120));

      // Reset to default
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should have proper accessibility for icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Icon should be part of the logo section
      expect(find.byType(SvgPicture), findsOneWidget);

      // The icon is decorative and part of the branding, so it doesn't need
      // explicit accessibility labels, but it should not interfere with
      // screen readers
      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svgPicture, isNotNull);

      // The app title provides the semantic meaning
      expect(find.text('Good Deeds Reminder'), findsOneWidget);
    });

    testWidgets('should handle asset loading errors gracefully', (WidgetTester tester) async {
      // This test verifies that the widget structure is set up correctly
      // to handle potential asset loading issues
      
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // SVG widget should be present with placeholder builder
      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svgPicture.placeholderBuilder, isNotNull);

      // Container should provide visual structure even if asset fails
      final iconContainers = find.byType(Container).evaluate().where((element) {
        final widget = element.widget as Container;
        return widget.width == 120 && widget.height == 120;
      });

      expect(iconContainers, hasLength(1));

      // Should not crash
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}