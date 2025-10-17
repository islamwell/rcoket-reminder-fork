-- Fix reminders table structure to match app expectations
-- Run this in Supabase SQL Editor

-- First, let's see what columns we currently have
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'reminders' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Add missing columns (using IF NOT EXISTS equivalent for PostgreSQL)
DO $$ 
BEGIN
    -- Add category column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'category') THEN
        ALTER TABLE reminders ADD COLUMN category TEXT;
    END IF;
    
    -- Add selectedAudio column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'selectedAudio') THEN
        ALTER TABLE reminders ADD COLUMN "selectedAudio" JSONB;
    END IF;
    
    -- Add enableNotifications column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'enableNotifications') THEN
        ALTER TABLE reminders ADD COLUMN "enableNotifications" BOOLEAN DEFAULT TRUE;
    END IF;
    
    -- Add repeatLimit column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'repeatLimit') THEN
        ALTER TABLE reminders ADD COLUMN "repeatLimit" INTEGER DEFAULT 0;
    END IF;
    
    -- Add createdAt column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'createdAt') THEN
        ALTER TABLE reminders ADD COLUMN "createdAt" TIMESTAMPTZ DEFAULT NOW();
    END IF;
    
    -- Add completionCount column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'completionCount') THEN
        ALTER TABLE reminders ADD COLUMN "completionCount" INTEGER DEFAULT 0;
    END IF;
    
    -- Add nextOccurrence column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'nextOccurrence') THEN
        ALTER TABLE reminders ADD COLUMN "nextOccurrence" TEXT;
    END IF;
    
    -- Add nextOccurrenceDateTime column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'nextOccurrenceDateTime') THEN
        ALTER TABLE reminders ADD COLUMN "nextOccurrenceDateTime" TIMESTAMPTZ;
    END IF;
    
    -- Add lastCompleted column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'lastCompleted') THEN
        ALTER TABLE reminders ADD COLUMN "lastCompleted" TIMESTAMPTZ;
    END IF;
    
    -- Add completedAt column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'completedAt') THEN
        ALTER TABLE reminders ADD COLUMN "completedAt" TIMESTAMPTZ;
    END IF;
    
    -- Add snoozedAt column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'reminders' AND column_name = 'snoozedAt') THEN
        ALTER TABLE reminders ADD COLUMN "snoozedAt" TIMESTAMPTZ;
    END IF;
    
END $$;

-- Verify the final structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'reminders' 
AND table_schema = 'public'
ORDER BY ordinal_position;