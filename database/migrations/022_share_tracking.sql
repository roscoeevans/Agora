-- Migration 022: Share Tracking
-- Adds share tracking similar to likes, but idempotent (one share per user per post)

-- === ADD 'share' TO event_type ENUM ===
-- Note: PostgreSQL doesn't support IF NOT EXISTS for ADD VALUE
-- This will error if 'share' already exists, which is safe to ignore
DO $$ BEGIN
  ALTER TYPE event_type ADD VALUE 'share';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- === SHARES TABLE ===
CREATE TABLE IF NOT EXISTS shares (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, post_id)
);

-- Enable RLS on shares
ALTER TABLE shares ENABLE ROW LEVEL SECURITY;

-- RLS Policies for shares
DROP POLICY IF EXISTS shares_insert_own ON shares;
CREATE POLICY shares_insert_own ON shares
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS shares_select_all ON shares;
CREATE POLICY shares_select_all ON shares
  FOR SELECT USING (true);  -- Aggregates are public

-- === SHARE COUNT COLUMN ===
-- Add share_count to posts table
ALTER TABLE posts ADD COLUMN IF NOT EXISTS share_count INT NOT NULL DEFAULT 0;

-- === INDEXES FOR PERFORMANCE ===
CREATE INDEX IF NOT EXISTS idx_shares_post_id ON shares(post_id);
CREATE INDEX IF NOT EXISTS idx_shares_user_post ON shares(user_id, post_id);

-- === COUNT TRIGGER ===
-- Trigger function to maintain share_count
CREATE OR REPLACE FUNCTION public.bump_share_count() 
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts 
    SET share_count = COALESCE(share_count, 0) + 1 
    WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts 
    SET share_count = GREATEST(COALESCE(share_count, 0) - 1, 0) 
    WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END; 
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_bump_share_count_ins ON public.shares;
CREATE TRIGGER trg_bump_share_count_ins
  AFTER INSERT ON public.shares 
  FOR EACH ROW EXECUTE FUNCTION public.bump_share_count();

DROP TRIGGER IF EXISTS trg_bump_share_count_del ON public.shares;
CREATE TRIGGER trg_bump_share_count_del
  AFTER DELETE ON public.shares 
  FOR EACH ROW EXECUTE FUNCTION public.bump_share_count();

-- === RPC FUNCTION ===
-- Record share (idempotent - won't duplicate if already shared)
-- Returns share_count after recording
CREATE OR REPLACE FUNCTION public.record_share(p_post_id UUID, p_user_id UUID)
RETURNS TABLE(share_count INTEGER) AS $$
DECLARE
  v_share_exists BOOLEAN;
  v_share_count INTEGER;
BEGIN
  SET search_path = public;  -- Prevent search_path hijacking
  
  -- Check if post exists first
  IF NOT EXISTS (SELECT 1 FROM posts WHERE id = p_post_id) THEN
    RAISE EXCEPTION 'Post not found';
  END IF;
  
  -- Check if share already exists
  SELECT EXISTS(SELECT 1 FROM shares WHERE user_id = p_user_id AND post_id = p_post_id)
  INTO v_share_exists;
  
  -- Only insert if not already shared (idempotent)
  IF NOT v_share_exists THEN
    INSERT INTO shares (user_id, post_id) VALUES (p_user_id, p_post_id)
    ON CONFLICT (user_id, post_id) DO NOTHING;
  END IF;
  
  -- Get updated count (drift-proof: COUNT from source of truth)
  SELECT COUNT(*)::int INTO v_share_count FROM shares WHERE post_id = p_post_id;
  
  -- Also update denormalized counter for read performance
  UPDATE posts SET share_count = v_share_count WHERE id = p_post_id;
  
  RETURN QUERY SELECT v_share_count AS share_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- === UPDATE RECONCILIATION FUNCTION ===
-- Add share_count reconciliation to existing reconcile_engagement_counts function
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
  
  -- Fix any drifted share counts
  UPDATE posts p
  SET share_count = (SELECT COUNT(*) FROM shares WHERE post_id = p.id)
  WHERE share_count != (SELECT COUNT(*) FROM shares WHERE post_id = p.id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

