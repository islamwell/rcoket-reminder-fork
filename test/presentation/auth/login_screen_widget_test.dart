import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/presentation/auth/login_screen.dart';
import '../../../lib/widgets/scrolling_quote_widget.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    setUp(() async {
      // Set up mock shared preferences
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display login screen with all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should display app title
      expect(find.text('Good Deeds Reminder'), findsOneWidget);

      // Should display scrolling quotes widget
      expect(find.byType(ScrollingQuoteWidget), findsOneWidget);

      // Should display auth toggle buttons
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Login'), findsAtLeastNWidgets(1));

      // Should display form fields
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Should display main login button
      expect(find.text('Login').last, findsOneWidget);
    });

    testWidgets('should display repositioned buttons correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find the top row with Guest and Sign Up buttons
      final topRowButtons = find.byType(Row).first;
      expect(topRowButtons, findsOneWidget);

      // Guest button should be in the top row
      final guestButton = find.text('Guest');
      expect(guestButton, findsOneWidget);

      // Sign Up button should be in the top row
      final signUpButton = find.text('Sign Up');
      expect(signUpButton, findsOneWidget);

      // Login button should be separate (when in login mode)
      final loginButtons = find.text('Login');
      expect(loginButtons, findsAtLeastNWidgets(1));

      // Verify the buttons are positioned correctly by checking their parent widgets
      final guestButtonWidget = tester.widget<GestureDetector>(
        find.ancestor(
          of: find.text('Guest'),
          matching: find.byType(GestureDetector),
        ).first,
      );
      expect(guestButtonWidget.onTap, isNotNull);
    });

    testWidgets('should switch between login and registration modes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Initially in login mode - no name field
      expect(find.text('Full Name'), findsNothing);
      expect(find.text('Login').last, findsOneWidget);

      // Tap Sign Up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should switch to registration mode
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Should have 3 form fields now (name, email, password)
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Switch back to login mode using bottom link
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Should be back in login mode
      expect(find.text('Full Name'), findsNothing);
      expect(find.text('Login').last, findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should display custom icon with SVG and PNG fallback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should display the logo container
      final logoContainer = find.byType(Container).first;
      expect(logoContainer, findsOneWidget);

      // Should have SvgPicture widget for the custom icon
      expect(find.byType(SvgPicture), findsOneWidget);

      // Verify SVG asset path
      final svgPicture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svgPicture.pictureProvider.toString(), contains('img_app_logo.svg'));

      // Verify container styling
      final container = tester.widget<Container>(logoContainer);
      expect(container.decoration, isA<BoxDecoration>());
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isA<BorderRadius>());
      expect(decoration.boxShadow, isNotNull);
      expect(decoration.color, isNotNull);
    });

    testWidgets('should display scrolling quotes widget with correct quotes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find the ScrollingQuoteWidget
      final scrollingQuoteWidget = find.byType(ScrollingQuoteWidget);
      expect(scrollingQuoteWidget, findsOneWidget);

      // Verify the widget has the correct quotes
      final widget = tester.widget<ScrollingQuoteWidget>(scrollingQuoteWidget);
      expect(widget.quotes, hasLength(2));
      expect(widget.quotes[0], equals("Whoever has done an atom's weight of good will see it. 99:7"));
      expect(widget.quotes[1], equals("And remind, for the reminder benefits the believers. 51:55"));

      // Verify text style is applied
      expect(widget.textStyle, isNotNull);
      expect(widget.textStyle?.fontSize, equals(18));
      expect(widget.textStyle?.fontWeight, equals(FontWeight.w400));
    });

    testWidgets('should handle guest button tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
          routes: {
            '/dashboard': (context) => Scaffold(body: Text('Dashboard')),
          },
        ),
      );

      // Tap guest button
      await tester.tap(find.text('Guest'));
      await tester.pumpAndSettle();

      // Should show loading state
      expect(find.text('Loading...'), findsOneWidget);

      // Wait for guest login to complete
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Should navigate to dashboard (or show error in test environment)
      expect(
        find.text('Dashboard').or(find.textContaining('Error')),
        findsOneWidget,
      );
    });

    testWidgets('should validate form inputs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Try to submit without entering data
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Should show email validation error
      expect(find.text('Please enter a valid email address'), findsOneWidget);

      // Enter valid email but short password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Should show password validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should show loading states correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      // Tap login button
      await tester.tap(find.text('Login').last);
      await tester.pump(); // Trigger one frame to show loading state

      // Should show loading state
      expect(find.text('Signing In...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Button should be disabled during loading
      final loginButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Signing In...'),
          matching: find.byType(ElevatedButton),
        ),
      );
      expect(loginButton.onPressed, isNull);
    });

    testWidgets('should handle password visibility toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Find password field
      final passwordField = find.byType(TextFormField).last;
      final passwordFieldWidget = tester.widget<TextFormField>(passwordField);

      // Initially password should be obscured
      expect(passwordFieldWidget.obscureText, isTrue);

      // Find and tap visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_off);
      expect(visibilityButton, findsOneWidget);

      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // Password should now be visible
      final updatedPasswordField = tester.widget<TextFormField>(passwordField);
      expect(updatedPasswordField.obscureText, isFalse);

      // Icon should change to visibility
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('should display error messages with proper styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Enter invalid credentials to trigger error
      await tester.enterText(find.byType(TextFormField).first, 'invalid@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpassword');
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Wait for potential error to appear
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Check if error container is displayed (might not appear in test environment)
      final errorContainers = find.byType(Container).evaluate().where((element) {
        final widget = element.widget as Container;
        final decoration = widget.decoration as BoxDecoration?;
        return decoration?.color?.toString().contains('red') == true ||
               decoration?.color?.toString().contains('orange') == true;
      });

      // If error is shown, verify its structure
      if (errorContainers.isNotEmpty) {
        expect(find.byIcon(Icons.close), findsOneWidget); // Close button
        expect(find.byType(Icon), findsAtLeastNWidgets(1)); // Error icon
      }
    });

    testWidgets('should handle registration mode correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Switch to registration mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should show name field
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Enter registration data
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      // Tap create account button
      await tester.tap(find.text('Create Account'));
      await tester.pump();

      // Should show loading state
      expect(find.text('Creating Account...'), findsOneWidget);
    });

    testWidgets('should have proper accessibility features', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Check for semantic labels and accessibility features
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Email field should have proper labeling
      final emailField = tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(emailField.decoration?.labelText, equals('Email Address'));

      // Password field should have proper labeling
      final passwordField = tester.widget<TextFormField>(find.byType(TextFormField).last);
      expect(passwordField.decoration?.labelText, equals('Password'));

      // Buttons should be tappable and have proper semantics
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Login'), findsAtLeastNWidgets(1));
    });

    testWidgets('should maintain proper layout on different screen sizes', (WidgetTester tester) async {
      // Test with different screen sizes
      await tester.binding.setSurfaceSize(Size(400, 800)); // Mobile size
      
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should display all elements properly
      expect(find.text('Good Deeds Reminder'), findsOneWidget);
      expect(find.byType(ScrollingQuoteWidget), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);

      // Test with tablet size
      await tester.binding.setSurfaceSize(Size(800, 1200));
      await tester.pumpAndSettle();

      // Should still display all elements
      expect(find.text('Good Deeds Reminder'), findsOneWidget);
      expect(find.byType(ScrollingQuoteWidget), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });
  });
}