class AppConfig {
  // Supabase configuration
  static const String supabaseUrl = 'https://jslerlyixschpaefyaft.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpzbGVybHlpeHNjaHBhZWZ5YWZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU5NTcwODUsImV4cCI6MjA3MTUzMzA4NX0.Wm1Eolk-HysrZ5PerTiu_1NMj7JYJidFdav1c6VvpIk';
  
  // Configuration validation
  static bool get isSupabaseConfigured => 
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  
  // Environment detection
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDebug => !isProduction;
  
  // App metadata
  static const String appName = 'Good Deeds Reminder';
  static const String appVersion = '1.0.0';
}