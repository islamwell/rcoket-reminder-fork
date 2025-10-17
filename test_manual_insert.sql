-- Test manual reminder insert
-- Replace 'YOUR_USER_ID_HERE' with the actual user ID from Authentication > Users

INSERT INTO reminders (
  user_id,
  title,
  category,
  frequency,
  time,
  description,
  status,
  created_at,
  completion_count,
  next_occurrence
) VALUES (
  'beb3ce79-2267-47f3-8bf5-a8c1989ec08b',  -- Replace with actual user ID
  'Test Manual Reminder',
  'test',
  '{"type": "daily"}',
  '12:00',
  'Manual test reminder',
  'active',
  NOW(),
  0,
  'Today at 12:00'
);

-- Check if it was inserted
SELECT * FROM reminders WHERE title = 'Test Manual Reminder';