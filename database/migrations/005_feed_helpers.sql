-- Migration 005: Feed Helper Functions
-- Helper functions for candidate generation and aggregates refresh

-- === CANDIDATE POSTS FROM AUTHORS ===
-- Returns posts from specific authors in the last N hours
CREATE OR REPLACE FUNCTION public.candidate_posts_from_authors(
  p_author_ids TEXT[], 
  p_since_hours INT
)
RETURNS TABLE (
  post_id UUID, 
  author_id TEXT
)
LANGUAGE sql 
STABLE 
AS $$
  SELECT p.id, p.author_id
  FROM public.posts p
  WHERE p.author_id = ANY (p_author_ids)
    AND p.created_at >= now() - make_interval(hours => p_since_hours)
  ORDER BY p.created_at DESC
  LIMIT 5000
$$;

-- === CANDIDATE QUALITY POOL ===
-- Returns global high-quality recent posts
CREATE OR REPLACE FUNCTION public.candidate_quality_pool(p_limit INT)
RETURNS TABLE (
  post_id UUID, 
  author_id TEXT
)
LANGUAGE sql 
STABLE 
AS $$
  SELECT p.id, p.author_id
  FROM public.posts p
  WHERE p.created_at >= now() - interval '48 hours'
  ORDER BY (
    COALESCE(p.like_count, 0) + 
    4 * COALESCE(p.repost_count, 0) + 
    5 * COALESCE(p.reply_count, 0)
  ) DESC,
  p.created_at DESC
  LIMIT GREATEST(100, LEAST(p_limit, 5000))
$$;

-- === REFRESH POST AGGREGATES ===
-- Refresh the post_aggregates materialized view
CREATE OR REPLACE FUNCTION public.refresh_post_aggregates()
RETURNS VOID 
LANGUAGE SQL 
AS $$
  REFRESH MATERIALIZED VIEW CONCURRENTLY public.post_aggregates;
$$;

