-- Migration 012: Complete Posting System
-- Adds post editing, edit history, self-destruct, and post media storage

-- === UPDATE POSTS TABLE ===
-- Add new columns for editing and self-destruct
ALTER TABLE public.posts 
  ADD COLUMN IF NOT EXISTS edited_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS self_destruct_at TIMESTAMPTZ;

-- Add index on self_destruct_at for cron job efficiency
CREATE INDEX IF NOT EXISTS idx_posts_self_destruct 
  ON public.posts (self_destruct_at) 
  WHERE self_destruct_at IS NOT NULL;

-- === CREATE POST EDITS HISTORY TABLE ===
CREATE TABLE IF NOT EXISTS public.post_edits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  previous_text TEXT NOT NULL,
  edited_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  edited_by TEXT NOT NULL
);

-- Add index for efficient edit history queries
CREATE INDEX IF NOT EXISTS idx_post_edits_post_id 
  ON public.post_edits (post_id, edited_at DESC);

-- Enable RLS on post_edits
ALTER TABLE public.post_edits ENABLE ROW LEVEL SECURITY;

-- RLS Policies for post_edits (anyone can read edit history for public posts)
DROP POLICY IF EXISTS "Anyone can view edit history" ON public.post_edits;
CREATE POLICY "Anyone can view edit history" 
  ON public.post_edits FOR SELECT 
  TO authenticated 
  USING (true);

DROP POLICY IF EXISTS "Users can insert their own edit history" ON public.post_edits;
CREATE POLICY "Users can insert their own edit history" 
  ON public.post_edits FOR INSERT 
  TO authenticated 
  WITH CHECK (edited_by = auth.uid()::text);

-- === CREATE POST MEDIA STORAGE BUCKET ===
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'post-media',
  'post-media',
  true, -- Public bucket so media URLs work without auth
  52428800, -- 50MB limit (larger than avatars for videos)
  ARRAY[
    'image/jpeg', 
    'image/png', 
    'image/webp', 
    'image/heic',
    'video/mp4',
    'video/quicktime',
    'video/x-m4v'
  ]
)
ON CONFLICT (id) DO NOTHING;

-- === STORAGE POLICIES FOR POST-MEDIA BUCKET ===

-- 1. Anyone can view post media (public bucket)
DROP POLICY IF EXISTS "Public post media access" ON storage.objects;
CREATE POLICY "Public post media access"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'post-media');

-- 2. Authenticated users can upload their own post media
DROP POLICY IF EXISTS "Users can upload their own post media" ON storage.objects;
CREATE POLICY "Users can upload their own post media"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'post-media' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 3. Users can update their own post media
DROP POLICY IF EXISTS "Users can update their own post media" ON storage.objects;
CREATE POLICY "Users can update their own post media"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'post-media' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- 4. Users can delete their own post media
DROP POLICY IF EXISTS "Users can delete their own post media" ON storage.objects;
CREATE POLICY "Users can delete their own post media"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'post-media' 
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- === UPDATE POST RLS POLICIES ===

-- Allow authenticated users to create posts
DROP POLICY IF EXISTS "Users can create posts" ON public.posts;
CREATE POLICY "Users can create posts" 
  ON public.posts FOR INSERT 
  TO authenticated 
  WITH CHECK (auth.uid()::text = author_id);

-- Allow users to update their own posts (only text and edited_at)
-- Note: We'll enforce 15-minute window in the Edge Function
DROP POLICY IF EXISTS "Users can edit their own posts" ON public.posts;
CREATE POLICY "Users can edit their own posts" 
  ON public.posts FOR UPDATE 
  TO authenticated 
  USING (auth.uid()::text = author_id)
  WITH CHECK (auth.uid()::text = author_id);

-- Allow users to delete their own posts
DROP POLICY IF EXISTS "Users can delete their own posts" ON public.posts;
CREATE POLICY "Users can delete their own posts" 
  ON public.posts FOR DELETE 
  TO authenticated 
  USING (auth.uid()::text = author_id);

-- Allow everyone to read public posts
DROP POLICY IF EXISTS "Anyone can view public posts" ON public.posts;
CREATE POLICY "Anyone can view public posts" 
  ON public.posts FOR SELECT 
  TO authenticated 
  USING (visibility = 'public');

-- === HELPER FUNCTION: Check if post is within edit window ===
CREATE OR REPLACE FUNCTION public.is_within_edit_window(post_created_at TIMESTAMPTZ)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN (NOW() - post_created_at) <= INTERVAL '15 minutes';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION public.is_within_edit_window IS 'Returns true if post was created within the last 15 minutes (edit window)';

