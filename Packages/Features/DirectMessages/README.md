# DirectMessages

An iMessage-inspired direct messaging system for the Agora app.

## Overview

This package provides a complete direct messaging experience with:
- Conversation list view showing all user conversations
- Individual chat interface with message bubbles and composer
- Real-time messaging with typing indicators
- Media attachment support
- Accessibility and internationalization support

## Architecture

The DirectMessages feature follows Agora's modular architecture:

- **Views**: Main UI components (DirectMessagesView, ConversationView)
- **ViewModels**: State management and business logic
- **Components**: Reusable UI components (MessageBubble, ComposerBar, etc.)
- **Routing**: Navigation and entry points

## Dependencies

- **DesignSystem**: UI components and styling
- **AppFoundation**: Service protocols and shared utilities
- **Media**: Media processing and attachment handling

## Usage

```swift
import DirectMessages

// Entry point for the DM system
DMsEntry(route: .list)

// Navigate to specific conversation
DMsEntry(route: .conversation(id: conversationId))
```

## Requirements

This implementation satisfies requirements 1.1 and 2.1 from the iMessage DM system specification.