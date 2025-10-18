# Engagement Kit

Post engagement services for Agora (likes, reposts, shares).

## Overview

The Engagement Kit provides a clean, protocol-based API for post engagement actions with:

- **Optimistic updates**: UI updates immediately before server confirmation
- **Error handling**: Typed errors with automatic rollback on failure
- **Rate limiting**: Server-side protection against spam
- **Analytics tracking**: Built-in event tracking for engagement actions
- **Real-time updates**: Support for live count updates via Supabase Realtime

## Architecture

```
EngagementService (protocol)
├── EngagementServiceLive (production)
└── EngagementServiceFake (testing/previews)
```

All implementations are actors for Swift 6 concurrency safety.

## Usage

### Initialization

```swift
// In composition root (e.g., AgoraApp.swift)
let engagement = EngagementServiceLive(
    baseURL: URL(string: "https://your-project.supabase.co/functions/v1")!,
    authTokenProvider: { await authSession.currentToken },
    session: .shared
)
```

### Toggle Like

```swift
do {
    let result = try await engagement.toggleLike(postId: "123")
    print("Liked: \(result.isLiked), Count: \(result.likeCount)")
} catch EngagementError.rateLimited {
    // Show rate limit message
} catch EngagementError.unauthorized {
    // Prompt sign in
}
```

### Toggle Repost

```swift
let result = try await engagement.toggleRepost(postId: "456")
print("Reposted: \(result.isReposted), Count: \(result.repostCount)")
```

### Get Share URL

```swift
let url = try await engagement.getShareURL(postId: "789")
// url: https://agora.app/p/789
```

## Testing

Use `EngagementServiceFake` for tests and previews:

```swift
#Preview {
    let fake = EngagementServiceFake()
    fake.likedPosts = ["post-1", "post-2"]
    
    return FeedView()
        .environment(\.engagement, fake)
}
```

## Error Handling

```swift
enum EngagementError {
    case postNotFound
    case unauthorized
    case networkError
    case serverError(String)
    case rateLimited
}
```

## Dependencies

- **AppFoundation**: Core domain models (Post, etc.)
- **Analytics**: Event tracking (optional)
- **Networking**: HTTP client infrastructure

## Backend Integration

This kit communicates with Supabase Edge Functions:

- `POST /functions/v1/toggle-like` - Toggle like on post
- `POST /functions/v1/toggle-repost` - Toggle repost on post

Both functions:
- Are idempotent (safe to retry)
- Enforce rate limiting (1 req/sec per user+post)
- Return updated counts from database
- Track correlation IDs for debugging

## Real-Time Updates

While this kit handles user-initiated actions, real-time count updates from other users
are handled by `RealtimeEngagementObserver` (see plan for implementation).

