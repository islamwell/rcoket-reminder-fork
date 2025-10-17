import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../lib/presentation/audio_library/widgets/audio_card_widget.dart';
import '../lib/core/app_export.dart';

void main() {
  group('Enhanced AudioCardWidget Tests', () {
    late Map<String, dynamic> mockAudioFile;

    setUp(() {
      mockAudioFile = {
        'id': 'test-audio-1',
        'filename': 'test_audio.mp3',
        'duration': '2:30',
        'size': '3.2 MB',
        'path': '/path/to/audio.mp3',
        'isFavorite': false,
        'category': 'test',
        'type': 'library',
        'description': 'Test audio file',
      };
    });

    testWidgets('AudioCardWidget displays all required elements', (WidgetTester tester) async {
      bool playPressed = false;
      bool pausePressed = false;
      bool favoritePressed = false;
      String? renamedTo;

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: Scaffold(
                body: AudioCardWidget(
                  audioFile: mockAudioFile,
                  onPlay: () => playPressed = true,
                  onPause: () => pausePressed = true,
                  onFavorite: () => favoritePressed = true,
                  onRename: (newName) => renamedTo = newName,
                  isPlaying: false,
                  isFavorite: false,
                  showSelectionMode: false,
                  isProcessing: false,
                ),
              ),
            );
          },
        ),
      );

      // Verify filename is displayed
      expect(find.text('test_audio.mp3'), findsOneWidget);
      
      // Verify duration and size are displayed
      expect(find.text('2:30'), findsOneWidget);
      expect(find.text('3.2 MB'), findsOneWidget);
      
      // Verify action buttons are present (by checking for tooltips)
      expect(find.byTooltip('Rename audio file'), findsOneWidget);
      expect(find.byTooltip('Add to favorites'), findsOneWidget);
    });

    testWidgets('Play button triggers onPlay callback', (WidgetTester tester) async {
      bool playPressed = false;

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: Scaffold(
                body: AudioCardWidget(
                  audioFile: mockAudioFile,
                  onPlay: () => playPressed = true,
                  onPause: () {},
                  isPlaying: false,
                  isFavorite: false,
                  showSelectionMode: false,
                  isProcessing: false,
                ),
              ),
            );
          },
        ),
      );

      // Find and tap the play button
      final playButton = find.byType(GestureDetector).first;
      await tester.tap(playButton);
      await tester.pump();

      expect(playPressed, isTrue);
    });

    testWidgets('Processing state disables buttons', (WidgetTester tester) async {
      bool playPressed = false;

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: Scaffold(
                body: AudioCardWidget(
                  audioFile: mockAudioFile,
                  onPlay: () => playPressed = true,
                  onPause: () {},
                  isPlaying: false,
                  isFavorite: false,
                  showSelectionMode: false,
                  isProcessing: true, // Processing state
                ),
              ),
            );
          },
        ),
      );

      // Try to tap the play button while processing
      final playButton = find.byType(GestureDetector).first;
      await tester.tap(playButton);
      await tester.pump();

      // Should not trigger callback when processing
      expect(playPressed, isFalse);
      
      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('Favorite button shows correct state', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: Scaffold(
                body: AudioCardWidget(
                  audioFile: mockAudioFile,
                  onPlay: () {},
                  onPause: () {},
                  isFavorite: true, // Favorited state
                  isPlaying: false,
                  showSelectionMode: false,
                  isProcessing: false,
                ),
              ),
            );
          },
        ),
      );

      // Should show "Remove from favorites" tooltip when favorited
      expect(find.byTooltip('Remove from favorites'), findsOneWidget);
    });
  });
}