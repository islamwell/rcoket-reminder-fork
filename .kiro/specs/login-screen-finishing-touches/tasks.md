# Implementation Plan

- [x] 1. Set up Supabase integration and environment configuration



  - Add Supabase Flutter SDK dependency to pubspec.yaml
  - Create environment configuration file for Supabase credentials
  - Initialize Supabase client in main.dart
  - Create Firebase configuration file for future switching capability
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 2. Update login screen UI layout and components





- [x] 2.1 Restructure top row buttons layout


  - Modify _buildAuthToggle() method to move Guest button to top row
  - Update button layout to show "Guest" and "Sign Up" in first row
  - Ensure Login button at bottom remains unchanged
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 2.2 Replace app icon with custom SVG asset


  - Update _buildLogo() method to use SvgPicture.asset with img_app_logo.svg
  - Implement PNG fallback for cases where SVG fails to load
  - Maintain existing sizing and styling properties
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 2.3 Implement scrolling Islamic quotes widget


  - Create ScrollingQuoteWidget as a stateful widget with animation controller
  - Implement automatic text scrolling between the two Islamic quotes
  - Replace existing subtitle text with the new scrolling quotes component
  - Add smooth transition animations between quote changes
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [-] 3. Create enhanced backend service layer


- [x] 3.1 Implement SupabaseService class


  - Create SupabaseService with authentication methods (signIn, signUp, signOut)
  - Implement user data retrieval and management methods
  - Add error handling for Supabase-specific exceptions
  - Write unit tests for SupabaseService methods
  - _Requirements: 2.1, 2.2_
-

- [x] 3.2 Update AuthService to integrate with Supabase




  - Modify existing AuthService to use SupabaseService for backend operations
  - Update login() method to authenticate through Supabase
  - Update register() method to create users in Supabase
  - Maintain guest mode functionality with local storage
  - _Requirements: 2.1, 2.2, 2.4_

- [x] 3.3 Implement user data synchronization



  - Create methods to sync user data between Supabase and local storage
  - Implement offline caching for user authentication state
  - Add data migration utilities for existing local user data
  - Write integration tests for data synchronization flows
  - _Requirements: 2.2, 2.4_

- [x] 4. Remove sample data and implement persistent storage




- [x] 4.1 Clean up hardcoded sample data







  - Remove all hardcoded test data from AuthService
  - Update services to use empty states when no real data exists
  - Remove sample user generation logic
  - _Requirements: 3.1, 3.2, 3.3_
- [x] 4.2 Update data storage to use Supabase backend



- [x] 4.2 Update data storage to use Supabase backend



  - Modify reminder storage service to use Supabase for persistence
  - Update user preferences to sync with backend
  - Implement proper data validation for backend operations
  - _Requirements: 3.3, 3.4_

- [x] 4.3 Implement offline data handling







  - Create offline data manager for caching critical user data
  - Add sync mechanisms for when connectivity is restored
  - Implement conflict resolution for offline/online data differences
  - Write tests for offline data scenarios
  - _Requirements: 3.4_

- [x] 5. Add error handling and user feedback




- [x] 5.1 Implement backend error handling







  - Create BackendErrorHandler class for Supabase operation error management
  - Add user-friendly error messages for authentication failures
  - Implement retry logic with exponential backoff for network issues
  - _Requirements: 2.1, 2.2_

- [x] 5.2 Update UI error states and loading indicators






  - Add loading states for Supabase authentication operations
  - Update error message display for backend-specific errors
  - Implement proper error recovery flows in the login screen
  - _Requirements: 1.2, 2.1_










- [ ] 6. Write comprehensive tests for new functionality

- [ ] 6.1 Create unit tests for new components



  - Write tests for ScrollingQuoteWidget animation behavior
  - Test SupabaseService authentication methods with mocked responses
  - Create tests for environment configuration loading
  - _Requirements: 5.5, 2.1_



- [ ] 6.2 Write integration tests for authentication flows



  - Test complete login flow with Supabase backend
  - Test registration flow with user data persistence
  - Test guest mode functionality with local storage
  - _Requirements: 1.1, 1.2, 2.1, 2.2_

- [ ] 6.3 Create widget tests for UI components


  - Test login screen layout with repositioned buttons
  - Test custom icon display with SVG and PNG fallback
  - Test scrolling quotes widget transitions and timing
  - _Requirements: 1.1, 4.1, 5.5_