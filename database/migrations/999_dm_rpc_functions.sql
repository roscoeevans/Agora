-- Direct Messaging RPC Functions
-- These functions are called by the MessagingServiceLive from the iOS app

-- Function: create_dm_thread
-- Creates a new DM thread and adds participants atomically
CREATE OR REPLACE FUNCTION create_dm_thread(
    thread_id UUID,
    kind TEXT,
    user_ids TEXT[]
)
RETURNS TABLE (
    id UUID,
    kind TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    participants JSON,
    unread_count INT
) AS $$
DECLARE
    v_user_id TEXT;
BEGIN
    -- Insert the thread
    INSERT INTO dms_threads (id, kind, created_at, updated_at)
    VALUES (thread_id, kind, NOW(), NOW());
    
    -- Add participants
    FOREACH v_user_id IN ARRAY user_ids LOOP
        INSERT INTO dms_participants (thread_id, user_id, joined_at)
        VALUES (thread_id, v_user_id::UUID, NOW());
    END LOOP;
    
    -- Return the thread with participant info
    RETURN QUERY
    SELECT 
        t.id,
        t.kind,
        t.created_at,
        t.updated_at,
        (
            SELECT JSON_AGG(
                JSON_BUILD_OBJECT(
                    'id', u.id,
                    'handle', u.handle,
                    'display_handle', u.display_handle,
                    'display_name', u.display_name,
                    'avatar_url', u.avatar_url
                )
            )
            FROM dms_participants p
            JOIN users u ON u.id = p.user_id
            WHERE p.thread_id = t.id
        ) AS participants,
        0 AS unread_count
    FROM dms_threads t
    WHERE t.id = thread_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: fetch_user_conversations
-- Fetches all conversations for a user with pagination
CREATE OR REPLACE FUNCTION fetch_user_conversations(
    user_id TEXT,
    "limit" INT DEFAULT 50,
    "offset" INT DEFAULT 0
)
RETURNS TABLE (
    thread JSON,
    participants JSON,
    last_message JSON,
    unread_count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        JSON_BUILD_OBJECT(
            'id', t.id,
            'kind', t.kind,
            'created_at', t.created_at,
            'updated_at', t.updated_at
        ) AS thread,
        (
            SELECT JSON_AGG(
                JSON_BUILD_OBJECT(
                    'id', u.id,
                    'handle', u.handle,
                    'display_handle', u.display_handle,
                    'display_name', u.display_name,
                    'avatar_url', u.avatar_url
                )
            )
            FROM dms_participants p
            JOIN users u ON u.id = p.user_id
            WHERE p.thread_id = t.id
        ) AS participants,
        (
            SELECT JSON_BUILD_OBJECT(
                'id', m.id,
                'thread_id', m.thread_id,
                'author_id', m.author_id,
                'text', m.text,
                'media_bundle_id', m.media_bundle_id,
                'created_at', m.created_at
            )
            FROM dms_messages m
            WHERE m.thread_id = t.id
            ORDER BY m.created_at DESC
            LIMIT 1
        ) AS last_message,
        (
            SELECT COUNT(*)::INT
            FROM dms_messages m
            WHERE m.thread_id = t.id
            AND m.author_id != user_id::UUID
            -- TODO: Add proper read receipt tracking
        ) AS unread_count
    FROM dms_threads t
    JOIN dms_participants p ON p.thread_id = t.id
    WHERE p.user_id = user_id::UUID
    ORDER BY t.updated_at DESC
    LIMIT "limit"
    OFFSET "offset";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: fetch_thread_messages
-- Fetches messages for a specific thread with pagination
CREATE OR REPLACE FUNCTION fetch_thread_messages(
    thread_id TEXT,
    user_id TEXT,
    before_timestamp TEXT DEFAULT NULL,
    "limit" INT DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    thread_id UUID,
    author_id UUID,
    text TEXT,
    media_bundle_id TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    -- Verify user is a participant in this thread
    IF NOT EXISTS (
        SELECT 1 FROM dms_participants
        WHERE dms_participants.thread_id = fetch_thread_messages.thread_id::UUID
        AND dms_participants.user_id = fetch_thread_messages.user_id::UUID
    ) THEN
        RAISE EXCEPTION 'User is not a participant in this thread';
    END IF;
    
    -- Fetch messages
    RETURN QUERY
    SELECT 
        m.id,
        m.thread_id,
        m.author_id,
        m.text,
        m.media_bundle_id,
        m.created_at
    FROM dms_messages m
    WHERE m.thread_id = fetch_thread_messages.thread_id::UUID
    AND (before_timestamp IS NULL OR m.created_at < before_timestamp::TIMESTAMPTZ)
    ORDER BY m.created_at DESC
    LIMIT "limit";
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: send_dm_message
-- Sends a message to a thread
CREATE OR REPLACE FUNCTION send_dm_message(
    message_id TEXT,
    thread_id TEXT,
    author_id TEXT,
    text TEXT,
    media_bundle_id TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    thread_id UUID,
    author_id UUID,
    text TEXT,
    media_bundle_id TEXT,
    created_at TIMESTAMPTZ
) AS $$
DECLARE
    v_message_id UUID := message_id::UUID;
BEGIN
    -- Verify user is a participant in this thread
    IF NOT EXISTS (
        SELECT 1 FROM dms_participants
        WHERE dms_participants.thread_id = send_dm_message.thread_id::UUID
        AND dms_participants.user_id = send_dm_message.author_id::UUID
    ) THEN
        RAISE EXCEPTION 'User is not a participant in this thread';
    END IF;
    
    -- Insert message
    INSERT INTO dms_messages (id, thread_id, author_id, text, media_bundle_id, created_at)
    VALUES (
        v_message_id,
        send_dm_message.thread_id::UUID,
        send_dm_message.author_id::UUID,
        send_dm_message.text,
        send_dm_message.media_bundle_id,
        NOW()
    );
    
    -- Update thread's updated_at timestamp
    UPDATE dms_threads
    SET updated_at = NOW()
    WHERE dms_threads.id = send_dm_message.thread_id::UUID;
    
    -- Return the created message
    RETURN QUERY
    SELECT 
        m.id,
        m.thread_id,
        m.author_id,
        m.text,
        m.media_bundle_id,
        m.created_at
    FROM dms_messages m
    WHERE m.id = v_message_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_dm_thread TO authenticated;
GRANT EXECUTE ON FUNCTION fetch_user_conversations TO authenticated;
GRANT EXECUTE ON FUNCTION fetch_thread_messages TO authenticated;
GRANT EXECUTE ON FUNCTION send_dm_message TO authenticated;



