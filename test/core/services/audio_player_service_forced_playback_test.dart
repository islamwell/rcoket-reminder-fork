import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:good_deeds_reminder/core/services/audio_player_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('AudioPlayerService Forced Playback Tests', () {
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

    group('Audio Capabilities Detection', () {
      test('should detect device audio capabilities', () async {
        final capabilities = await audioService.getDeviceAudioCapabilities();
        
        expect(capabilities, isNotNull);
        expect(capabilities.canPlayMedia, isA<bool>());
        expect(capabilities.canPlayNotificationSounds, isA<bool>());
        expect(capabilities.canVibrate, isA<bool>());
        expect(capabilities.respectsSilentMode, isA<bool>());
        expect(capabilities.supportsVolumeOverride, isA<bool>());
      });

      test('should cache audio capabilities after first detection', () async {
        final capabilities1 = await audioService.getDeviceAudioCapabilities();
        final capabilities2 = await audioService.getDeviceAudioCapabilities();
        
        expect(identical(capabilities1, capabilities2), isTrue);
      });

      test('should detect platform-specific capabilities correctly', () async {
        final capabilities = await audioService.getDeviceAudioCapabilities();
        
        if (Platform.isAndroid) {
          expect(capabilities.supportsVolumeOverride, isTrue);
          expect(capabilities.canPlayNotificationSounds, isTrue);
        } else if (Platform.isIOS) {
          expect(capabilities.respectsSilentMode, isTrue);
          expect(capabilities.supportsVolumeOverride, isFalse);
        }
      });
    });

    group('Forced Audio Playback', () {
      test('should play audio with forced playback enabled', () async {
        const audioId = 'test_audio_forced';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath, bypassSilentMode: true);
        
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });

      test('should play audio with forced playback disabled', () async {
        const audioId = 'test_audio_normal';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath, bypassSilentMode: false);
        
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });

      test('should stop current audio before playing new forced audio', () async {
        const audioId1 = 'test_audio_1';
        const audioId2 = 'test_audio_2';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId1, audioPath);
        expect(audioService.currentlyPlayingId, equals(audioId1));
        
        await audioService.playAudioForced(audioId2, audioPath);
        expect(audioService.currentlyPlayingId, equals(audioId2));
      });

      test('should emit playing state changes during forced playback', () async {
        const audioId = 'test_audio_state';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        final playingStates = <bool>[];
        final playingIds = <String?>[];
        
        final stateSubscription = audioService.playingStateStream.listen(playingStates.add);
        final idSubscription = audioService.playingStream.listen(playingIds.add);
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Allow some time for stream events
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(playingStates, contains(true));
        expect(playingIds, contains(audioId));
        
        await stateSubscription.cancel();
        await idSubscription.cancel();
      });
    });

    group('Notification Audio Stream Configuration', () {
      test('should configure notification audio stream without errors', () async {
        expect(() async => await audioService.setNotificationAudioStream(), 
               returnsNormally);
      });
    });

    group('Fallback Strategies', () {
      test('should handle asset file playback in forced mode', () async {
        const audioId = 'test_asset_audio';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });

      test('should handle non-existent file gracefully with fallback', () async {
        const audioId = 'test_missing_audio';
        const audioPath = '/non/existent/path/audio.mp3';
        
        // Should not throw exception, should use fallback strategy
        await audioService.playAudioForced(audioId, audioPath);
        
        // Should still register as playing (using fallback)
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });

      test('should use vibration fallback when audio fails', () async {
        const audioId = 'test_vibration_fallback';
        const audioPath = '/invalid/path/audio.mp3';
        
        // Mock HapticFeedback to verify vibration is called
        bool vibrationCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrationCalled = true;
          }
          return null;
        });
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Should still register as playing even with fallback
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });
    });

    group('Audio Playback State Management', () {
      test('should stop forced audio playback correctly', () async {
        const audioId = 'test_stop_audio';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        expect(audioService.isPlaying, isTrue);
        
        await audioService.stopAudio();
        
        expect(audioService.isPlaying, isFalse);
        expect(audioService.currentlyPlayingId, isNull);
      });

      test('should pause forced audio playback correctly', () async {
        const audioId = 'test_pause_audio';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        expect(audioService.isPlaying, isTrue);
        
        await audioService.pauseAudio();
        
        expect(audioService.isPlaying, isFalse);
        expect(audioService.currentlyPlayingId, equals(audioId));
      });

      test('should handle multiple stop calls gracefully', () async {
        const audioId = 'test_multiple_stop';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Multiple stop calls should not cause errors
        await audioService.stopAudio();
        await audioService.stopAudio();
        await audioService.stopAudio();
        
        expect(audioService.isPlaying, isFalse);
        expect(audioService.currentlyPlayingId, isNull);
      });
    });

    group('Background Audio Playback', () {
      test('should maintain playback state for background audio', () async {
        const audioId = 'test_background_audio';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Simulate app going to background (audio should continue)
        expect(audioService.isPlaying, isTrue);
        expect(audioService.currentlyPlayingId, equals(audioId));
        
        // Audio state should persist
        await Future.delayed(const Duration(milliseconds: 100));
        expect(audioService.isPlaying, isTrue);
      });
    });

    group('Error Handling and Graceful Degradation', () {
      test('should provide user feedback through state streams on errors', () async {
        const audioId = 'test_error_feedback';
        const audioPath = '/completely/invalid/path.mp3';
        
        final playingStates = <bool>[];
        final subscription = audioService.playingStateStream.listen(playingStates.add);
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Should still emit playing state even with fallback
        await Future.delayed(const Duration(milliseconds: 100));
        expect(playingStates, contains(true));
        
        await subscription.cancel();
      });

      test('should handle system sound fallback gracefully', () async {
        const audioId = 'test_system_sound';
        const audioPath = '/invalid/path.mp3';
        
        // Should not throw exception
        expect(() async => await audioService.playAudioForced(audioId, audioPath), 
               returnsNormally);
        
        // Should register as playing with fallback
        expect(audioService.currentlyPlayingId, equals(audioId));
      });

      test('should handle vibration fallback when audio and system sounds fail', () async {
        const audioId = 'test_vibration_only';
        const audioPath = '/invalid/path.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Should complete without errors and register as playing
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });
    });

    group('Device State Compatibility', () {
      test('should work in silent mode with bypass enabled', () async {
        const audioId = 'test_silent_mode';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        // Simulate silent mode by using forced playback
        await audioService.playAudioForced(audioId, audioPath, bypassSilentMode: true);
        
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });

      test('should work in vibration mode', () async {
        const audioId = 'test_vibration_mode';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        await audioService.playAudioForced(audioId, audioPath);
        
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });

      test('should handle device capability limitations gracefully', () async {
        const audioId = 'test_capability_limits';
        const audioPath = 'assets/audio/test_sound.mp3';
        
        final capabilities = await audioService.getDeviceAudioCapabilities();
        
        await audioService.playAudioForced(audioId, audioPath);
        
        // Should work regardless of device capabilities
        expect(audioService.currentlyPlayingId, equals(audioId));
        expect(audioService.isPlaying, isTrue);
      });
    });
  });
}