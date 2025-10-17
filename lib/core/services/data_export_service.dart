import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background_task_manager.dart';

class DataExportService {
  static DataExportService? _instance;
  static DataExportService get instance => _instance ??= DataExportService._();
  DataExportService._();

  // Export all app data to JSON file
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all app data
      final exportData = {
        'exportVersion': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'userData': _getStringData(prefs, 'user_data'),
        'reminders': _getStringData(prefs, 'reminders'),
        'completionFeedback': _getStringData(prefs, 'completion_feedback'),
        'audioFiles': _getStringData(prefs, 'audio_files'),
        'settings': {
          'isLoggedIn': prefs.getBool('is_logged_in') ?? false,
          'isGuestMode': prefs.getBool('is_guest_mode') ?? false,
          'nextReminderId': prefs.getInt('next_reminder_id') ?? 1,
          'lastExportDate': prefs.getString('last_export_date'),
          'autoExportEnabled': prefs.getBool('auto_export_enabled') ?? true,
        },
        'appVersion': '1.0.0',
      };

      return exportData;
    } catch (e) {
      print('Error exporting data: $e');
      throw Exception('Failed to export data: $e');
    }
  }

  // Export data to file and share
  Future<String> exportToFile() async {
    try {
      final exportData = await exportAllData();
      final jsonString = JsonEncoder.withIndent('  ').convert(exportData);
      
      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'good_deeds_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      // Write data to file
      await file.writeAsString(jsonString);
      
      // Update last export date
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_export_date', DateTime.now().toIso8601String());
      
      print('Data exported to: ${file.path}');
      return file.path;
    } catch (e) {
      print('Error exporting to file: $e');
      throw Exception('Failed to export to file: $e');
    }
  }

  // Share exported data
  Future<void> shareExportedData() async {
    try {
      final filePath = await exportToFile();
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Good Deeds Reminder - Data Backup',
        subject: 'My Reminder Data Backup',
      );
    } catch (e) {
      print('Error sharing data: $e');
      throw Exception('Failed to share data: $e');
    }
  }

  // Import data from file
  Future<bool> importFromFile() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        
        return await importFromJson(jsonString);
      }
      
      return false;
    } catch (e) {
      print('Error importing from file: $e');
      throw Exception('Failed to import from file: $e');
    }
  }

  // Import data from JSON string
  Future<bool> importFromJson(String jsonString) async {
    try {
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Validate import data
      if (!_validateImportData(importData)) {
        throw Exception('Invalid backup file format');
      }

      final prefs = await SharedPreferences.getInstance();
      
      // Import user data
      if (importData['userData'] != null) {
        await prefs.setString('user_data', importData['userData']);
      }
      
      // Import reminders
      if (importData['reminders'] != null) {
        await prefs.setString('reminders', importData['reminders']);
      }
      
      // Import completion feedback
      if (importData['completionFeedback'] != null) {
        await prefs.setString('completion_feedback', importData['completionFeedback']);
      }
      
      // Import audio files
      if (importData['audioFiles'] != null) {
        await prefs.setString('audio_files', importData['audioFiles']);
      }
      
      // Import settings
      final settings = importData['settings'] as Map<String, dynamic>?;
      if (settings != null) {
        if (settings['isLoggedIn'] != null) {
          await prefs.setBool('is_logged_in', settings['isLoggedIn']);
        }
        if (settings['isGuestMode'] != null) {
          await prefs.setBool('is_guest_mode', settings['isGuestMode']);
        }
        if (settings['nextReminderId'] != null) {
          await prefs.setInt('next_reminder_id', settings['nextReminderId']);
        }
        if (settings['autoExportEnabled'] != null) {
          await prefs.setBool('auto_export_enabled', settings['autoExportEnabled']);
        }
      }
      
      // Set import date
      await prefs.setString('last_import_date', DateTime.now().toIso8601String());
      
      // Reschedule all active reminders for background notifications after import
      try {
        await BackgroundTaskManager.instance.scheduleAllActiveReminders();
        print('Background notifications rescheduled after import');
      } catch (e) {
        print('Warning: Failed to reschedule background notifications after import: $e');
        // Continue - import was successful even if background scheduling failed
      }
      
      print('Data imported successfully');
      return true;
    } catch (e) {
      print('Error importing data: $e');
      throw Exception('Failed to import data: $e');
    }
  }

  // Auto export (called daily)
  Future<void> performAutoExport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoExportEnabled = prefs.getBool('auto_export_enabled') ?? true;
      
      if (!autoExportEnabled) {
        print('Auto export is disabled');
        return;
      }
      
      final lastExportDate = prefs.getString('last_export_date');
      final now = DateTime.now();
      
      // Check if we need to export (once per day)
      if (lastExportDate != null) {
        final lastExport = DateTime.parse(lastExportDate);
        final daysSinceLastExport = now.difference(lastExport).inDays;
        
        if (daysSinceLastExport < 1) {
          print('Auto export not needed yet (last export: $daysSinceLastExport days ago)');
          return;
        }
      }
      
      // Perform auto export
      await exportToFile();
      print('Auto export completed successfully');
      
      // Clean up old backup files (keep only last 7 days)
      await _cleanupOldBackups();
      
    } catch (e) {
      print('Auto export failed: $e');
      // Don't throw error for auto export failures
    }
  }

  // Get export statistics
  Future<Map<String, dynamic>> getExportStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final directory = await getApplicationDocumentsDirectory();
      
      // Count backup files
      final backupFiles = directory.listSync()
          .where((file) => file.path.contains('good_deeds_backup_'))
          .length;
      
      return {
        'lastExportDate': prefs.getString('last_export_date'),
        'lastImportDate': prefs.getString('last_import_date'),
        'autoExportEnabled': prefs.getBool('auto_export_enabled') ?? true,
        'backupFilesCount': backupFiles,
        'totalDataSize': await _calculateDataSize(),
      };
    } catch (e) {
      print('Error getting export stats: $e');
      return {};
    }
  }

  // Enable/disable auto export
  Future<void> setAutoExportEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_export_enabled', enabled);
  }

  // Helper methods
  String? _getStringData(SharedPreferences prefs, String key) {
    try {
      return prefs.getString(key);
    } catch (e) {
      print('Error getting $key: $e');
      return null;
    }
  }

  bool _validateImportData(Map<String, dynamic> data) {
    // Check required fields
    return data.containsKey('exportVersion') && 
           data.containsKey('exportDate') &&
           data.containsKey('appVersion');
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupFiles = directory.listSync()
          .where((file) => file.path.contains('good_deeds_backup_'))
          .map((file) => File(file.path))
          .toList();
      
      // Sort by modification date (newest first)
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Keep only the 7 most recent backups
      if (backupFiles.length > 7) {
        for (int i = 7; i < backupFiles.length; i++) {
          await backupFiles[i].delete();
          print('Deleted old backup: ${backupFiles[i].path}');
        }
      }
    } catch (e) {
      print('Error cleaning up old backups: $e');
    }
  }

  Future<String> _calculateDataSize() async {
    try {
      final exportData = await exportAllData();
      final jsonString = jsonEncode(exportData);
      final sizeInBytes = jsonString.length;
      
      if (sizeInBytes < 1024) {
        return '${sizeInBytes} B';
      } else if (sizeInBytes < 1024 * 1024) {
        return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}