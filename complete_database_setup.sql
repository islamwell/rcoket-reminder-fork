-- Complete Database Setup for Kiro Reminder App
-- This script creates all tables with the exact column names the app expects
-- Run this in Supabase SQL Editor

-- =====================================================
-- 1. DROP EXISTING TABLES (if you want a fresh start)
-- =====================================================
DROP TABLE IF EXISTS reminders CASCADE;
DROP TABLE IF EXISTS completions CASCADE;
DROP TABLE IF EXISTS ratings CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS completion_feedback CASCADE;

-- =====================================================
-- 2. CREATE PROFILES TABLE
-- =====================================================
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  email TEXT,
  profile_picture TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. CREATE KIRO_REMINDERS TABLE (Main reminders table)
-- =====================================================
CREATE TABLE kiro_reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Basic reminder info
  title TEXT NOT NULL,
  category TEXT,
  description TEXT,
  
  -- Scheduling info
  frequency JSONB NOT NULL,
  time TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  
  -- Audio settings
  "selectedAudio" JSONB,
  
  -- Notification settings
  "enableNotifications" BOOLEAN DEFAULT TRUE,
  "repeatLimit" INTEGER DEFAULT 0,
  
  -- Tracking info
  "completionCount" INTEGER DEFAULT 0,
  "nextOccurrence" TEXT,
  "nextOccurrenceDateTime" TIMESTAMPTZ,
  
  -- Timestamps
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "lastCompleted" TIMESTAMPTZ,
  "completedAt" TIMESTAMPTZ,
  "snoozedAt" TIMESTAMPTZ,
  
  -- Legacy compatibility columns (if needed)
  scheduled_time TIMESTAMPTZ,
  is_completed BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 4. CREATE COMPLETIONS TABLE (Completion tracking)
-- =====================================================
CREATE TABLE completions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Reminder reference
  reminder_id UUID REFERENCES kiro_reminders(id) ON DELETE CASCADE NOT NULL,
  reminder_title TEXT NOT NULL,
  reminder_category TEXT,
  
  -- Completion details
  completion_notes TEXT,
  actual_duration_minutes INTEGER,
  mood TEXT,
  satisfaction_rating INTEGER,
  
  -- Timestamps
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 5. CREATE RATINGS TABLE (User ratings/feedback)
-- =====================================================
CREATE TABLE ratings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Rating details
  reminder_id UUID REFERENCES kiro_reminders(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL,
  feedback_text TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 6. CREATE COMPLETION_FEEDBACK TABLE (Detailed feedback)
-- =====================================================
CREATE TABLE completion_feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Reminder reference
  reminder_id UUID REFERENCES kiro_reminders(id) ON DELETE CASCADE,
  reminder_title TEXT,
  reminder_category TEXT,
  
  -- Feedback details
  rating INTEGER,
  mood INTEGER,
  mood_before TEXT,
  mood_after TEXT,
  satisfaction_rating INTEGER,
  completion_notes TEXT,
  actual_duration_minutes INTEGER,
  
  -- Experience tracking
  difficulty_level INTEGER,
  enjoyment_level INTEGER,
  impact_rating INTEGER,
  
  -- Timestamps
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 7. ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiro_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE completion_feedback ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 8. CREATE RLS POLICIES
-- =====================================================

-- Profiles policies
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- Kiro_reminders policies
CREATE POLICY "Users can view own reminders" ON kiro_reminders
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own reminders" ON kiro_reminders
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reminders" ON kiro_reminders
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reminders" ON kiro_reminders
  FOR DELETE USING (auth.uid() = user_id);

-- Completions policies
CREATE POLICY "Users can view own completions" ON completions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own completions" ON completions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own completions" ON completions
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own completions" ON completions
  FOR DELETE USING (auth.uid() = user_id);

-- Ratings policies
CREATE POLICY "Users can view own ratings" ON ratings
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own ratings" ON ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own ratings" ON ratings
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own ratings" ON ratings
  FOR DELETE USING (auth.uid() = user_id);

-- Completion_feedback policies
CREATE POLICY "Users can view own feedback" ON completion_feedback
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own feedback" ON completion_feedback
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own feedback" ON completion_feedback
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own feedback" ON completion_feedback
  FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 9. CREATE TRIGGERS FOR AUTOMATIC PROFILE CREATION
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, name, email, created_at)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    NEW.email,
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 10. CREATE UPDATED_AT TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
DROP TRIGGER IF EXISTS on_profile_updated ON profiles;
CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_reminder_updated ON kiro_reminders;
CREATE TRIGGER on_reminder_updated
  BEFORE UPDATE ON kiro_reminders
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =====================================================
-- 11. GRANT PERMISSIONS
-- =====================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.profiles TO anon, authenticated;
GRANT ALL ON public.kiro_reminders TO anon, authenticated;
GRANT ALL ON public.completions TO anon, authenticated;
GRANT ALL ON public.ratings TO anon, authenticated;
GRANT ALL ON public.completion_feedback TO anon, authenticated;

-- =====================================================
-- 12. CREATE INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX idx_kiro_reminders_user_id ON kiro_reminders(user_id);
CREATE INDEX idx_kiro_reminders_status ON kiro_reminders(status);
CREATE INDEX idx_kiro_reminders_next_occurrence ON kiro_reminders("nextOccurrenceDateTime");
CREATE INDEX idx_completions_user_id ON completions(user_id);
CREATE INDEX idx_completions_reminder_id ON completions(reminder_id);
CREATE INDEX idx_completion_feedback_user_id ON completion_feedback(user_id);

-- =====================================================
-- 13. VERIFICATION QUERIES
-- =====================================================
-- Check that all tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('profiles', 'kiro_reminders', 'completions', 'ratings', 'completion_feedback')
ORDER BY table_name;

-- Check kiro_reminders table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'kiro_reminders' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test insert (will fail due to user_id but shows structure is correct)
/*
INSERT INTO kiro_reminders (
    user_id, title, category, frequency, time, description, status,
    "selectedAudio", "enableNotifications", "repeatLimit", "createdAt",
    "completionCount", "nextOccurrence", "nextOccurrenceDateTime"
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    'Test Reminder',
    'charity',
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