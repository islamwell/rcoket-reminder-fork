import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_export_service.dart';

class AutoExportScheduler {
  static AutoExportScheduler? _instance;
  static AutoExportScheduler get instance => _instance ??= AutoExportScheduler._();
  AutoExportScheduler._();

  Timer? _dailyTimer;
  bool _isInitialized = false;

  // Initialize the auto export scheduler
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check if auto export is enabled
      final prefs = await SharedPreferences.getInstance();
      final autoExportEnabled = prefs.getBool('auto_export_enabled') ?? true;
      
      if (autoExportEnabled) {
        await _scheduleNextExport();
      }
      
      _isInitialized = true;
      print('Auto export scheduler initialized');
    } catch (e) {
      print('Error initializing auto export scheduler: $e');
    }
  }

  // Schedule the next auto export
  Future<void> _scheduleNextExport() async {
    try {
      _dailyTimer?.cancel();
      
      final now = DateTime.now();
      final nextExportTime = _getNextExportTime(now);
      final duration = nextExportTime.difference(now);
      
      print('Next auto export scheduled for: $nextExportTime (in ${duration.inHours}h ${duration.inMinutes % 60}m)');
      
      _dailyTimer = Timer(duration, () async {
        await _performScheduledExport();
        // Schedule the next export for tomorrow
        await _scheduleNextExport();
      });
    } catch (e) {
      print('Error scheduling auto export: $e');
    }
  }

  // Get the next export time (daily at 2 AM)
  DateTime _getNextExportTime(DateTime now) {
    // Schedule for 2 AM to avoid interfering with user activity
    var nextExport = DateTime(now.year, now.month, now.day, 2, 0, 0);
    
    // If it's already past 2 AM today, schedule for tomorrow
    if (nextExport.isBefore(now)) {
      nextExport = nextExport.add(Duration(days: 1));
    }
    
    return nextExport;
  }

  // Perform the scheduled export
  Future<void> _performScheduledExport() async {
    try {
      print('Performing scheduled auto export...');
      await DataExportService.instance.performAutoExport();
      print('Scheduled auto export completed');
    } catch (e) {
      print('Scheduled auto export failed: $e');
      // Don't crash the app if auto export fails
    }
  }

  // Enable auto export
  Future<void> enableAutoExport() async {
    try {
      await DataExportService.instance.setAutoExportEnabled(true);
      await _scheduleNextExport();
      print('Auto export enabled');
    } catch (e) {
      print('Error enabling auto export: $e');
    }
  }

  // Disable auto export
  Future<void> disableAutoExport() async {
    try {
      await DataExportService.instance.setAutoExportEnabled(false);
      _dailyTimer?.cancel();
      _dailyTimer = null;
      print('Auto export disabled');
    } catch (e) {
      print('Error disabling auto export: $e');
    }
  }

  // Check if auto export is enabled
  Future<bool> isAutoExportEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('auto_export_enabled') ?? true;
    } catch (e) {
      print('Error checking auto export status: $e');
      return false;
    }
  }

  // Manually trigger export (for testing)
  Future<void> triggerManualExport() async {
    try {
      print('Triggering manual export...');
      await DataExportService.instance.performAutoExport();
      print('Manual export completed');
    } catch (e) {
      print('Manual export failed: $e');
      throw e;
    }
  }

  // Get time until next export
  Duration? getTimeUntilNextExport() {
    if (_dailyTimer == null || !_dailyTimer!.isActive) {
      return null;
    }
    
    final now = DateTime.now();
    final nextExportTime = _getNextExportTime(now);
    return nextExportTime.difference(now);
  }

  // Dispose the scheduler
  void dispose() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
    _isInitialized = false;
  }
}