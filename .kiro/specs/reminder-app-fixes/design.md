# Design Document

## Overview

This design addresses critical functionality issues and feature enhancements for the reminder application. The solution focuses on fixing database schema and data integrity issues, resolving the fallback mode issue, enhancing feedback management, ensuring reliable audio playback, implementing flexible completion delays, resolving authentication-related errors, improving scheduling accuracy, organizing activity displays, and implementing comprehensive data persistence for analytics.

## Architecture

The solution builds upon the existing Flutter architecture with these key components:

- **Database Schema Service**: New service to handle database integrity and schema validation
- **Reminder Storage Service**: Enhanced with proper UUID handling and database error recovery
- **Error Handling Service**: Enhanced to better manage fallback mode states
- **Audio Player Service**: Improved to ensure reliable playback regardless of device settings
- **Notification Service**: Enhanced with better error handling and completion delay options
- **Completion Feedback Service**: Enhanced with editing capabilities and better data structure
- **Dashboard Service**: New service for organizing activity lists and analytics data
- **Analytics Service**: New service for comprehensive data collection and storage

## Components and Interfaces

### 1. Database Schema and Data Integrity Fixes

**Component**: New Database Schema Service
- **Purpose**: Ensure database schema integrity and proper data handling
- **Key Methods**:
  - `validateDatabaseSchema()`: Check for missing tables, columns, and functions
  - `createMissingFunctions()`: Create required database functions like exec_sql
  - `repairSchemaIssues()`: Fix schema inconsistencies
  - `generateProperUUID()`: Generate valid UUIDs for database operations

**Interface Changes**:
```dart
class DatabaseSchemaService {
  Future<bool> validateDatabaseSchema();
  Future<void> createMissingFunctions();
  Future<void> repairSchemaIssues();
  String generateProperUUID();
}
```

**Component**: Enhanced Reminder Storage Service (Database Fixes)
- **Purpose**: Fix UUID handling and database operation errors
- **Key Methods**:
  - `validateDataBeforeInsert()`: Ensure data integrity before database operations
  - `handleDatabaseErrors()`: Proper error handling for database failures
  - `retryFailedOperations()`: Retry mechanism for failed database operations

**Implementation Strategy**:
- Replace integer ID generation with proper UUID generation
- Add database schema validation on app startup
- Create missing database functions (exec_sql, etc.)
- Implement proper error handling for database operations
- Add loading state management to prevent UI freezing

### 2. Fallback Mode Resolution

**Component**: Enhanced Error Handling Service
- **Purpose**: Resolve the "limited functionality" message appearing unexpectedly
- **Key Methods**:
  - `checkFallbackModeStatus()`: Verify current fallback state
  - `resetFallbackMode()`: Clear unnecessary fallback mode
  - `validateSystemHealth()`: Comprehensive system health check

**Interface Changes**:
```dart
class ErrorHandlingService {
  Future<bool> shouldBeInFallbackMode();
  Future<void> resetToNormalMode();
  Future<SystemHealthReport> generateHealthReport();
}
```

### 3. Feedback Review and Editing

**Component**: Enhanced Completion Feedback Service
- **Purpose**: Allow users to review and edit completed feedback
- **Key Methods**:
  - `getFeedbackById(int id)`: Retrieve specific feedback
  - `updateFeedback(int id, Map<String, dynamic> updates)`: Update existing feedback
  - `getFeedbackHistory(int reminderId)`: Get all feedback versions for a reminder

**Interface Changes**:
```dart
class CompletionFeedbackService {
  Future<Map<String, dynamic>?> getFeedbackById(int id);
  Future<void> updateFeedback(int id, Map<String, dynamic> updates);
  Future<List<Map<String, dynamic>>> getFeedbackHistory(int reminderId);
}
```

**UI Component**: Feedback Edit Screen
- Modal bottom sheet or full screen for editing
- Pre-populated form with existing feedback data
- Version history display
- Save/cancel actions with confirmation

### 4. Reliable Audio Playback

**Component**: Enhanced Audio Player Service
- **Purpose**: Ensure audio plays regardless of device settings
- **Key Methods**:
  - `playAudioForced(String audioId, String path)`: Play audio bypassing device settings
  - `setAudioStreamType()`: Configure audio stream for notifications
  - `validateAudioCapabilities()`: Check device audio capabilities

**Interface Changes**:
```dart
class AudioPlayerService {
  Future<void> playAudioForced(String audioId, String path, {bool bypassSilentMode = true});
  Future<void> setNotificationAudioStream();
  Future<AudioCapabilities> getDeviceAudioCapabilities();
}
```

**Implementation Strategy**:
- Use notification audio stream instead of media stream
- Implement platform-specific audio channel configuration
- Add fallback to system sounds with vibration
- Test audio playback on app initialization

### 5. Flexible Completion Delay Options

**Component**: Enhanced Notification Service
- **Purpose**: Provide multiple delay options for "complete later"
- **Key Methods**:
  - `showCompletionDelayDialog()`: Display delay options
  - `scheduleDelayedCompletion(int reminderId, Duration delay)`: Schedule with custom delay
  - `getDelayPresets()`: Get predefined delay options

**Interface Changes**:
```dart
class NotificationService {
  Future<Duration?> showCompletionDelayDialog(BuildContext context);
  Future<void> scheduleDelayedCompletion(int reminderId, Duration delay);
  List<DelayOption> getDelayPresets();
}

class DelayOption {
  final String label;
  final Duration duration;
  final IconData icon;
}
```

**UI Component**: Completion Delay Dialog
- Bottom sheet with preset options (1min, 5min, 15min, 1hr)
- Custom time picker option
- Visual indicators for each delay type
- Confirmation with scheduled time display

### 6. Authentication Error Resolution

**Component**: Enhanced Reminder Storage Service
- **Purpose**: Fix errors appearing only for logged-in users
- **Key Methods**:
  - `validateUserSession()`: Check authentication state
  - `retryWithAuth(Function operation)`: Retry operations with proper auth
  - `handleAuthErrors(Exception error)`: Specific auth error handling

**Interface Changes**:
```dart
class ReminderStorageService {
  Future<bool> validateUserSession();
  Future<T> retryWithAuth<T>(Future<T> Function() operation);
  Future<void> handleAuthErrors(Exception error, String operation);
}
```

**Implementation Strategy**:
- Add authentication validation before Supabase operations
- Implement proper error handling for auth failures
- Add retry logic with exponential backoff
- Provide user feedback for auth-related issues

### 7. Accurate Future Reminder Scheduling

**Component**: Enhanced Reminder Storage Service
- **Purpose**: Fix scheduling issues where 2-minute reminders go to tomorrow
- **Key Methods**:
  - `calculatePreciseScheduleTime(Map frequency, String time)`: Accurate time calculation
  - `validateScheduleTime(DateTime scheduledTime)`: Validate scheduling logic
  - `adjustForTimeConflicts(DateTime proposed)`: Handle time conflicts

**Interface Changes**:
```dart
class ReminderStorageService {
  DateTime calculatePreciseScheduleTime(Map<String, dynamic> frequency, String time);
  bool validateScheduleTime(DateTime scheduledTime);
  DateTime adjustForTimeConflicts(DateTime proposedTime);
}
```

**Implementation Strategy**:
- Fix time calculation logic to consider current time properly
- Add buffer time validation (minimum 1 minute in future)
- Implement smart scheduling that considers user intent
- Add confirmation dialog for schedule adjustments

### 8. Activity Organization Lists

**Component**: New Dashboard Activity Service
- **Purpose**: Organize reminders into categorized activity lists
- **Key Methods**:
  - `getMissedReminders()`: Get reminders that were missed
  - `getAwaitingFeedback()`: Get completed reminders without feedback
  - `getPausedReminders()`: Get currently paused reminders
  - `organizeRecentActivity()`: Categorize all recent activity

**Interface Changes**:
```dart
class DashboardActivityService {
  Future<List<Map<String, dynamic>>> getMissedReminders();
  Future<List<Map<String, dynamic>>> getAwaitingFeedback();
  Future<List<Map<String, dynamic>>> getPausedReminders();
  Future<Map<String, List<Map<String, dynamic>>>> organizeRecentActivity();
}
```

**UI Component**: Organized Activity Lists
- Expandable sections for each category
- Action buttons for each list item
- Visual indicators for urgency/priority
- Quick actions (reschedule, complete, resume)

### 9. Comprehensive Data Persistence

**Component**: New Analytics Data Service
- **Purpose**: Save all data for future graphs, charts, and statistics
- **Key Methods**:
  - `recordReminderEvent(String eventType, Map data)`: Record any reminder event
  - `saveAnalyticsData(Map data)`: Store data for analytics
  - `getAnalyticsData(DateRange range)`: Retrieve data for analysis
  - `exportAnalyticsData()`: Export data for external analysis

**Interface Changes**:
```dart
class AnalyticsDataService {
  Future<void> recordReminderEvent(String eventType, Map<String, dynamic> data);
  Future<void> saveAnalyticsData(Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getAnalyticsData(DateRange range);
  Future<String> exportAnalyticsData(ExportFormat format);
}

enum EventType {
  reminderCreated,
  reminderCompleted,
  reminderMissed,
  reminderPaused,
  reminderResumed,
  reminderDeleted,
  feedbackProvided,
  feedbackEdited
}
```

## Data Models

### Enhanced Feedback Model
```dart
class FeedbackModel {
  final int id;
  final int reminderId;
  final String reminderTitle;
  final String reminderCategory;
  final DateTime completedAt;
  final DateTime? editedAt;
  final int version;
  final Map<String, dynamic> feedbackData;
  final bool isEdited;
}
```

### Activity Item Model
```dart
class ActivityItem {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final List<ActivityAction> availableActions;
}

enum ActivityType {
  missed,
  awaitingFeedback,
  paused,
  completed,
  created,
  edited
}
```

### Analytics Event Model
```dart
class AnalyticsEvent {
  final String id;
  final EventType type;
  final DateTime timestamp;
  final int? reminderId;
  final String? userId;
  final Map<String, dynamic> eventData;
  final Map<String, dynamic> metadata;
}
```

### Delay Option Model
```dart
class DelayOption {
  final String id;
  final String label;
  final Duration duration;
  final IconData icon;
  final bool isCustom;
}
```

## Error Handling

### Fallback Mode Management
- Implement proper fallback mode detection
- Add automatic recovery mechanisms
- Provide clear user feedback about system status
- Log fallback mode triggers for debugging

### Audio Playback Errors
- Multiple fallback strategies (notification stream, media stream, system sounds)
- Device capability detection
- User notification for audio issues
- Graceful degradation with vibration

### Authentication Errors
- Proper session validation
- Automatic token refresh
- Fallback to local storage
- Clear error messages for users

### Scheduling Errors
- Time validation and correction
- Conflict resolution
- User confirmation for adjustments
- Fallback scheduling strategies

## Testing Strategy

### Unit Tests
- Fallback mode detection and resolution
- Audio playback across different device states
- Time calculation accuracy
- Authentication error handling
- Data persistence and retrieval

### Integration Tests
- Complete user flows for each feature
- Cross-service communication
- Error recovery scenarios
- Data consistency across services

### User Acceptance Tests
- Feedback editing workflow
- Audio playback in various scenarios
- Completion delay functionality
- Activity list organization
- Data export and analytics

### Performance Tests
- Large dataset handling
- Memory usage with analytics data
- Audio playback performance
- UI responsiveness with organized lists

## Implementation Phases

### Phase 1: Critical Fixes
1. Resolve fallback mode issue
2. Fix authentication errors
3. Correct scheduling accuracy
4. Ensure reliable audio playback

### Phase 2: Feature Enhancements
1. Implement feedback editing
2. Add completion delay options
3. Create organized activity lists
4. Basic analytics data collection

### Phase 3: Advanced Features
1. Comprehensive analytics service
2. Data export functionality
3. Advanced scheduling options
4. Enhanced error recovery

## Security Considerations

- Secure storage of analytics data
- User privacy in data collection
- Authentication token management
- Data encryption for sensitive information

## Performance Considerations

- Efficient data querying for analytics
- Lazy loading for large activity lists
- Audio resource management
- Background task optimization

## Accessibility Considerations

- Screen reader support for activity lists
- High contrast mode for visual indicators
- Voice feedback for audio issues
- Keyboard navigation for all features