# Home

The Home feature module provides the main home feed experience in Agora. This module combines the For You and Following feeds into a unified home experience with feed switching capabilities.

## Purpose

This module implements the primary home screen where users can switch between their personalized "For You" feed and their chronological "Following" feed. It serves as the main entry point for content consumption.

## Key Components

- **HomeView**: Main SwiftUI view that combines For You and Following feeds
- **FeedType**: Enum defining the available feed types (forYou, following)

## Dependencies

- **DesignSystem**: UI components and design tokens
- **HomeForYou**: For You feed functionality
- **HomeFollowing**: Following feed functionality

## Usage

```swift
import Home

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
        }
    }
}
```

## Features

- **Feed Switching**: Toggle between For You and Following feeds
- **Unified Navigation**: Consistent navigation experience across feeds
- **Segmented Control**: Easy feed type selection in the navigation bar
- **Responsive Design**: Adapts to different screen sizes and orientations

## Architecture

The module follows MVVM architecture with SwiftUI and uses `@State` for local state management. The view coordinates between the two feed modules:

- **HomeForYou**: Provides personalized content recommendations
- **HomeFollowing**: Provides chronological content from followed users

## Testing

Run tests using:
```bash
swift test --package-path Packages/Features/Home
```

The module includes unit tests for feed switching logic and UI tests for the home experience.


