# Fullscreen Reminder Testing Instructions

## Overview
This document provides comprehensive instructions for testing the fullscreen reminder functionality after the recent fixes.

## What Was Fixed

### Issues Identified and Resolved:

1. **Missing Full Screen Intent Permission**
   - Added `USE_FULL_SCREEN_INTENT` permission to AndroidManifest.xml
   - This permission is required for Android to show fullscreen notifications on lock screen

2. **Incomplete Notification Configuration**
   - Added `fullScreenIntent: true` flag
   - Set notification category to `ALARM` for high-priority behavior
   - Increased importance and priority to `MAX`
   - Added `visibility: public` to show on lock screen
   - Set `autoCancel: false` and `ongoing: true` for persistent notifications

3. **Missing Notification Channel**
   - Created explicit notification channel with MAX importance
   - Enabled sound, vibration, and lights for better visibility

## Testing Methods

### Method 1: Using the Test Screen (Recommended)

The app now includes a dedicated test screen for verifying fullscreen reminders:

**To access the test screen:**
1. Add the test screen to your app routes (if not already added)
2. Navigate to Settings > Reminder Test Utilities
3. Use the UI to create and test reminders

**Test Screen Features:**
- ✅ Check notification status and permissions
- ✅ Create test reminders with configurable delays (10s, 30s, 60s)
- ✅ Manually trigger reminders instantly
- ✅ Request permissions
- ✅ Delete test reminders
- ✅ Print comprehensive test reports

### Method 2: Using Code

You can programmatically test reminders using the `ReminderTestHelper`:

```dart
import 'package:your_app/core/services/reminder_test_helper.dart';

// Create a test reminder that triggers in 10 seconds
final testHelper = ReminderTestHelper.instance;
await testHelper.createTestReminder(
  title: 'Test Fullscreen Reminder',
  category: 'Test',
  delaySeconds: 10,
);

// Check notification status
final status = await testHelper.checkNotificationStatus();
print('Notifications enabled: ${status['notificationsEnabled']}');

// Print comprehensive test report
await testHelper.printTestReport();
```

### Method 3: Manual Testing

1. **Create a Regular Reminder:**
   - Open the app
   - Create a new reminder with a time 1-2 minutes in the future
   - Save the reminder

2. **Test Background Behavior:**
   - Lock your device or press home button
   - Wait for the reminder time
   - A fullscreen notification should appear

3. **Test Foreground Behavior:**
   - Keep the app open and in foreground
   - Wait for the reminder time
   - A fullscreen dialog should appear immediately

## What to Verify

### ✅ Fullscreen Notification Checklist

When testing, verify the following:

- [ ] **Permission Status**: Notification permissions are granted
- [ ] **Lock Screen**: Notification appears on lock screen when device is locked
- [ ] **Background**: Notification appears when app is in background
- [ ] **Foreground**: Dialog appears immediately when app is in foreground
- [ ] **Visual Priority**: Notification has high visual prominence (not a small banner)
- [ ] **Sound**: Notification plays sound (even if phone is on silent/DND)
- [ ] **Vibration**: Device vibrates when notification appears
- [ ] **Interaction**: User can interact with the notification buttons
- [ ] **Persistence**: Notification doesn't auto-dismiss (requires user action)

## Expected Behavior

### When App is in Foreground:
- ✅ Animated fullscreen dialog appears immediately
- ✅ Audio plays (bypasses silent mode)
- ✅ Dialog is non-dismissible (user must interact)
- ✅ Three action buttons: "Mark as Done", "Skip", "Complete Later"

### When App is in Background/Locked:
- ✅ Fullscreen notification appears on lock screen
- ✅ High-priority visual treatment (covers screen)
- ✅ Sound and vibration even in DND mode
- ✅ Tapping notification opens the fullscreen dialog
- ✅ Notification is persistent (doesn't auto-dismiss)

## Debug Logging

The app now includes enhanced debug logging. Check the console/logcat for:

```
DEBUG: ✓ Notification channel created with MAX importance
DEBUG: ✓ Full screen intent enabled
DEBUG: ✓ Permissions requested: true
DEBUG: ✓ Scheduled FULLSCREEN notification for reminder [ID]
DEBUG:   - Scheduled time: [TIME]
DEBUG:   - Importance: MAX
DEBUG:   - Priority: MAX
DEBUG:   - Full screen intent: ENABLED
DEBUG:   - Category: ALARM
```

## Troubleshooting

### Issue: Notification appears as small banner instead of fullscreen

**Solution:**
1. Check that app has notification permissions
2. Verify USE_FULL_SCREEN_INTENT permission is granted
3. On Android 12+, check Settings > Apps > [App Name] > Notifications > Full screen notifications is enabled

### Issue: No notification appears at all

**Solution:**
1. Use ReminderTestHelper to check notification status
2. Verify permissions are granted
3. Check logcat for error messages
4. Try creating a test reminder with 10s delay and observe logs

### Issue: Notification appears but no sound

**Solution:**
1. Check device is not in silent mode (audio should bypass silent mode)
2. Verify notification channel settings in Android system settings
3. Check app has MODIFY_AUDIO_SETTINGS permission

### Issue: Notification doesn't appear on lock screen

**Solution:**
1. Verify notification visibility is set to PUBLIC
2. Check device lock screen notification settings
3. Ensure USE_FULL_SCREEN_INTENT permission is granted

## Android Version Considerations

### Android 12 and above (API 31+):
- Requires explicit USE_FULL_SCREEN_INTENT permission ✅ (Added)
- User may need to manually enable "Full screen notifications" in app settings
- Check Settings > Apps > [App Name] > Notifications > Full screen notifications

### Android 10-11 (API 29-30):
- Full screen intent works automatically with permission ✅
- No additional user action required

### Android 9 and below (API 28 and below):
- Full screen intent works with standard notification permissions ✅

## Testing Scenarios

### Scenario 1: Quick Test (10 seconds)
```dart
await ReminderTestHelper.instance.createTestReminder(delaySeconds: 10);
// Lock device and wait 10 seconds
```

### Scenario 2: Realistic Test (60 seconds)
```dart
await ReminderTestHelper.instance.createTestReminder(delaySeconds: 60);
// Use app normally or lock device
```

### Scenario 3: Immediate Trigger
```dart
await ReminderTestHelper.instance.triggerFirstActiveReminder();
// Should show dialog immediately
```

### Scenario 4: Comprehensive Status Check
```dart
await ReminderTestHelper.instance.printTestReport();
// Check console for detailed status report
```

## Files Modified

The following files were modified to implement fullscreen reminders:

1. **android/app/src/main/AndroidManifest.xml**
   - Added USE_FULL_SCREEN_INTENT permission

2. **lib/core/services/notification_service.dart**
   - Updated AndroidNotificationDetails with fullscreen flags
   - Added _createNotificationChannel() method
   - Enhanced debug logging

3. **lib/core/services/reminder_test_helper.dart** (NEW)
   - Test utilities for creating and managing test reminders
   - Status checking and reporting

4. **lib/presentation/settings/screens/reminder_test_screen.dart** (NEW)
   - UI screen for testing reminders
   - Visual status indicators
   - Quick action buttons

## Success Criteria

The fullscreen reminder implementation is working correctly when:

✅ All checklist items pass
✅ Debug logs show fullscreen configuration
✅ Users report seeing fullscreen notifications on lock screen
✅ No regression in foreground dialog behavior
✅ Audio plays even in silent/DND mode
✅ Notifications persist until user interaction

## Support

If issues persist after following these instructions:

1. Run comprehensive test report: `ReminderTestHelper.instance.printTestReport()`
2. Check logcat/console for error messages
3. Verify all permissions in Android system settings
4. Test on different Android versions if possible
5. Document specific device model and Android version

## Additional Notes

- **Battery Optimization**: Ensure app is not being restricted by battery optimization
- **Background Restrictions**: Check that app doesn't have background restrictions
- **DND Override**: App should bypass DND for reminders (requires ACCESS_NOTIFICATION_POLICY)
- **Auto-start**: Some devices require auto-start permission for background notifications

---

**Last Updated**: 2025-11-05
**Version**: 1.0
**Status**: Ready for Testing
