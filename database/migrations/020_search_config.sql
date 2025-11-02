-- Migration: 020_search_config
-- Description: Configuration table for runtime search tuning (no code pushes needed)
-- Author: AI Assistant
-- Date: 2025-10-28

-- Create search configuration table
create table if not exists public.search_config (
  id serial primary key,
  -- Blending parameters
  alpha_strong numeric not null default 0.10,        -- Text weight for strong matches (>= 0.60 relevance)
  alpha_weak numeric not null default 0.25,          -- Text weight for weak matches (< 0.60 relevance)
  
  -- Similarity thresholds
  sim_handle_threshold numeric not null default 0.20,   -- Min similarity for handle trigram
  sim_name_threshold numeric not null default 0.25,     -- Min similarity for display name trigram
  
  -- Popularity boosts
  verified_boost numeric not null default 0.08,         -- Boost for verified accounts
  trust_boost_threshold smallint not null default 2,    -- Min trust level for boost
  trust_boost numeric not null default 0.04,            -- Boost for trusted accounts
  
  -- Recency parameters
  recency_center_days int not null default 14,          -- Sigmoid center (days since last active)
  recency_steepness numeric not null default 4.0,       -- Sigmoid steepness
  recency_base numeric not null default 0.7,            -- Base recency multiplier
  recency_max_boost numeric not null default 0.3,       -- Max additional boost
  
  -- Popularity scaling
  pop_log_divisor numeric not null default 10.0,        -- Logarithmic scaling divisor
  
  -- Metadata
  description text,
  is_active boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Insert default configuration
insert into public.search_config (
  alpha_strong,
  alpha_weak,
  sim_handle_threshold,
  sim_name_threshold,
  verified_boost,
  trust_boost_threshold,
  trust_boost,
  recency_center_days,
  recency_steepness,
  recency_base,
  recency_max_boost,
  pop_log_divisor,
  description,
  is_active
) values (
  0.10,  -- alpha_strong
  0.25,  -- alpha_weak
  0.20,  -- sim_handle_threshold
  0.25,  -- sim_name_threshold
  0.08,  -- verified_boost
  2,     -- trust_boost_threshold
  0.04,  -- trust_boost
  14,    -- recency_center_days
  4.0,   -- recency_steepness
  0.7,   -- recency_base
  0.3,   -- recency_max_boost
  10.0,  -- pop_log_divisor
  'Default search configuration with balanced text + popularity ranking',
  true   -- is_active
);

-- Function to get active search config
create or replace function public.get_active_search_config()
returns table (
  alpha_strong numeric,
  alpha_weak numeric,
  sim_handle_threshold numeric,
  sim_name_threshold numeric,
  verified_boost numeric,
  trust_boost_threshold smallint,
  trust_boost numeric,
  recency_center_days int,
  recency_steepness numeric,
  recency_base numeric,
  recency_max_boost numeric,
  pop_log_divisor numeric
)
language sql
stable
security definer
as $$
  select
    alpha_strong,
    alpha_weak,
    sim_handle_threshold,
    sim_name_threshold,
    verified_boost,
    trust_boost_threshold,
    trust_boost,
    recency_center_days,
    recency_steepness,
    recency_base,
    recency_max_boost,
    pop_log_divisor
  from public.search_config
  where is_active = true
  order by created_at desc
  limit 1;
$$;

-- Enable RLS on search_config (only service role can modify)
alter table public.search_config enable row level security;

-- Policy: Anyone can read active config
create policy "Anyone can read search config"
  on public.search_config for select
  using (is_active = true);

-- Policy: Only service role can modify config (via dashboard/admin tools)
create policy "Only service role can modify config"
  on public.search_config for all
  using (false)  -- Prevents all direct modifications
  with check (false);

-- Comments
comment on table public.search_config is 
  'Runtime configuration for search ranking parameters. Allows tuning without code deployments.';

comment on column public.search_config.alpha_strong is 
  'Popularity weight for strong text matches (>= 0.60 relevance). Lower = more text, higher = more popularity.';

comment on column public.search_config.alpha_weak is 
  'Popularity weight for weak text matches (< 0.60 relevance). Higher values give more weight to popularity.';

comment on column public.search_config.sim_handle_threshold is 
  'Minimum trigram similarity score to include handle match in candidates (0.0-1.0).';

comment on column public.search_config.sim_name_threshold is 
  'Minimum trigram similarity score to include display name match in candidates (0.0-1.0).';

comment on function public.get_active_search_config() is 
  'Returns the currently active search configuration for use in ranking functions.';



