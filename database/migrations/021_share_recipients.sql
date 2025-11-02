-- Migration: Share Recipients RPC Functions
-- Description: Functions for fetching recent DM recipients and follows for share menu
-- Author: Agora AI
-- Date: 2025-11-01

-- Function: fetch_recent_dm_recipients
-- Fetches distinct peer users from recent conversations for share menu
CREATE OR REPLACE FUNCTION fetch_recent_dm_recipients(
    p_user_id TEXT,
    p_limit INT DEFAULT 3
)
RETURNS TABLE (
    id TEXT,
    handle TEXT,
    display_name TEXT,
    avatar_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (p.id)
        p.id::TEXT as id,
        p.handle,
        p.display_name,
        p.avatar_url
    FROM dm_threads dt
    JOIN dm_thread_participants dtp ON dt.id = dtp.thread_id
    JOIN dm_thread_participants dtp2 ON dt.id = dtp2.thread_id
    JOIN profiles p ON dtp2.user_id = p.id
    WHERE dtp.user_id = p_user_id::UUID
      AND dtp2.user_id != p_user_id::UUID
      AND dt.kind = '1:1'
    ORDER BY p.id, dt.updated_at DESC
    LIMIT p_limit;
END;
$$;

-- Function: fetch_recent_follows
-- Fetches recent follows as fallback for share menu
CREATE OR REPLACE FUNCTION fetch_recent_follows(
    p_user_id TEXT,
    p_limit INT DEFAULT 3
)
RETURNS TABLE (
    id TEXT,
    handle TEXT,
    display_name TEXT,
    avatar_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.id::TEXT as id,
        p.handle,
        p.display_name,
        p.avatar_url
    FROM follows f
    JOIN profiles p ON f.following_id = p.id
    WHERE f.follower_id = p_user_id::UUID
    ORDER BY f.created_at DESC
    LIMIT p_limit;
END;
$$;

-- Function: find_or_create_1to1_conversation
-- Finds existing 1:1 conversation or returns empty for creation
CREATE OR REPLACE FUNCTION find_or_create_1to1_conversation(
    p_user_id TEXT,
    p_recipient_id TEXT
)
RETURNS TABLE (
    id UUID,
    kind TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    last_message_at TIMESTAMPTZ,
    last_message_text TEXT,
    last_message_author_id UUID,
    participant_ids UUID[],
    participant_handles TEXT[],
    participant_display_names TEXT[],
    participant_avatar_urls TEXT[],
    unread_count INT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Find existing 1:1 conversation
    RETURN QUERY
    SELECT
        dt.id,
        dt.kind,
        dt.created_at,
        dt.updated_at,
        dt.last_message_at,
        dt.last_message_text,
        dt.last_message_author_id,
        ARRAY_AGG(DISTINCT dtp.user_id) as participant_ids,
        ARRAY_AGG(DISTINCT p.handle) as participant_handles,
        ARRAY_AGG(DISTINCT p.display_name) as participant_display_names,
        ARRAY_AGG(DISTINCT p.avatar_url) as participant_avatar_urls,
        COALESCE(
            (SELECT COUNT(*)::INT
             FROM dm_messages m
             WHERE m.thread_id = dt.id
               AND m.author_id != p_user_id::UUID
               AND m.created_at > COALESCE(
                   (SELECT last_read_at
                    FROM dm_thread_participants
                    WHERE thread_id = dt.id AND user_id = p_user_id::UUID),
                   '1970-01-01'::TIMESTAMPTZ
               )
            ), 0
        ) as unread_count
    FROM dm_threads dt
    JOIN dm_thread_participants dtp ON dt.id = dtp.thread_id
    JOIN profiles p ON dtp.user_id = p.id
    WHERE dt.kind = '1:1'
      AND dt.id IN (
          SELECT thread_id
          FROM dm_thread_participants
          WHERE user_id = p_user_id::UUID
      )
      AND dt.id IN (
          SELECT thread_id
          FROM dm_thread_participants
          WHERE user_id = p_recipient_id::UUID
      )
    GROUP BY dt.id, dt.kind, dt.created_at, dt.updated_at, dt.last_message_at,
             dt.last_message_text, dt.last_message_author_id
    LIMIT 1;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION fetch_recent_dm_recipients(TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION fetch_recent_follows(TEXT, INT) TO authenticated;
GRANT EXECUTE ON FUNCTION find_or_create_1to1_conversation(TEXT, TEXT) TO authenticated;


