# Supabase Authentication Troubleshooting Guide

## Current Issues Identified

### 1. Slow Login Performance
**Cause**: The app is trying to fetch user profile data from a `profiles` table that doesn't exist in your Supabase database.

**Solution**: 
- **Quick Fix**: I've updated the code to handle missing profiles table gracefully
- **Proper Fix**: Run the SQL setup script to create the profiles table

### 2. User Not Visible in Supabase Dashboard
**Possible Causes**:
- Email confirmation is disabled but user creation is still failing
- Row Level Security (RLS) policies are hiding users
- Database connection issues

## Immediate Steps to Fix

### Step 1: Check Supabase Dashboard
1. Go to your Supabase dashboard
2. Navigate to **Authentication > Users**
3. Check if `it@nrq.no` appears in the user list
4. If not visible, check the **Settings > Authentication** section

### Step 2: Verify Authentication Settings
1. In Supabase Dashboard, go to **Authentication > Settings**
2. Ensure these settings:
   - **Enable email confirmations**: OFF (since you mentioned you turned it off)
   - **Enable email change confirmations**: OFF
   - **Enable manual linking**: ON (optional)

### Step 3: Run Database Setup (Recommended)
1. Go to **SQL Editor** in your Supabase dashboard
2. Copy and paste the contents of `supabase_setup.sql`
3. Click **Run** to execute the script
4. This will create the `profiles` table and necessary triggers

### Step 4: Test with Debug Script
1. Run the debug script: `dart run debug_auth_test.dart`
2. This will show you exactly what's happening with authentication
3. Look for specific error messages

## Common Issues and Solutions

### Issue: "User already registered" but user not in dashboard
**Cause**: User was created but failed during profile creation
**Solution**: 
```sql
-- Check if user exists in auth.users
SELECT id, email, email_confirmed_at, created_at 
FROM auth.users 
WHERE email = 'it@nrq.no';

-- If user exists, you can delete and recreate:
DELETE FROM auth.users WHERE email = 'it@nrq.no';
```

### Issue: Slow login (taking 10+ seconds)
**Cause**: App waiting for profile table queries to timeout
**Solution**: The updated code now handles this gracefully with faster timeouts

### Issue: Email confirmation redirect to localhost
**Cause**: Default Supabase settings
**Solution**: 
1. Go to **Authentication > URL Configuration**
2. Set **Site URL** to your production URL or `https://jslerlyixschpaefyaft.supabase.co`
3. Add redirect URLs if needed

## Database Schema Check

Run this query in Supabase SQL Editor to check your current setup:

```sql
-- Check if profiles table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'profiles';

-- Check current users
SELECT id, email, email_confirmed_at, created_at 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'profiles';
```

## Testing Authentication Flow

### Test 1: Basic Signup
```dart
// This should work even without profiles table
final response = await supabase.auth.signUp(
  email: 'test@example.com',
  password: 'test123456',
);
```

### Test 2: Basic Login
```dart
// This should be fast now
final response = await supabase.auth.signInWithPassword(
  email: 'test@example.com',
  password: 'test123456',
);
```

## Recommended Actions

1. **Immediate**: The code updates I made should fix the slow login issue
2. **Short-term**: Run the `supabase_setup.sql` script to create proper database structure
3. **Long-term**: Consider implementing proper error handling and user feedback

## Verification Steps

After implementing fixes:

1. Try registering a new user with a different email
2. Check if the user appears in Supabase dashboard immediately
3. Try logging in - should be much faster now
4. Check the app logs for any remaining warnings

## Contact Points

If issues persist:
1. Check Supabase logs in Dashboard > Logs
2. Run the debug script and share the output
3. Check browser network tab for API call details
4. Verify your Supabase project URL and anon key are correct

## Notes

- The app now works without the profiles table (basic functionality)
- Profile features will be limited until the database is properly set up
- All changes maintain backward compatibility
- Users created before the fix should still work after the database setup