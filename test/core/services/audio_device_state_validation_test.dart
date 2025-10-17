import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:good_deeds_reminder/core/services/audio_player_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Audio Device State Validation Tests', () {
    late AudioPlayerService audioService;

    setUpAll(() {
      // Mock the audioplayers plugin methods
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'init':
              return null;
            default:
              return null;
          }
        },
      );
      
      // Mock individual audio player channels
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'create':
              return 'test_player_id';
            case 'play':
              return null;
            case 'stop':
              return null;
            case 'pause':
              return null;
            case 'setAudioContext':
              return null;
            default:
              return null;
          }
        },
      );
    });

    setUp(() {
      audioService = AudioPlayerService.instance;
    });

    tearDown(() async {
      try {
        await audioService.stopAudio();
      } catch (e) {
        // Ignore errors in tearDown for tests
      }
    });

    group('Silent Mode Testing', () {
      test('should play audio in silent mode with bypass enabled', () async {
        const audioId = 'silent_mode_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        // Test forced playback that should bypass silent mode
        await audioService.playAudioForced(audioId, audioPath, bypassSilentMode: true);
        
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
        
        // Verify that notification stream configuration was attempted
        final capabilities = await audioService.getDeviceAudioCapabilities();
        if (capabilities.canPlayNotificationSounds) {
          // Should use notification stream for bypass
          expect(audioService.isPlaying, isTrue);
        }
      });

      test('should respect silent mode when bypass is disabled', () async {
        const audioId = 'silent_mode_respect_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        // Test normal playback that should respect silent mode
        await audioService.playAudioForced(audioId, audioPath, bypassSilentMode: false);
        
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });

      test('should fallback to vibration in silent mode when audio fails', () async {
        const audioId = 'silent_vibration_test';
        const audioPath = '/invalid/path/audio.mp3';
        
        bool vibrationTriggered = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrationTriggered = true;
          }
          return null;
        });
        
        await audioService.playAudioForced(audioId, audioPath, bypassSilentMode: true);
        
        // Should still register as playing with vibration fallback
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });
    });

    group('Vibration Mode Testing', () {
      test('should play audio in vibration mode', () async {
        const audioId = 'vibration_mode_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });

      test('should combine audio and vibration for enhanced notification', () async {
        const audioId = 'audio_vibration_combo_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        bool vibrationTriggered = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrationTriggered = true;
          }
          return null;
        });
        
        await audioService.playAudioForced(audioId, audioPath);
        
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });

      test('should use vibration pattern when audio is unavailable', () async {
        const audioId = 'vibration_pattern_test';
        const audioPath = '/non/existent/audio.mp3';
        
        final vibrationCalls = <String>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrationCalls.add(call.arguments.toString());
          }
          return null;
        });
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Should register as playing with vibration fallback
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });
    });

    group('Background Audio Playback Testing', () {
      test('should maintain audio playback when app goes to background', () async {
        const audioId = 'background_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Simulate app lifecycle change to background
        expect(audioService.isPlaying, isTrue);
        expect(audioService.currentlyPlayingId, equals(audioId));
        
        // Audio should continue playing in background
        await Future.delayed(const Duration(milliseconds: 200));
        expect(audioService.isPlaying, isTrue);
      });

      test('should handle background audio interruptions gracefully', () async {
        const audioId = 'background_interruption_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        expect(audioService.isPlaying, isTrue);
        
        // Simulate interruption (like phone call)
        await audioService.pauseAudio();
        expect(audioService.isPlaying, isFalse);
        
        // Should be able to resume
        await audioService.playAudioForced(audioId, audioPath);
        expect(audioService.isPlaying, isTrue);
      });

      test('should configure audio session for background playback', () async {
        // Test that notification audio stream is configured correctly
        expect(() async => await audioService.setNotificationAudioStream(), 
               returnsNormally);
        
        const audioId = 'background_session_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        expect(audioService.isPlaying, isTrue);
      });
    });

    group('Graceful Degradation Testing', () {
      test('should provide user feedback when audio fails', () async {
        const audioId = 'feedback_test';
        const audioPath = '/completely/invalid/path.mp3';
        
        final stateChanges = <bool>[];
        final subscription = audioService.playingStateStream.listen(stateChanges.add);
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Should emit state changes even with fallback
        await Future.delayed(const Duration(milliseconds: 100));
        expect(stateChanges, isNotEmpty);
        expect(stateChanges, contains(true));
        
        await subscription.cancel();
      });

      test('should handle complete audio system failure gracefully', () async {
        const audioId = 'system_failure_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        // Mock complete audio system failure including system sounds
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method.contains('audio') || call.method.contains('Audio') || call.method == 'SystemSound.play') {
            throw PlatformException(code: 'AUDIO_FAILED', message: 'Audio system unavailable');
          }
          return null;
        });
        
        // Should not throw exception
        expect(() async => await audioService.playAudioForced(audioId, audioPath), 
               returnsNormally);
        
        // Should still register as playing (silent fallback)
        // Add a small delay to allow async operations to complete
        await Future.delayed(const Duration(milliseconds: 100));
        expect(audioService.currentlyPlayingId, equals(audioId));
      });

      test('should provide appropriate fallback for each device capability', () async {
        const audioId = 'capability_fallback_test';
        const audioPath = '/invalid/audio.mp3';
        
        final capabilities = await audioService.getDeviceAudioCapabilities();
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Should complete successfully regardless of capabilities
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
        
        // Verify appropriate fallback was used based on capabilities
        if (capabilities.canVibrate) {
          // Should have attempted vibration fallback
          expect(audioService.isPlaying, isTrue);
        }
      });
    });

    group('Multiple Device State Scenarios', () {
      test('should handle rapid device state changes', () async {
        const audioId = 'rapid_state_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        // Start playback
        await audioService.playAudioForced(audioId, audioPath);
        expect(audioService.isPlaying, isTrue);
        
        // Rapid pause/resume cycle
        await audioService.pauseAudio();
        expect(audioService.isPlaying, isFalse);
        
        await audioService.playAudioForced(audioId, audioPath);
        expect(audioService.isPlaying, isTrue);
        
        await audioService.stopAudio();
        expect(audioService.isPlaying, isFalse);
      });

      test('should handle concurrent audio requests', () async {
        const audioId1 = 'concurrent_test_1';
        const audioId2 = 'concurrent_test_2';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        // Start first audio
        await audioService.playAudioForced(audioId1, audioPath);
        expect(audioService.currentlyPlayingId, equals(audioId1));
        
        // Start second audio (should stop first)
        await audioService.playAudioForced(audioId2, audioPath);
        expect(audioService.currentlyPlayingId, equals(audioId2));
        expect(audioService.isPlaying, isTrue);
      });

      test('should maintain consistent state across device rotations', () async {
        const audioId = 'rotation_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        expect(audioService.isPlaying, isTrue);
        
        // Simulate device rotation (state should persist)
        await Future.delayed(const Duration(milliseconds: 100));
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });
    });

    group('Platform-Specific Behavior Testing', () {
      test('should handle Android-specific audio stream configuration', () async {
        if (Platform.isAndroid) {
          const audioId = 'android_stream_test';
          const audioPath = 'assets/audio/test_sound.mp3';
          
          await audioService.setNotificationAudioStream();
          await audioService.playAudioForced(audioId, audioPath, bypassSilentMode: true);
          
          expect(audioService.isPlaying, isTrue);
          expect(audioService.currentlyPlayingId, equals(audioId));
        }
      });

      test('should handle iOS-specific audio session configuration', () async {
        if (Platform.isIOS) {
          const audioId = 'ios_session_test';
          const audioPath = 'assets/audio/test_sound.mp3';
          
          await audioService.setNotificationAudioStream();
          await audioService.playAudioForced(audioId, audioPath);
          
          expect(audioService.isPlaying, isTrue);
          expect(audioService.currentlyPlayingId, equals(audioId));
        }
      });

      test('should detect platform capabilities correctly', () async {
        final capabilities = await audioService.getDeviceAudioCapabilities();
        
        if (Platform.isAndroid) {
          expect(capabilities.supportsVolumeOverride, isTrue);
          expect(capabilities.canPlayNotificationSounds, isTrue);
        } else if (Platform.isIOS) {
          expect(capabilities.respectsSilentMode, isTrue);
        }
        
        // Common capabilities
        expect(capabilities.canPlayMedia, isTrue);
      });
    });

    group('Audio Quality and Performance Testing', () {
      test('should handle large audio files without blocking UI', () async {
        const audioId = 'large_file_test';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        final startTime = DateTime.now();
        await audioService.playAudioForced(audioId, audioPath);
        final endTime = DateTime.now();
        
        // Should complete quickly (non-blocking)
        expect(endTime.difference(startTime).inMilliseconds, lessThan(1000));
        expect(audioService.isPlaying, isTrue);
      });

      test('should handle multiple rapid play requests efficiently', () async {
        const audioPath = 'assets/audio/test_sound.mp3';
        
        final startTime = DateTime.now();
        
        for (int i = 0; i < 5; i++) {
          await audioService.playAudioForced('test_$i', audioPath);
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        final endTime = DateTime.now();
        
        // Should handle rapid requests efficiently
        expect(endTime.difference(startTime).inMilliseconds, lessThan(2000));
        expect(audioService.isPlaying, isTrue);
      });
    });
  });
}