# Requirements Document

## Introduction

This feature addresses critical issues with the reminder system where reminders fail to activate when the app is minimized or in power-saving mode, and the time display shows incorrect "in six minutes" information that never updates. The solution will implement proper background processing and accurate time calculations to ensure reminders work reliably regardless of app state.

## Requirements

### Requirement 1

**User Story:** As a user, I want my reminders to trigger even when the app is minimized or my device is in power-saving mode, so that I never miss important reminders.

#### Acceptance Criteria

1. WHEN the app is minimized THEN reminders SHALL still trigger at their scheduled times
2. WHEN the device is in power-saving mode THEN reminders SHALL still trigger at their scheduled times
3. WHEN a reminder triggers in the background THEN the system SHALL display a native notification
4. WHEN a user taps a background notification THEN the app SHALL open and show the reminder dialog
5. IF the app is in the foreground WHEN a reminder triggers THEN the system SHALL show the in-app dialog as currently implemented

### Requirement 2

**User Story:** As a user, I want to see accurate time remaining for my reminders instead of a static "in six minutes" display, so that I know exactly when my next reminder will occur.

#### Acceptance Criteria

1. WHEN viewing the reminder list THEN each reminder SHALL display the actual time remaining until next occurrence
2. WHEN the time remaining changes THEN the display SHALL update automatically every minute
3. WHEN a reminder is set for today THEN it SHALL show "Today at [time]" format
4. WHEN a reminder is set for tomorrow THEN it SHALL show "Tomorrow at [time]" format
5. WHEN a reminder is set for this week THEN it SHALL show "[Day] at [time]" format
6. WHEN a reminder is less than 60 minutes away THEN it SHALL show "In X minutes" format
7. WHEN a reminder is overdue THEN it SHALL show "Overdue" status

### Requirement 3

**User Story:** As a user, I want the app to request necessary permissions for background processing, so that I understand why these permissions are needed and can grant them appropriately.

#### Acceptance Criteria

1. WHEN the app first launches THEN it SHALL request notification permissions
2. WHEN notification permissions are denied THEN the app SHALL explain the impact and provide a way to enable them
3. WHEN the app needs background processing permissions THEN it SHALL request them with clear explanations
4. IF permissions are not granted THEN the app SHALL still function but warn users about limited reminder functionality

### Requirement 4

**User Story:** As a user, I want my hourly reminders to show accurate countdown times instead of always displaying "in six minutes", so that I can track when the next reminder will actually occur.

#### Acceptance Criteria

1. WHEN I create an hourly reminder THEN the next occurrence SHALL be calculated as exactly one hour from the current time
2. WHEN an hourly reminder completes THEN the next occurrence SHALL be recalculated as one hour from the completion time
3. WHEN viewing an hourly reminder THEN it SHALL show the actual minutes remaining until the next hour
4. WHEN the countdown reaches zero THEN the reminder SHALL trigger immediately

### Requirement 5

**User Story:** As a developer, I want the background reminder system to be robust and handle edge cases, so that the system remains reliable under various conditions.

#### Acceptance Criteria

1. WHEN the device restarts THEN active reminders SHALL be rescheduled automatically
2. WHEN the system time changes THEN reminder schedules SHALL be recalculated appropriately
3. WHEN the app is force-closed THEN background reminders SHALL continue to work
4. WHEN multiple reminders are scheduled for the same time THEN all SHALL trigger correctly
5. WHEN the app is updated THEN existing reminder schedules SHALL be preserved