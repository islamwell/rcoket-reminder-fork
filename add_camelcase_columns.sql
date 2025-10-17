-- Add the camelCase columns that the app expects
-- This will work alongside the existing snake_case columns

-- Add missing camelCase columns
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "selectedAudio" JSONB;
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "enableNotifications" BOOLEAN DEFAULT TRUE;
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "repeatLimit" INTEGER DEFAULT 0;
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMPTZ DEFAULT NOW();
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "completionCount" INTEGER DEFAULT 0;
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "nextOccurrence" TEXT;
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "nextOccurrenceDateTime" TIMESTAMPTZ;
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "lastCompleted" TIMESTAMPTZ;
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "completedAt" TIMESTAMPTZ;
ALTER TABLE reminders ADD COLUMN IF NOT EXISTS "snoozedAt" TIMESTAMPTZ;

-- Verify the columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'reminders' 
AND table_schema = 'public'
ORDER BY ordinal_position;