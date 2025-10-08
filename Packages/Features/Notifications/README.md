# Notifications

The Notifications feature module provides activity notification management and display functionality in Agora. This module handles notification display, interaction, and settings.

## Purpose

This module implements the notifications experience where users can see activity related to their posts and account, including likes, replies, follows, and mentions.

## Key Components

- **NotificationsView**: Main SwiftUI view displaying notification list
- **NotificationsViewModel**: Observable view model managing notification state and updates

## Dependencies

- **DesignSystem**: UI components and design tokens
- **Networking**: API communication for notification data

## Usage

```swift
import Notifications

struct MainTabView: View {
    var body: some View {
        TabView {
            NotificationsView()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
        }
    }
}
```

## Features

- **Activity Feed**: Display of likes, replies, follows, and mentions
- **Real-time Updates**: Live notification updates
- **Notification Grouping**: Smart grouping of similar activities
- **Mark as Read**: Read state management
- **Notification Settings**: Granular notification preferences

## Architecture

The module follows MVVM architecture with SwiftUI and uses `@Observable` for reactive state management. The view model handles:

- Notification data loading and updates
- Read state management
- Real-time notification processing
- Notification grouping logic

## Testing

Run tests using:
```bash
swift test --package-path Packages/Features/Notifications
```

The module includes unit tests for notification processing and UI tests for interaction flows.