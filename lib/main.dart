import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services in proper order
  try {
    // Initialize Supabase first
    if (AppConfig.isSupabaseConfigured) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      );
      print('Supabase initialized successfully');
    }
    
    // Initialize error handling service
    await ErrorHandlingService.instance.initialize();
    print('Error handling service initialized');
    
    // Initialize core services
    await AuthService.instance.initialize();
    await AutoExportScheduler.instance.initialize();
    
    // Initialize and validate database schema
    await DatabaseSchemaService.instance.initializeSchema();
    
    // Validate schema integrity
    final isSchemaValid = await DatabaseSchemaService.instance.validateDatabaseSchema();
    if (!isSchemaValid) {
      print('Database schema validation failed - attempting repair');
      await DatabaseSchemaService.instance.repairSchemaIssues();
      
      // Re-validate after repair
      final isSchemaValidAfterRepair = await DatabaseSchemaService.instance.validateDatabaseSchema();
      if (isSchemaValidAfterRepair) {
        print('Database schema repaired successfully');
      } else {
        print('Database schema repair failed - app will continue with local storage only');
      }
    } else {
      print('Database schema validation passed');
    }
    
    print('Database schema initialized and validated');
    
    // Initialize background services for reminders with error handling
    await BackgroundTaskManager.instance.initialize();
    
    // Migrate existing reminders to new format with nextOccurrenceDateTime
    await ReminderStorageService.instance.migrateRemindersToNewFormat();
    
    print('Background services initialized successfully');
  } catch (e) {
    print('Error initializing services: $e');
    
    // Log the initialization error
    try {
      await ErrorHandlingService.instance.logError(
        'APP_INIT_ERROR',
        'Error during app initialization: $e',
        severity: ErrorSeverity.error,
        stackTrace: StackTrace.current,
      );
    } catch (logError) {
      print('Failed to log initialization error: $logError');
    }
    
    // Continue app startup even if background services fail
    // This ensures the app remains functional in foreground mode
  }

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(
      errorDetails: details,
    );
  };
  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Add app lifecycle observer for background state management
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize notification service with context after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotificationService();
    });
  }

  @override
  void dispose() {
    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Delegate app lifecycle changes to background task manager
    BackgroundTaskManager.instance.handleAppStateChange(state);
  }

  /// Initialize notification service with context
  Future<void> _initializeNotificationService() async {
    try {
      if (mounted) {
        await NotificationService.instance.initialize(context);
        print('Notification service initialized with context');
      }
    } catch (e) {
      print('Error initializing notification service with context: $e');
      // Continue without notification service context
      // Background notifications will still work through BackgroundTaskManager
    }
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, screenType) {
      return MaterialApp(
        title: 'good_deeds_reminder',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        initialRoute: AuthService.instance.needsAuthentication 
            ? AppRoutes.login 
            : AppRoutes.dashboard,
      );
    });
  }
}
