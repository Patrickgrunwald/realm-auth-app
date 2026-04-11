-- Realm Auth — Initiale Datenbank-Migration
-- Führe dies im Supabase SQL Editor aus: https://app.supabase.com → SQL Editor

-- ============================================================
-- USERS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL CHECK (length(username) BETWEEN 3 AND 20 AND username ~ '^[a-zA-Z0-9_]+$'),
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT CHECK (length(bio) <= 150),
  followers_count INTEGER NOT NULL DEFAULT 0,
  following_count INTEGER NOT NULL DEFAULT 0,
  posts_count INTEGER NOT NULL DEFAULT 0,
  is_admin BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Automatisch users-Eintrag erstellen wenn sich jemand bei Auth registriert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, username, email, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'username')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- POSTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('photo', 'video')),
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT CHECK (length(caption) <= 500),
  is_ea_content BOOLEAN NOT NULL DEFAULT false,
  is_ai_confirmed BOOLEAN NOT NULL DEFAULT false,
  ea_report_count INTEGER NOT NULL DEFAULT 0,
  likes_count INTEGER NOT NULL DEFAULT 0,
  comments_count INTEGER NOT NULL DEFAULT 0,
  shares_count INTEGER NOT NULL DEFAULT 0,
  report_status TEXT NOT NULL DEFAULT 'none'
    CHECK (report_status IN ('none', 'pending', 'confirmed', 'rejected')),
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: posts_count aktuell halten
CREATE OR REPLACE FUNCTION public.update_posts_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.users SET posts_count = posts_count + 1 WHERE id = NEW.user_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.users SET posts_count = GREATEST(0, posts_count - 1) WHERE id = OLD.user_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_post_insert ON public.posts;
CREATE TRIGGER on_post_insert
  AFTER INSERT OR DELETE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION public.update_posts_count();

-- ============================================================
-- LIKES
-- ============================================================
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, post_id)
);

-- Trigger: likes_count auf posts aktuell halten
CREATE OR REPLACE FUNCTION public.update_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_like_change ON public.likes;
CREATE TRIGGER on_like_change
  AFTER INSERT OR DELETE ON public.likes
  FOR EACH ROW EXECUTE FUNCTION public.update_likes_count();

-- ============================================================
-- COMMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (length(content) BETWEEN 1 AND 500),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger: comments_count
CREATE OR REPLACE FUNCTION public.update_comments_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts SET comments_count = GREATEST(0, comments_count - 1) WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_comment_change ON public.comments;
CREATE TRIGGER on_comment_change
  AFTER INSERT OR DELETE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION public.update_comments_count();

-- ============================================================
-- FOLLOWS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.follows (
  follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- Trigger: follower/following counts
CREATE OR REPLACE FUNCTION public.update_follow_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.users SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
    UPDATE public.users SET following_count = following_count + 1 WHERE id = NEW.follower_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.users SET followers_count = GREATEST(0, followers_count - 1) WHERE id = OLD.following_id;
    UPDATE public.users SET following_count = GREATEST(0, following_count - 1) WHERE id = OLD.follower_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_follow_change ON public.follows;
CREATE TRIGGER on_follow_change
  AFTER INSERT OR DELETE ON public.follows
  FOR EACH ROW EXECUTE FUNCTION public.update_follow_counts();

-- ============================================================
-- EA REPORTS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ea_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(post_id, reporter_id)
);

-- Trigger: ea_report_count + Auto-pending bei >= 5
CREATE OR REPLACE FUNCTION public.update_ea_report_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.posts
    SET ea_report_count = ea_report_count + 1
    WHERE id = NEW.post_id
      AND deleted_at IS NULL;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.posts
    SET ea_report_count = GREATEST(0, ea_report_count - 1)
    WHERE id = OLD.post_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_ea_report_change ON public.ea_reports;
CREATE TRIGGER on_ea_report_change
  AFTER INSERT OR DELETE ON public.ea_reports
  FOR EACH ROW EXECUTE FUNCTION public.update_ea_report_count();

-- RPC: EA Auto-Pending (wird von Edge Function aufgerufen)
CREATE OR REPLACE FUNCTION public.auto_pending_ea(post_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE public.posts
  SET report_status = 'pending',
      is_ea_content = true
  WHERE id = post_uuid
    AND ea_report_count >= 5
    AND report_status = 'none'
    AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'follow', 'ea_confirmed', 'ea_resolved')),
  actor_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  post_id UUID REFERENCES public.posts(id) ON DELETE SET NULL,
  read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_report_status ON public.posts(report_status) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_posts_feed ON public.posts(created_at DESC) WHERE deleted_at IS NULL AND report_status != 'confirmed';
CREATE INDEX IF NOT EXISTS idx_likes_post_id ON public.likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_id ON public.likes(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_follows_following_id ON public.follows(following_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower_id ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(user_id, read) WHERE read = false;
CREATE INDEX IF NOT EXISTS idx_ea_reports_post_id ON public.ea_reports(post_id);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ea_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- USERS
CREATE POLICY "users_select_all" ON public.users FOR SELECT USING (true);
CREATE POLICY "users_update_own" ON public.users FOR UPDATE USING (auth.uid() = id);

-- POSTS
CREATE POLICY "posts_select_public" ON public.posts FOR SELECT
  USING (deleted_at IS NULL);
CREATE POLICY "posts_insert_auth" ON public.posts FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "posts_update_own" ON public.posts FOR UPDATE
  USING (auth.uid() = user_id);
CREATE POLICY "posts_delete_own" ON public.posts FOR DELETE
  USING (auth.uid() = user_id);

-- LIKES
CREATE POLICY "likes_select_all" ON public.likes FOR SELECT USING (true);
CREATE POLICY "likes_insert_auth" ON public.likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "likes_delete_own" ON public.likes FOR DELETE
  USING (auth.uid() = user_id);

-- COMMENTS
CREATE POLICY "comments_select_all" ON public.comments FOR SELECT USING (true);
CREATE POLICY "comments_insert_auth" ON public.comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "comments_delete_own" ON public.comments FOR DELETE
  USING (auth.uid() = user_id);

-- FOLLOWS
CREATE POLICY "follows_select_all" ON public.follows FOR SELECT USING (true);
CREATE POLICY "follows_insert_auth" ON public.follows FOR INSERT
  WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "follows_delete_own" ON public.follows FOR DELETE
  USING (auth.uid() = follower_id);

-- EA REPORTS
CREATE POLICY "ea_reports_select_auth" ON public.ea_reports FOR SELECT
  USING (auth.uid() = reporter_id);
CREATE POLICY "ea_reports_insert_auth" ON public.ea_reports FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

-- NOTIFICATIONS
CREATE POLICY "notifications_select_own" ON public.notifications FOR SELECT
  USING (auth.uid() = user_id);
CREATE POLICY "notifications_update_own" ON public.notifications FOR UPDATE
  USING (auth.uid() = user_id);
CREATE POLICY "notifications_insert_service" ON public.notifications FOR INSERT
  WITH CHECK (true); -- Service role kann alles

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
-- Führe dies im Supabase Dashboard → Storage aus:
-- 1. Neuer Bucket: "realm-auth-app" (public)
-- 2. Ordner: avatars/, posts/
-- 3. Policies:
--    - avatars: Public lesen, Auth schreiben
--    - posts: Public lesen, Auth schreiben

-- ============================================================
-- FERTIG!
-- ============================================================
-- Deine Supabase-URL und anon-Key kommen in:
-- ~/workspace/realm-auth-app/flutter/.env
