# Search

The Search feature module provides user and content discovery functionality in Agora. This module handles search queries, result display, and discovery recommendations.

## Purpose

This module implements the search and discovery experience where users can find other users, posts, and trending topics. It provides both real-time search and curated discovery content.

## Key Components

- **SearchView**: Main SwiftUI view for search interface and results
- **SearchViewModel**: Observable view model managing search state and results

## Dependencies

- **DesignSystem**: UI components and design tokens
- **Networking**: API communication for search queries

## Usage

```swift
import Search

struct MainTabView: View {
    var body: some View {
        TabView {
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
        }
    }
}
```

## Features

- **Real-time Search**: Live search results as user types
- **User Discovery**: Find users by handle or display name
- **Content Search**: Search posts by content and hashtags
- **Trending Topics**: Discover popular conversations
- **Search History**: Recent search suggestions

## Architecture

The module follows MVVM architecture with SwiftUI and uses `@Observable` for reactive state management. The view model handles:

- Search query debouncing and execution
- Result caching and pagination
- Search history management
- Trending content updates

## Testing

Run tests using:
```bash
swift test --package-path Packages/Features/Search
```

The module includes unit tests for search logic and UI tests for the search experience.