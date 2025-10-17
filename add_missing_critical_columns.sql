-- Add the missing critical columns that the app requires
-- These are essential for the app to work properly

-- Add frequency column (stores how often reminder repeats)
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS frequency JSONB;

-- Add time column (stores time like "14:30")
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS time TEXT;

-- Add status column (stores "active", "paused", "completed")
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';

-- Add description column if missing (though it seems to exist)
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS description TEXT;

-- Verify all columns are now present
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'reminders' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test that we can now insert a reminder with all required fields
-- (This is just a test - don't worry if it fails due to user_id)
/*
INSERT INTO reminders (
    user_id, title, category, frequency, time, description, status,
    "selectedAudio", "enableNotifications", "repeatLimit", "createdAt",
    "completionCount", "nextOccurrence", "nextOccurrenceDateTime"
) VALUES (
    '00000000-0000-0000-0000-000000000000', -- dummy user_id
    'Test Reminder',
    'test',
    '{"type": "daily"}',
    '12:00',
    'Test description',
    'active',
    null,
    true,
    0,
    NOW(),
    0,
    'Today at 12:00',
    NOW() + INTERVAL '1 hour'
);
*/