# Real-Time Engagement Integration Guide

This guide shows how to add real-time engagement count updates to feed views.

## Overview

The `RealtimeEngagementObserver` provides live updates for like and repost counts across all visible posts in a feed. It uses **server-side filtering** with Supabase Realtime's `in` operator and automatically chunks subscriptions for >100 posts.

## Key Features

- ✅ **Server-side filtering** (uses `id=in.(...)` filter, max 100 IDs per channel)
- ✅ **Automatic chunking** (creates multiple channels if >100 visible posts)
- ✅ **Automatic throttling** (300ms between updates)
- ✅ **Background pause/resume** (conserves battery)
- ✅ **Buffering during actions** (local actions win)
- ✅ **Debounced subscriptions** (smooth during scroll)

## Scaling Considerations

- **Up to 100 posts**: Single subscription with `in` filter
- **101-300 posts**: 2-3 chunked subscriptions (still efficient)
- **>300 posts**: Consider pagination or Broadcast channels
- **Production scale**: Supabase recommends migrating to Broadcast channels for very high throughput

## Integration Steps

### 1. Add Observer to Feed View

```swift
import SwiftUI
import Engagement
import DesignSystem
import AppFoundation
import Supabase

public struct YourFeedView: View {
    @State private var viewModel: YourFeedViewModel
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
        guard let supabase = deps.supabase as? SupabaseClient else {
            return
        }
        
        realtimeObserver = RealtimeEngagementObserver(supabase: supabase)
        
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

### 2. Update View Model

Add a method to handle real-time updates:

```swift
@Observable
public final class YourFeedViewModel {
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

### 3. Optional: Buffer Updates During Actions

If you want to prevent conflicts when the user is liking/reposting:

```swift
// In your engagement action handler
await realtimeObserver?.markInProgress(postId)
let result = try await engagementService.toggleLike(postId: postId)
await realtimeObserver?.markCompleted(postId)
```

This ensures that local optimistic updates always win over realtime updates.

## Performance Characteristics

### Server-Side Filtering
- Uses `id=in.(uuid1,uuid2,...)` filter (Supabase Realtime Postgres Changes)
- Only receives updates for visible posts (99%+ bandwidth reduction vs all-posts subscription)
- Automatically chunks into ≤100 IDs per channel (Supabase limit)
- No spaces in filter string to avoid parsing issues

### Throttling
- Maximum 1 update per post every 300ms
- Drops intermediate updates to prevent UI churn

### Debouncing
- Subscription updates debounced by 500ms during scroll
- Prevents excessive channel creation/destruction

### Buffering
- Updates received during in-progress actions are buffered
- Applied after action completes if still relevant

### Lifecycle
- Auto-pauses on app background
- Auto-resumes on app foreground
- Unsubscribes when view disappears

### Chunking Example
```
Visible posts: 250 posts
Result: 3 channels created
  - Channel 1: posts 1-100 with filter "id=in.(uuid1,uuid2,...,uuid100)"
  - Channel 2: posts 101-200 with filter "id=in.(uuid101,uuid102,...,uuid200)"
  - Channel 3: posts 201-250 with filter "id=in.(uuid201,uuid202,...,uuid250)"
```

## Testing

Use the fake engagement service to test real-time behavior:

```swift
#Preview {
    let fake = EngagementServiceFake()
    
    return YourFeedView()
        .environment(\.deps, Dependencies.test(
            engagement: fake,
            supabase: MockSupabaseClient()
        ))
}
```

## Troubleshooting

### Updates not appearing?

1. Check that `deps.supabase` is wired up in `AgoraApp.swift`
2. Verify post IDs are being tracked in `visiblePostIds`
3. Ensure Supabase Realtime is enabled in your project
4. Check console for subscription errors
5. Verify post IDs are valid UUIDs (malformed IDs will fail the `in` filter)

### Performance issues?

1. Ensure only visible posts are tracked
2. Check that `.onDisappear` is removing posts
3. Verify throttling is working (check update frequency)
4. Check number of active subscriptions (should be `ceil(visiblePostIds.count / 100)`)
5. If >300 visible posts, consider pagination or limiting visible tracking

### Filter not working?

1. Check that post IDs are UUIDs (no quotes needed)
2. Ensure no spaces in the `in.(...)` list: `in.(uuid1,uuid2)` ✅ not `in.(uuid1, uuid2)` ❌
3. Verify visiblePostIds.count ≤ maxPostIdsPerChannel * subscriptions.count
4. Check Supabase logs for filter parsing errors

### Conflicts with local actions?

1. Use `markInProgress()` / `markCompleted()` buffering
2. Ensure optimistic updates happen before server call
3. Verify rollback logic on errors

## Database Setup

The observer subscribes to the `posts` table with server-side `in` filters. Ensure your database has:

```sql
-- Enable Realtime on posts table (required for Postgres Changes)
ALTER PUBLICATION supabase_realtime ADD TABLE posts;

-- Ensure RLS allows reads for public posts
CREATE POLICY posts_select_all ON posts
  FOR SELECT USING (visibility = 'public');

-- Verify Realtime is enabled in Supabase Dashboard:
-- Settings → API → Realtime → Enable Realtime for tables: posts
```

**Important:** The `in` filter is server-side, so RLS policies still apply. Make sure your RLS policies allow reading the posts you're subscribing to.

## Advanced: Multiple Feeds

Each feed view creates its own observer instance. This is efficient because:

1. Each observer only tracks its visible posts (server-side filtering)
2. Supabase multiplexes channels efficiently
3. Observers clean up on view disappear
4. Multiple observers watching the same post will share the same Realtime event (no duplication)

No special handling needed for multiple feeds.

## Migration Path to Broadcast (Future Scale)

If you outgrow Postgres Changes (e.g., >1000 posts/feed, millions of users), migrate to Broadcast:

```swift
// Instead of subscribing to database changes, subscribe to broadcast messages
// Edge Function broadcasts targeted engagement updates:
//   supabase.channel('engagement').send({ postId: 'x', likeCount: 42 })
// Client receives and applies updates without database subscriptions
```

Supabase docs recommend Broadcast for "high scale, high throughput" use cases.

