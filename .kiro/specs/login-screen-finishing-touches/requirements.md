# Requirements Document

## Introduction

This feature focuses on finalizing the login screen with UI improvements, backend integration with Supabase, and replacing sample data with persistent data storage. The changes include repositioning UI elements, updating branding elements, and implementing proper data persistence.

## Requirements

### Requirement 1

**User Story:** As a user, I want to see a "Guest" option prominently displayed at the top of the login screen, so that I can quickly access the app without creating an account.

#### Acceptance Criteria

1. WHEN the login screen loads THEN the system SHALL display a "Guest" button in the top row next to the "Sign Up" button
2. WHEN a user clicks the "Guest" button THEN the system SHALL navigate to the main app without requiring authentication
3. WHEN the login screen is displayed THEN the system SHALL maintain the existing "Login" button at the bottom of the screen unchanged

### Requirement 2

**User Story:** As a developer, I want to integrate Supabase as the backend service and maintain a Firebase configuration file for potential future switching, so that the app has reliable data persistence with flexibility for backend changes.

#### Acceptance Criteria

1. WHEN the app initializes THEN the system SHALL connect to Supabase using the provided credentials
2. WHEN data operations are performed THEN the system SHALL use Supabase for all backend operations
3. WHEN the project is set up THEN the system SHALL include a Firebase configuration file for potential future use
4. WHEN backend operations are implemented THEN the system SHALL use a service layer that could be adapted for different backends

### Requirement 3

**User Story:** As a user, I want all sample and test data removed from the app, so that I start with a clean slate and only see my actual data.

#### Acceptance Criteria

1. WHEN the app loads THEN the system SHALL NOT display any hardcoded sample data
2. WHEN a new user accesses the app THEN the system SHALL show empty states instead of test data
3. WHEN data is retrieved from the backend THEN the system SHALL only display actual user data from the persistent storage
4. WHEN the app is reset or reinstalled THEN the system SHALL maintain user data through the backend service

### Requirement 4

**User Story:** As a user, I want to see the custom app icon instead of a generic icon, so that the app has proper branding and visual identity.

#### Acceptance Criteria

1. WHEN the login screen loads THEN the system SHALL display the custom icon from "assets/images/img_app_logo.svg" with PNG fallback
2. WHEN the icon is displayed THEN the system SHALL maintain proper aspect ratio and sizing
3. WHEN the app is launched THEN the system SHALL use the custom icon consistently throughout the application

### Requirement 5

**User Story:** As a user, I want to see inspiring Islamic quotes that scroll automatically, so that I feel motivated and connected to my spiritual goals.

#### Acceptance Criteria

1. WHEN the login screen loads THEN the system SHALL display "Whoever has done an atom's weight of good will see it. 99:7" as the initial text
2. WHEN the initial text is displayed THEN the system SHALL automatically scroll to show "And remind, for the reminder benefits the believers. 51:55"
3. WHEN the text scrolling completes THEN the system SHALL continue cycling between the two quotes
4. WHEN the text is displayed THEN the system SHALL replace the current "stay connected with your spiritual goals" text
5. WHEN the scrolling animation occurs THEN the system SHALL provide smooth transitions between the quotes