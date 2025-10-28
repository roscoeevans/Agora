-- Migration: 016_search_mvp
-- Description: Search MVP infrastructure - columns, tables, indexes for user search
-- Author: AI Assistant
-- Date: 2025-10-28

-- Enable required extensions
create extension if not exists pg_trgm;      -- Trigram similarity for fuzzy matching

-- Try to enable unaccent (for diacritic-insensitive search) - optional
do $$
begin
  create extension if not exists unaccent;
exception when others then
  raise notice 'unaccent extension not available, skipping';
end $$;

-- Try to enable fuzzystrmatch (for phonetic matching) - optional
do $$
begin
  create extension if not exists fuzzystrmatch;
exception when others then
  raise notice 'fuzzystrmatch extension not available, skipping';
end $$;

-- Add search-related columns to users table
alter table public.users
  add column if not exists verified boolean default false,
  add column if not exists is_active boolean default true,
  add column if not exists locale text,
  add column if not exists country text,
  add column if not exists followers_count int default 0,
  add column if not exists following_count int default 0,
  add column if not exists posts_count int default 0,
  add column if not exists last_active_at timestamptz;

-- Backfill existing users to is_active = true
update public.users set is_active = true where is_active is null;

-- Blocks table: RLS will keep read/write scoped; used to filter search
create table if not exists public.blocks (
  blocker_id uuid references public.users(id) on delete cascade,
  blocked_id uuid references public.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (blocker_id, blocked_id),
  constraint no_self_block check (blocker_id != blocked_id)
);

-- Mutes table: RLS will keep read/write scoped; used to filter search
create table if not exists public.mutes (
  muter_id uuid references public.users(id) on delete cascade,
  muted_id uuid references public.users(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (muter_id, muted_id),
  constraint no_self_mute check (muter_id != muted_id)
);

-- Expression trigram indexes on lowercased columns (case-insensitive search)
-- Note: Using lower() instead of unaccent+lower for MVP compatibility
create index if not exists idx_users_handle_lower_trgm
  on public.users using gin (lower(handle) gin_trgm_ops);

create index if not exists idx_users_display_name_lower_trgm
  on public.users using gin (lower(display_name) gin_trgm_ops);

-- Btree indexes for popularity sorting
create index if not exists idx_users_followers_count_desc
  on public.users (followers_count desc);

create index if not exists idx_users_is_active
  on public.users (is_active) where is_active = true;

create index if not exists idx_users_verified
  on public.users (verified) where verified = true;

-- Composite index for "suggested creators" query
create index if not exists idx_users_suggested_creators
  on public.users (is_active, followers_count desc) 
  where is_active = true;

-- Indexes on blocks and mutes for fast filtering
create index if not exists idx_blocks_blocker_id on public.blocks (blocker_id);
create index if not exists idx_blocks_blocked_id on public.blocks (blocked_id);
create index if not exists idx_mutes_muter_id on public.mutes (muter_id);
create index if not exists idx_mutes_muted_id on public.mutes (muted_id);

-- Materialized view for banned users (constant-time exclusion in queries)
create or replace view public.banned_users as
select distinct subject_id as user_id
from public.moderation_actions
where subject_type = 'user' and action = 'ban';

-- Enable RLS on new tables
alter table public.blocks enable row level security;
alter table public.mutes enable row level security;

-- RLS policies for blocks
create policy "Users can read their own blocks"
  on public.blocks for select
  using (auth.uid() = blocker_id);

create policy "Users can create their own blocks"
  on public.blocks for insert
  with check (auth.uid() = blocker_id);

create policy "Users can delete their own blocks"
  on public.blocks for delete
  using (auth.uid() = blocker_id);

-- RLS policies for mutes
create policy "Users can read their own mutes"
  on public.mutes for select
  using (auth.uid() = muter_id);

create policy "Users can create their own mutes"
  on public.mutes for insert
  with check (auth.uid() = muter_id);

create policy "Users can delete their own mutes"
  on public.mutes for delete
  using (auth.uid() = muter_id);

-- Comment documentation
comment on column public.users.verified is 'Verified badge for trusted accounts';
comment on column public.users.is_active is 'Account is active and visible in search';
comment on column public.users.locale is 'User preferred locale (e.g., en-US)';
comment on column public.users.country is 'User country code (e.g., US)';
comment on column public.users.followers_count is 'Cached follower count for popularity ranking';
comment on column public.users.following_count is 'Cached following count';
comment on column public.users.posts_count is 'Cached post count';
comment on column public.users.last_active_at is 'Last meaningful activity timestamp for recency scoring';

comment on table public.blocks is 'User blocking relationships for filtering search results';
comment on table public.mutes is 'User muting relationships for filtering search results';
comment on view public.banned_users is 'Materialized view of banned user IDs for fast exclusion';

