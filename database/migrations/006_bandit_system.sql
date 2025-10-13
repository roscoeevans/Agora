-- Migration 006: Bandit System
-- Multi-armed bandit infrastructure for exploration

-- === BANDIT STATS TABLE ===
CREATE TABLE IF NOT EXISTS public.bandit_stats (
  entity_type TEXT NOT NULL CHECK (entity_type IN ('post','author','topic')),
  entity_id   UUID NOT NULL,
  successes   INT  NOT NULL DEFAULT 0,
  trials      INT  NOT NULL DEFAULT 0,
  last_update TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (entity_type, entity_id)
);

CREATE INDEX IF NOT EXISTS idx_bandit_stats_entity
  ON public.bandit_stats (entity_type, entity_id);

-- Enable RLS
ALTER TABLE public.bandit_stats ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS bs_select_all ON public.bandit_stats;
CREATE POLICY bs_select_all ON public.bandit_stats 
  FOR SELECT TO authenticated 
  USING (true);

DROP POLICY IF EXISTS bs_update_srv ON public.bandit_stats;
CREATE POLICY bs_update_srv ON public.bandit_stats 
  FOR UPDATE TO service_role 
  USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS bs_insert_srv ON public.bandit_stats;
CREATE POLICY bs_insert_srv ON public.bandit_stats 
  FOR INSERT TO service_role 
  WITH CHECK (true);

-- === HELPER FUNCTIONS ===

-- Record a trial (impression/exposure)
CREATE OR REPLACE FUNCTION public.bandit_record_trial(
  p_type TEXT, 
  p_id UUID
)
RETURNS VOID 
LANGUAGE sql 
SECURITY DEFINER 
AS $$
  INSERT INTO public.bandit_stats(entity_type, entity_id, trials)
  VALUES (p_type, p_id, 1)
  ON CONFLICT (entity_type, entity_id)
  DO UPDATE SET 
    trials = public.bandit_stats.trials + 1, 
    last_update = now();
$$;

-- Record a success or failure (1 = success, 0 = failure)
CREATE OR REPLACE FUNCTION public.bandit_record_success(
  p_type TEXT, 
  p_id UUID, 
  p_success INT
)
RETURNS VOID 
LANGUAGE sql 
SECURITY DEFINER 
AS $$
  INSERT INTO public.bandit_stats(entity_type, entity_id, successes, trials)
  VALUES (p_type, p_id, p_success, 1)
  ON CONFLICT (entity_type, entity_id)
  DO UPDATE SET
    successes = public.bandit_stats.successes + p_success,
    trials    = public.bandit_stats.trials + 1,
    last_update = now();
$$;

