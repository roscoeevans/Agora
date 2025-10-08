# HomeFollowing

The HomeFollowing feature module provides the chronological "Following" feed experience in Agora. This module displays posts from users that the current user follows in reverse chronological order.

## Purpose

This module implements the traditional social media timeline where users see posts from accounts they follow, ordered by recency. It provides a more predictable and controllable feed experience compared to the algorithmic For You feed.

## Key Components

- **FollowingView**: Main SwiftUI view displaying the chronological feed
- **FollowingViewModel**: Observable view model managing feed state and refresh logic

## Dependencies

- **DesignSystem**: UI components and design tokens
- **Networking**: API communication for feed data
- **Analytics**: User interaction tracking

## Usage

```swift
import HomeFollowing

struct MainTabView: View {
    var body: some View {
        TabView {
            FollowingView()
                .tabItem {
                    Label("Following", systemImage: "person.2")
                }
        }
    }
}
```

## Architecture

The module follows MVVM architecture with SwiftUI and uses `@Observable` for reactive state management. The view model handles:

- Chronological feed data loading
- Pull-to-refresh functionality
- Real-time updates for new posts
- Error handling and retry logic

## Testing

Run tests using:
```bash
swift test --package-path Packages/Features/HomeFollowing
```

The module includes unit tests for the view model and UI tests for feed interactions.