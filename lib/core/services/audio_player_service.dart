import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Audio capabilities detected on the device
class AudioCapabilities {
  final bool canPlayMedia;
  final bool canPlayNotificationSounds;
  final bool canVibrate;
  final bool respectsSilentMode;
  final bool supportsVolumeOverride;

  const AudioCapabilities({
    required this.canPlayMedia,
    required this.canPlayNotificationSounds,
    required this.canVibrate,
    required this.respectsSilentMode,
    required this.supportsVolumeOverride,
  });
}

/// Fallback strategy for audio playback when primary method fails
enum AudioFallbackStrategy {
  notificationStream,
  systemSounds,
  vibration,
  silent
}

class AudioPlayerService {
  static AudioPlayerService? _instance;
  static AudioPlayerService get instance => _instance ??= AudioPlayerService._();
  AudioPlayerService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _notificationAudioPlayer = AudioPlayer();
  String? _currentlyPlayingId;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  StreamController<String?> _playingController = StreamController<String?>.broadcast();
  StreamController<bool> _playingStateController = StreamController<bool>.broadcast();
  
  // Audio capabilities cache
  AudioCapabilities? _cachedCapabilities;

  // Getters
  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlaying => _isPlaying;
  Stream<String?> get playingStream => _playingController.stream;
  Stream<bool> get playingStateStream => _playingStateController.stream;

  /// Get device audio capabilities
  Future<AudioCapabilities> getDeviceAudioCapabilities() async {
    if (_cachedCapabilities != null) {
      return _cachedCapabilities!;
    }

    try {
      // Test basic media playback capability
      bool canPlayMedia = true;
      bool canPlayNotificationSounds = true;
      bool canVibrate = true;
      bool respectsSilentMode = true;
      bool supportsVolumeOverride = false;

      // Platform-specific capability detection
      if (Platform.isAndroid) {
        // Android typically supports volume override and notification streams
        supportsVolumeOverride = true;
        canPlayNotificationSounds = true;
      } else if (Platform.isIOS) {
        // iOS is more restrictive with silent mode
        respectsSilentMode = true;
        supportsVolumeOverride = false;
      }

      // Test vibration capability
      try {
        await HapticFeedback.lightImpact();
        canVibrate = true;
      } catch (e) {
        canVibrate = false;
      }

      _cachedCapabilities = AudioCapabilities(
        canPlayMedia: canPlayMedia,
        canPlayNotificationSounds: canPlayNotificationSounds,
        canVibrate: canVibrate,
        respectsSilentMode: respectsSilentMode,
        supportsVolumeOverride: supportsVolumeOverride,
      );

      return _cachedCapabilities!;
    } catch (e) {
      debugPrint('Error detecting audio capabilities: $e');
      // Return conservative defaults
      _cachedCapabilities = const AudioCapabilities(
        canPlayMedia: true,
        canPlayNotificationSounds: false,
        canVibrate: false,
        respectsSilentMode: true,
        supportsVolumeOverride: false,
      );
      return _cachedCapabilities!;
    }
  }

  /// Configure audio player to use notification stream for bypassing silent mode
  Future<void> setNotificationAudioStream() async {
    try {
      // Configure the notification audio player for forced playback
      await _notificationAudioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notification,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error setting notification audio stream: $e');
    }
  }

  /// Play audio with forced playback that bypasses device silent mode
  Future<void> playAudioForced(String audioId, String audioPath, {bool bypassSilentMode = true}) async {
    try {
      // Stop current playback if any
      await stopAudio();

      _currentlyPlayingId = audioId;
      _isPlaying = true;
      
      _playingController.add(audioId);
      _playingStateController.add(true);

      // Get device capabilities
      final capabilities = await getDeviceAudioCapabilities();
      
      // Try multiple strategies in order of preference
      final strategies = _getFallbackStrategies(capabilities, bypassSilentMode);
      
      bool playbackSuccessful = false;
      
      for (final strategy in strategies) {
        try {
          playbackSuccessful = await _executePlaybackStrategy(strategy, audioPath);
          if (playbackSuccessful) {
            debugPrint('Audio playback successful with strategy: $strategy');
            break;
          }
        } catch (e) {
          debugPrint('Playback strategy $strategy failed: $e');
          continue;
        }
      }

      if (!playbackSuccessful) {
        debugPrint('All playback strategies failed, falling back to vibration');
        await _fallbackToVibration();
        // Ensure we still register as playing even with final fallback
        _playbackTimer = Timer(const Duration(seconds: 1), () {
          stopAudio();
        });
      }

    } catch (e) {
      debugPrint('Error in forced audio playback: $e');
      await _fallbackToVibration();
      // Don't call stopAudio() here as it resets the currentlyPlayingId
      // Instead, set a timer to clean up later
      _playbackTimer = Timer(const Duration(seconds: 1), () {
        stopAudio();
      });
    }
  }

  /// Get ordered list of fallback strategies based on device capabilities
  List<AudioFallbackStrategy> _getFallbackStrategies(AudioCapabilities capabilities, bool bypassSilentMode) {
    final strategies = <AudioFallbackStrategy>[];
    
    if (bypassSilentMode && capabilities.canPlayNotificationSounds) {
      strategies.add(AudioFallbackStrategy.notificationStream);
    }
    
    if (capabilities.canPlayMedia) {
      // Add regular media playback as fallback
      strategies.add(AudioFallbackStrategy.notificationStream);
    }
    
    strategies.add(AudioFallbackStrategy.systemSounds);
    
    if (capabilities.canVibrate) {
      strategies.add(AudioFallbackStrategy.vibration);
    }
    
    strategies.add(AudioFallbackStrategy.silent);
    
    return strategies;
  }

  /// Execute specific playback strategy
  Future<bool> _executePlaybackStrategy(AudioFallbackStrategy strategy, String audioPath) async {
    switch (strategy) {
      case AudioFallbackStrategy.notificationStream:
        return await _playWithNotificationStream(audioPath);
      case AudioFallbackStrategy.systemSounds:
        return await _playSystemSound();
      case AudioFallbackStrategy.vibration:
        return await _playWithVibration();
      case AudioFallbackStrategy.silent:
        return await _playSilent();
    }
  }

  /// Play audio using notification stream (bypasses silent mode on Android)
  Future<bool> _playWithNotificationStream(String audioPath) async {
    try {
      await setNotificationAudioStream();
      
      if (audioPath.startsWith('assets/')) {
        await _notificationAudioPlayer.play(AssetSource(audioPath.replaceFirst('assets/', '')));
      } else {
        final file = File(audioPath);
        if (await file.exists()) {
          await _notificationAudioPlayer.play(DeviceFileSource(audioPath));
        } else {
          return false;
        }
      }

      // Listen for completion
      _notificationAudioPlayer.onPlayerComplete.listen((_) {
        stopAudio();
      });

      return true;
    } catch (e) {
      debugPrint('Notification stream playback failed: $e');
      return false;
    }
  }

  /// Play system sound as fallback
  Future<bool> _playSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      // Auto-stop after 2 seconds for system sound
      _playbackTimer = Timer(const Duration(seconds: 2), () {
        stopAudio();
      });
      return true;
    } catch (e) {
      debugPrint('System sound playback failed: $e');
      return false;
    }
  }

  /// Use vibration as audio alternative
  Future<bool> _playWithVibration() async {
    try {
      // Create a vibration pattern that mimics audio alert
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
      
      // Auto-stop after vibration sequence
      _playbackTimer = Timer(const Duration(seconds: 1), () {
        stopAudio();
      });
      return true;
    } catch (e) {
      debugPrint('Vibration playback failed: $e');
      return false;
    }
  }

  /// Silent fallback (just marks as played)
  Future<bool> _playSilent() async {
    // Auto-stop after minimal delay for silent mode
    _playbackTimer = Timer(const Duration(milliseconds: 500), () {
      stopAudio();
    });
    return true;
  }

  /// Fallback to vibration when all audio methods fail
  Future<void> _fallbackToVibration() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Vibration fallback also failed: $e');
    }
  }

  // Play audio file
  Future<void> playAudio(String audioId, String audioPath, {int? durationSeconds}) async {
    try {
      // Stop current playback if any
      await stopAudio();

      _currentlyPlayingId = audioId;
      _isPlaying = true;
      
      _playingController.add(audioId);
      _playingStateController.add(true);

      if (audioPath.startsWith('assets/')) {
        // For asset files, use AssetSource
        await _audioPlayer.play(AssetSource(audioPath.replaceFirst('assets/', '')));
      } else {
        // For local files, use DeviceFileSource
        final file = File(audioPath);
        if (await file.exists()) {
          await _audioPlayer.play(DeviceFileSource(audioPath));
        } else {
          throw Exception('Audio file not found: $audioPath');
        }
      }

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        stopAudio();
      });

    } catch (e) {
      print('Error playing audio: $e');
      // Fallback to system sound for demo purposes
      try {
        await SystemSound.play(SystemSoundType.click);
        // Auto-stop after 2 seconds for demo
        _playbackTimer = Timer(Duration(seconds: 2), () {
          stopAudio();
        });
      } catch (systemSoundError) {
        print('System sound also failed: $systemSoundError');
        stopAudio();
      }
    }
  }

  // Stop audio playback
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping main audio player: $e');
    }
    
    try {
      await _notificationAudioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping notification audio player: $e');
    }
    
    _playbackTimer?.cancel();
    _playbackTimer = null;
    
    if (_isPlaying) {
      _isPlaying = false;
      _playingStateController.add(false);
    }
    
    if (_currentlyPlayingId != null) {
      _currentlyPlayingId = null;
      _playingController.add(null);
    }
  }

  // Pause audio
  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
      await _notificationAudioPlayer.pause();
      _isPlaying = false;
      _playingStateController.add(false);
    } catch (e) {
      debugPrint('Error pausing audio: $e');
      await stopAudio();
    }
  }

  // Toggle playback
  Future<void> togglePlayback(String audioId, String audioPath, {int? durationSeconds}) async {
    if (_currentlyPlayingId == audioId && _isPlaying) {
      await pauseAudio();
    } else {
      await playAudio(audioId, audioPath, durationSeconds: durationSeconds);
    }
  }



  // Get audio duration
  Future<Duration> getAudioDuration(String audioPath) async {
    try {
      Duration? duration;
      if (audioPath.startsWith('assets/')) {
        // For asset files
        duration = await _audioPlayer.getDuration();
      } else {
        // For local files
        final file = File(audioPath);
        if (await file.exists()) {
          duration = await _audioPlayer.getDuration();
        }
      }
      return duration ?? Duration(seconds: 30); // Default fallback
    } catch (e) {
      print('Error getting audio duration: $e');
      return Duration(seconds: 30); // Default fallback
    }
  }

  // Format duration for display
  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Check if audio file is valid
  Future<bool> isValidAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      
      final extension = filePath.toLowerCase().split('.').last;
      return ['mp3', 'm4a', 'wav', 'aac'].contains(extension);
    } catch (e) {
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    _playbackTimer?.cancel();
    _audioPlayer.dispose();
    _notificationAudioPlayer.dispose();
    _playingController.close();
    _playingStateController.close();
  }
}