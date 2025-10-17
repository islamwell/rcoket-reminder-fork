import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'audio_storage_service.dart';

class AudioRecordingService {
  static AudioRecordingService? _instance;
  static AudioRecordingService get instance => _instance ??= AudioRecordingService._();
  AudioRecordingService._();

  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  // Getters
  bool get isRecording => _isRecording;
  Duration? get recordingDuration {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  // Check if recording permission is available
  Future<bool> hasPermission() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      print('Error checking recording permission: $e');
      return false;
    }
  }

  // Start recording
  Future<String?> startRecording({String? customFilename}) async {
    try {
      if (_isRecording) {
        throw Exception('Recording is already in progress');
      }

      if (!await hasPermission()) {
        throw Exception('Microphone permission denied');
      }

      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = customFilename ?? 'recording_$timestamp';
      
      String path;
      RecordConfig config;

      if (kIsWeb) {
        // Web configuration
        path = '$filename.wav';
        config = const RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 44100,
        );
      } else {
        // Mobile configuration
        final audioDir = await AudioStorageService.instance.audioDirectory;
        path = '${audioDir.path}/$filename.m4a';
        config = const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );
      }

      await _audioRecorder.start(config, path: path);
      
      _isRecording = true;
      _currentRecordingPath = path;
      _recordingStartTime = DateTime.now();

      return path;
    } catch (e) {
      print('Error starting recording: $e');
      throw Exception('Failed to start recording: ${e.toString()}');
    }
  }

  // Stop recording and save
  Future<Map<String, dynamic>?> stopRecording({
    String? customName,
    String? category,
  }) async {
    try {
      if (!_isRecording) {
        throw Exception('No recording in progress');
      }

      final recordingPath = await _audioRecorder.stop();
      _isRecording = false;
      
      if (recordingPath == null || recordingPath.isEmpty) {
        throw Exception('Recording failed - no file created');
      }

      // Calculate duration
      final duration = _recordingStartTime != null 
          ? DateTime.now().difference(_recordingStartTime!)
          : Duration.zero;

      // Get file size
      int fileSize = 0;
      if (!kIsWeb) {
        fileSize = await AudioStorageService.instance.getFileSize(recordingPath);
      }

      // Create audio file metadata
      final audioFile = {
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "filename": customName ?? "Recording_${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}.${kIsWeb ? 'wav' : 'm4a'}",
        "duration": _formatDuration(duration),
        "size": AudioStorageService.instance.formatFileSize(fileSize),
        "uploadDate": DateTime.now().toString().split(' ')[0],
        "isFavorite": false,
        "category": category ?? "Personal",
        "path": recordingPath,
        "type": "recorded",
        "description": "Voice recording created in app",
      };

      // Save to storage service
      await AudioStorageService.instance.saveAudioFile(audioFile);

      // Reset recording state
      _currentRecordingPath = null;
      _recordingStartTime = null;

      return audioFile;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      throw Exception('Failed to stop recording: ${e.toString()}');
    }
  }

  // Cancel recording without saving
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        
        // Delete the recording file if it exists
        if (_currentRecordingPath != null && !kIsWeb) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error canceling recording: $e');
    } finally {
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
    }
  }

  // Pause recording (if supported)
  Future<void> pauseRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.pause();
      }
    } catch (e) {
      print('Error pausing recording: $e');
      // Pause might not be supported on all platforms
    }
  }

  // Resume recording (if supported)
  Future<void> resumeRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.resume();
      }
    } catch (e) {
      print('Error resuming recording: $e');
      // Resume might not be supported on all platforms
    }
  }

  // Get recording amplitude (for visual feedback)
  Future<double> getAmplitude() async {
    try {
      if (_isRecording) {
        final amplitude = await _audioRecorder.getAmplitude();
        return amplitude.current.clamp(0.0, 1.0);
      }
    } catch (e) {
      print('Error getting amplitude: $e');
    }
    return 0.0;
  }

  // Format duration for display
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Dispose resources
  void dispose() {
    _audioRecorder.dispose();
  }
}