-- Migration 003: Feed Foundation
-- Creates tables for impressions, events, aggregates, and graph proximity

-- === ENUMS ===
DO $$ BEGIN
  CREATE TYPE event_type AS ENUM (
    'impression','view','like','unlike','comment','repost','expand',
    'profile_visit','follow_after_view','hide','mute','block'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- === IMPRESSIONS (7-day suppression, 90-day retention) ===
CREATE TABLE IF NOT EXISTS public.post_impressions (
  user_id      UUID        NOT NULL,
  post_id      UUID        NOT NULL,
  impression_id UUID       NOT NULL DEFAULT gen_random_uuid(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  page_id      UUID        NULL,
  position     INT         NULL,
  reasons      JSONB       NULL,
  PRIMARY KEY (user_id, post_id, created_at)
);

CREATE INDEX IF NOT EXISTS idx_post_impressions_user_created
  ON public.post_impressions (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_impressions_post
  ON public.post_impressions (post_id);
CREATE INDEX IF NOT EXISTS idx_post_impressions_page
  ON public.post_impressions (page_id);

-- === GENERIC EVENT LOG (trust-weight later) ===
CREATE TABLE IF NOT EXISTS public.post_events (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL,
  post_id      UUID        NOT NULL,
  type         event_type  NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  dwell_ms     INTEGER     NULL,
  meta         JSONB       NULL
);

CREATE INDEX IF NOT EXISTS idx_post_events_post_type_time
  ON public.post_events (post_id, type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_events_user_time
  ON public.post_events (user_id, created_at DESC);

-- === AUTHOR/USER PROXIMITY (lightweight graph cache) ===
CREATE TABLE IF NOT EXISTS public.graph_proximity (
  user_id     UUID NOT NULL,
  other_id    UUID NOT NULL,
  rel_weight  FLOAT8 NOT NULL,
  computed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, other_id)
);

CREATE INDEX IF NOT EXISTS idx_graph_proximity_user_rel
  ON public.graph_proximity (user_id, rel_weight DESC);

-- === AGGREGATES (Materialized View) ===
-- Note: Using text for author_id to match posts table
CREATE MATERIALIZED VIEW IF NOT EXISTS public.post_aggregates AS
SELECT
  p.id                            AS post_id,
  p.author_id                     AS author_id,
  p.created_at                    AS created_at,
  COALESCE(p.like_count,   0)     AS like_count,
  COALESCE(p.repost_count, 0)     AS repost_count,
  COALESCE(p.reply_count,  0)     AS comment_count,
  0::int                          AS expand_count,
  0::int                          AS profile_visit_count,
  0::int                          AS follow_after_view_count,
  0::int                          AS hide_count,
  0::int                          AS mute_count,
  0::int                          AS block_count
FROM public.posts p;

CREATE UNIQUE INDEX IF NOT EXISTS idx_post_aggregates_post
  ON public.post_aggregates (post_id);
CREATE INDEX IF NOT EXISTS idx_post_aggregates_time
  ON public.post_aggregates (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_post_aggregates_author_time
  ON public.post_aggregates (author_id, created_at DESC);

-- Enable RLS on new tables
ALTER TABLE public.post_impressions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.graph_proximity ENABLE ROW LEVEL SECURITY;

-- RLS Policies for post_impressions
DROP POLICY IF EXISTS pi_insert_self ON public.post_impressions;
CREATE POLICY pi_insert_self ON public.post_impressions
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS pi_select_self ON public.post_impressions;
CREATE POLICY pi_select_self ON public.post_impressions
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- RLS Policies for post_events
DROP POLICY IF EXISTS pe_insert_self ON public.post_events;
CREATE POLICY pe_insert_self ON public.post_events
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS pe_select_self ON public.post_events;
CREATE POLICY pe_select_self ON public.post_events
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- RLS Policies for graph_proximity (readable by logged-in user)
DROP POLICY IF EXISTS gp_select_self ON public.graph_proximity;
CREATE POLICY gp_select_self ON public.graph_proximity
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

