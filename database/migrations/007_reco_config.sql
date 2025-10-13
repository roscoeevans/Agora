-- Migration 007: Centralized Recommendation Config
-- Single source of truth for all algorithm knobs

-- === RECO CONFIG TABLE ===
CREATE TABLE IF NOT EXISTS public.reco_config (
  id            BIGSERIAL PRIMARY KEY,
  env           TEXT NOT NULL DEFAULT 'staging',
  version       TEXT NOT NULL,
  is_active     BOOLEAN NOT NULL DEFAULT false,
  description   TEXT,
  config        JSONB NOT NULL,
  created_by    UUID DEFAULT auth.uid(),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (env, version)
);

CREATE INDEX IF NOT EXISTS idx_reco_config_env_active 
  ON public.reco_config(env, is_active);

-- Enable RLS
ALTER TABLE public.reco_config ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS reco_config_read ON public.reco_config;
CREATE POLICY reco_config_read ON public.reco_config
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS reco_config_write ON public.reco_config;
CREATE POLICY reco_config_write ON public.reco_config
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- === HELPER FUNCTIONS ===

-- Fetch the active config for an environment
CREATE OR REPLACE FUNCTION public.get_active_reco_config(p_env TEXT)
RETURNS JSONB
LANGUAGE sql
STABLE
AS $$
  SELECT rc.config
  FROM public.reco_config rc
  WHERE rc.env = p_env AND rc.is_active = true
  ORDER BY rc.created_at DESC
  LIMIT 1
$$;

-- Activate exactly one config per environment
CREATE OR REPLACE FUNCTION public.activate_reco_config(
  p_env TEXT, 
  p_version TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.reco_config SET is_active = false WHERE env = p_env;
  UPDATE public.reco_config SET is_active = true
  WHERE env = p_env AND version = p_version;
END;
$$;

-- === SEED STAGING CONFIG ===
INSERT INTO public.reco_config (env, version, is_active, description, config)
VALUES (
  'staging',
  '2025-10-12a',
  true,
  'MVP knobs: light follow, 12% explore, 7-day suppression',
  '{
    "freshness": { "tau_hours": 12 },
    "weights": {
      "like": 1.0,
      "comment": 5.0,
      "repost": 4.0,
      "expand": 1.5,
      "profile_visit": 3.0,
      "follow_after_view": 8.0,
      "hide": -12.0,
      "mute": -25.0,
      "block": -50.0
    },
    "mixing": {
      "alpha_quality": 0.6,
      "beta_relation": 0.25,
      "gamma_similarity": 0.15
    },
    "follow": {
      "boost": 0.2,
      "catchup_every": 12,
      "min_quality_floor": 0
    },
    "explore": {
      "curiosity_ratio": 0.12,
      "epsilon": 0.05,
      "novelty_bonus": 0.25,
      "min_trust_for_explore": 0,
      "max_in_top10": 3
    },
    "diversity": {
      "avoid_back_to_back_author": true,
      "topic_penalty": 0.0,
      "author_repeat_window": 5
    },
    "suppression": {
      "dedupe_days": 7
    },
    "quality_pool": {
      "lookback_hours": 48,
      "limit": 5000,
      "score_formula": "like + 4*repost + 5*comment"
    }
  }'::jsonb
) ON CONFLICT (env, version) DO NOTHING;

