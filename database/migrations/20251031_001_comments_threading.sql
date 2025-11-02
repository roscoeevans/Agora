-- Threaded Comments System
-- Migration: 20251031_001_comments_threading
-- Applied: October 31, 2025
-- Status: ✅ DEPLOYED to Staging

-- 1) Table
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  author_id uuid not null references public.users(id) on delete cascade,
  parent_comment_id uuid references public.comments(id) on delete cascade,
  depth smallint not null default 0 check (depth between 0 and 2), -- 0=top,1=reply,2=sub-reply
  body text not null check (length(body) > 0),
  reply_count integer not null default 0,  -- denormalized for quick counts
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2) Depth guard: parent.depth + 1 = child.depth; enforce <=2
create or replace function public.enforce_comment_depth()
returns trigger language plpgsql as $$
declare parent_depth smallint;
begin
  if NEW.parent_comment_id is null then
    NEW.depth := 0;
  else
    select depth into parent_depth from public.comments where id = NEW.parent_comment_id for update;
    if parent_depth is null then
      raise exception 'Parent comment does not exist';
    end if;
    if parent_depth >= 2 then
      raise exception 'Maximum nesting depth reached';
    end if;
    NEW.depth := parent_depth + 1;
  end if;
  return NEW;
end $$;

drop trigger if exists trg_enforce_comment_depth on public.comments;
create trigger trg_enforce_comment_depth
before insert on public.comments
for each row execute function public.enforce_comment_depth();

-- 3) Maintain reply_count and updated_at
create or replace function public.bump_reply_count()
returns trigger language plpgsql as $$
begin
  if NEW.parent_comment_id is not null then
    update public.comments
       set reply_count = reply_count + 1,
           updated_at = now()
     where id = NEW.parent_comment_id;
  end if;
  return NEW;
end $$;

drop trigger if exists trg_bump_reply_count on public.comments;
create trigger trg_bump_reply_count
after insert on public.comments
for each row execute function public.bump_reply_count();

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  NEW.updated_at := now();
  return NEW;
end $$;

drop trigger if exists trg_touch_updated_at on public.comments;
create trigger trg_touch_updated_at
before update on public.comments
for each row execute function public.touch_updated_at();

-- 4) Indexes for keyset pagination
create index if not exists idx_comments_post_depth_created
  on public.comments (post_id, depth, created_at desc, id desc);

create index if not exists idx_comments_parent_created
  on public.comments (parent_comment_id, created_at desc, id desc);

create index if not exists idx_comments_author_created
  on public.comments (author_id, created_at desc);

-- 5) RLS
alter table public.comments enable row level security;

-- Read: everyone can read comments for visible posts (tighten if you have post visibility)
drop policy if exists comments_select_all on public.comments;
create policy comments_select_all
on public.comments
for select
using (true);

-- Insert: authenticated users only; author_id must match
drop policy if exists comments_insert_own on public.comments;
create policy comments_insert_own
on public.comments
for insert
with check (auth.uid() = author_id);

-- Update/Delete: only author (or admins—add your admin role check if needed)
drop policy if exists comments_update_own on public.comments;
create policy comments_update_own
on public.comments
for update
using (auth.uid() = author_id)
with check (auth.uid() = author_id);

drop policy if exists comments_delete_own on public.comments;
create policy comments_delete_own
on public.comments
for delete
using (auth.uid() = author_id);

-- 6) RPCs (keyset pagination: pass last_seen_created_at + last_seen_id)
--    Top-level comments (depth=0)
create or replace function public.fetch_post_comments(
  in_p_post_id uuid,
  in_p_limit integer default 50,
  in_p_last_created_at timestamptz default null,
  in_p_last_id uuid default null
)
returns setof public.comments
language sql stable as $$
  select *
    from public.comments c
   where c.post_id = in_p_post_id
     and c.depth = 0
     and (
       in_p_last_created_at is null
       or (c.created_at, c.id) < (in_p_last_created_at, in_p_last_id)
     )
   order by c.created_at desc, c.id desc
   limit greatest(1, least(in_p_limit, 100));
$$;

-- Replies for any parent (depth 1 or 2 parents; returns direct children only)
create or replace function public.fetch_comment_replies(
  in_p_parent_comment_id uuid,
  in_p_limit integer default 25,
  in_p_last_created_at timestamptz default null,
  in_p_last_id uuid default null
)
returns setof public.comments
language sql stable as $$
  select *
    from public.comments c
   where c.parent_comment_id = in_p_parent_comment_id
     and (
       in_p_last_created_at is null
       or (c.created_at, c.id) < (in_p_last_created_at, in_p_last_id)
     )
   order by c.created_at desc, c.id desc
   limit greatest(1, least(in_p_limit, 100));
$$;

-- Create top-level comment
create or replace function public.create_comment(
  in_p_post_id uuid,
  in_p_body text
)
returns public.comments
language plpgsql security definer as $$
declare new_row public.comments;
begin
  insert into public.comments (post_id, author_id, parent_comment_id, body, depth)
  values (in_p_post_id, auth.uid(), null, in_p_body, 0)
  returning * into new_row;
  return new_row;
end $$;

-- Create reply (enforces max depth via trigger)
create or replace function public.create_reply(
  in_p_parent_comment_id uuid,
  in_p_body text
)
returns public.comments
language plpgsql security definer as $$
declare parent_row public.comments;
declare new_row public.comments;
begin
  select * into parent_row from public.comments where id = in_p_parent_comment_id;
  if parent_row is null then
    raise exception 'Parent comment not found';
  end if;

  insert into public.comments (post_id, author_id, parent_comment_id, body)
  values (parent_row.post_id, auth.uid(), in_p_parent_comment_id, in_p_body)
  returning * into new_row;

  return new_row;
end $$;

-- Grant execute permissions
grant execute on function public.fetch_post_comments to authenticated;
grant execute on function public.fetch_comment_replies to authenticated;
grant execute on function public.create_comment to authenticated;
grant execute on function public.create_reply to authenticated;

-- Realtime: Enable for real-time comment delivery
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
-- (Applied separately via Supabase Dashboard/SQL)


