# ToastKit

A sophisticated toast notification system built on iOS 26's Liquid Glass design language. Provides elegant, non-intrusive feedback with scene-aware presentation, accessibility support, and intelligent queuing.

## Features

- **Liquid Glass Materials**: iOS 26 translucent backgrounds with backdrop blur and vibrancy
- **Scene Awareness**: Multi-window support with proper toast isolation
- **Smart Queuing**: FIFO with priority interruption and coalescing policies
- **Accessibility**: Full VoiceOver support, Dynamic Type, and Reduce Motion adaptation
- **Performance**: Actor-based concurrency with optimized rendering and battery considerations

## Usage

```swift
import ToastKit

// Environment access
@Environment(\.toasts) private var toasts

// Show basic toast
toasts.success("Profile updated successfully")

// Show toast with action
toasts.error("Failed to save", action: ToastAction(
    title: "Retry",
    handler: { /* retry logic */ }
))

// Custom toast
toasts.show(ToastItem(
    id: ToastID(),
    message: "Custom notification",
    kind: .custom(icon: Image(systemName: "star"), accent: .purple),
    options: ToastOptions(duration: .seconds(5), presentationEdge: .bottom)
))
```

## Architecture

The system is built around three core components:

- **ToastManager**: Actor-based service for thread-safe queue management
- **ToastPresenter**: Scene-bound component for overlay hosting
- **ToastView**: SwiftUI component with Liquid Glass materials

See the design document for detailed architecture information.