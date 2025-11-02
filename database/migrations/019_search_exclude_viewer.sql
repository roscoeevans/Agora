-- Migration: 019_search_exclude_viewer
-- Description: Update search function to exclude viewer from their own search results
-- Author: AI Assistant
-- Date: 2025-10-28

-- Update search_users_v1 to exclude viewer
create or replace function public.search_users_v1(
  q text,
  viewer_id uuid,
  page_limit int default 20,
  after_handle text default null
)
returns table (
  user_id uuid,
  handle text,
  display_handle text,
  display_name text,
  avatar_url text,
  trust_level smallint,
  verified boolean,
  followers_count int,
  last_active_at timestamptz,
  score numeric
)
language sql
stable
security definer
as $$
  -- Normalize query input
  with params as (
    select
      trim(both ' ' from coalesce(q, '')) as raw,
      lower(trim(both ' ' from coalesce(q, ''))) as ql
  ),
  
  -- Extract handle-friendly query (strip @ prefix)
  norm as (
    select
      regexp_replace((select ql from params), '^@', '') as qh,
      lower((select ql from params)) as qlow,
      (select raw from params) like '@%' as at_prefix
  ),
  
  -- Base candidate set: filter by is_active, not banned, not blocked
  base as (
    select
      u.*,
      lower(u.handle) as h_lower,
      lower(u.display_name) as d_lower
    from public.users u
    where u.is_active = true
      -- Exclude viewer (don't show yourself in search)
      and u.id != viewer_id
      -- Exclude banned users
      and not exists (
        select 1 from public.banned_users b where b.user_id = u.id
      )
      -- Exclude blocked users (bidirectional)
      and not exists (
        select 1 from public.blocks bl
        where (bl.blocker_id = viewer_id and bl.blocked_id = u.id)
           or (bl.blocker_id = u.id and bl.blocked_id = viewer_id)
      )
      -- Require non-empty query
      and (select qlow from norm) <> ''
      -- Fast candidate expansion: prefix or trigram match
      and (
        lower(u.handle) like (select qlow from norm) || '%'
        or lower(u.display_name) like (select qlow from norm) || '%'
        or similarity(lower(u.handle), (select qlow from norm)) > 0.20
        or similarity(lower(u.display_name), (select qlow from norm)) > 0.25
      )
      -- Cursor pagination
      and (after_handle is null or u.handle > after_handle)
  ),
  
  -- Calculate text relevance scores
  text_scores as (
    select
      u.*,
      -- Exact handle match gets perfect score
      greatest(
        case when h_lower = (select qh from norm) then 1.0 else 0 end,
        -- Prefer handle matches if query started with @
        (case when (select at_prefix from norm) then 0.75 else 0.60 end)
          * greatest(similarity(h_lower, (select qlow from norm)), 0),
        -- Display name matches weighted lower
        0.50 * greatest(similarity(d_lower, (select qlow from norm)), 0)
      ) as r_text
    from base u
  ),
  
  -- Calculate popularity scores with recency multiplier
  pop as (
    select
      t.*,
      -- Popularity: logarithmic scaling + trust/verified boost
      least(1.0, 
        ln(1 + greatest(0, t.followers_count)) / 10.0
        + case when t.verified then 0.08 else 0 end
        + case when t.trust_level >= 2 then 0.04 else 0 end
      ) as p_raw,
      -- Recency multiplier (sigmoid centered at 14 days)
      (case
        when t.last_active_at is null then 0.85
        else 0.7 + 0.3 * (1.0 / (1.0 + exp((extract(epoch from (now() - t.last_active_at))/86400.0 - 14)/4)))
      end) as activity_mult
    from text_scores t
  ),
  
  -- Blend text relevance with popularity
  blended as (
    select
      p.*,
      (p.p_raw * p.activity_mult) as p,
      -- Adaptive alpha: exact matches ignore popularity, weak matches lean on it
      case
        when p.h_lower = (select qh from norm) then 0.0    -- exact handle → pure text
        when p.r_text >= 0.60 then 0.10                    -- strong match → mostly text
        else 0.25                                          -- weak match → more popularity
      end as alpha
    from pop p
  )
  
  -- Final ranking and return
  select
    id as user_id,
    handle,
    display_handle,
    display_name,
    avatar_url,
    trust_level,
    verified,
    followers_count,
    last_active_at,
    ((1 - alpha) * r_text + alpha * p) as score
  from blended
  order by
    (lower(handle) = (select qh from norm)) desc,  -- pin exact handle matches
    ((1 - alpha) * r_text + alpha * p) desc,
    verified desc,
    followers_count desc,
    last_active_at desc nulls last,
    handle asc
  limit greatest(5, page_limit);
$$;

-- Update suggested_creators to also exclude viewer
create or replace function public.suggested_creators(
  viewer_id uuid,
  page_limit int default 20
)
returns table (
  user_id uuid,
  handle text,
  display_handle text,
  display_name text,
  avatar_url text,
  trust_level smallint,
  verified boolean,
  followers_count int,
  last_active_at timestamptz
)
language sql
stable
security definer
as $$
  select
    u.id as user_id,
    u.handle,
    u.display_handle,
    u.display_name,
    u.avatar_url,
    u.trust_level,
    u.verified,
    u.followers_count,
    u.last_active_at
  from public.users u
  where u.is_active = true
    and u.id != viewer_id  -- Don't suggest yourself
    -- Exclude banned users
    and not exists (
      select 1 from public.banned_users b where b.user_id = u.id
    )
    -- Exclude blocked users
    and not exists (
      select 1 from public.blocks bl
      where (bl.blocker_id = viewer_id and bl.blocked_id = u.id)
         or (bl.blocker_id = u.id and bl.blocked_id = viewer_id)
    )
    -- Exclude users already followed
    and not exists (
      select 1 from public.follows f
      where f.follower_id = viewer_id and f.followee_id = u.id
    )
  order by
    u.verified desc,
    u.followers_count desc,
    u.last_active_at desc nulls last
  limit greatest(5, page_limit);
$$;

-- Update comments
comment on function public.search_users_v1(text, uuid, int, text) is 
  'Main user search function with popularity-blended ranking. Excludes viewer from their own results. Returns users matching query with relevance + popularity scores.';

comment on function public.suggested_creators(uuid, int) is 
  'Returns popular, active users not followed by viewer (excluding viewer themselves), sorted by popularity.';



