// Debug script to test Supabase authentication
// Run this with: dart run debug_auth_test.dart

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jslerlyixschpaefyaft.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzbGVybHlpeHNjaHBhZWZ5YWZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU5NTcwODUsImV4cCI6MjA3MTUzMzA4NX0.Wm1Eolk-HysrZ5PerTiu_1NMj7JYJidFdav1c6VvpIk',
  );

  final supabase = Supabase.instance.client;
  
  print('=== Supabase Auth Debug Test ===');
  print('Testing with email: it@nrq.no');
  
  try {
    // Test 1: Try to sign up
    print('\n1. Testing signup...');
    final signUpResponse = await supabase.auth.signUp(
      email: 'it@nrq.no',
      password: 'test123456',
      data: {'name': 'Test User'},
    );
    
    print('Signup response:');
    print('  User: ${signUpResponse.user?.id}');
    print('  Email: ${signUpResponse.user?.email}');
    print('  Email confirmed: ${signUpResponse.user?.emailConfirmedAt}');
    print('  Session: ${signUpResponse.session != null}');
    
  } catch (e) {
    print('Signup error: $e');
    print('Error type: ${e.runtimeType}');
    
    if (e is AuthException) {
      print('Auth error message: ${e.message}');
    }
  }
  
  try {
    // Test 2: Try to sign in
    print('\n2. Testing signin...');
    final signInResponse = await supabase.auth.signInWithPassword(
      email: 'it@nrq.no',
      password: 'test123456',
    );
    
    print('Signin response:');
    print('  User: ${signInResponse.user?.id}');
    print('  Email: ${signInResponse.user?.email}');
    print('  Session: ${signInResponse.session != null}');
    
    // Test 3: Check if profiles table exists
    print('\n3. Testing profiles table...');
    try {
      final profileResponse = await supabase
          .from('profiles')
          .select()
          .eq('id', signInResponse.user!.id)
          .single();
      print('Profile found: $profileResponse');
    } catch (profileError) {
      print('Profile error: $profileError');
      print('This might be why login is slow - profiles table might not exist');
    }
    
  } catch (e) {
    print('Signin error: $e');
    print('Error type: ${e.runtimeType}');
    
    if (e is AuthException) {
      print('Auth error message: ${e.message}');
    }
  }
  
  // Test 4: Check current user
  print('\n4. Current user status:');
  final currentUser = supabase.auth.currentUser;
  print('  Current user: ${currentUser?.id}');
  print('  Email: ${currentUser?.email}');
  print('  Email confirmed: ${currentUser?.emailConfirmedAt}');
  
  // Test 5: List all users (if you have admin access)
  print('\n5. Testing database connection...');
  try {
    // Try a simple query to test database connectivity
    final testQuery = await supabase.from('profiles').select('count').limit(1);
    print('Database connection: OK');
  } catch (e) {
    print('Database connection error: $e');
    if (e.toString().contains('relation "profiles" does not exist')) {
      print('ISSUE FOUND: profiles table does not exist!');
    }
  }
}