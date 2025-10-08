# Threading

The Threading feature module provides reply chain management and conversation threading functionality in Agora. This module handles the display and navigation of nested reply structures.

## Purpose

This module implements the conversation threading system that allows users to follow reply chains and participate in nested discussions. It provides the infrastructure for displaying hierarchical conversations in a readable format.

## Key Components

- **ThreadView**: SwiftUI view for displaying reply chains
- **ThreadViewModel**: Observable view model managing thread state and navigation

## Dependencies

- **DesignSystem**: UI components and design tokens
- **Networking**: API communication for thread data

## Usage

```swift
import Threading

struct PostDetailView: View {
    let postId: String
    
    var body: some View {
        VStack {
            // Main post content
            ThreadView(rootPostId: postId)
        }
    }
}
```

## Features

- **Hierarchical Display**: Nested reply visualization with proper indentation
- **Thread Navigation**: Expand/collapse functionality for long threads
- **Reply Composition**: Inline reply creation within threads
- **Context Preservation**: Maintain thread context during navigation

## Architecture

The module follows MVVM architecture with SwiftUI and uses `@Observable` for reactive state management. The view model handles:

- Thread data loading and parsing
- Reply hierarchy management
- Expand/collapse state tracking
- Real-time thread updates

## Testing

Run tests using:
```bash
swift test --package-path Packages/Features/Threading
```

The module includes unit tests for thread parsing logic and UI tests for navigation flows.