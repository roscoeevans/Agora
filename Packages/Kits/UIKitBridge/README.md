# UIKitBridge

A centralized Swift Package for UIKit-to-SwiftUI bridges in the Agora iOS app.

## Overview

UIKitBridge provides clean, well-isolated wrappers for UIKit components that cannot be easily replaced with SwiftUI equivalents. This package centralizes all UIKit usage to maintain our SwiftUI-first architecture while providing necessary system integrations.

## What's Included

- **MediaPickerBridge**: System photo picker (`PHPickerViewController`)
- **ImagePickerBridge**: Simple image picker for profile photos
- **DesignSystemBridge**: Dark mode configuration utilities

## Usage

```swift
import UIKitBridge

// Use the bridges in your SwiftUI views
struct MyView: View {
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    var body: some View {
        Button("Select Image") {
            showImagePicker = true
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerBridge(image: $selectedImage)
        }
    }
}
```

## Architecture Principles

- **SwiftUI-First**: All public APIs are SwiftUI-native
- **Minimal UIKit Exposure**: UIKit types never leak beyond bridge boundaries
- **Platform Isolation**: iOS-only with proper `#if os(iOS)` guards
- **Clean Naming**: All bridges follow `{Thing}Bridge` naming convention

## When to Add New Bridges

Only add new UIKit bridges when:
1. **System Requirement**: The system/SDK mandates a UIViewController/UIView
2. **Rich Text Editing**: Complex text editing beyond SwiftUI's capabilities
3. **Specialized Input**: Custom gesture handling or drawing surfaces
4. **Legacy Integration**: Temporary wrappers for legacy components

## Testing

```bash
# Test the UIKitBridge module
agctl test UIKitBridge

# Test all modules
agctl test
```

## Related Documentation

- [SwiftUI-First Architecture Rule](../.cursor/rules/swiftui-first-architecture.mdc)
- [Project Structure Guidelines](../.cursor/rules/project-structure.mdc)
