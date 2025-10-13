-- Migration 008: pg_cron Jobs
-- Automated maintenance for aggregates and impression cleanup

-- === REFRESH AGGREGATES EVERY 2 MINUTES ===
SELECT cron.schedule(
  'refresh_post_aggregates_every_2m',
  '*/2 * * * *',
  $$ SELECT public.refresh_post_aggregates(); $$
);

-- === PRUNE OLD IMPRESSIONS DAILY ===
-- Remove impressions older than 90 days to keep storage tidy
CREATE OR REPLACE FUNCTION public.prune_old_impressions()
RETURNS VOID 
LANGUAGE SQL 
AS $$
  DELETE FROM public.post_impressions
  WHERE created_at < now() - interval '90 days';
$$;

SELECT cron.schedule(
  'prune_post_impressions_daily',
  '15 3 * * *',
  $$ SELECT public.prune_old_impressions(); $$
);

