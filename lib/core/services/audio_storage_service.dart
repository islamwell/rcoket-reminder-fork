import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioStorageService {
  static const String _audioFilesKey = 'audio_files';
  static const String _audioFolderName = 'reminder_audio';

  static AudioStorageService? _instance;
  static AudioStorageService get instance => _instance ??= AudioStorageService._();
  AudioStorageService._();

  // Get the audio directory
  Future<Directory> get audioDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}/$_audioFolderName');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  // Save audio file metadata
  Future<void> saveAudioFile(Map<String, dynamic> audioFile) async {
    final prefs = await SharedPreferences.getInstance();
    final audioFiles = await getAudioFiles();
    
    // Check if file already exists and update or add
    final existingIndex = audioFiles.indexWhere((file) => file['id'] == audioFile['id']);
    if (existingIndex != -1) {
      audioFiles[existingIndex] = audioFile;
    } else {
      audioFiles.insert(0, audioFile);
    }
    
    await prefs.setString(_audioFilesKey, jsonEncode(audioFiles));
  }

  // Get all audio files
  Future<List<Map<String, dynamic>>> getAudioFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final audioFilesJson = prefs.getString(_audioFilesKey);
    
    if (audioFilesJson == null) {
      return _getDefaultAudioFiles();
    }
    
    try {
      final List<dynamic> decoded = jsonDecode(audioFilesJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return _getDefaultAudioFiles();
    }
  }

  // Delete audio file
  Future<void> deleteAudioFile(String audioId) async {
    final audioFiles = await getAudioFiles();
    final audioFile = audioFiles.firstWhere(
      (file) => file['id'] == audioId,
      orElse: () => <String, dynamic>{},
    );
    
    // Delete physical file if it exists and is not a default file
    if (audioFile.isNotEmpty && audioFile['type'] != 'default') {
      final filePath = audioFile['path'] as String?;
      if (filePath != null && filePath.isNotEmpty) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting file: $e');
        }
      }
    }
    
    // Remove from metadata
    audioFiles.removeWhere((file) => file['id'] == audioId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_audioFilesKey, jsonEncode(audioFiles));
  }

  // Update audio file metadata
  Future<void> updateAudioFile(String audioId, Map<String, dynamic> updates) async {
    final audioFiles = await getAudioFiles();
    final index = audioFiles.indexWhere((file) => file['id'] == audioId);
    
    if (index != -1) {
      audioFiles[index] = {...audioFiles[index], ...updates};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_audioFilesKey, jsonEncode(audioFiles));
    }
  }

  // Get audio file by ID
  Future<Map<String, dynamic>?> getAudioFileById(String audioId) async {
    final audioFiles = await getAudioFiles();
    try {
      return audioFiles.firstWhere((file) => file['id'] == audioId);
    } catch (e) {
      return null;
    }
  }

  // Copy file to app directory
  Future<String> copyFileToAppDirectory(String sourcePath, String filename) async {
    final audioDir = await audioDirectory;
    final targetPath = '${audioDir.path}/$filename';
    
    final sourceFile = File(sourcePath);
    final targetFile = await sourceFile.copy(targetPath);
    
    return targetFile.path;
  }

  // Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Error getting file size: $e');
    }
    return 0;
  }

  // Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Get default audio files (built-in options)
  List<Map<String, dynamic>> _getDefaultAudioFiles() {
    return [
      {
        "id": "default_1",
        "filename": "Gentle Reminder.mp3",
        "duration": "0:15",
        "size": "0.8 MB",
        "uploadDate": DateTime.now().toString().split(' ')[0],
        "isFavorite": false,
        "category": "Default",
        "path": "assets/audio/gentle_reminder.mp3",
        "type": "default",
        "description": "Soft chime with Islamic greeting",
      },
      {
        "id": "default_2",
        "filename": "Quran Recitation.mp3",
        "duration": "0:30",
        "size": "1.2 MB",
        "uploadDate": DateTime.now().toString().split(' ')[0],
        "isFavorite": false,
        "category": "Default",
        "path": "assets/audio/quran_recitation.mp3",
        "type": "default",
        "description": "Beautiful Quranic verse recitation",
      },
      {
        "id": "default_3",
        "filename": "Dhikr Bell.mp3",
        "duration": "0:10",
        "size": "0.5 MB",
        "uploadDate": DateTime.now().toString().split(' ')[0],
        "isFavorite": false,
        "category": "Default",
        "path": "assets/audio/dhikr_bell.mp3",
        "type": "default",
        "description": "Traditional Islamic bell sound",
      },
    ];
  }

  // Clear all audio files (for testing/reset)
  Future<void> clearAllAudioFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_audioFilesKey);
    
    // Also delete all files in audio directory
    try {
      final audioDir = await audioDirectory;
      if (await audioDir.exists()) {
        await audioDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing audio directory: $e');
    }
  }
}