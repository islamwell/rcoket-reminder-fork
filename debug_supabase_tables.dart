// Debug script to check Supabase tables
// Run this with: dart run debug_supabase_tables.dart

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jslerlyixschpaefyaft.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzbGVybHlpeHNjaHBhZWZ5YWZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU5NTcwODUsImV4cCI6MjA3MTUzMzA4NX0.Wm1Eolk-HysrZ5PerTiu_1NMj7JYJidFdav1c6VvpIk',
  );

  final supabase = Supabase.instance.client;
  
  print('=== Supabase Tables Debug Test ===');
  
  // Test 1: Check if reminders table exists
  print('\n1. Testing reminders table...');
  try {
    final remindersResponse = await supabase
        .from('reminders')
        .select('count')
        .limit(1);
    print('  ✅ Reminders table exists');
    print('  Response: $remindersResponse');
  } catch (e) {
    print('  ❌ Reminders table error: $e');
    if (e.toString().contains('relation "reminders" does not exist')) {
      print('  🔍 ISSUE FOUND: reminders table does not exist!');
    }
  }
  
  // Test 2: Check if profiles table exists
  print('\n2. Testing profiles table...');
  try {
    final profilesResponse = await supabase
        .from('profiles')
        .select('count')
        .limit(1);
    print('  ✅ Profiles table exists');
    print('  Response: $profilesResponse');
  } catch (e) {
    print('  ❌ Profiles table error: $e');
    if (e.toString().contains('relation "profiles" does not exist')) {
      print('  🔍 ISSUE FOUND: profiles table does not exist!');
    }
  }
  
  // Test 3: Try to create a test reminder (if table exists)
  print('\n3. Testing reminder creation...');
  try {
    // First, try to sign in
    final authResponse = await supabase.auth.signInWithPassword(
      email: 'it@nrq.no',
      password: 'test123456', // Replace with actual password
    );
    
    if (authResponse.user != null) {
      print('  ✅ User authenticated: ${authResponse.user!.id}');
      
      // Try to insert a test reminder
      final testReminder = {
        'user_id': authResponse.user!.id,
        'title': 'Test Reminder',
        'category': 'test',
        'frequency': {'type': 'daily'},
        'time': '12:00',
        'description': 'Test reminder for debugging',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'completion_count': 0,
        'next_occurrence': 'Today at 12:00',
        'next_occurrence_date_time': DateTime.now().add(Duration(hours: 1)).toIso8601String(),
      };
      
      final insertResponse = await supabase
          .from('reminders')
          .insert(testReminder)
          .select()
          .single();
      
      print('  ✅ Test reminder created successfully!');
      print('  Reminder ID: ${insertResponse['id']}');
      
      // Clean up - delete the test reminder
      await supabase
          .from('reminders')
          .delete()
          .eq('id', insertResponse['id']);
      print('  🧹 Test reminder cleaned up');
      
    } else {
      print('  ❌ Authentication failed');
    }
  } catch (e) {
    print('  ❌ Reminder creation test failed: $e');
  }
  
  // Test 4: Check current user and permissions
  print('\n4. Testing current user...');
  try {
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      print('  ✅ Current user: ${currentUser.id}');
      print('  Email: ${currentUser.email}');
      print('  Email confirmed: ${currentUser.emailConfirmedAt != null}');
    } else {
      print('  ❌ No current user');
    }
  } catch (e) {
    print('  ❌ User check error: $e');
  }
  
  print('\n=== Debug Test Complete ===');
  print('\n📋 Next Steps:');
  print('1. If reminders table doesn\'t exist, run the supabase_setup.sql script');
  print('2. Check Row Level Security (RLS) policies if table exists but inserts fail');
  print('3. Verify user authentication and permissions');
}