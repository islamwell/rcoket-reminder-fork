-- Simple script to create reminders table
-- Copy and paste this into Supabase SQL Editor and click RUN

-- 1. Create reminders table
CREATE TABLE IF NOT EXISTS reminders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  category TEXT,
  frequency JSONB,
  time TEXT,
  description TEXT,
  selected_audio JSONB,
  enable_notifications BOOLEAN DEFAULT TRUE,
  repeat_limit INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completion_count INTEGER DEFAULT 0,
  next_occurrence TEXT,
  next_occurrence_date_time TIMESTAMPTZ,
  last_completed TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  snoozed_at TIMESTAMPTZ
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- 3. Create policies for reminders table
CREATE POLICY "Users can view own reminders" ON reminders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own reminders" ON reminders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reminders" ON reminders
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reminders" ON reminders
  FOR DELETE USING (auth.uid() = user_id);

-- 4. Grant permissions
GRANT ALL ON reminders TO authenticated;

-- 5. Test query (optional - you can run this to verify)
-- SELECT COUNT(*) FROM reminders;