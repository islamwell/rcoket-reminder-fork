# Requirements Document

## Introduction

This feature addresses several UI improvements needed for the post-login screen experience. The changes focus on fixing layout overflow issues, updating greeting text with cultural sensitivity, improving visual design with a new color scheme, and enhancing user interaction with recent activity items.

## Requirements

### Requirement 1

**User Story:** As a user, I want the post-login screen to display properly without layout overflow issues, so that I can view all content clearly without visual distortion.

#### Acceptance Criteria

1. WHEN the post-login screen loads THEN the system SHALL ensure no bottom overflow occurs
2. WHEN measuring layout dimensions THEN the system SHALL fix the 7.7 pixel overflow issue
3. WHEN displaying content THEN all UI elements SHALL fit within the screen boundaries

### Requirement 2

**User Story:** As a Muslim user, I want to see a culturally appropriate greeting, so that I feel welcomed in a way that aligns with my cultural and religious background.

#### Acceptance Criteria

1. WHEN the post-login screen displays THEN the system SHALL show "Assalamo alaykum" instead of "Welcome back"
2. WHEN positioning the greeting THEN the system SHALL move the greeting text up near the settings gear icon
3. WHEN displaying the greeting THEN the system SHALL maintain proper text styling and readability

### Requirement 3

**User Story:** As a user, I want the app to have a more natural and calming visual appearance, so that the interface feels more pleasant and less harsh on my eyes.

#### Acceptance Criteria

1. WHEN the post-login screen loads THEN the system SHALL display a dark green gradient instead of the purple gradient
2. WHEN applying the gradient THEN the system SHALL maintain visual consistency across the interface
3. WHEN users view the screen THEN the dark green gradient SHALL provide appropriate contrast for text readability

### Requirement 5

**User Story:** As a user, I want all UI elements to have consistent and professional styling, so that the app feels polished and visually cohesive.

#### Acceptance Criteria

1. WHEN displaying any boxes or containers THEN the system SHALL apply much darker shadows around all boxes
2. WHEN rendering UI elements THEN the system SHALL ensure all boxes have rounded corners
3. WHEN applying styling THEN the system SHALL maintain consistency across all UI components
4. WHEN users interact with elements THEN the enhanced shadows and rounded corners SHALL provide clear visual hierarchy

### Requirement 4

**User Story:** As a user, I want to tap on recent activity items to view detailed information, so that I can quickly access the full context of my past reminders including ratings, mood, and comments.

#### Acceptance Criteria

1. WHEN a user taps on a recent activity item THEN the system SHALL display the reminder details screen
2. WHEN showing reminder details THEN the system SHALL display the rating information
3. WHEN showing reminder details THEN the system SHALL display the mood information
4. WHEN showing reminder details THEN the system SHALL display any associated comments
5. WHEN displaying details THEN the system SHALL provide a way to navigate back to the recent activity list
6. WHEN no details are available THEN the system SHALL handle the case gracefully with appropriate messaging