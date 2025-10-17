-- =====================================================
-- COMPLETE KIRO DATABASE SCHEMA
-- All tables with kiro_ prefix for comprehensive data tracking
-- =====================================================

-- Drop existing tables for fresh start
DROP TABLE IF EXISTS kiro_notification_interactions CASCADE;
DROP TABLE IF EXISTS kiro_user_sessions CASCADE;
DROP TABLE IF EXISTS kiro_error_logs CASCADE;
DROP TABLE IF EXISTS kiro_user_preferences CASCADE;
DROP TABLE IF EXISTS kiro_completion_feedback CASCADE;
DROP TABLE IF EXISTS kiro_ratings CASCADE;
DROP TABLE IF EXISTS kiro_completions CASCADE;
DROP TABLE IF EXISTS kiro_reminders CASCADE;
DROP TABLE IF EXISTS kiro_profiles CASCADE;

-- =====================================================
-- 1. KIRO_PROFILES - User profile data
-- =====================================================
CREATE TABLE kiro_profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  email TEXT,
  profile_picture TEXT,
  timezone TEXT DEFAULT 'UTC',
  language TEXT DEFAULT 'en',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  total_login_count INTEGER DEFAULT 0
);

-- =====================================================
-- 2. KIRO_REMINDERS - Main reminders table
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
  status TEXT DEFAULT 'active', -- active, paused, completed, snoozed
  
  -- Audio settings
  "selectedAudio" JSONB,
  
  -- Notification settings
  "enableNotifications" BOOLEAN DEFAULT TRUE,
  "repeatLimit" INTEGER DEFAULT 0,
  
  -- Tracking info
  "completionCount" INTEGER DEFAULT 0,
  "nextOccurrence" TEXT,
  "nextOccurrenceDateTime" TIMESTAMPTZ,
  
  -- Analytics data
  streak INTEGER DEFAULT 0,
  "successRate" DECIMAL(5,2) DEFAULT 0.00,
  total_triggers INTEGER DEFAULT 0,
  total_completions INTEGER DEFAULT 0,
  total_snoozes INTEGER DEFAULT 0,
  total_skips INTEGER DEFAULT 0,
  
  -- Timestamps
  "createdAt" TIMESTAMPTZ DEFAULT NOW(),
  "lastCompleted" TIMESTAMPTZ,
  "completedAt" TIMESTAMPTZ,
  "snoozedAt" TIMESTAMPTZ,
  last_triggered TIMESTAMPTZ,
  
  -- Legacy compatibility columns
  scheduled_time TIMESTAMPTZ,
  is_completed BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. KIRO_COMPLETIONS - Completion tracking
-- =====================================================
CREATE TABLE kiro_completions (
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
  satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
  
  -- Completion context
  completion_method TEXT, -- manual, notification, scheduled
  was_on_time BOOLEAN DEFAULT TRUE,
  delay_minutes INTEGER DEFAULT 0,
  
  -- Timestamps
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 4. KIRO_RATINGS - User ratings and feedback
-- =====================================================
CREATE TABLE kiro_ratings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Rating details
  reminder_id UUID REFERENCES kiro_reminders(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  feedback_text TEXT,
  rating_type TEXT DEFAULT 'general', -- general, difficulty, enjoyment, impact
  
  -- Context
  completion_id UUID REFERENCES kiro_completions(id) ON DELETE SET NULL,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 5. KIRO_COMPLETION_FEEDBACK - Detailed completion feedback
-- =====================================================
CREATE TABLE kiro_completion_feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Reminder reference
  reminder_id UUID REFERENCES kiro_reminders(id) ON DELETE CASCADE,
  reminder_title TEXT,
  reminder_category TEXT,
  
  -- Feedback details
  rating INTEGER CHECK (rating >= 1 AND rating <= 5),
  mood INTEGER CHECK (mood >= 1 AND mood <= 5),
  mood_before TEXT,
  mood_after TEXT,
  satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
  completion_notes TEXT,
  actual_duration_minutes INTEGER,
  
  -- Experience tracking
  difficulty_level INTEGER CHECK (difficulty_level >= 1 AND difficulty_level <= 5),
  enjoyment_level INTEGER CHECK (enjoyment_level >= 1 AND enjoyment_level <= 5),
  impact_rating INTEGER CHECK (impact_rating >= 1 AND impact_rating <= 5),
  
  -- Additional context
  environment TEXT, -- home, work, outdoor, etc.
  energy_level INTEGER CHECK (energy_level >= 1 AND energy_level <= 5),
  motivation_level INTEGER CHECK (motivation_level >= 1 AND motivation_level <= 5),
  
  -- Timestamps
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 6. KIRO_USER_PREFERENCES - User settings and preferences
-- =====================================================
CREATE TABLE kiro_user_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  
  -- Notification preferences
  notification_enabled BOOLEAN DEFAULT TRUE,
  notification_sound TEXT DEFAULT 'default',
  notification_vibration BOOLEAN DEFAULT TRUE,
  quiet_hours_start TIME,
  quiet_hours_end TIME,
  
  -- App preferences
  theme TEXT DEFAULT 'system', -- light, dark, system
  language TEXT DEFAULT 'en',
  timezone TEXT DEFAULT 'UTC',
  
  -- Reminder preferences
  default_reminder_time TIME DEFAULT '09:00',
  default_category TEXT DEFAULT 'general',
  auto_complete_enabled BOOLEAN DEFAULT FALSE,
  snooze_duration_minutes INTEGER DEFAULT 10,
  
  -- Privacy preferences
  analytics_enabled BOOLEAN DEFAULT TRUE,
  crash_reporting_enabled BOOLEAN DEFAULT TRUE,
  
  -- Advanced preferences
  backup_enabled BOOLEAN DEFAULT TRUE,
  sync_enabled BOOLEAN DEFAULT TRUE,
  
  -- Custom preferences (JSON for flexibility)
  custom_settings JSONB DEFAULT '{}',
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 7. KIRO_NOTIFICATION_INTERACTIONS - Track notification responses
-- =====================================================
CREATE TABLE kiro_notification_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Notification details
  reminder_id UUID REFERENCES kiro_reminders(id) ON DELETE CASCADE NOT NULL,
  notification_id TEXT NOT NULL,
  
  -- Interaction details
  action TEXT NOT NULL, -- trigger, snooze, complete, dismiss, skip
  interaction_time TIMESTAMPTZ DEFAULT NOW(),
  response_time_seconds INTEGER, -- time from notification to action
  
  -- Context
  notification_type TEXT, -- scheduled, background, foreground
  device_state TEXT, -- active, background, locked
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 8. KIRO_USER_SESSIONS - Track user app usage
-- =====================================================
CREATE TABLE kiro_user_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  
  -- Session details
  session_start TIMESTAMPTZ DEFAULT NOW(),
  session_end TIMESTAMPTZ,
  duration_seconds INTEGER,
  
  -- Session context
  app_version TEXT,
  device_platform TEXT, -- android, ios, web
  device_model TEXT,
  
  -- Activity tracking
  screens_visited TEXT[], -- array of screen names
  actions_performed TEXT[], -- array of action types
  reminders_created INTEGER DEFAULT 0,
  reminders_completed INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 9. KIRO_ERROR_LOGS - Application error tracking
-- =====================================================
CREATE TABLE kiro_error_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Error details
  error_code TEXT NOT NULL,
  error_message TEXT NOT NULL,
  error_type TEXT NOT NULL, -- validation, network, database, etc.
  severity TEXT NOT NULL, -- info, warning, error, critical
  
  -- Context
  screen_name TEXT,
  action_attempted TEXT,
  user_agent TEXT,
  app_version TEXT,
  
  -- Technical details
  stack_trace TEXT,
  metadata JSONB DEFAULT '{}',
  
  -- Resolution
  resolved BOOLEAN DEFAULT FALSE,
  resolution_notes TEXT,
  
  -- Timestamps
  occurred_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 10. ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================
ALTER TABLE kiro_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiro_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiro_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiro_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiro_completion_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiro_user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiro_notification_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiro_user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE kiro_error_logs ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 11. CREATE RLS POLICIES
-- =====================================================

-- Profiles policies
CREATE POLICY "Users can view own profile" ON kiro_profiles
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON kiro_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON kiro_profiles
  FOR UPDATE USING (auth.uid() = id);

-- Reminders policies
CREATE POLICY "Users can view own reminders" ON kiro_reminders
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own reminders" ON kiro_reminders
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own reminders" ON kiro_reminders
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own reminders" ON kiro_reminders
  FOR DELETE USING (auth.uid() = user_id);

-- Completions policies
CREATE POLICY "Users can view own completions" ON kiro_completions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own completions" ON kiro_completions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own completions" ON kiro_completions
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own completions" ON kiro_completions
  FOR DELETE USING (auth.uid() = user_id);

-- Ratings policies
CREATE POLICY "Users can view own ratings" ON kiro_ratings
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own ratings" ON kiro_ratings
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own ratings" ON kiro_ratings
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own ratings" ON kiro_ratings
  FOR DELETE USING (auth.uid() = user_id);

-- Completion feedback policies
CREATE POLICY "Users can view own feedback" ON kiro_completion_feedback
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own feedback" ON kiro_completion_feedback
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own feedback" ON kiro_completion_feedback
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own feedback" ON kiro_completion_feedback
  FOR DELETE USING (auth.uid() = user_id);

-- User preferences policies
CREATE POLICY "Users can view own preferences" ON kiro_user_preferences
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own preferences" ON kiro_user_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own preferences" ON kiro_user_preferences
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own preferences" ON kiro_user_preferences
  FOR DELETE USING (auth.uid() = user_id);

-- Notification interactions policies
CREATE POLICY "Users can view own interactions" ON kiro_notification_interactions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own interactions" ON kiro_notification_interactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User sessions policies
CREATE POLICY "Users can view own sessions" ON kiro_user_sessions
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own sessions" ON kiro_user_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own sessions" ON kiro_user_sessions
  FOR UPDATE USING (auth.uid() = user_id);

-- Error logs policies (users can only view their own errors)
CREATE POLICY "Users can view own errors" ON kiro_error_logs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own errors" ON kiro_error_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 12. CREATE TRIGGERS FOR AUTOMATIC PROFILE CREATION
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.kiro_profiles (id, name, email, created_at, last_login, total_login_count)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    NEW.email,
    NOW(),
    NOW(),
    1
  );
  
  -- Also create default user preferences
  INSERT INTO public.kiro_user_preferences (user_id, created_at)
  VALUES (NEW.id, NOW());
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 13. CREATE UPDATED_AT TRIGGERS
-- =====================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
DROP TRIGGER IF EXISTS on_profile_updated ON kiro_profiles;
CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON kiro_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_reminder_updated ON kiro_reminders;
CREATE TRIGGER on_reminder_updated
  BEFORE UPDATE ON kiro_reminders
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_preferences_updated ON kiro_user_preferences;
CREATE TRIGGER on_preferences_updated
  BEFORE UPDATE ON kiro_user_preferences
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =====================================================
-- 14. CREATE ANALYTICS TRIGGERS
-- =====================================================

-- Update reminder analytics on completion
CREATE OR REPLACE FUNCTION public.update_reminder_analytics()
RETURNS TRIGGER AS $$
BEGIN
  -- Update completion count and success rate
  UPDATE kiro_reminders 
  SET 
    total_completions = total_completions + 1,
    "completionCount" = "completionCount" + 1,
    "lastCompleted" = NEW.completed_at,
    "successRate" = CASE 
      WHEN total_triggers > 0 THEN (total_completions + 1) * 100.0 / total_triggers
      ELSE 100.0
    END
  WHERE id = NEW.reminder_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_completion_created ON kiro_completions;
CREATE TRIGGER on_completion_created
  AFTER INSERT ON kiro_completions
  FOR EACH ROW EXECUTE FUNCTION public.update_reminder_analytics();

-- Update reminder analytics on notification interaction
CREATE OR REPLACE FUNCTION public.update_interaction_analytics()
RETURNS TRIGGER AS $$
BEGIN
  -- Update counters based on action
  UPDATE kiro_reminders 
  SET 
    total_triggers = CASE WHEN NEW.action = 'trigger' THEN total_triggers + 1 ELSE total_triggers END,
    total_snoozes = CASE WHEN NEW.action = 'snooze' THEN total_snoozes + 1 ELSE total_snoozes END,
    total_skips = CASE WHEN NEW.action IN ('dismiss', 'skip') THEN total_skips + 1 ELSE total_skips END,
    last_triggered = CASE WHEN NEW.action = 'trigger' THEN NEW.interaction_time ELSE last_triggered END
  WHERE id = NEW.reminder_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_interaction_created ON kiro_notification_interactions;
CREATE TRIGGER on_interaction_created
  AFTER INSERT ON kiro_notification_interactions
  FOR EACH ROW EXECUTE FUNCTION public.update_interaction_analytics();

-- =====================================================
-- 15. CREATE PERFORMANCE INDEXES
-- =====================================================

-- Reminders indexes
CREATE INDEX idx_kiro_reminders_user_id ON kiro_reminders(user_id);
CREATE INDEX idx_kiro_reminders_status ON kiro_reminders(status);
CREATE INDEX idx_kiro_reminders_next_occurrence ON kiro_reminders("nextOccurrenceDateTime");
CREATE INDEX idx_kiro_reminders_category ON kiro_reminders(category);
CREATE INDEX idx_kiro_reminders_created_at ON kiro_reminders("createdAt");

-- Completions indexes
CREATE INDEX idx_kiro_completions_user_id ON kiro_completions(user_id);
CREATE INDEX idx_kiro_completions_reminder_id ON kiro_completions(reminder_id);
CREATE INDEX idx_kiro_completions_completed_at ON kiro_completions(completed_at);

-- Feedback indexes
CREATE INDEX idx_kiro_completion_feedback_user_id ON kiro_completion_feedback(user_id);
CREATE INDEX idx_kiro_completion_feedback_reminder_id ON kiro_completion_feedback(reminder_id);

-- Notification interactions indexes
CREATE INDEX idx_kiro_notification_interactions_user_id ON kiro_notification_interactions(user_id);
CREATE INDEX idx_kiro_notification_interactions_reminder_id ON kiro_notification_interactions(reminder_id);
CREATE INDEX idx_kiro_notification_interactions_action ON kiro_notification_interactions(action);
CREATE INDEX idx_kiro_notification_interactions_time ON kiro_notification_interactions(interaction_time);

-- Sessions indexes
CREATE INDEX idx_kiro_user_sessions_user_id ON kiro_user_sessions(user_id);
CREATE INDEX idx_kiro_user_sessions_start ON kiro_user_sessions(session_start);

-- Error logs indexes
CREATE INDEX idx_kiro_error_logs_user_id ON kiro_error_logs(user_id);
CREATE INDEX idx_kiro_error_logs_severity ON kiro_error_logs(severity);
CREATE INDEX idx_kiro_error_logs_occurred_at ON kiro_error_logs(occurred_at);

-- =====================================================
-- 16. GRANT PERMISSIONS
-- =====================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.kiro_profiles TO anon, authenticated;
GRANT ALL ON public.kiro_reminders TO anon, authenticated;
GRANT ALL ON public.kiro_completions TO anon, authenticated;
GRANT ALL ON public.kiro_ratings TO anon, authenticated;
GRANT ALL ON public.kiro_completion_feedback TO anon, authenticated;
GRANT ALL ON public.kiro_user_preferences TO anon, authenticated;
GRANT ALL ON public.kiro_notification_interactions TO anon, authenticated;
GRANT ALL ON public.kiro_user_sessions TO anon, authenticated;
GRANT ALL ON public.kiro_error_logs TO anon, authenticated;

-- =====================================================
-- 17. CREATE DASHBOARD ANALYTICS VIEWS
-- =====================================================

-- User dashboard stats view
CREATE OR REPLACE VIEW kiro_user_dashboard_stats AS
SELECT 
  r.user_id,
  COUNT(*) as total_reminders,
  COUNT(*) FILTER (WHERE r.status = 'active') as active_reminders,
  COUNT(*) FILTER (WHERE r.status = 'completed') as completed_reminders,
  COUNT(*) FILTER (WHERE r.status = 'paused') as paused_reminders,
  COUNT(*) FILTER (WHERE r.status = 'snoozed') as snoozed_reminders,
  SUM(r.total_completions) as total_completions,
  SUM(r.total_snoozes) as total_snoozes,
  SUM(r.total_skips) as total_skips,
  AVG(r."successRate") as avg_success_rate,
  MAX(r.streak) as best_streak,
  COUNT(*) FILTER (WHERE DATE(r."lastCompleted") = CURRENT_DATE) as completed_today,
  COUNT(*) FILTER (WHERE DATE(r."createdAt") >= CURRENT_DATE - INTERVAL '7 days') as created_this_week
FROM kiro_reminders r
GROUP BY r.user_id;

-- User activity summary view
CREATE OR REPLACE VIEW kiro_user_activity_summary AS
SELECT 
  u.id as user_id,
  p.name,
  p.email,
  p.total_login_count,
  p.last_login,
  COALESCE(ds.total_reminders, 0) as total_reminders,
  COALESCE(ds.active_reminders, 0) as active_reminders,
  COALESCE(ds.total_completions, 0) as total_completions,
  COALESCE(ds.avg_success_rate, 0) as avg_success_rate,
  COALESCE(ds.best_streak, 0) as best_streak,
  COALESCE(ds.completed_today, 0) as completed_today
FROM auth.users u
LEFT JOIN kiro_profiles p ON u.id = p.id
LEFT JOIN kiro_user_dashboard_stats ds ON u.id = ds.user_id;

-- =====================================================
-- 18. VERIFICATION QUERIES
-- =====================================================

-- List all created tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'kiro_%'
ORDER BY table_name;

-- Check kiro_reminders structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'kiro_reminders' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Test dashboard stats view
-- SELECT * FROM kiro_user_dashboard_stats LIMIT 5;

-- Test user activity view  
-- SELECT * FROM kiro_user_activity_summary LIMIT 5;