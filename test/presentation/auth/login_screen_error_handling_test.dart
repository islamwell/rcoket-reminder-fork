import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/presentation/auth/login_screen.dart';

void main() {
  group('LoginScreen UI Error Handling Tests', () {
    testWidgets('should render login screen with all required elements', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      // Assert - Check basic UI elements
      expect(find.text('Good Deeds Reminder'), findsOneWidget);
      expect(find.text('Guest'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Login'), findsAtLeastNWidgets(1));
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
    });

    testWidgets('should show validation errors for empty fields', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      
      // Tap login button without entering any data
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Assert - Should show validation errors
      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid email', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      
      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      
      // Tap login button
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should show validation error for short password', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      
      // Enter short password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');
      
      // Tap login button
      await tester.tap(find.text('Login').last);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should switch between login and signup modes', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      
      // Initially in login mode - should show 2 text fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      // Switch to signup mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      
      // Should now show 3 text fields (name, email, password)
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Create Account'), findsOneWidget);
      
      // Switch back to login mode
      await tester.tap(find.text('Login').first);
      await tester.pumpAndSettle();
      
      // Should show 2 text fields again
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should show name field validation in signup mode', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      
      // Switch to signup mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      
      // Enter email and password but leave name empty
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      
      // Tap create account button
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter your full name'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      
      // Find password field and visibility toggle
      final passwordField = find.byType(TextFormField).last;
      final visibilityToggle = find.byIcon(Icons.visibility_off);
      
      // Initially password should be obscured
      expect(visibilityToggle, findsOneWidget);
      
      // Tap visibility toggle
      await tester.tap(visibilityToggle);
      await tester.pumpAndSettle();
      
      // Should now show visibility icon (password visible)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should show scrolling quotes widget', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));
      await tester.pumpAndSettle();

      // Assert - Should find the scrolling quotes widget
      // Note: The exact text might be animated, so we check for the widget type
      expect(find.byType(SingleChildScrollView), findsWidgets);
      
      // Should show the app logo
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('should handle form submission with valid data', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(),
        routes: {
          '/dashboard': (context) => Scaffold(body: Text('Dashboard')),
        },
      ));
      
      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      
      // Tap login button
      await tester.tap(find.text('Login').last);
      await tester.pump(); // Don't settle to catch loading state
      
      // Should show loading state
      expect(find.text('Signing In...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should show different loading text for signup', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(),
        routes: {
          '/dashboard': (context) => Scaffold(body: Text('Dashboard')),
        },
      ));
      
      // Switch to signup mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
      
      // Enter valid data
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      
      // Tap create account button
      await tester.tap(find.text('Create Account'));
      await tester.pump(); // Don't settle to catch loading state
      
      // Should show creating account loading text
      expect(find.text('Creating Account...'), findsOneWidget);
    });

    testWidgets('should show guest loading state', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(),
        routes: {
          '/dashboard': (context) => Scaffold(body: Text('Dashboard')),
        },
      ));
      
      // Tap guest button
      await tester.tap(find.text('Guest'));
      await tester.pump(); // Don't settle to catch loading state

      // Should show guest loading state
      expect(find.text('Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}