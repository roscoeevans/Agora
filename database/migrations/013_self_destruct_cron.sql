-- Migration 013: Self-Destruct Cron Job
-- Sets up automated deletion of posts that have reached their self_destruct_at time

-- Enable pg_cron extension if not already enabled
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Create function to delete expired posts
CREATE OR REPLACE FUNCTION delete_expired_posts()
RETURNS void AS $$
DECLARE
  expired_post RECORD;
  deleted_count INT := 0;
BEGIN
  -- Find all posts that have reached their self-destruct time
  FOR expired_post IN 
    SELECT id, author_id, text
    FROM public.posts 
    WHERE self_destruct_at IS NOT NULL 
      AND self_destruct_at <= NOW()
    LIMIT 100 -- Process in batches to avoid long transactions
  LOOP
    -- Delete the post (cascades to post_edits, likes, reposts, etc.)
    DELETE FROM public.posts WHERE id = expired_post.id;
    
    deleted_count := deleted_count + 1;
    
    -- TODO: Send push notification to author
    -- This requires OneSignal integration
    -- For now, we just log the deletion
    RAISE NOTICE 'Deleted post % for user %', expired_post.id, expired_post.author_id;
  END LOOP;
  
  IF deleted_count > 0 THEN
    RAISE NOTICE 'Self-destruct: deleted % posts', deleted_count;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Set proper search path for security
ALTER FUNCTION delete_expired_posts() SET search_path = public, pg_temp;

-- Grant execute permission to postgres role
GRANT EXECUTE ON FUNCTION delete_expired_posts() TO postgres;

-- Schedule cron job to run every 5 minutes
-- Job name: delete-expired-posts
-- Schedule: */5 * * * * (every 5 minutes)
SELECT cron.schedule(
  'delete-expired-posts',
  '*/5 * * * *',
  $$SELECT delete_expired_posts();$$
);

-- To view scheduled jobs:
-- SELECT * FROM cron.job;

-- To unschedule the job (if needed):
-- SELECT cron.unschedule('delete-expired-posts');

COMMENT ON FUNCTION delete_expired_posts IS 'Deletes posts that have reached their self_destruct_at timestamp. Runs every 5 minutes via pg_cron.';

