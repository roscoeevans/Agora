-- Migration: 017_search_count_triggers
-- Description: Triggers to maintain cached counts for search ranking
-- Author: AI Assistant
-- Date: 2025-10-28

-- =============================================================================
-- FOLLOWERS COUNT TRIGGERS
-- =============================================================================

-- Function: Update followers_count and following_count on follows changes
create or replace function public.bump_follow_counts()
returns trigger
language plpgsql
security definer
as $$
begin
  if TG_OP = 'INSERT' then
    -- Increment follower count for followee
    update public.users
    set followers_count = followers_count + 1
    where id = new.followee_id;
    
    -- Increment following count for follower
    update public.users
    set following_count = following_count + 1
    where id = new.follower_id;
    
  elsif TG_OP = 'DELETE' then
    -- Decrement follower count for followee (prevent negative)
    update public.users
    set followers_count = greatest(0, followers_count - 1)
    where id = old.followee_id;
    
    -- Decrement following count for follower (prevent negative)
    update public.users
    set following_count = greatest(0, following_count - 1)
    where id = old.follower_id;
  end if;
  
  return null;
end;
$$;

-- Trigger: Apply follow count updates
drop trigger if exists trg_follows_counts on public.follows;
create trigger trg_follows_counts
  after insert or delete on public.follows
  for each row
  execute function public.bump_follow_counts();

-- =============================================================================
-- POSTS COUNT TRIGGERS
-- =============================================================================

-- Function: Update posts_count and last_active_at on post changes
create or replace function public.bump_posts_counts()
returns trigger
language plpgsql
security definer
as $$
begin
  if TG_OP = 'INSERT' then
    -- Increment post count and update last_active_at
    update public.users
    set posts_count = posts_count + 1,
        last_active_at = now()
    where id = new.author_id;
    
  elsif TG_OP = 'DELETE' then
    -- Decrement post count (prevent negative)
    update public.users
    set posts_count = greatest(0, posts_count - 1)
    where id = old.author_id;
  end if;
  
  return null;
end;
$$;

-- Trigger: Apply post count updates
drop trigger if exists trg_posts_counts on public.posts;
create trigger trg_posts_counts
  after insert or delete on public.posts
  for each row
  execute function public.bump_posts_counts();

-- =============================================================================
-- LAST ACTIVE TRACKING (Optional: track engagement activity)
-- =============================================================================

-- Function: Update last_active_at on meaningful post events
-- This tracks engagement activity beyond just posting
create or replace function public.bump_last_active_on_engagement()
returns trigger
language plpgsql
security definer
as $$
begin
  -- Only track certain event types as "active"
  if new.type in ('like', 'comment', 'repost') then
    update public.users
    set last_active_at = now()
    where id = new.user_id;
  end if;
  
  return null;
end;
$$;

-- Trigger: Apply last_active_at updates on engagement
drop trigger if exists trg_last_active_on_engagement on public.post_events;
create trigger trg_last_active_on_engagement
  after insert on public.post_events
  for each row
  execute function public.bump_last_active_on_engagement();

-- =============================================================================
-- BACKFILL EXISTING COUNTS
-- =============================================================================

-- Backfill followers_count
update public.users u
set followers_count = (
  select count(*)
  from public.follows f
  where f.followee_id = u.id
);

-- Backfill following_count
update public.users u
set following_count = (
  select count(*)
  from public.follows f
  where f.follower_id = u.id
);

-- Backfill posts_count
update public.users u
set posts_count = (
  select count(*)
  from public.posts p
  where p.author_id = u.id
);

-- Backfill last_active_at (use most recent post created_at)
update public.users u
set last_active_at = (
  select max(p.created_at)
  from public.posts p
  where p.author_id = u.id
)
where exists (
  select 1 from public.posts p where p.author_id = u.id
);

-- =============================================================================
-- COMMENTS
-- =============================================================================

comment on function public.bump_follow_counts() is 
  'Maintains followers_count and following_count on users table when follows change';

comment on function public.bump_posts_counts() is 
  'Maintains posts_count and last_active_at on users table when posts are created/deleted';

comment on function public.bump_last_active_on_engagement() is 
  'Updates last_active_at when users engage with content (like, comment, repost)';




