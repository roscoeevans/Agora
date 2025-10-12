-- Agora Database Schema v1.0
-- Initial schema for the Agora human-only social platform

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Users table (core user data)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handle TEXT UNIQUE NOT NULL CHECK (handle ~ '^[a-z0-9_]{3,15}$'),
    display_handle TEXT NOT NULL,
    display_name TEXT NOT NULL,
    bio TEXT DEFAULT '',
    avatar_url TEXT,
    apple_sub TEXT UNIQUE,
    phone_e164 TEXT UNIQUE,
    trust_level SMALLINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Devices table (for App Attest + DeviceCheck)
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    app_attest_key_id TEXT,
    devicecheck_token_hash TEXT,
    last_attested_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, app_attest_key_id)
);

-- Sessions table (for auth tokens)
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Media bundles table (for images and videos)
-- Note: Created before posts table since posts references media_bundles
CREATE TABLE media_bundles (
    id BIGSERIAL PRIMARY KEY,
    type TEXT NOT NULL CHECK (type IN ('image', 'video')),
    cf_image_id TEXT,
    cf_stream_id TEXT,
    width INT,
    height INT,
    duration_sec INT,
    nsfw_flag BOOLEAN DEFAULT FALSE,
    ai_detect_score FLOAT DEFAULT 0.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Posts table (main content)
CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text VARCHAR(70) NOT NULL,
    link_url TEXT,
    media_bundle_id BIGINT REFERENCES media_bundles(id),
    reply_to_post_id BIGINT REFERENCES posts(id),
    quote_post_id BIGINT REFERENCES posts(id),
    like_count INT NOT NULL DEFAULT 0,
    repost_count INT NOT NULL DEFAULT 0,
    reply_count INT NOT NULL DEFAULT 0,
    visibility TEXT NOT NULL DEFAULT 'public',
    moderation_state TEXT NOT NULL DEFAULT 'clean',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Follows table (social graph)
CREATE TABLE follows (
    follower_id UUID REFERENCES users(id) ON DELETE CASCADE,
    followee_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (follower_id, followee_id)
);

-- Likes table (post interactions)
CREATE TABLE likes (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    post_id BIGINT REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);

-- Reposts table (repost/quote interactions)
CREATE TABLE reposts (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    post_id BIGINT REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_quote BOOLEAN NOT NULL DEFAULT FALSE,
    quote_text VARCHAR(70),
    PRIMARY KEY (user_id, post_id)
);

-- Reports table (moderation system)
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type TEXT NOT NULL CHECK (target_type IN ('post', 'user')),
    target_id UUID NOT NULL,
    reason TEXT NOT NULL CHECK (reason IN ('abuse', 'spam', 'ai_gen', 'nsfw', 'illegal', 'other')),
    notes TEXT,
    evidence_urls TEXT[],
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Moderation actions table (admin actions)
CREATE TABLE moderation_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_type TEXT NOT NULL CHECK (subject_type IN ('post', 'user')),
    subject_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('remove', 'strike', 'timeout', 'restore', 'ban')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- DM threads table (direct message conversations)
CREATE TABLE dms_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    kind TEXT NOT NULL DEFAULT '1:1' CHECK (kind IN ('1:1', 'group')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- DM participants table (users in each conversation)
CREATE TABLE dms_participants (
    thread_id UUID REFERENCES dms_threads(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (thread_id, user_id)
);

-- DM messages table (individual messages)
CREATE TABLE dms_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES dms_threads(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    media_bundle_id BIGINT REFERENCES media_bundles(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Feed scores table (recommendation system)
CREATE TABLE feed_scores (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    score FLOAT NOT NULL DEFAULT 0.0,
    reason JSONB,
    scored_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);

-- Notifications table (push notifications)
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('like', 'reply', 'repost', 'quote', 'mention', 'follow', 'dm')),
    actor_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    post_id BIGINT REFERENCES posts(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Rate limits table (anti-abuse)
CREATE TABLE rate_limits (
    key TEXT NOT NULL,
    window_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    count INT NOT NULL DEFAULT 0,
    PRIMARY KEY (key, window_start)
);

-- Create indexes for performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_handle_trgm ON users USING GIN (handle gin_trgm_ops);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_display_name_trgm ON users USING GIN (display_name gin_trgm_ops);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_author_created ON posts (author_id, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_text_search ON posts USING GIN (to_tsvector('simple', text));
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_likes ON likes (post_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_posts_likes_user ON likes (user_id, created_at);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_follows_follower ON follows (follower_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_follows_followee ON follows (followee_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_feed_scores_user_score ON feed_scores (user_id, score DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_notifications_user_created ON notifications (user_id, created_at DESC);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_dms_thread_participants ON dms_participants (user_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dms_threads_updated_at BEFORE UPDATE ON dms_threads FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_bundles ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reposts ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE dms_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE dms_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE dms_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE feed_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_limits ENABLE ROW LEVEL SECURITY;

-- RLS Policies for posts (public read, authenticated write)
CREATE POLICY "Posts are viewable by everyone" ON posts FOR SELECT USING (true);
CREATE POLICY "Users can insert their own posts" ON posts FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users can update their own posts" ON posts FOR UPDATE USING (auth.uid() = author_id);
CREATE POLICY "Users can delete their own posts" ON posts FOR DELETE USING (auth.uid() = author_id);

-- RLS Policies for users (public read, authenticated self-update)
CREATE POLICY "User profiles are viewable by everyone" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile" ON users FOR INSERT WITH CHECK (auth.uid() = id);

-- RLS Policies for follows (authenticated users only)
CREATE POLICY "Follows are viewable by everyone" ON follows FOR SELECT USING (true);
CREATE POLICY "Authenticated users can manage follows" ON follows FOR ALL USING (auth.uid() = follower_id);

-- RLS Policies for likes (authenticated users only)
CREATE POLICY "Likes are viewable by everyone" ON likes FOR SELECT USING (true);
CREATE POLICY "Authenticated users can manage likes" ON likes FOR ALL USING (auth.uid() = user_id);

-- RLS Policies for DMs (participants only)
CREATE POLICY "DM participants can view threads" ON dms_threads FOR SELECT USING (
    EXISTS (SELECT 1 FROM dms_participants dp WHERE dp.thread_id = id AND dp.user_id = auth.uid())
);
CREATE POLICY "DM participants can view messages" ON dms_messages FOR SELECT USING (
    EXISTS (SELECT 1 FROM dms_participants dp WHERE dp.thread_id = thread_id AND dp.user_id = auth.uid())
);
CREATE POLICY "DM participants can send messages" ON dms_messages FOR INSERT WITH CHECK (
    auth.uid() = author_id AND
    EXISTS (SELECT 1 FROM dms_participants dp WHERE dp.thread_id = thread_id AND dp.user_id = auth.uid())
);

-- RLS Policies for notifications (own notifications only)
CREATE POLICY "Users can view their own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can insert notifications" ON notifications FOR INSERT WITH CHECK (true);

-- RLS Policies for reports (reporters can view their own)
CREATE POLICY "Users can view their own reports" ON reports FOR SELECT USING (auth.uid() = reporter_id);
CREATE POLICY "Users can create reports" ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- RLS Policies for moderation actions (admin only - simplified for MVP)
CREATE POLICY "Moderation actions are viewable by everyone" ON moderation_actions FOR SELECT USING (true);
CREATE POLICY "System can create moderation actions" ON moderation_actions FOR INSERT WITH CHECK (true);

-- Create initial admin user (you'll need to set this up manually)
-- INSERT INTO users (id, handle, display_name, trust_level) VALUES ('00000000-0000-0000-0000-000000000000', 'admin', 'System Administrator', 10);
