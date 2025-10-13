-- Migration 004: Count Triggers
-- Maintains like_count, repost_count, reply_count on posts table

-- === LIKES COUNT ===
CREATE OR REPLACE FUNCTION public.bump_like_count() 
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts 
    SET like_count = COALESCE(like_count, 0) + 1 
    WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts 
    SET like_count = GREATEST(COALESCE(like_count, 0) - 1, 0) 
    WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END; 
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_bump_like_count_ins ON public.likes;
CREATE TRIGGER trg_bump_like_count_ins
  AFTER INSERT ON public.likes 
  FOR EACH ROW EXECUTE FUNCTION public.bump_like_count();

DROP TRIGGER IF EXISTS trg_bump_like_count_del ON public.likes;
CREATE TRIGGER trg_bump_like_count_del
  AFTER DELETE ON public.likes 
  FOR EACH ROW EXECUTE FUNCTION public.bump_like_count();

-- === REPOSTS COUNT ===
CREATE OR REPLACE FUNCTION public.bump_repost_count() 
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts 
    SET repost_count = COALESCE(repost_count, 0) + 1 
    WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts 
    SET repost_count = GREATEST(COALESCE(repost_count, 0) - 1, 0) 
    WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END; 
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_bump_repost_count_ins ON public.reposts;
CREATE TRIGGER trg_bump_repost_count_ins
  AFTER INSERT ON public.reposts 
  FOR EACH ROW EXECUTE FUNCTION public.bump_repost_count();

DROP TRIGGER IF EXISTS trg_bump_repost_count_del ON public.reposts;
CREATE TRIGGER trg_bump_repost_count_del
  AFTER DELETE ON public.reposts 
  FOR EACH ROW EXECUTE FUNCTION public.bump_repost_count();

-- === REPLIES COUNT ===
-- Trigger for reply_count based on reply_to_post_id
CREATE OR REPLACE FUNCTION public.bump_reply_count() 
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.reply_to_post_id IS NOT NULL THEN
    UPDATE public.posts 
    SET reply_count = COALESCE(reply_count, 0) + 1 
    WHERE id = NEW.reply_to_post_id;
  ELSIF TG_OP = 'DELETE' AND OLD.reply_to_post_id IS NOT NULL THEN
    UPDATE public.posts 
    SET reply_count = GREATEST(COALESCE(reply_count, 0) - 1, 0) 
    WHERE id = OLD.reply_to_post_id;
  END IF;
  RETURN NULL;
END; 
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_bump_reply_count_ins ON public.posts;
CREATE TRIGGER trg_bump_reply_count_ins
  AFTER INSERT ON public.posts 
  FOR EACH ROW EXECUTE FUNCTION public.bump_reply_count();

DROP TRIGGER IF EXISTS trg_bump_reply_count_del ON public.posts;
CREATE TRIGGER trg_bump_reply_count_del
  AFTER DELETE ON public.posts 
  FOR EACH ROW EXECUTE FUNCTION public.bump_reply_count();

