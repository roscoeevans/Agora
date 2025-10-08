# HomeForYou

The HomeForYou feature module provides the personalized "For You" feed experience in Agora. This module displays algorithmically curated content based on user preferences and engagement patterns.

## Purpose

This module implements the main discovery feed where users see recommended posts from across the platform. The feed uses server-side recommendation algorithms combined with client-side mixing to provide a personalized experience.

## Key Components

- **HomeForYouView**: Main SwiftUI view displaying the personalized feed
- **ForYouViewModel**: Observable view model managing feed state and data loading
- **ForYouCoordinator**: Navigation coordinator for handling deep links and transitions

## Dependencies

- **DesignSystem**: UI components and design tokens
- **Networking**: API communication for feed data
- **Analytics**: User interaction tracking
- **Recommender**: Client-side feed mixing and signal collection

## Usage

```swift
import HomeForYou

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeForYouView()
                .tabItem {
                    Label("For You", systemImage: "house")
                }
        }
    }
}
```

## Architecture

The module follows MVVM architecture with SwiftUI and uses `@Observable` for reactive state management. The view model handles:

- Feed data loading and pagination
- Pull-to-refresh functionality
- Error handling and retry logic
- Analytics event tracking

## Testing

Run tests using:
```bash
swift test --package-path Packages/Features/HomeForYou
```

The module includes unit tests for the view model and integration tests for the coordinator.