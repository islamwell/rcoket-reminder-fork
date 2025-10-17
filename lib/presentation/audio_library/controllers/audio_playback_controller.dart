import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../core/services/audio_player_service.dart';

/// Centralized controller for managing audio playback across all audio cards
/// Ensures only one audio plays at a time and provides real-time state updates
class AudioPlaybackController extends ChangeNotifier {
  final AudioPlayerService _audioPlayerService = AudioPlayerService.instance;
  
  String? _currentlyPlayingId;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  StreamSubscription<String?>? _playingSubscription;
  StreamSubscription<bool>? _playingStateSubscription;

  // Getters
  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  /// Check if a specific audio is currently playing
  bool isAudioPlaying(String audioId) {
    return _currentlyPlayingId == audioId && _isPlaying;
  }
  
  /// Check if a specific audio is currently loading
  bool isAudioLoading(String audioId) {
    return _currentlyPlayingId == audioId && _isLoading;
  }

  AudioPlaybackController() {
    _setupListeners();
  }

  void _setupListeners() {
    // Listen to audio player service streams
    _playingSubscription = _audioPlayerService.playingStream.listen((audioId) {
      _currentlyPlayingId = audioId;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    });

    _playingStateSubscription = _audioPlayerService.playingStateStream.listen((isPlaying) {
      _isPlaying = isPlaying;
      if (!isPlaying) {
        _isLoading = false;
        _errorMessage = null;
      }
      notifyListeners();
    });
  }

  /// Play audio with the given ID and path
  /// Automatically stops any currently playing audio
  Future<void> playAudio(String audioId, String audioPath) async {
    try {
      _clearError();
      
      // If the same audio is already playing, do nothing
      if (_currentlyPlayingId == audioId && _isPlaying) {
        return;
      }
      
      // Set loading state for this audio
      _currentlyPlayingId = audioId;
      _isLoading = true;
      notifyListeners();
      
      // Stop any currently playing audio first
      if (_audioPlayerService.isPlaying) {
        await _audioPlayerService.stopAudio();
      }
      
      // Play the new audio
      await _audioPlayerService.playAudio(audioId, audioPath);
      
    } catch (e) {
      _handleError(audioId, 'Failed to play audio: ${e.toString()}');
    }
  }

  /// Pause the currently playing audio
  Future<void> pauseAudio() async {
    try {
      _clearError();
      await _audioPlayerService.pauseAudio();
    } catch (e) {
      _handleError(_currentlyPlayingId, 'Failed to pause audio: ${e.toString()}');
    }
  }

  /// Stop the currently playing audio
  Future<void> stopAudio() async {
    try {
      _clearError();
      await _audioPlayerService.stopAudio();
    } catch (e) {
      _handleError(_currentlyPlayingId, 'Failed to stop audio: ${e.toString()}');
    }
  }

  /// Toggle playback for the given audio
  Future<void> togglePlayback(String audioId, String audioPath) async {
    if (_currentlyPlayingId == audioId && _isPlaying) {
      await pauseAudio();
    } else {
      await playAudio(audioId, audioPath);
    }
  }



  void _handleError(String? audioId, String error) {
    _currentlyPlayingId = audioId;
    _isPlaying = false;
    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clear any error state
  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _playingSubscription?.cancel();
    _playingStateSubscription?.cancel();
    super.dispose();
  }
}