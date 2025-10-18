# Real-Time Engagement Integration Guide

This guide shows how to add real-time engagement count updates to feed views.

## Overview

The `RealtimeEngagementObserver` provides live updates for like and repost counts across all visible posts in a feed. It uses a single Supabase Realtime channel for optimal performance.

## Key Features

- ✅ **Single channel per feed** (not per post)
- ✅ **Automatic throttling** (300ms between updates)
- ✅ **Background pause/resume** (conserves battery)
- ✅ **Buffering during actions** (local actions win)
- ✅ **Debounced subscriptions** (smooth during scroll)

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

### Performance issues?

1. Ensure only visible posts are tracked
2. Check that `.onDisappear` is removing posts
3. Verify throttling is working (check update frequency)
4. Consider reducing visible post count

### Conflicts with local actions?

1. Use `markInProgress()` / `markCompleted()` buffering
2. Ensure optimistic updates happen before server call
3. Verify rollback logic on errors

## Database Setup

The observer subscribes to the `posts` table. Ensure your database has:

```sql
-- Enable Realtime on posts table
ALTER PUBLICATION supabase_realtime ADD TABLE posts;

-- Ensure RLS allows reads
CREATE POLICY posts_select_all ON posts
  FOR SELECT USING (visibility = 'public');
```

## Advanced: Multiple Feeds

Each feed view creates its own observer instance. This is efficient because:

1. Each observer only tracks its visible posts
2. Supabase multiplexes channels efficiently
3. Observers clean up on view disappear

No special handling needed for multiple feeds.

