# PostDetail

The PostDetail feature module provides detailed post viewing and interaction functionality in Agora. This module displays individual posts with their full context, replies, and interaction options.

## Purpose

This module implements the detailed post view where users can see a post's full content, read replies, and interact with the post through likes, reposts, and replies. It serves as the destination for post deep links and detailed discussions.

## Key Components

- **PostDetailView**: Main SwiftUI view displaying the post and replies
- **PostDetailViewModel**: Observable view model managing post data and interactions

## Dependencies

- **DesignSystem**: UI components and design tokens
- **Networking**: API communication for post data and interactions
- **Threading**: Reply chain management and display

## Usage

```swift
import PostDetail

struct FeedView: View {
    var body: some View {
        NavigationStack {
            // Feed content
            NavigationLink(destination: PostDetailView(postId: "123")) {
                PostRowView(post: post)
            }
        }
    }
}
```

## Features

- **Post Display**: Full post content with media and metadata
- **Reply Threading**: Hierarchical reply display and navigation
- **Interactions**: Like, repost, reply, and share functionality
- **Deep Linking**: Support for direct post URLs
- **Accessibility**: Full VoiceOver support and semantic markup

## Architecture

The module follows MVVM architecture with SwiftUI and uses `@Observable` for reactive state management. The view model handles:

- Post data loading and caching
- Reply thread management
- User interaction handling
- Real-time updates for engagement metrics

## Testing

Run tests using:
```bash
swift test --package-path Packages/Features/PostDetail
```

The module includes unit tests for the view model and integration tests for threading functionality.