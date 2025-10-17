// Debug script to test reminder storage
// Run this with: dart run debug_reminder_storage.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  print('=== Reminder Storage Debug Test ===');
  
  try {
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // Check if reminders exist in local storage
    final remindersJson = prefs.getString('reminders');
    print('\n1. Local Storage Check:');
    
    if (remindersJson == null) {
      print('  No reminders found in local storage');
    } else {
      print('  Raw reminders JSON: $remindersJson');
      
      try {
        final List<dynamic> decoded = jsonDecode(remindersJson);
        final reminders = decoded.cast<Map<String, dynamic>>();
        
        print('  Found ${reminders.length} reminders in local storage:');
        for (int i = 0; i < reminders.length; i++) {
          final reminder = reminders[i];
          print('    ${i + 1}. ID: ${reminder['id']}, Title: "${reminder['title']}", Status: ${reminder['status']}');
          print('       Created: ${reminder['createdAt']}');
          print('       Category: ${reminder['category']}');
          print('       Next: ${reminder['nextOccurrence']}');
        }
      } catch (e) {
        print('  Error parsing reminders JSON: $e');
      }
    }
    
    // Check next ID counter
    final nextId = prefs.getInt('next_reminder_id') ?? 1;
    print('\n2. Next ID Counter: $nextId');
    
    // Check all SharedPreferences keys
    final allKeys = prefs.getKeys();
    print('\n3. All SharedPreferences keys:');
    for (final key in allKeys) {
      if (key.contains('reminder') || key.contains('user') || key.contains('auth')) {
        final value = prefs.get(key);
        print('  $key: ${value.toString().length > 100 ? '${value.toString().substring(0, 100)}...' : value}');
      }
    }
    
    print('\n=== Debug Test Complete ===');
    
  } catch (e) {
    print('Error during debug test: $e');
  }
}