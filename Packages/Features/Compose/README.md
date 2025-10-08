# Compose

The Compose feature module provides post creation and editing functionality in Agora. This module handles text input, media attachment, and post publishing with proper validation and verification.

## Purpose

This module implements the post composition experience, including text input with character limits, media selection, draft management, and post publishing. It enforces Agora's human-only posting requirements through verification checks.

## Key Components

- **ComposeView**: Main SwiftUI view for post composition
- **ComposeViewModel**: Observable view model managing composition state and validation
- **MediaPickerView**: Interface for selecting photos and videos

## Dependencies

- **DesignSystem**: UI components and design tokens
- **Media**: Photo/video selection and processing
- **Networking**: API communication for post publishing
- **Verification**: Human verification checks for posting

## Usage

```swift
import Compose

struct MainView: View {
    @State private var showingCompose = false
    
    var body: some View {
        Button("New Post") {
            showingCompose = true
        }
        .sheet(isPresented: $showingCompose) {
            ComposeView()
        }
    }
}
```

## Features

- **Text Composition**: Rich text input with 70-character limit
- **Media Attachment**: Photo and video selection with compression
- **Draft Management**: Automatic draft saving and restoration
- **Verification**: Human verification checks before posting
- **Accessibility**: Full VoiceOver and Dynamic Type support

## Architecture

The module follows MVVM architecture with SwiftUI and uses `@Observable` for reactive state management. The view model handles:

- Text input validation and character counting
- Media selection and processing
- Draft persistence and restoration
- Post publishing and error handling

## Testing

Run tests using:
```bash
swift test --package-path Packages/Features/Compose
```

The module includes unit tests for validation logic and UI tests for the composition flow.