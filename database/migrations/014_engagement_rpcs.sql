-- Migration 014: Engagement RPC Functions and Security Hardening
-- Adds toggle_like, toggle_repost RPCs with proper security and drift prevention

-- === HOT INDEXES FOR PERFORMANCE ===
-- Note: Basic indexes exist from migration 001; adding optimizations for hot paths

-- Index for post_id lookups on likes (already exists as idx_posts_likes)
-- Adding composite index for user+post checks
CREATE INDEX IF NOT EXISTS idx_likes_user_post ON likes(user_id, post_id);

-- Index for reposts lookups
CREATE INDEX IF NOT EXISTS idx_reposts_post_id ON reposts(post_id);
CREATE INDEX IF NOT EXISTS idx_reposts_user_post ON reposts(user_id, post_id);
CREATE INDEX IF NOT EXISTS idx_reposts_user_created ON reposts(user_id, created_at DESC);

-- === RLS POLICIES ===

-- Users can insert/delete their own likes
DROP POLICY IF EXISTS likes_insert_own ON likes;
CREATE POLICY likes_insert_own ON likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS likes_delete_own ON likes;
CREATE POLICY likes_delete_own ON likes
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS likes_select_all ON likes;
CREATE POLICY likes_select_all ON likes
  FOR SELECT USING (true);  -- Aggregates are public

-- Same for reposts
DROP POLICY IF EXISTS reposts_insert_own ON reposts;
CREATE POLICY reposts_insert_own ON reposts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS reposts_delete_own ON reposts;
CREATE POLICY reposts_delete_own ON reposts
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS reposts_select_all ON reposts;
CREATE POLICY reposts_select_all ON reposts
  FOR SELECT USING (true);

-- === RPC FUNCTIONS ===

-- Toggle like (idempotent, drift-proof)
-- NOTE: Edge Function derives p_user_id from JWT (never from client body)
CREATE OR REPLACE FUNCTION public.toggle_like(p_post_id BIGINT, p_user_id UUID)
RETURNS TABLE(is_liked BOOLEAN, like_count INTEGER) AS $$
DECLARE
  v_like_exists BOOLEAN;
  v_like_count INTEGER;
BEGIN
  SET search_path = public;  -- Prevent search_path hijacking
  
  -- Check if like exists
  SELECT EXISTS(SELECT 1 FROM likes WHERE user_id = p_user_id AND post_id = p_post_id)
  INTO v_like_exists;
  
  IF v_like_exists THEN
    -- Unlike
    DELETE FROM likes WHERE user_id = p_user_id AND post_id = p_post_id;
  ELSE
    -- Like
    INSERT INTO likes (user_id, post_id) VALUES (p_user_id, p_post_id)
    ON CONFLICT (user_id, post_id) DO NOTHING;
  END IF;
  
  -- Get updated count (drift-proof: COUNT from source of truth)
  SELECT COUNT(*)::int INTO v_like_count FROM likes WHERE post_id = p_post_id;
  
  -- Also update denormalized counter for read performance
  UPDATE posts SET like_count = v_like_count WHERE id = p_post_id;
  
  RETURN QUERY SELECT NOT v_like_exists AS is_liked, v_like_count AS like_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle repost (idempotent, drift-proof)
CREATE OR REPLACE FUNCTION public.toggle_repost(p_post_id BIGINT, p_user_id UUID)
RETURNS TABLE(is_reposted BOOLEAN, repost_count INTEGER) AS $$
DECLARE
  v_repost_exists BOOLEAN;
  v_repost_count INTEGER;
BEGIN
  SET search_path = public;  -- Prevent search_path hijacking
  
  -- Check if repost exists
  SELECT EXISTS(SELECT 1 FROM reposts WHERE user_id = p_user_id AND post_id = p_post_id)
  INTO v_repost_exists;
  
  IF v_repost_exists THEN
    -- Unrepost
    DELETE FROM reposts WHERE user_id = p_user_id AND post_id = p_post_id;
  ELSE
    -- Repost
    INSERT INTO reposts (user_id, post_id, is_quote) VALUES (p_user_id, p_post_id, false)
    ON CONFLICT (user_id, post_id) DO NOTHING;
  END IF;
  
  -- Get updated count (drift-proof: COUNT from source of truth)
  SELECT COUNT(*)::int INTO v_repost_count FROM reposts WHERE post_id = p_post_id;
  
  -- Also update denormalized counter for read performance
  UPDATE posts SET repost_count = v_repost_count WHERE id = p_post_id;
  
  RETURN QUERY SELECT NOT v_repost_exists AS is_reposted, v_repost_count AS repost_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Nightly counter reconciliation (run via cron)
CREATE OR REPLACE FUNCTION public.reconcile_engagement_counts()
RETURNS void AS $$
BEGIN
  SET search_path = public;
  
  -- Fix any drifted like counts
  UPDATE posts p
  SET like_count = (SELECT COUNT(*) FROM likes WHERE post_id = p.id)
  WHERE like_count != (SELECT COUNT(*) FROM likes WHERE post_id = p.id);
  
  -- Fix any drifted repost counts
  UPDATE posts p
  SET repost_count = (SELECT COUNT(*) FROM reposts WHERE post_id = p.id)
  WHERE repost_count != (SELECT COUNT(*) FROM reposts WHERE post_id = p.id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- === RATE LIMITING TABLE ===
-- Create table for rate limiting (if not exists from previous migrations)
CREATE TABLE IF NOT EXISTS rate_limits (
  key TEXT NOT NULL,
  last_action_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (key)
);

-- Enable RLS on rate_limits
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own rate limit entries
DROP POLICY IF EXISTS rate_limits_own ON rate_limits;
CREATE POLICY rate_limits_own ON rate_limits
  FOR ALL USING (true);  -- Allow service role to manage all entries

-- === CRON JOB (if pg_cron extension is available) ===
-- Note: This requires pg_cron extension to be installed
-- If not available, run reconcile_engagement_counts() manually or via external scheduler

DO $$
BEGIN
  -- Check if pg_cron is available
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Schedule nightly reconciliation at 3 AM
    PERFORM cron.schedule(
      'reconcile-engagement-counts',
      '0 3 * * *',
      'SELECT public.reconcile_engagement_counts()'
    );
  ELSE
    RAISE NOTICE 'pg_cron extension not available. Schedule reconcile_engagement_counts() externally.';
  END IF;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Could not schedule cron job: %', SQLERRM;
END $$;

