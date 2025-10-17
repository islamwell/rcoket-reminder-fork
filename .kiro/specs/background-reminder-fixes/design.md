# Design Document

## Overview

This design addresses the critical issues with reminder background processing and time display accuracy. The solution implements a multi-layered approach using Flutter's native notification system, proper background task scheduling, and real-time countdown updates to ensure reminders work reliably regardless of app state.

## Architecture

### Background Processing Strategy

The solution uses a hybrid approach combining:

1. **Flutter Local Notifications Plugin** - For native system notifications that work when app is backgrounded
2. **Background Task Scheduling** - Using platform-specific background execution capabilities
3. **App Lifecycle Management** - Proper handling of app state changes
4. **Persistent Scheduling** - Storing scheduled notifications that survive app restarts

### Time Calculation Improvements

1. **Real-time Updates** - Live countdown timers that update every minute
2. **Accurate Next Occurrence Calculation** - Fixed logic for hourly and other recurring reminders
3. **Dynamic Display Formatting** - Context-aware time display based on proximity

## Components and Interfaces

### 1. Enhanced Notification Service

**File:** `lib/core/services/notification_service.dart`

**Key Changes:**
- Add `flutter_local_notifications` dependency
- Implement native notification scheduling
- Handle notification tap actions
- Manage notification permissions
- Coordinate between foreground dialogs and background notifications

**New Methods:**
```dart
Future<void> scheduleNotification(Map<String, dynamic> reminder)
Future<void> cancelNotification(int reminderId)
Future<void> requestPermissions()
Future<bool> areNotificationsEnabled()
void handleNotificationTap(String payload)
```

### 2. Background Task Manager

**File:** `lib/core/services/background_task_manager.dart` (New)

**Purpose:** Manage background execution and notification scheduling
- Schedule notifications for all active reminders
- Handle app lifecycle changes
- Reschedule notifications after device restart
- Coordinate with notification service

**Key Methods:**
```dart
Future<void> scheduleAllActiveReminders()
Future<void> rescheduleReminder(int reminderId)
Future<void> handleAppStateChange(AppLifecycleState state)
Future<void> initializeBackgroundTasks()
```

### 3. Real-time Countdown Widget

**File:** `lib/presentation/reminder_management/widgets/countdown_display_widget.dart` (New)

**Purpose:** Display accurate, updating countdown times
- Real-time countdown updates
- Smart formatting based on time remaining
- Automatic refresh every minute
- Handle overdue states

### 4. Enhanced Reminder Storage Service

**File:** `lib/core/services/reminder_storage_service.dart`

**Enhancements:**
- Fix next occurrence calculation logic
- Add notification scheduling integration
- Improve time formatting accuracy
- Handle edge cases for recurring reminders

## Data Models

### Notification Payload Structure
```dart
class NotificationPayload {
  final int reminderId;
  final String title;
  final String category;
  final String action; // 'trigger', 'snooze', 'complete'
  
  Map<String, dynamic> toJson();
  static NotificationPayload fromJson(Map<String, dynamic> json);
}
```

### Enhanced Reminder Model
```dart
// Additional fields for background processing
{
  "id": int,
  "title": String,
  "category": String,
  "frequency": Map<String, dynamic>,
  "time": String,
  "nextOccurrence": String,
  "nextOccurrenceDateTime": String, // ISO 8601 for precise scheduling
  "notificationId": int, // Unique ID for system notifications
  "backgroundScheduled": bool, // Track if background notification is scheduled
  // ... existing fields
}
```

## Error Handling

### Permission Handling
- Graceful degradation when notification permissions are denied
- Clear user messaging about functionality limitations
- Retry mechanisms for permission requests
- Fallback to foreground-only mode when necessary

### Background Task Failures
- Retry logic for failed notification scheduling
- Logging and monitoring of background task execution
- Fallback to app-based checking when background tasks fail
- User notifications about background processing issues

### Time Calculation Edge Cases
- Handle daylight saving time changes
- Manage leap years and month boundaries
- Deal with invalid dates (e.g., February 30th)
- Graceful handling of system time changes

## Testing Strategy

### Unit Tests
- Test notification scheduling logic
- Verify time calculation accuracy
- Test permission handling flows
- Validate payload serialization/deserialization

### Integration Tests
- Test background notification delivery
- Verify app lifecycle handling
- Test notification tap actions
- Validate reminder rescheduling after app restart

### Manual Testing Scenarios
- Test with app minimized for extended periods
- Verify functionality in power-saving mode
- Test with various reminder frequencies
- Validate time display accuracy over time
- Test notification permissions flow

## Implementation Phases

### Phase 1: Foundation
1. Add flutter_local_notifications dependency
2. Create background task manager service
3. Implement notification permissions handling
4. Set up basic notification scheduling

### Phase 2: Core Functionality
1. Enhance notification service with native notifications
2. Fix time calculation logic in reminder storage service
3. Implement notification tap handling
4. Add app lifecycle management

### Phase 3: UI Improvements
1. Create real-time countdown display widget
2. Update reminder list to show accurate times
3. Add permission request UI flows
4. Implement notification settings screen

### Phase 4: Polish & Testing
1. Add comprehensive error handling
2. Implement retry mechanisms
3. Add logging and monitoring
4. Perform extensive testing across scenarios

## Platform-Specific Considerations

### Android
- Request notification permissions (Android 13+)
- Handle battery optimization settings
- Configure foreground service for critical reminders
- Set up notification channels with appropriate priorities

### iOS
- Request notification authorization
- Handle notification settings changes
- Configure notification categories for actions
- Manage background app refresh settings

## Performance Considerations

### Battery Optimization
- Use efficient notification scheduling
- Minimize background processing
- Batch notification updates
- Respect system power management

### Memory Management
- Proper disposal of timers and streams
- Efficient countdown widget updates
- Minimize persistent background tasks
- Clean up scheduled notifications when reminders are deleted

## Security Considerations

- Validate notification payloads
- Secure handling of reminder data in notifications
- Proper permission checks before scheduling
- Safe handling of deep links from notifications