import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/animations/audio_animations.dart';
import '../../../lib/core/animations/animated_components.dart';

void main() {
  group('Animation System Tests', () {
    testWidgets('AudioAnimations creates proper scale animation', (WidgetTester tester) async {
      late AnimationController controller;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              controller = AnimationController(
                duration: const Duration(milliseconds: 300),
                vsync: const TestVSync(),
              );
              
              final animation = AudioAnimations.createScaleAnimation(controller);
              
              expect(animation.value, equals(1.0)); // Initial value
              return Container();
            },
          ),
        ),
      );
      
      controller.dispose();
    });

    testWidgets('AudioAnimations creates proper color animation', (WidgetTester tester) async {
      late AnimationController controller;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              controller = AnimationController(
                duration: const Duration(milliseconds: 300),
                vsync: const TestVSync(),
              );
              
              final animation = AudioAnimations.createColorAnimation(
                controller,
                Colors.red,
                Colors.blue,
              );
              
              expect(animation.value, equals(Colors.red)); // Initial value
              return Container();
            },
          ),
        ),
      );
      
      controller.dispose();
    });

    testWidgets('AnimatedActionButton renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedActionButton(
              iconName: 'play_arrow',
              onTap: () {},
              tooltip: 'Test button',
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedActionButton), findsOneWidget);
      expect(find.byTooltip('Test button'), findsOneWidget);
    });

    testWidgets('AnimatedFavoriteButton toggles state correctly', (WidgetTester tester) async {
      bool isFavorite = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedFavoriteButton(
                  isFavorite: isFavorite,
                  onToggle: () {
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedFavoriteButton), findsOneWidget);
      
      // Tap the button
      await tester.tap(find.byType(AnimatedFavoriteButton));
      await tester.pumpAndSettle();
      
      expect(isFavorite, isTrue);
    });

    testWidgets('AnimatedLoadingIndicator renders all types', (WidgetTester tester) async {
      for (final type in LoadingType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedLoadingIndicator(
                type: type,
                color: Colors.blue,
              ),
            ),
          ),
        );

        expect(find.byType(AnimatedLoadingIndicator), findsOneWidget);
        await tester.pump(); // Just pump once instead of pumpAndSettle
      }
    });

    testWidgets('AnimatedSelectionIndicator shows selection state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedSelectionIndicator(
              isSelected: true,
              selectedColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedSelectionIndicator), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('AnimatedStateTransition responds to trigger', (WidgetTester tester) async {
      bool trigger = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedStateTransition(
                      trigger: trigger,
                      animationType: AnimationType.scale,
                      child: Container(
                        width: 50,
                        height: 50,
                        color: Colors.red,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          trigger = !trigger;
                        });
                      },
                      child: Text('Toggle'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedStateTransition), findsOneWidget);
      
      // Tap the toggle button
      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();
      
      expect(trigger, isTrue);
    });
  });
}