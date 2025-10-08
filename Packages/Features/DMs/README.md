# DMs

The DMs (Direct Messages) feature module provides private messaging functionality in Agora. This module handles direct message conversations, thread management, and message composition.

## Purpose

This module implements the direct messaging system where users can have private conversations with other users. It provides a secure and intuitive messaging experience with real-time updates.

## Key Components

- **DMThreadsView**: Main SwiftUI view displaying message thread list
- **DMThreadsViewModel**: Observable view model managing thread state and updates

## Dependencies

- **DesignSystem**: UI components and design tokens
- **Networking**: API communication for message data
- **Media**: Media sharing in messages

## Usage

```swift
import DMs

struct MainTabView: View {
    var body: some View {
        TabView {
            DMThreadsView()
                .tabItem {
                    Label("Messages", systemImage: "message")
                }
        }
    }
}
```

## Features

- **Thread List**: Overview of all message conversations
- **Real-time Messaging**: Live message updates and delivery
- **Media Sharing**: Photo and video sharing in messages
- **Message Status**: Read receipts and delivery indicators
- **Thread Management**: Archive, delete, and mute conversations

## Architecture

The module follows MVVM architecture with SwiftUI and uses `@Observable` for reactive state management. The view model handles:

- Message thread loading and updates
- Real-time message processing
- Media attachment handling
- Thread state management

## Testing

Run tests using:
```bash
swift test --package-path Packages/Features/DMs
```

The module includes unit tests for message handling and UI tests for conversation flows.