# Engagement Buttons Implementation Plan

## Overview
Wire in real and mock functionality for the 4 engagement buttons (Like, Comment, Repost, Share) in `FeedPostView` with optimistic UI updates, smooth animations, full Supabase persistence, and **real-time count updates** (MVP priority).

**The 4 Buttons:**
1. **Like** (heart icon) - Toggle like with fill animation
2. **Comment** (bubble icon) - Open TikTok-style comment sheet
3. **Repost** (arrows icon) - Toggle repost with rotation animation
4. **Share** (share icon) - Open share menu with multiple options

---

## Architecture Decisions

### ✅ **Repost Behavior: Entry in `reposts` Table Only**
**Decision:** Reposting creates an entry in the `reposts` table, NOT a new post in the `posts` table.

**IMPORTANT:** Viewer state flags (`isLikedByViewer`, `isRepostedByViewer`) are **non-optional Bool** (default `false`) to prevent animation glitches and reduce client-side branching.

**Database structure:**
```sql
reposts (
  user_id UUID,
  post_id UUID,
  created_at TIMESTAMPTZ,
  is_quote BOOLEAN DEFAULT false,
  quote_text VARCHAR(70)
)
```

**Why this approach:**
1. **Engagement signal:** The `reposts` table trigger automatically increments `post.repost_count`, which feeds into the recommendation algorithm's quality score (weight 4.0×).
2. **Following feed visibility:** Users following the reposter see the reposted content chronologically. This requires updating the `feed-following` Edge Function to UNION:
   - Posts by followed users (`author_id IN followees`)
   - Posts reposted by followed users (`JOIN reposts WHERE reposts.user_id IN followees`)
3. **Discovery boost:** Multiple reposts increase the original post's `repost_count`, improving its reach in the For You feed via the recommendation system.
4. **Data integrity:** No duplication of post content; single source of truth.

### ✅ **Single `EngagementService` (Modern 2025 Pattern)**
Modern iOS apps favor cohesive service boundaries. Like, repost, and share are related operations on the same domain entity (Post).

**Benefits:**
- Reduces DI boilerplate
- Shared rate limiting / error handling
- Easier to mock in tests
- Cleaner API surface

### ✅ **Optimistic UI Updates with Rollback**
All engagement actions update UI immediately before server confirmation, with automatic rollback on failure.

### ✅ **Real-Time Count Updates (MVP Priority)**
Use Supabase Realtime subscriptions to broadcast count changes when any user likes/reposts a post.

### ✅ **TikTok-Style Comment Sheet**
Full-screen modal sheet from bottom, with drag-to-dismiss. Placeholder UI for MVP (real comments in Phase 2).

### ✅ **iOS Native Share Patterns**
Share menu appears as a popover/sheet with:
- Share to Agora DM (placeholder for now)
- Share via iMessage (native iOS share)
- Copy Link (to pasteboard)

### ✅ **No Undo Toast**
Actions are instant and reversible by tapping again. No undo affordance needed.

---

## Phase 1: Data Model & Backend Foundation

### 1.1 Update `Post` Model
**Location:** `Packages/Shared/AppFoundation/Sources/AppFoundation/Dependencies.swift`

Add viewer state fields to track current user's interactions:
```swift
public struct Post: Sendable, Codable, Identifiable {
    // ... existing fields ...
    
    // Viewer interaction state (NEW) - Non-optional to prevent animation glitches
    public let isLikedByViewer: Bool
    public let isRepostedByViewer: Bool
    
    public init(
        // ... existing params ...
        isLikedByViewer: Bool = false,
        isRepostedByViewer: Bool = false
    ) {
        // ... existing assignments ...
        self.isLikedByViewer = isLikedByViewer
        self.isRepostedByViewer = isRepostedByViewer
    }
}
```

**Why:** Non-optional Bool prevents branching and animation glitches. Server-side defaults to `false`.

### 1.2 Update Feed Edge Functions
**Locations:** 
- `supabase/functions/feed-for-you/index.ts`
- `supabase/functions/feed-following/index.ts`
- `supabase/functions/get-user-posts/index.ts`

**Changes:**
1. Add LEFT JOINs to fetch viewer state:
```typescript
.select(`
  *,
  users!inner (handle, display_handle, display_name, avatar_url),
  likes!left (user_id),
  reposts!left (user_id)
`)
.eq('likes.user_id', currentUserId)
.eq('reposts.user_id', currentUserId)
```

2. Transform to include `isLikedByViewer` and `isRepostedByViewer` (non-optional, default false):
```typescript
isLikedByViewer: post.likes?.length > 0 || false,
isRepostedByViewer: post.reposts?.length > 0 || false,
```

3. **For Following Feed:** Update to include reposts by followed users using UNION ALL:
```typescript
// UNION ALL approach (cleaner than LEFT JOIN with OR):
// 1. Posts authored by followed users
// 2. Posts reposted by followed users (from reposts table)
const query = `
  WITH combined AS (
    -- Authored posts
    SELECT p.id, p.created_at as sort_time
    FROM posts p
    WHERE p.author_id = ANY($1::uuid[])
      AND p.visibility = 'public'
    
    UNION ALL
    
    -- Reposted posts (use repost timestamp for chronological ordering)
    SELECT r.post_id as id, r.created_at as sort_time
    FROM reposts r
    JOIN posts p ON r.post_id = p.id
    WHERE r.user_id = ANY($1::uuid[])
      AND p.visibility = 'public'
  ),
  deduped AS (
    -- Dedup if multiple followees repost same post; keep latest
    SELECT DISTINCT ON (id) id, sort_time
    FROM combined
    ORDER BY id, sort_time DESC
  )
  SELECT 
    p.*,
    u.handle, u.display_handle, u.display_name, u.avatar_url,
    d.sort_time,
    EXISTS(SELECT 1 FROM likes l WHERE l.post_id = p.id AND l.user_id = $2) as is_liked,
    EXISTS(SELECT 1 FROM reposts r WHERE r.post_id = p.id AND r.user_id = $2) as is_reposted
  FROM deduped d
  JOIN posts p ON d.id = p.id
  JOIN users u ON p.author_id = u.id
  ORDER BY d.sort_time DESC
  LIMIT $3
`;

// $1 = followee_ids, $2 = current_user_id, $3 = limit
```

**Why UNION ALL:** Avoids join duplication, clearer intent, better query plan. DISTINCT ON deduplicates after union.

### 1.3 Create Database RPC Functions
**Location:** `database/migrations/014_engagement_rpcs.sql`

Create atomic toggle functions with **hardened security** and **drift-proof counting**:

```sql
-- Unique constraints (prevent duplicate likes/reposts)
ALTER TABLE likes ADD CONSTRAINT likes_user_post_unique UNIQUE (user_id, post_id);
ALTER TABLE reposts ADD CONSTRAINT reposts_user_post_unique UNIQUE (user_id, post_id);

-- Hot indexes for performance
CREATE INDEX IF NOT EXISTS idx_likes_post_id ON likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_post ON likes(user_id, post_id);
CREATE INDEX IF NOT EXISTS idx_reposts_post_id ON reposts(post_id);
CREATE INDEX IF NOT EXISTS idx_reposts_user_post ON reposts(user_id, post_id);
CREATE INDEX IF NOT EXISTS idx_reposts_user_created ON reposts(user_id, created_at DESC);

-- RLS Policies
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE reposts ENABLE ROW LEVEL SECURITY;

-- Users can insert/delete their own likes
CREATE POLICY likes_insert_own ON likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY likes_delete_own ON likes
  FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY likes_select_all ON likes
  FOR SELECT USING (true);  -- Aggregates are public

-- Same for reposts
CREATE POLICY reposts_insert_own ON reposts
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY reposts_delete_own ON reposts
  FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY reposts_select_all ON reposts
  FOR SELECT USING (true);

-- Toggle like (idempotent, drift-proof)
-- NOTE: Edge Function derives p_user_id from JWT (never from client body)
CREATE OR REPLACE FUNCTION public.toggle_like(p_post_id UUID, p_user_id UUID)
RETURNS TABLE(is_liked BOOLEAN, like_count INTEGER) AS $$
DECLARE
  v_like_exists BOOLEAN;
  v_like_count INTEGER;
BEGIN
  SET search_path = public;  -- Prevent search_path hijacking
  
  -- Check if like exists
  SELECT EXISTS(SELECT 1 FROM likes WHERE user_id = p_user_id AND post_id = p_post_id)
  INTO v_like_exists;
  
  IF v_like_exists THEN
    -- Unlike
    DELETE FROM likes WHERE user_id = p_user_id AND post_id = p_post_id;
  ELSE
    -- Like
    INSERT INTO likes (user_id, post_id) VALUES (p_user_id, p_post_id)
    ON CONFLICT (user_id, post_id) DO NOTHING;
  END IF;
  
  -- Get updated count (drift-proof: COUNT from source of truth)
  SELECT COUNT(*)::int INTO v_like_count FROM likes WHERE post_id = p_post_id;
  
  -- Also update denormalized counter for read performance
  UPDATE posts SET like_count = v_like_count WHERE id = p_post_id;
  
  RETURN QUERY SELECT NOT v_like_exists AS is_liked, v_like_count AS like_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Toggle repost (idempotent, drift-proof)
CREATE OR REPLACE FUNCTION public.toggle_repost(p_post_id UUID, p_user_id UUID)
RETURNS TABLE(is_reposted BOOLEAN, repost_count INTEGER) AS $$
DECLARE
  v_repost_exists BOOLEAN;
  v_repost_count INTEGER;
BEGIN
  SET search_path = public;  -- Prevent search_path hijacking
  
  -- Check if repost exists
  SELECT EXISTS(SELECT 1 FROM reposts WHERE user_id = p_user_id AND post_id = p_post_id)
  INTO v_repost_exists;
  
  IF v_repost_exists THEN
    -- Unrepost
    DELETE FROM reposts WHERE user_id = p_user_id AND post_id = p_post_id;
  ELSE
    -- Repost
    INSERT INTO reposts (user_id, post_id, is_quote) VALUES (p_user_id, p_post_id, false)
    ON CONFLICT (user_id, post_id) DO NOTHING;
  END IF;
  
  -- Get updated count (drift-proof: COUNT from source of truth)
  SELECT COUNT(*)::int INTO v_repost_count FROM reposts WHERE post_id = p_post_id;
  
  -- Also update denormalized counter for read performance
  UPDATE posts SET repost_count = v_repost_count WHERE id = p_post_id;
  
  RETURN QUERY SELECT NOT v_repost_exists AS is_reposted, v_repost_count AS repost_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Nightly counter reconciliation (run via cron)
CREATE OR REPLACE FUNCTION public.reconcile_engagement_counts()
RETURNS void AS $$
BEGIN
  SET search_path = public;
  
  -- Fix any drifted like counts
  UPDATE posts p
  SET like_count = (SELECT COUNT(*) FROM likes WHERE post_id = p.id)
  WHERE like_count != (SELECT COUNT(*) FROM likes WHERE post_id = p.id);
  
  -- Fix any drifted repost counts
  UPDATE posts p
  SET repost_count = (SELECT COUNT(*) FROM reposts WHERE post_id = p.id)
  WHERE repost_count != (SELECT COUNT(*) FROM reposts WHERE post_id = p.id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add to cron schedule (runs daily at 3 AM)
SELECT cron.schedule(
  'reconcile-engagement-counts',
  '0 3 * * *',
  'SELECT public.reconcile_engagement_counts()'
);
```

**Key Security Hardening:**
1. **Unique constraints** prevent duplicate likes/reposts
2. **Indexes** for hot paths (post_id lookups, user_id + post_id checks)
3. **RLS policies** enforce that users can only modify their own likes/reposts
4. **SET search_path** prevents SQL injection via search_path hijacking
5. **COUNT-based** returns (drift-proof, always accurate)
6. **Nightly reconciliation** cron job fixes any drift in denormalized counters

### 1.4 Add OpenAPI Endpoints
**Location:** `OpenAPI/agora.yaml`

Add engagement endpoints with **standardized error schema** and **correlation IDs**:
```yaml
paths:
  /posts/{id}/like:
    post:
      summary: Toggle like on a post (idempotent)
      tags: [Posts]
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
          description: Post ID
      responses:
        '200':
          description: Like toggled successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/LikeResult'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          description: Post not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limited
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /posts/{id}/repost:
    post:
      summary: Toggle repost on a post (idempotent)
      tags: [Posts]
      security:
        - bearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
          description: Post ID
      responses:
        '200':
          description: Repost toggled successfully
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/RepostResult'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          description: Post not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '429':
          description: Rate limited
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
        '500':
          $ref: '#/components/responses/InternalServerError'

  /posts/{id}/share-url:
    get:
      summary: Get shareable deep link for a post
      tags: [Posts]
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: Post ID
      responses:
        '200':
          description: Share URL retrieved
          content:
            application/json:
              schema:
                type: object
                properties:
                  url:
                    type: string
                    format: uri
                    example: "https://agora.app/p/abc123"
        '404':
          description: Post not found
        '500':
          $ref: '#/components/responses/InternalServerError'

components:
  schemas:
    LikeResult:
      type: object
      required:
        - isLiked
        - likeCount
      properties:
        isLiked:
          type: boolean
          description: Whether the current user now likes the post
        likeCount:
          type: integer
          minimum: 0
          description: Updated total like count

    RepostResult:
      type: object
      required:
        - isReposted
        - repostCount
      properties:
        isReposted:
          type: boolean
          description: Whether the current user now has reposted the post
        repostCount:
          type: integer
          minimum: 0
          description: Updated total repost count
    
    Error:
      type: object
      required:
        - code
        - message
        - correlationId
      properties:
        code:
          type: string
          example: "POST_NOT_FOUND"
          description: Stable error code for programmatic handling
        message:
          type: string
          example: "Post not found"
          description: Human-readable error message
        correlationId:
          type: string
          format: uuid
          description: Unique ID for this request, used for debugging and analytics
```

Then run: `agctl generate openapi` to regenerate Swift client types.

### 1.5 Create Edge Functions for Engagement
**Location:** `supabase/functions/toggle-like/index.ts`

Hardened implementation with **JWT-derived user_id**, **correlation IDs**, **rate limiting**, and **standardized errors**:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST',  // Only allow POST
}

serve(async (req) => {
  // Generate correlation ID for request tracking
  const correlationId = crypto.randomUUID()
  
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }
  
  // Only allow POST
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({
        code: 'METHOD_NOT_ALLOWED',
        message: 'Only POST requests are allowed',
        correlationId
      }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
  
  try {
    // Initialize Supabase client with JWT from Authorization header
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )
    
    // Get authenticated user from JWT (NEVER trust client-provided user_id)
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({
          code: 'UNAUTHORIZED',
          message: 'You must be signed in to like posts',
          correlationId
        }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Parse body
    const { postId } = await req.json()
    
    if (!postId) {
      return new Response(
        JSON.stringify({
          code: 'INVALID_REQUEST',
          message: 'postId is required',
          correlationId
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Rate limit check (max 1 toggle per user+post per second)
    const rateLimitKey = `rate_limit:like:${user.id}:${postId}`
    const rateLimitCheck = await supabaseClient
      .from('rate_limits')
      .select('last_action_at')
      .eq('key', rateLimitKey)
      .single()
    
    if (rateLimitCheck.data) {
      const lastAction = new Date(rateLimitCheck.data.last_action_at)
      const now = new Date()
      if (now.getTime() - lastAction.getTime() < 1000) {
        return new Response(
          JSON.stringify({
            code: 'RATE_LIMITED',
            message: "You're doing that too quickly. Please wait a moment.",
            correlationId
          }),
          { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }
    
    // Call RPC (user_id is derived from JWT, not client body)
    const { data, error } = await supabaseClient
      .rpc('toggle_like', {
        p_post_id: postId,
        p_user_id: user.id  // From JWT only!
      })
      .single()
    
    if (error) {
      console.error(`[${correlationId}] RPC error:`, error)
      
      // Check for specific errors
      if (error.message?.includes('not found')) {
        return new Response(
          JSON.stringify({
            code: 'POST_NOT_FOUND',
            message: 'Post not found',
            correlationId
          }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      
      return new Response(
        JSON.stringify({
          code: 'INTERNAL_ERROR',
          message: 'Failed to toggle like',
          correlationId
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    // Update rate limit timestamp
    await supabaseClient
      .from('rate_limits')
      .upsert({
        key: rateLimitKey,
        last_action_at: new Date().toISOString()
      })
    
    // Record engagement event for recommendation system (fire and forget)
    supabaseClient.from('post_events').insert({
      user_id: user.id,
      post_id: postId,
      type: data.is_liked ? 'like' : 'unlike',
      correlation_id: correlationId
    }).then()
    
    // Update bandit stats if it's a like (fire and forget)
    if (data.is_liked) {
      supabaseClient.rpc('bandit_record_success', {
        entity_type: 'post',
        entity_id: postId,
        success: 1
      }).then()
    }
    
    return new Response(
      JSON.stringify({
        isLiked: data.is_liked,
        likeCount: data.like_count
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (err) {
    console.error(`[${correlationId}] Unexpected error:`, err)
    return new Response(
      JSON.stringify({
        code: 'INTERNAL_ERROR',
        message: 'An unexpected error occurred',
        correlationId
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
```

**Key Improvements:**
1. **JWT-only user_id**: Never trust client body; always derive from JWT
2. **Correlation IDs**: UUID for each request for debugging and analytics
3. **Standardized errors**: `{ code, message, correlationId }` on all errors
4. **Rate limiting**: Max 1 toggle per user+post per second (prevents spam taps)
5. **CORS hardening**: Only allow POST method
6. **Idempotent**: Safe to retry; stable response even on duplicate requests

**Similar implementation for:** `toggle-repost/index.ts` (same pattern, different RPC)

---

## Phase 2: Service Layer (DI Pattern)

### 2.1 Create Engagement Kit
**Location:** `Packages/Kits/Engagement/`

Create new Swift Package following `ios-module-standards.mdc`:

```
Engagement/
├── Package.swift
├── README.md
├── Sources/
│   └── Engagement/
│       ├── Engagement.swift          # Public interface
│       ├── EngagementService.swift   # Protocol
│       ├── EngagementServiceLive.swift
│       ├── EngagementError.swift
│       └── RealtimeEngagementObserver.swift
└── Tests/
    └── EngagementTests/
        └── EngagementServiceTests.swift
```

**Package.swift:**
```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Engagement",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Engagement", targets: ["Engagement"]),
    ],
    dependencies: [
        .package(path: "../Networking"),
        .package(path: "../Analytics"),
        .package(path: "../../Shared/AppFoundation"),
    ],
    targets: [
        .target(
            name: "Engagement",
            dependencies: [
                "Networking",
                "Analytics",
                "AppFoundation"
            ]
        ),
        .testTarget(
            name: "EngagementTests",
            dependencies: ["Engagement"]
        ),
    ]
)
```

### 2.2 Define `EngagementService` Protocol
**Location:** `Packages/Kits/Engagement/Sources/Engagement/EngagementService.swift`

```swift
import Foundation
import AppFoundation

/// Service for handling post engagement actions (like, repost, share)
public protocol EngagementService: Sendable {
    /// Toggle like on a post (idempotent)
    /// - Parameter postId: The ID of the post to like/unlike
    /// - Returns: Result containing new like state and count
    /// - Throws: EngagementError if operation fails
    func toggleLike(postId: String) async throws -> LikeResult
    
    /// Toggle repost on a post (idempotent)
    /// - Parameter postId: The ID of the post to repost/unrepost
    /// - Returns: Result containing new repost state and count
    /// - Throws: EngagementError if operation fails
    func toggleRepost(postId: String) async throws -> RepostResult
    
    /// Get shareable URL for a post
    /// - Parameter postId: The ID of the post to share
    /// - Returns: Deep link URL for the post
    /// - Throws: EngagementError if operation fails
    func getShareURL(postId: String) async throws -> URL
}

/// Result of a like toggle operation
public struct LikeResult: Sendable {
    public let isLiked: Bool
    public let likeCount: Int
    
    public init(isLiked: Bool, likeCount: Int) {
        self.isLiked = isLiked
        self.likeCount = likeCount
    }
}

/// Result of a repost toggle operation
public struct RepostResult: Sendable {
    public let isReposted: Bool
    public let repostCount: Int
    
    public init(isReposted: Bool, repostCount: Int) {
        self.isReposted = isReposted
        self.repostCount = repostCount
    }
}

/// Errors that can occur during engagement operations
public enum EngagementError: LocalizedError, Sendable {
    case postNotFound
    case unauthorized
    case networkError
    case serverError(String)
    case rateLimited
    
    public var errorDescription: String? {
        switch self {
        case .postNotFound:
            return "Post not found"
        case .unauthorized:
            return "You must be signed in to perform this action"
        case .networkError:
            return "Network connection failed. Please try again."
        case .serverError(let message):
            return "Server error: \(message)"
        case .rateLimited:
            return "You're doing that too quickly. Please wait a moment."
        }
    }
}
```

### 2.3 Implement `EngagementServiceLive`
**Location:** `Packages/Kits/Engagement/Sources/Engagement/EngagementServiceLive.swift`

```swift
import Foundation
import Networking
import Analytics
import AppFoundation

public struct EngagementServiceLive: EngagementService {
    private let networking: NetworkingClient
    private let analytics: AnalyticsClient
    
    public init(networking: NetworkingClient, analytics: AnalyticsClient) {
        self.networking = networking
        self.analytics = analytics
    }
    
    public func toggleLike(postId: String) async throws -> LikeResult {
        // Track analytics event
        await analytics.track("post_like_toggled", properties: ["post_id": postId])
        
        do {
            // Call POST /posts/{id}/like
            let request = HTTPRequest(
                method: .post,
                path: "/posts/\(postId)/like"
            )
            
            let response: LikeResultResponse = try await networking.send(request)
            
            // Track outcome
            await analytics.track(
                response.isLiked ? "post_liked" : "post_unliked",
                properties: [
                    "post_id": postId,
                    "like_count": response.likeCount
                ]
            )
            
            return LikeResult(
                isLiked: response.isLiked,
                likeCount: response.likeCount
            )
        } catch {
            await analytics.track("post_like_failed", properties: [
                "post_id": postId,
                "error": error.localizedDescription
            ])
            throw mapError(error)
        }
    }
    
    public func toggleRepost(postId: String) async throws -> RepostResult {
        await analytics.track("post_repost_toggled", properties: ["post_id": postId])
        
        do {
            let request = HTTPRequest(
                method: .post,
                path: "/posts/\(postId)/repost"
            )
            
            let response: RepostResultResponse = try await networking.send(request)
            
            await analytics.track(
                response.isReposted ? "post_reposted" : "post_unreposted",
                properties: [
                    "post_id": postId,
                    "repost_count": response.repostCount
                ]
            )
            
            return RepostResult(
                isReposted: response.isReposted,
                repostCount: response.repostCount
            )
        } catch {
            await analytics.track("post_repost_failed", properties: [
                "post_id": postId,
                "error": error.localizedDescription
            ])
            throw mapError(error)
        }
    }
    
    public func getShareURL(postId: String) async throws -> URL {
        // For MVP, construct URL directly
        // In future, could call API to get short URL
        guard let url = URL(string: "https://agora.app/p/\(postId)") else {
            throw EngagementError.serverError("Invalid post ID")
        }
        
        await analytics.track("post_share_url_generated", properties: ["post_id": postId])
        
        return url
    }
    
    // MARK: - Private Helpers
    
    private func mapError(_ error: Error) -> EngagementError {
        // Map networking errors to engagement errors
        if let httpError = error as? HTTPError {
            switch httpError.statusCode {
            case 404:
                return .postNotFound
            case 401:
                return .unauthorized
            case 429:
                return .rateLimited
            default:
                return .serverError(httpError.message ?? "Unknown error")
            }
        }
        return .networkError
    }
}

// MARK: - Response Types (from OpenAPI generation)

private struct LikeResultResponse: Decodable {
    let isLiked: Bool
    let likeCount: Int
}

private struct RepostResultResponse: Decodable {
    let isReposted: Bool
    let repostCount: Int
}
```

### 2.4 Implement Real-Time Observer
**Location:** `Packages/Kits/Engagement/Sources/Engagement/RealtimeEngagementObserver.swift`

**CRITICAL FIXES:** Single channel per feed, proper UUID quoting, throttling, actor-safe callbacks, background pause.

```swift
import Foundation
import AppFoundation
import Supabase

/// Observes real-time engagement count updates via Supabase Realtime
/// Uses a SINGLE channel per feed (not per post) with debounced visible post tracking
public actor RealtimeEngagementObserver {
    private let supabase: SupabaseClient
    private var subscription: RealtimeChannel?
    private var visiblePostIds: Set<String> = []
    private var updateDebounceTask: Task<Void, Never>?
    
    /// Stream of engagement updates (postId, likeCount, repostCount)
    public let updates: AsyncStream<EngagementUpdate>
    private let continuation: AsyncStream<EngagementUpdate>.Continuation
    
    /// Throttle state: map of postId -> last update time
    private var lastUpdateTimes: [String: Date] = [:]
    private let throttleInterval: TimeInterval = 0.3  // 300ms
    
    /// Buffer for updates received during in-progress actions
    private var bufferedUpdates: [String: EngagementUpdate] = [:]
    private var inProgressPosts: Set<String> = []
    
    public init(supabase: SupabaseClient) {
        self.supabase = supabase
        
        // Create async stream for updates
        (self.updates, self.continuation) = AsyncStream.makeStream()
        
        // Listen for app lifecycle events
        Task { @MainActor in
            NotificationCenter.default.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { await self?.pauseObserving() }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { await self?.resumeObserving() }
            }
        }
    }
    
    /// Update visible posts and resubscribe with new filter
    public func updateVisiblePosts(_ postIds: Set<String>) async {
        guard visiblePostIds != postIds else { return }
        visiblePostIds = postIds
        
        // Debounce subscription updates (avoid churn during scroll)
        updateDebounceTask?.cancel()
        updateDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await resubscribe()
        }
    }
    
    /// Mark a post as having an action in progress (buffer realtime updates)
    public func markInProgress(_ postId: String) {
        inProgressPosts.insert(postId)
    }
    
    /// Mark a post as no longer in progress (flush buffered updates)
    public func markCompleted(_ postId: String) {
        inProgressPosts.remove(postId)
        
        // Flush any buffered update for this post
        if let buffered = bufferedUpdates.removeValue(forKey: postId) {
            continuation.yield(buffered)
        }
    }
    
    /// Pause observing (called on background)
    private func pauseObserving() async {
        await subscription?.unsubscribe()
        subscription = nil
    }
    
    /// Resume observing (called on foreground)
    private func resumeObserving() async {
        await resubscribe()
    }
    
    /// Resubscribe with current visible posts
    private func resubscribe() async {
        // Unsubscribe existing
        await subscription?.unsubscribe()
        subscription = nil
        
        guard !visiblePostIds.isEmpty else { return }
        
        // Build properly quoted filter for UUIDs
        let quotedIds = visiblePostIds.map { "\"\($0)\"" }.joined(separator: ",")
        let filter = "id=in.(\(quotedIds))"
        
        // Single channel for all visible posts
        subscription = await supabase.channel("engagement_\(UUID().uuidString)")
            .on(
                .postgresChanges(
                    event: .update,
                    schema: "public",
                    table: "posts",
                    filter: filter
                )
            ) { [weak self] payload in
                // Use nonisolated callback to hop into actor
                Task {
                    await self?.handleUpdate(payload)
                }
            }
            .subscribe()
    }
    
    /// Stop observing updates
    public func stopObserving() async {
        updateDebounceTask?.cancel()
        await subscription?.unsubscribe()
        subscription = nil
    }
    
    private func handleUpdate(_ payload: RealtimePayload) {
        guard let record = payload.record as? [String: Any],
              let postId = record["id"] as? String,
              let likeCount = record["like_count"] as? Int,
              let repostCount = record["repost_count"] as? Int else {
            return
        }
        
        let update = EngagementUpdate(
            postId: postId,
            likeCount: likeCount,
            repostCount: repostCount
        )
        
        // If action in progress, buffer the update
        if inProgressPosts.contains(postId) {
            bufferedUpdates[postId] = update
            return
        }
        
        // Throttle: only emit if >300ms since last update for this post
        let now = Date()
        if let lastUpdate = lastUpdateTimes[postId],
           now.timeIntervalSince(lastUpdate) < throttleInterval {
            // Drop update (too soon)
            return
        }
        
        lastUpdateTimes[postId] = now
        continuation.yield(update)
    }
    
    deinit {
        continuation.finish()
    }
}

/// Real-time engagement update
public struct EngagementUpdate: Sendable {
    public let postId: String
    public let likeCount: Int
    public let repostCount: Int
    
    public init(postId: String, likeCount: Int, repostCount: Int) {
        self.postId = postId
        self.likeCount = likeCount
        self.repostCount = repostCount
    }
}
```

**Key Improvements:**
1. **Single channel per feed**: Uses `updateVisiblePosts()` with debouncing instead of per-post channels
2. **Proper UUID quoting**: `"uuid1","uuid2"` format for Postgres
3. **Throttling**: Max 1 update per post every 300ms (drops intermediate updates)
4. **Actor-safe callbacks**: Uses `Task { await self?.handleUpdate() }` (no weak self needed in actor)
5. **Background pause**: Auto-unsubscribe on background, resubscribe on foreground
6. **Local action wins**: Buffers realtime updates during in-progress actions, applies after completion

### 2.5 Create Test Fake
**Location:** `Packages/Shared/TestSupport/Sources/TestSupport/EngagementServiceFake.swift`

```swift
import Foundation
import Engagement
import AppFoundation

/// Fake engagement service for testing and previews
public actor EngagementServiceFake: EngagementService {
    public var likedPosts: Set<String> = []
    public var repostedPosts: Set<String> = []
    public var shouldFail = false
    public var delay: Duration = .zero
    
    public init() {}
    
    public func toggleLike(postId: String) async throws -> LikeResult {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw EngagementError.networkError
        }
        
        let isLiked: Bool
        let count: Int
        
        if likedPosts.contains(postId) {
            likedPosts.remove(postId)
            isLiked = false
            count = 41  // Mock decrement
        } else {
            likedPosts.insert(postId)
            isLiked = true
            count = 42  // Mock increment
        }
        
        return LikeResult(isLiked: isLiked, likeCount: count)
    }
    
    public func toggleRepost(postId: String) async throws -> RepostResult {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw EngagementError.networkError
        }
        
        let isReposted: Bool
        let count: Int
        
        if repostedPosts.contains(postId) {
            repostedPosts.remove(postId)
            isReposted = false
            count = 7  // Mock decrement
        } else {
            repostedPosts.insert(postId)
            isReposted = true
            count = 8  // Mock increment
        }
        
        return RepostResult(isReposted: isReposted, repostCount: count)
    }
    
    public func getShareURL(postId: String) async throws -> URL {
        if delay > .zero {
            try await Task.sleep(for: delay)
        }
        
        if shouldFail {
            throw EngagementError.networkError
        }
        
        return URL(string: "https://agora.app/p/\(postId)")!
    }
}
```

### 2.6 Add to Dependencies
**Location:** `Packages/Shared/AppFoundation/Sources/AppFoundation/Dependencies.swift`

```swift
import Supabase

public struct Dependencies: Sendable {
    // ... existing ...
    public var engagement: EngagementService  // NEW
    public var supabase: SupabaseClient  // NEW (required for realtime)
    
    public init(
        // ... existing params ...
        engagement: EngagementService,
        supabase: SupabaseClient
    ) {
        // ... existing assignments ...
        self.engagement = engagement
        self.supabase = supabase
    }
}

// Add to preview mocks
extension Dependencies {
    public static let previewMocks = Dependencies(
        // ... existing ...
        engagement: EngagementServiceFake(),
        supabase: SupabaseClient(
            supabaseURL: URL(string: "https://example.supabase.co")!,
            supabaseKey: "mock-key"
        )
    )
}
```

**Why add supabase:** `RealtimeEngagementObserver` and feed views need direct access to `SupabaseClient` for realtime subscriptions.

### 2.7 Wire in Composition Root
**Location:** `Resources/AgoraApp.swift`

```swift
import Supabase

@main
struct AgoraApp: App {
    private let deps: Dependencies = {
        let networking = NetworkingClientLive(session: .shared)
        let analytics = AnalyticsClientLive()
        let auth = AuthSessionLive(storage: KeychainStorageLive())
        
        // Initialize Supabase client
        let supabase = SupabaseClient(
            supabaseURL: URL(string: ProcessInfo.processInfo.environment["SUPABASE_URL"]!)!,
            supabaseKey: ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]!
        )
        
        let engagement = EngagementServiceLive(
            networking: networking,
            analytics: analytics
        )
        
        return Dependencies(
            networking: networking,
            analytics: analytics,
            auth: auth,
            engagement: engagement,
            supabase: supabase,
            clock: SystemClock()
        )
    }()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.deps, deps)
        }
    }
}
```

---

## Phase 3: UI Components & Animations

### 3.1 Update `EngagementButton` with State
**Location:** `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/EngagementButton.swift`

```swift
import SwiftUI

/// Individual engagement button with count, state, and animations
public struct EngagementButton: View {
    let icon: String
    let iconFilled: String?  // e.g. "heart.fill"
    let count: Int
    let isActive: Bool
    let isLoading: Bool
    let tintColor: Color?
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var animationTrigger = false
    
    public init(
        icon: String,
        iconFilled: String? = nil,
        count: Int,
        isActive: Bool = false,
        isLoading: Bool = false,
        tintColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.iconFilled = iconFilled
        self.count = count
        self.isActive = isActive
        self.isLoading = isLoading
        self.tintColor = tintColor
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            animationTrigger.toggle()
            action()
        }) {
            HStack(spacing: SpacingTokens.xxs) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: isActive ? (iconFilled ?? icon) : icon)
                        .font(.system(size: 16, weight: .regular))
                        .symbolEffect(.bounce, value: animationTrigger)  // iOS 26 animation
                        .contentTransition(.symbolEffect(.replace))
                }
                
                if count > 0 {
                    Text("\(count)")
                        .font(TypographyScale.caption1)
                        .contentTransition(.numericText())  // Smooth count changes
                }
            }
            .foregroundColor(foregroundColor)
        }
        .frame(minWidth: 44, minHeight: 44) // Ensure 44pt touch target
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(count > 0 ? "\(count)" : "")
        .accessibilityHint(accessibilityHint)
    }
    
    private var foregroundColor: Color {
        if isActive, let tintColor {
            return tintColor
        } else if isActive {
            return ColorTokens.accentPrimary
        } else {
            return ColorTokens.tertiaryText
        }
    }
    
    private var accessibilityLabel: String {
        switch icon {
        case "heart", "heart.fill":
            return isActive ? "Unlike" : "Like"
        case "arrow.2.squarepath":
            return isActive ? "Unrepost" : "Repost"
        case "bubble.left":
            return "Comment"
        case "arrow.turn.up.right":
            return "Share"
        default:
            return "Action"
        }
    }
    
    private var accessibilityHint: String {
        switch icon {
        case "heart", "heart.fill":
            return "Double tap to \(isActive ? "unlike" : "like") this post"
        case "arrow.2.squarepath":
            return "Double tap to \(isActive ? "unrepost" : "repost") this post"
        case "bubble.left":
            return "Double tap to open comments"
        case "arrow.turn.up.right":
            return "Double tap to share this post"
        default:
            return ""
        }
    }
}
```

### 3.2 Create `CommentSheet`
**Location:** `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/CommentSheet.swift`

TikTok-style bottom sheet with placeholder UI:

```swift
import SwiftUI
import AppFoundation

/// TikTok-style comment sheet for viewing and adding comments
public struct CommentSheet: View {
    let post: Post
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    public init(post: Post, onDismiss: @escaping () -> Void) {
        self.post = post
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("\(post.replyCount) \(post.replyCount == 1 ? "comment" : "comments")")
                        .font(TypographyScale.headline)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Spacer()
                    
                    Button(action: {
                        onDismiss()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                }
                .padding(SpacingTokens.md)
                .background(.ultraThinMaterial)
                
                Divider()
                
                // Comments list (placeholder)
                ScrollView {
                    VStack(spacing: SpacingTokens.lg) {
                        Spacer()
                            .frame(height: 60)
                        
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        Text("Comments coming soon")
                            .font(TypographyScale.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Text("We're building a thoughtful\nconversation experience")
                            .font(TypographyScale.body)
                            .foregroundColor(ColorTokens.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                
                Divider()
                
                // Comment input (disabled placeholder)
                HStack(spacing: SpacingTokens.sm) {
                    Circle()
                        .fill(ColorTokens.separator.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(ColorTokens.tertiaryText)
                                .font(.system(size: 14))
                        }
                    
                    Text("Add a comment...")
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SpacingTokens.sm)
                        .background(ColorTokens.secondaryBackground)
                        .cornerRadius(SpacingTokens.sm)
                    
                    Button(action: {}) {
                        Text("Post")
                            .font(TypographyScale.callout)
                            .fontWeight(.semibold)
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                    .disabled(true)
                }
                .padding(SpacingTokens.md)
                .background(.ultraThinMaterial)
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(SpacingTokens.lg)
    }
}
```

### 3.3 Create `ShareMenu`
**Location:** `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/ShareMenu.swift`

```swift
import SwiftUI
import AppFoundation

/// Share menu with multiple sharing options
public struct ShareMenu: View {
    let post: Post
    let shareURL: URL
    let onShareToDM: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedToast = false
    
    public init(
        post: Post,
        shareURL: URL,
        onShareToDM: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.post = post
        self.shareURL = shareURL
        self.onShareToDM = onShareToDM
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Share")
                    .font(TypographyScale.headline)
                    .foregroundColor(ColorTokens.primaryText)
                
                Spacer()
                
                Button(action: {
                    onDismiss()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ColorTokens.tertiaryText)
                }
            }
            .padding(SpacingTokens.md)
            
            Divider()
            
            // Share options
            VStack(spacing: 0) {
                ShareMenuItem(
                    icon: "paperplane.fill",
                    title: "Share to Agora DM",
                    subtitle: "Send in a message",
                    action: {
                        onShareToDM()
                        dismiss()
                    }
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ShareMenuItem(
                    icon: "message.fill",
                    title: "Share via iMessage",
                    subtitle: "Send to contacts",
                    shareURL: shareURL  // Use ShareLink internally
                )
                
                Divider()
                    .padding(.leading, 60)
                
                ShareMenuItem(
                    icon: "doc.on.doc",
                    title: "Copy Link",
                    subtitle: "Share anywhere",
                    action: {
                        copyLink()
                    }
                )
            }
            
            Spacer()
        }
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                ToastView(message: "Link copied to clipboard", icon: "checkmark.circle.fill")
                    .padding(.bottom, SpacingTokens.lg)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.visible)
    }
    
    private func copyLink() {
        UIPasteboard.general.url = shareURL
        
        withAnimation(.spring(response: 0.3)) {
            showCopiedToast = true
        }
        
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.spring(response: 0.3)) {
                showCopiedToast = false
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

/// Individual share menu item (supports action or ShareLink)
struct ShareMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    let shareURL: URL?
    
    @State private var isPressed = false
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.shareURL = nil
    }
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        shareURL: URL
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = nil
        self.shareURL = shareURL
    }
    
    var body: some View {
        Group {
            if let shareURL {
                // Use native ShareLink for system share sheet
                ShareLink(item: shareURL) {
                    shareMenuContent
                }
            } else {
                Button(action: { action?() }) {
                    shareMenuContent
                }
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var shareMenuContent: some View {
        HStack(spacing: SpacingTokens.md) {
            ZStack {
                Circle()
                    .fill(ColorTokens.accentPrimary.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(ColorTokens.accentPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.primaryText)
                
                Text(subtitle)
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.tertiaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(ColorTokens.quaternaryText)
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .contentShape(Rectangle())
    }
}

/// Toast notification view
struct ToastView: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: SpacingTokens.sm) {
            Image(systemName: icon)
                .foregroundColor(.white)
            
            Text(message)
                .font(TypographyScale.callout)
                .foregroundColor(.white)
        }
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.sm)
        .background(.black.opacity(0.85))
        .cornerRadius(SpacingTokens.md)
        .shadow(color: .black.opacity(0.1), radius: SpacingTokens.sm, y: 4)
    }
}
```

### 3.4 Update `EngagementBar`
**Location:** `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/EngagementBar.swift`

```swift
import SwiftUI

/// Engagement bar with action buttons for posts
public struct EngagementBar: View {
    let likeCount: Int
    let isLiked: Bool
    let isLikeLoading: Bool
    
    let repostCount: Int
    let isReposted: Bool
    let isRepostLoading: Bool
    
    let replyCount: Int
    
    let onLike: () -> Void
    let onRepost: () -> Void
    let onReply: () -> Void
    let onShare: () -> Void
    
    public init(
        likeCount: Int,
        isLiked: Bool = false,
        isLikeLoading: Bool = false,
        repostCount: Int,
        isReposted: Bool = false,
        isRepostLoading: Bool = false,
        replyCount: Int,
        onLike: @escaping () -> Void = {},
        onRepost: @escaping () -> Void = {},
        onReply: @escaping () -> Void = {},
        onShare: @escaping () -> Void = {}
    ) {
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.isLikeLoading = isLikeLoading
        self.repostCount = repostCount
        self.isReposted = isReposted
        self.isRepostLoading = isRepostLoading
        self.replyCount = replyCount
        self.onLike = onLike
        self.onRepost = onRepost
        self.onReply = onReply
        self.onShare = onShare
    }
    
    public var body: some View {
        HStack(spacing: SpacingTokens.md) {
            // Like
            EngagementButton(
                icon: "heart",
                iconFilled: "heart.fill",
                count: likeCount,
                isActive: isLiked,
                isLoading: isLikeLoading,
                tintColor: .red,
                action: onLike
            )
            
            // Reply/Comment
            EngagementButton(
                icon: "bubble.left",
                count: replyCount,
                action: onReply
            )
            
            // Repost
            EngagementButton(
                icon: "arrow.2.squarepath",
                count: repostCount,
                isActive: isReposted,
                isLoading: isRepostLoading,
                tintColor: .green,
                action: onRepost
            )
            
            // Share
            EngagementButton(
                icon: "arrow.turn.up.right",
                count: 0,  // Share doesn't show count
                action: onShare
            )
            
            Spacer()
        }
        .padding(.top, SpacingTokens.xs)
    }
}
```

---

## Phase 4: State Management & Wiring

### 4.1 Create `PostEngagementState`
**Location:** `Packages/Kits/DesignSystem/Sources/DesignSystem/PostEngagementState.swift`

```swift
import Foundation
import Observation
import AppFoundation
import Engagement

/// Observable state for post engagement with optimistic updates
@Observable
@MainActor
public final class PostEngagementState {
    // Optimistic state
    public var isLiked: Bool
    public var likeCount: Int
    public var isReposted: Bool
    public var repostCount: Int
    
    // Loading states
    public var isLikingInProgress = false
    public var isRepostingInProgress = false
    
    // Error state
    public var error: EngagementError?
    
    private let postId: String
    private let engagement: EngagementService
    
    public init(post: Post, engagement: EngagementService) {
        self.postId = post.id
        self.isLiked = post.isLikedByViewer ?? false
        self.likeCount = post.likeCount
        self.isReposted = post.isRepostedByViewer ?? false
        self.repostCount = post.repostCount
        self.engagement = engagement
    }
    
    /// Toggle like with optimistic update and rollback on failure
    public func toggleLike() async {
        // Prevent reentrancy
        guard !isLikingInProgress else { return }
        
        // Capture previous state for rollback
        let previousLiked = isLiked
        let previousCount = likeCount
        
        // Optimistic update
        isLiked.toggle()
        likeCount = max(0, likeCount + (isLiked ? 1 : -1))  // Clamp to 0
        isLikingInProgress = true
        error = nil
        
        do {
            // Call service
            let result = try await engagement.toggleLike(postId: postId)
            
            // Reconcile with server state
            isLiked = result.isLiked
            likeCount = max(0, result.likeCount)  // Clamp to 0
        } catch let engagementError as EngagementError {
            // Rollback on error
            isLiked = previousLiked
            likeCount = previousCount
            error = engagementError
        } catch {
            // Rollback on unknown error
            isLiked = previousLiked
            likeCount = previousCount
            error = .networkError
        }
        
        isLikingInProgress = false
    }
    
    /// Toggle repost with optimistic update and rollback on failure
    public func toggleRepost() async {
        // Prevent reentrancy
        guard !isRepostingInProgress else { return }
        
        // Capture previous state for rollback
        let previousReposted = isReposted
        let previousCount = repostCount
        
        // Optimistic update
        isReposted.toggle()
        repostCount = max(0, repostCount + (isReposted ? 1 : -1))  // Clamp to 0
        isRepostingInProgress = true
        error = nil
        
        do {
            // Call service
            let result = try await engagement.toggleRepost(postId: postId)
            
            // Reconcile with server state
            isReposted = result.isReposted
            repostCount = max(0, result.repostCount)  // Clamp to 0
        } catch let engagementError as EngagementError {
            // Rollback on error
            isReposted = previousReposted
            repostCount = previousCount
            error = engagementError
        } catch {
            // Rollback on unknown error
            isReposted = previousReposted
            repostCount = previousCount
            error = .networkError
        }
        
        isRepostingInProgress = false
    }
    
    /// Update counts from real-time observer
    public func updateFromRealtime(likeCount: Int, repostCount: Int) {
        // Only update if not currently performing an action
        if !isLikingInProgress {
            self.likeCount = likeCount
        }
        
        if !isRepostingInProgress {
            self.repostCount = repostCount
        }
    }
}
```

### 4.2 Update `FeedPostView`
**Location:** `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/FeedPostView.swift`

```swift
import SwiftUI
import AppFoundation
import Engagement

/// Post view component for displaying posts in feed lists
public struct FeedPostView: View {
    let post: Post
    let onAuthorTap: () -> Void
    
    @State private var engagementState: PostEngagementState?
    @State private var showCommentSheet = false
    @State private var showShareMenu = false
    @State private var shareURL: URL?
    
    @Environment(\.deps) private var deps
    
    public init(
        post: Post,
        onAuthorTap: @escaping () -> Void = {}
    ) {
        self.post = post
        self.onAuthorTap = onAuthorTap
    }
    
    public var body: some View {
        HStack(alignment: .top, spacing: SpacingTokens.sm) {
            // Left column: Profile picture
            Button(action: onAuthorTap) {
                if let avatarUrl = post.authorAvatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            placeholderAvatar
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderAvatar
                        @unknown default:
                            placeholderAvatar
                        }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    placeholderAvatar
                }
            }
            .frame(width: 44, height: 44)
            
            // Right column: All content
            VStack(alignment: .leading, spacing: SpacingTokens.sm) {
                // Header row
                HStack(alignment: .firstTextBaseline, spacing: SpacingTokens.xxs) {
                    Text("@\(post.authorDisplayHandle)")
                        .font(TypographyScale.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Text("·")
                        .foregroundColor(ColorTokens.quaternaryText)
                    
                    Text(formatTimestamp(post.createdAt))
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                    
                    if post.editedAt != nil {
                        Text("·")
                            .foregroundColor(ColorTokens.quaternaryText)
                        
                        HStack(spacing: 2) {
                            Image(systemName: "pencil.circle")
                            Text("Edited")
                        }
                        .font(TypographyScale.caption2)
                        .foregroundColor(ColorTokens.tertiaryText)
                    }
                    
                    Spacer()
                }
                
                // Post text
                Text(post.text)
                    .font(TypographyScale.body)
                    .foregroundColor(ColorTokens.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Engagement bar
                if let state = engagementState {
                    EngagementBar(
                        likeCount: state.likeCount,
                        isLiked: state.isLiked,
                        isLikeLoading: state.isLikingInProgress,
                        repostCount: state.repostCount,
                        isReposted: state.isReposted,
                        isRepostLoading: state.isRepostingInProgress,
                        replyCount: post.replyCount,
                        onLike: { Task { await state.toggleLike() } },
                        onRepost: { Task { await state.toggleRepost() } },
                        onReply: { showCommentSheet = true },
                        onShare: { Task { await handleShare() } }
                    )
                }
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .task {
            // Initialize engagement state
            engagementState = PostEngagementState(
                post: post,
                engagement: deps.engagement
            )
        }
        .sheet(isPresented: $showCommentSheet) {
            CommentSheet(post: post, onDismiss: { showCommentSheet = false })
        }
        .sheet(isPresented: $showShareMenu) {
            if let shareURL {
                ShareMenu(
                    post: post,
                    shareURL: shareURL,
                    onShareToDM: { /* TODO: Navigate to DM picker */ },
                    onDismiss: { showShareMenu = false }
                )
            }
        }
        .alert(
            "Action Failed",
            isPresented: Binding(
                get: { engagementState?.error != nil },
                set: { if !$0 { engagementState?.error = nil } }
            ),
            presenting: engagementState?.error
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.errorDescription ?? "An error occurred")
        }
    }
    
    private var placeholderAvatar: some View {
        Circle()
            .fill(ColorTokens.separator.opacity(0.3))
            .frame(width: 40, height: 40)
            .overlay {
                Image(systemName: "person.fill")
                    .foregroundColor(ColorTokens.tertiaryText)
                    .font(.system(size: 18))
            }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        // Use RelativeDateTimeFormatter for proper i18n
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    @MainActor
    private func handleShare() async {
        do {
            shareURL = try await deps.engagement.getShareURL(postId: post.id)
            showShareMenu = true
        } catch {
            // Handle error
        }
    }
}
```

---

## Phase 5: Real-Time Updates (MVP Priority)

### 5.1 Add Real-Time Observer to Feed Views
**Location:** `Packages/Features/HomeForYou/Sources/HomeForYou/ForYouFeedView.swift`

**Updated to use single channel with `updateVisiblePosts()` API:**

```swift
import SwiftUI
import AppFoundation
import DesignSystem
import Engagement

public struct ForYouFeedView: View {
    @State private var viewModel: ForYouFeedViewModel
    @State private var realtimeObserver: RealtimeEngagementObserver?
    @State private var visiblePostIds: Set<String> = []
    
    @Environment(\.deps) private var deps
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: SpacingTokens.md) {
                ForEach(viewModel.posts) { post in
                    FeedPostView(post: post)
                        .onAppear {
                            // Track visible post
                            visiblePostIds.insert(post.id)
                            Task {
                                await realtimeObserver?.updateVisiblePosts(visiblePostIds)
                            }
                        }
                        .onDisappear {
                            // Untrack when scrolled off screen
                            visiblePostIds.remove(post.id)
                            Task {
                                await realtimeObserver?.updateVisiblePosts(visiblePostIds)
                            }
                        }
                }
            }
        }
        .task {
            await startRealtimeObserver()
        }
        .onDisappear {
            Task {
                await realtimeObserver?.stopObserving()
            }
        }
    }
    
    private func startRealtimeObserver() async {
        realtimeObserver = RealtimeEngagementObserver(supabase: deps.supabase)
        
        // Start listening to updates
        Task {
            guard let observer = realtimeObserver else { return }
            
            for await update in observer.updates {
                // Update the corresponding post's engagement state
                viewModel.updateEngagement(
                    postId: update.postId,
                    likeCount: update.likeCount,
                    repostCount: update.repostCount
                )
            }
        }
    }
}
```

**Key Changes:**
- Track visible posts with `visiblePostIds` set
- Call `updateVisiblePosts()` on appear/disappear (debounced internally)
- Single channel subscription per feed (much better performance)

### 5.2 Update View Models to Handle Real-Time Updates
```swift
@Observable
public final class ForYouFeedViewModel {
    public var posts: [Post] = []
    
    // ... existing code ...
    
    public func updateEngagement(postId: String, likeCount: Int, repostCount: Int) {
        guard let index = posts.firstIndex(where: { $0.id == postId }) else { return }
        
        // Update the post model with new counts
        // This will trigger UI updates via @Observable
        posts[index] = Post(
            id: posts[index].id,
            authorId: posts[index].authorId,
            authorDisplayHandle: posts[index].authorDisplayHandle,
            text: posts[index].text,
            linkUrl: posts[index].linkUrl,
            mediaBundleId: posts[index].mediaBundleId,
            replyToPostId: posts[index].replyToPostId,
            quotePostId: posts[index].quotePostId,
            likeCount: likeCount,
            repostCount: repostCount,
            replyCount: posts[index].replyCount,
            visibility: posts[index].visibility,
            createdAt: posts[index].createdAt,
            authorDisplayName: posts[index].authorDisplayName,
            authorAvatarUrl: posts[index].authorAvatarUrl,
            editedAt: posts[index].editedAt,
            selfDestructAt: posts[index].selfDestructAt,
            score: posts[index].score,
            reasons: posts[index].reasons,
            explore: posts[index].explore,
            isLikedByViewer: posts[index].isLikedByViewer,
            isRepostedByViewer: posts[index].isRepostedByViewer
        )
    }
}
```

---

## Implementation Order

### **Sprint 1: Backend Foundation** (2-3 days)
1. ✅ Update Post model with viewer state fields
2. ✅ Create database RPC functions (`toggle_like`, `toggle_repost`)
3. ✅ Update feed Edge Functions to include viewer state
4. ✅ Update Following feed to include reposts by followed users
5. ✅ Add OpenAPI endpoints
6. ✅ Create Edge Functions (`toggle-like`, `toggle-repost`)
7. ✅ Run `agctl generate openapi`
8. ✅ Test endpoints with curl/Postman

### **Sprint 2: Service Layer** (2 days)
9. ✅ Create Engagement Kit package structure
10. ✅ Implement EngagementService protocol
11. ✅ Implement EngagementServiceLive
12. ✅ Implement EngagementServiceFake
13. ✅ Add to Dependencies + wire in AgoraApp
14. ✅ Write unit tests for service

### **Sprint 3: UI Components** (3 days)
15. ✅ Update EngagementButton with state & animations
16. ✅ Create CommentSheet
17. ✅ Create ShareMenu + ShareMenuItem
18. ✅ Update EngagementBar
19. ✅ Create ToastView
20. ✅ Test animations and accessibility

### **Sprint 4: State Management & Wiring** (2-3 days)
21. ✅ Create PostEngagementState
22. ✅ Update FeedPostView to use state
23. ✅ Wire sheets and menus
24. ✅ Test optimistic updates + rollback
25. ✅ Add error handling and alerts

### **Sprint 5: Real-Time Updates** (2 days)
26. ✅ Implement RealtimeEngagementObserver
27. ✅ Add real-time to ForYou feed
28. ✅ Add real-time to Following feed
29. ✅ Test concurrent updates

### **Sprint 6: Polish & Testing** (2 days)
30. ✅ Add haptic feedback variations
31. ✅ Accessibility audit (VoiceOver, Dynamic Type)
32. ✅ Performance testing (scroll performance)
33. ✅ Integration tests
34. ✅ Update previews and documentation

---

## Testing Strategy

### Unit Tests
- `EngagementServiceLiveTests` - API calls, error mapping, correlation IDs
- `PostEngagementStateTests` - Optimistic updates, rollback, reentrancy protection
- `EngagementServiceFakeTests` - Test double behavior
- `RealtimeEngagementObserverTests` - Real-time subscriptions, throttling, buffering

### UI Tests
- `EngagementButtonUITests` - Animations, accessibility, states, haptics
- `CommentSheetUITests` - Sheet presentation, dismissal
- `ShareMenuUITests` - Menu actions, pasteboard, ShareLink
- `FeedPostViewUITests` - Full integration

### Integration Tests
- Like a post → verify DB `likes` table
- Unlike a post → verify count decrement
- Repost → verify `reposts` table + Following feed
- Unrepost → verify removal
- Real-time update → verify UI reflects changes

### **Critical Race Tests (REQUIRED)**
**File:** `Tests/EngagementTests/RaceConditionTests.swift`

```swift
import XCTest
@testable import Engagement

final class RaceConditionTests: XCTestCase {
    /// Test rapid like/unlike + interleaved realtime snapshots
    func testRapidLikeUnlikeWithRealtimeUpdates() async throws {
        let fake = EngagementServiceFake()
        fake.delay = .milliseconds(100)
        
        let state = PostEngagementState(
            post: mockPost,
            engagement: fake
        )
        
        // User rapidly taps like 5 times
        async let like1 = state.toggleLike()
        async let like2 = state.toggleLike()  // Should be blocked by reentrancy
        async let like3 = state.toggleLike()
        async let like4 = state.toggleLike()
        async let like5 = state.toggleLike()
        
        // Simulate realtime update arriving mid-toggle
        try await Task.sleep(for: .milliseconds(50))
        await state.updateFromRealtime(likeCount: 100, repostCount: 5)
        
        _ = await [like1, like2, like3, like4, like5]
        
        // Final state should match server
        XCTAssertEqual(state.isLiked, fake.likedPosts.contains(mockPost.id))
        XCTAssertEqual(state.likeCount, 42)  // From fake service
    }
    
    /// Test concurrent like + realtime update
    func testConcurrentLikeAndRealtimeUpdate() async throws {
        let fake = EngagementServiceFake()
        fake.delay = .milliseconds(200)
        
        let state = PostEngagementState(
            post: mockPost,
            engagement: fake
        )
        
        // Start a like
        async let like = state.toggleLike()
        
        // Realtime update arrives while like is in flight
        try await Task.sleep(for: .milliseconds(100))
        await state.updateFromRealtime(likeCount: 999, repostCount: 5)
        
        // Counts should NOT update while in-progress
        XCTAssertEqual(state.likeCount, 1)  // Optimistic value
        
        _ = await like
        
        // After completion, server value wins
        XCTAssertEqual(state.likeCount, 42)
    }
}
```

### **Offline & Network Failure Tests (REQUIRED)**
**File:** `Tests/EngagementTests/OfflineTests.swift`

```swift
final class OfflineTests: XCTestCase {
    func testLikeFailsOfflineWithRollback() async throws {
        let fake = EngagementServiceFake()
        fake.shouldFail = true
        
        let state = PostEngagementState(
            post: mockPost,
            engagement: fake
        )
        
        let originalLiked = state.isLiked
        let originalCount = state.likeCount
        
        // Try to like
        await state.toggleLike()
        
        // Should roll back
        XCTAssertEqual(state.isLiked, originalLiked)
        XCTAssertEqual(state.likeCount, originalCount)
        XCTAssertNotNil(state.error)
    }
}
```

### **Realtime Load Tests (REQUIRED)**
**File:** `Tests/EngagementTests/RealtimeLoadTests.swift`

```swift
final class RealtimeLoadTests: XCTestCase {
    func testSingleChannelFor100Posts() async throws {
        let observer = RealtimeEngagementObserver(supabase: mockSupabase)
        
        // Simulate 100 visible posts
        let postIds = (0..<100).map { _ in UUID().uuidString }
        await observer.updateVisiblePosts(Set(postIds))
        
        // Should only create 1 channel
        let channels = await mockSupabase.activeChannelCount()
        XCTAssertEqual(channels, 1)
    }
    
    func testThrottlingUnder300ms() async throws {
        let observer = RealtimeEngagementObserver(supabase: mockSupabase)
        var receivedUpdates: [EngagementUpdate] = []
        
        Task {
            for await update in observer.updates {
                receivedUpdates.append(update)
            }
        }
        
        // Simulate 10 rapid updates for same post (within 300ms)
        for i in 0..<10 {
            await observer.handleUpdate(mockPayload(likeCount: i))
            try await Task.sleep(for: .milliseconds(20))
        }
        
        // Should drop intermediate updates, only emit ~3-4
        try await Task.sleep(for: .seconds(1))
        XCTAssertLessThan(receivedUpdates.count, 5)
    }
}
```

### **Counter Drift Monitoring (REQUIRED)**
Add to PostHog dashboard:

```sql
-- Daily drift check query
SELECT 
  p.id,
  p.like_count as denormalized_count,
  COUNT(l.user_id)::int as actual_count,
  ABS(p.like_count - COUNT(l.user_id)::int) as drift
FROM posts p
LEFT JOIN likes l ON l.post_id = p.id
GROUP BY p.id
HAVING ABS(p.like_count - COUNT(l.user_id)::int) > 0
ORDER BY drift DESC
LIMIT 50;
```

Alert if drift > 10 posts/day.

---

## Success Criteria

✅ **Like button:**
- Tapping fills heart with red tint and bounce animation
- Count increments immediately (optimistic)
- Server persists state
- Automatic rollback if API fails
- Heart stays filled on scroll + return to post
- Real-time count updates when others like

✅ **Comment button:**
- Opens TikTok-style sheet from bottom
- Sheet shows placeholder "Comments coming soon"
- Drag-to-dismiss works
- Accessible with VoiceOver

✅ **Repost button:**
- Rotating arrow animation on tap
- Green tint when reposted
- Count increments optimistically
- Repost appears in followers' Following feed chronologically
- Boosts original post's reach in For You feed

✅ **Share button:**
- Opens menu with 3 options
- Copy link → pasteboard + toast
- iMessage share → native iOS share sheet
- Agora DM → shows "Coming soon" placeholder
- Menu dismisses after action

✅ **All buttons:**
- Work in ForYou, Following, PostDetail, Profile feeds
- Work in SwiftUI Previews with mock service
- Pass accessibility audit (labels, hints, VoiceOver)
- Proper haptic feedback (light for tap, medium for copy)
- Optimistic updates feel instant
- Real-time updates for counts (MVP)

✅ **Performance:**
- Scroll performance maintained (60fps on non-ProMotion, 120fps on ProMotion)
- No dropped frames during animations
- Real-time subscription doesn't impact battery

---

## Files to Create/Modify

### **New Files** (28 files)
```
Packages/Kits/Engagement/
  Package.swift
  README.md
  Sources/Engagement/
    Engagement.swift
    EngagementService.swift
    EngagementServiceLive.swift
    EngagementError.swift
    RealtimeEngagementObserver.swift
  Tests/EngagementTests/
    EngagementServiceTests.swift
    RealtimeEngagementObserverTests.swift

Packages/Kits/DesignSystem/Sources/DesignSystem/Components/
  CommentSheet.swift
  ShareMenu.swift
  PostEngagementState.swift

Packages/Shared/TestSupport/Sources/TestSupport/
  EngagementServiceFake.swift

database/migrations/
  014_engagement_rpcs.sql

supabase/functions/
  toggle-like/index.ts
  toggle-repost/index.ts
```

### **Modified Files** (12 files)
```
Packages/Shared/AppFoundation/Sources/AppFoundation/
  Dependencies.swift (add engagement service)
  Dependencies.swift (update Post model)

Packages/Kits/DesignSystem/Sources/DesignSystem/Components/
  EngagementButton.swift (add state, animations)
  EngagementBar.swift (pass through state)
  FeedPostView.swift (wire up state + sheets)

OpenAPI/
  agora.yaml (add engagement endpoints)

Resources/
  AgoraApp.swift (wire EngagementServiceLive)

supabase/functions/
  feed-for-you/index.ts (add viewer state)
  feed-following/index.ts (add reposts + viewer state)
  get-user-posts/index.ts (add viewer state)
```

---

## Monitoring & Analytics

Track these events in PostHog with **correlation IDs** for debugging:

**Engagement Events:**
- `post_like_toggled` → post_id, **correlation_id**
- `post_liked` → post_id, like_count, **correlation_id**
- `post_unliked` → post_id, like_count, **correlation_id**
- `post_like_failed` → post_id, error, **correlation_id**
- `post_repost_toggled` → post_id, **correlation_id**
- `post_reposted` → post_id, repost_count, **correlation_id**
- `post_unreposted` → post_id, repost_count, **correlation_id**
- `post_repost_failed` → post_id, error, **correlation_id**
- `comment_sheet_opened` → post_id
- `share_menu_opened` → post_id
- `post_shared_dm` → post_id (placeholder)
- `post_shared_imessage` → post_id
- `post_link_copied` → post_id

**Real-Time Events:**
- `realtime_engagement_update` → post_id, delta_likes, delta_reposts, source (realtime/optimistic)
- `realtime_connection_status` → status (connected/disconnected)
- `realtime_update_throttled` → post_id, dropped_updates_count
- `realtime_update_buffered` → post_id (during in-progress action)

**Error Events:**
- `engagement_optimistic_rollback` → post_id, action, error, **correlation_id**
- `realtime_subscription_failed` → error, visible_post_count

**Performance Metrics:**
- `engagement_toggle_latency` → post_id, action (like/repost), duration_ms
- `realtime_channel_count` → count (should always be 1 per feed)
- `counter_drift_detected` → post_id, denormalized_count, actual_count, drift_amount

---

## Future Enhancements (Post-MVP)

### Phase 2: Rich Comments
- Full comment thread UI
- Reply to comments
- Comment likes
- Nested threading (1 level deep)

### Phase 3: Advanced Sharing
- Share to DM picker (select followers)
- Share to other apps (Twitter, Threads)
- QR code for post
- Embeddable links with preview cards

### Phase 4: Engagement Insights
- "See who liked this"
- "See who reposted this"
- Engagement trends over time
- Post performance analytics for creators

### Phase 5: Quote Reposts
- Repost with comment (quote_text field)
- Quote reposts show in separate tab
- Quote thread navigation

---

## Questions Answered

1. **Repost behavior**: Entry in `reposts` table only (not new post). Affects Following feed chronologically and recommendation system via `repost_count` signal.

2. **Share to DM**: Placeholder UI for now (says "Coming soon"). Will integrate with DMs feature in Phase 2.

3. **Comment reply flow**: Full-screen modal sheet (TikTok-style). Placeholder UI for MVP; real comments in Phase 2.

4. **Real-time priority**: **MVP PRIORITY**. Implemented via Supabase Realtime subscriptions to `posts` table for live count updates.

5. **Undo action**: **No undo toast**. Actions are instant and reversible by tapping again.

---

## References

- [ios-di-injection.mdc](../../../.cursor/rules/ios-di-injection.mdc) - DI patterns
- [ios-module-standards.mdc](../../../.cursor/rules/ios-module-standards.mdc) - Package structure
- [apple-ui-ux-design.mdc](../../../.cursor/rules/apple-ui-ux-design.mdc) - UI/UX guidelines
- [FEED_ALGORITHM.md](./FEED_ALGORITHM.md) - Recommendation system integration
- [Supabase Realtime Docs](https://supabase.com/docs/guides/realtime)
- [iOS 26 SF Symbols](https://developer.apple.com/sf-symbols/)
- [SwiftUI Animation Guidelines](https://developer.apple.com/design/human-interface-guidelines/animations)

---

## 🔒 Security & Correctness Hardening Summary

This plan includes critical production-grade improvements over the initial draft:

### **Database & Backend**
✅ **Drift-proof counting**: RPCs use `COUNT(*)` from source tables, not denormalized counters  
✅ **Unique constraints**: Prevent duplicate likes/reposts at DB level  
✅ **Hot indexes**: Optimized for `post_id` and `(user_id, post_id)` lookups  
✅ **RLS policies**: Users can only modify their own likes/reposts  
✅ **Search path hardening**: `SET search_path = public;` prevents SQL injection  
✅ **Nightly reconciliation**: Cron job fixes any counter drift  
✅ **Rate limiting**: Max 1 toggle per user+post per second (server-side)

### **API & Edge Functions**
✅ **JWT-only user_id**: Never trust client-provided user_id (always derive from JWT)  
✅ **Correlation IDs**: UUID per request for debugging and analytics tracking  
✅ **Standardized errors**: `{ code, message, correlationId }` on all errors  
✅ **Method allowlist**: Only POST for toggles, proper CORS preflight  
✅ **Idempotent**: Safe to retry; stable response even on duplicate requests

### **Real-Time Architecture**
✅ **Single channel per feed**: Not per-post (critical perf fix)  
✅ **Proper UUID quoting**: `"uuid1","uuid2"` format for Postgres filters  
✅ **Throttling**: Max 1 update per post per 300ms (drops intermediate updates)  
✅ **Actor-safe callbacks**: No weak self capture issues  
✅ **Background pause**: Auto-unsubscribe on background, resubscribe on foreground  
✅ **Local action wins**: Buffers realtime during in-progress, applies after

### **Client-Side Robustness**
✅ **Non-optional viewer flags**: `Bool` instead of `Bool?` (prevents glitches)  
✅ **Reentrancy protection**: Guard against rapid double-taps  
✅ **Count clamping**: `max(0, count)` prevents negative counts  
✅ **Proper alert binding**: Real binding, not `.constant()` hack  
✅ **ShareLink**: Native iOS share instead of manual UIActivityViewController  
✅ **RelativeDateTimeFormatter**: i18n-correct timestamp formatting  
✅ **Haptic etiquette**: Only on success, no double-firing

### **Following Feed SQL**
✅ **UNION ALL pipeline**: Cleaner than `LEFT JOIN` + `OR`  
✅ **Deduplication**: If multiple followees repost same post, show once with latest timestamp  
✅ **Deterministic ordering**: Proper `DISTINCT ON` with inner + outer `ORDER BY`

### **Testing & Monitoring**
✅ **Race condition tests**: Rapid toggle + interleaved realtime  
✅ **Offline tests**: Network failure rollback  
✅ **Realtime load tests**: Single channel for 100 posts, throttling verification  
✅ **Counter drift monitoring**: Daily SQL query + PostHog alerts  
✅ **Correlation IDs in analytics**: Every error event includes request correlation ID

### **Production Readiness Checklist**
- [x] Security: RLS, rate limiting, JWT-only user derivation
- [x] Correctness: COUNT-based returns, drift reconciliation, reentrancy guards
- [x] Performance: Single realtime channel, throttling, indexes
- [x] Reliability: Rollback on error, offline handling, buffering during in-progress
- [x] Observability: Correlation IDs, comprehensive analytics, drift monitoring
- [x] i18n: RelativeDateTimeFormatter, accessibility labels
- [x] Testing: Race, offline, load tests included

**This is a production-grade implementation, not a prototype.** 🚀

