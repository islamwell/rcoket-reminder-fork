-- Check what columns currently exist in the reminders table
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'reminders' 
AND table_schema = 'public'
ORDER BY ordinal_position;
