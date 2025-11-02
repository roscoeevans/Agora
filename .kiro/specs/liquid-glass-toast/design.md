# Design Document

## Overview

The Liquid Glass Toast system provides a sophisticated, Apple-native notification experience built on iOS 26's translucent design language. The architecture centers around an actor-based ToastManager for thread-safe queuing and scene-aware ToastPresenters that host SwiftUI overlays with Liquid Glass materials.

## Architecture

### System Components

```
App Environment
├── ToastManager (Actor)
│   ├── Queue<ToastItem> (FIFO with priority interruption)
│   ├── CoalescingPolicy (deduplication by key)
│   ├── RateLimiter (800ms minimum interval)
│   └── HapticsCoordinator
├── ToastPresenter (per UIScene/WindowGroup)
│   ├── OverlayWindow/SwiftUI overlay host
│   ├── KeyboardAvoidance
│   └── SafeAreaCalculation
└── ToastView (SwiftUI)
    ├── LiquidGlassMaterial
    ├── ContentLayout (icon + text + action)
    └── AnimationController
```

### Concurrency Model

- **ToastManager**: Actor ensuring thread-safe queue operations and state management
- **UI Operations**: All SwiftUI updates hop to @MainActor for thread safety
- **Scene Coordination**: Each UIScene gets its own ToastPresenter instance
- **Timer Management**: Background/foreground lifecycle handled at manager level

### Dependency Integration

- **AppFoundation**: ToastManager registered as singleton service with configurable ToastPolicy
- **DesignSystem**: ToastView consumes Agora's color tokens, spacing scale, and typography hierarchy
- **Environment**: Exposed via `@Environment(\.toasts)` with policy overrides via `@Environment(\.toastPolicy)`
- **UIKitBridge**: SceneOverlayCoordinator uses UIKitHostingController for gesture isolation

### Design System Integration

```swift
// Liquid Glass material with Agora design tokens
private var liquidGlassMaterial: some ShapeStyle {
    .ultraThinMaterial
        .blendMode(.overlay)
        .background {
            // Agora's gradient tokens for subtle brand integration
            LinearGradient(
                colors: [
                    DesignSystem.Colors.glassTint.opacity(0.1),
                    DesignSystem.Colors.glassTint.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
}

// Typography using Agora's scale
private var titleFont: Font {
    DesignSystem.Typography.title3.weight(.semibold)
}

// Spacing using Agora's tokens
private var contentPadding: EdgeInsets {
    EdgeInsets(
        top: DesignSystem.Spacing.medium,
        leading: DesignSystem.Spacing.large,
        bottom: DesignSystem.Spacing.medium,
        trailing: DesignSystem.Spacing.large
    )
}
```

## Components and Interfaces

### Core Data Models

```swift
public struct ToastID: Hashable, Sendable {
    private let uuid = UUID()
}

public enum ToastKind: Sendable {
    case success, error, info, warning
    case custom(icon: Image?, accent: Color?)
}

public enum ToastPriority: Sendable {
    case normal     // Default for info/success
    case elevated   // Warnings
    case critical   // Errors, can interrupt lower priority
}

public struct ToastOptions: Sendable {
    public var duration: Duration = .seconds(3)
    public var allowsUserDismiss: Bool = true
    public var presentationEdge: Edge = .top
    public var haptics: ToastHaptic = .auto
    public var accessibilityPolite: Bool = true
    public var dedupeKey: String? = nil
    public var maxWidth: CGFloat? = 600
    public var safeAreaBehavior: SafeAreaBehavior = .avoid
    public var reduceMotion: MotionBehavior = .respect
    public var priority: ToastPriority = .normal
}

public struct ToastAction: Sendable {
    public var title: LocalizedStringKey
    public var role: ButtonRole? = nil
    public var handler: @MainActor () -> Void
}

public struct ToastItem: Identifiable, Sendable {
    public let id: ToastID
    public let message: LocalizedStringKey
    public let kind: ToastKind
    public var options: ToastOptions
    public var action: ToastAction? = nil
}
```

### Public API Protocol

```swift
@MainActor public protocol ToastsProviding: AnyObject {
    func show(_ item: ToastItem)
    func show(_ message: LocalizedStringKey, 
              kind: ToastKind = .info, 
              options: ToastOptions = .init(),
              action: ToastAction? = nil)
    func dismiss(id: ToastID)
    func dismissAll()
}

// Convenience extensions
public extension ToastsProviding {
    func success(_ message: LocalizedStringKey, options: ToastOptions = .init(), action: ToastAction? = nil)
    func error(_ message: LocalizedStringKey, options: ToastOptions = .init(), action: ToastAction? = nil)
    func info(_ message: LocalizedStringKey, options: ToastOptions = .init(), action: ToastAction? = nil)
    func warning(_ message: LocalizedStringKey, options: ToastOptions = .init(), action: ToastAction? = nil)
}
```

### Environment Integration

```swift
public struct ToastEnvironmentKey: EnvironmentKey {
    public static let defaultValue: ToastsProviding = NoOpToastProvider()
}

public extension EnvironmentValues {
    var toasts: ToastsProviding {
        get { self[ToastEnvironmentKey.self] }
        set { self[ToastEnvironmentKey.self] = newValue }
    }
}
```

## Data Models

### ToastManager (Actor)

```swift
public actor ToastManager: ToastsProviding {
    private var queue: [ToastItem] = []
    private var currentToast: ToastItem?
    private var presentationState: PresentationState = .idle
    private var presenters: [ObjectIdentifier: ToastPresenter] = [:]
    private var coalescingCache: [String: ToastItem] = [:]
    private var lastPresentationTime: ContinuousClock.Instant?
    private var restorationQueue: [ToastItem] = [] // Cold launch restoration
    
    // State management for deterministic transitions
    enum PresentationState {
        case idle
        case presenting(ToastItem)
        case dismissing(ToastItem, reason: DismissalReason)
        case interrupted(current: ToastItem, next: ToastItem)
    }
    
    // Queue management with priority interruption
    private func enqueue(_ item: ToastItem) async
    private func processQueue() async
    private func handlePriorityInterruption(_ newItem: ToastItem) async
    private func transitionState(to newState: PresentationState) async
    
    // Scene restoration handling
    private func restoreQueuedToasts() async
    private func persistCriticalToasts() async
    
    // Coalescing logic
    private func shouldCoalesce(_ item: ToastItem) -> Bool
    private func updateExistingItem(_ item: ToastItem)
    
    // Rate limiting with configurable policy
    private func shouldRateLimit() -> Bool
    private func scheduleDelayedPresentation(_ item: ToastItem)
}
```

### ToastPresenter (MainActor)

```swift
@MainActor
public final class ToastPresenter: ObservableObject {
    @Published private(set) var currentToast: ToastItem?
    @Published private(set) var isPresented = false
    
    private let scene: UIScene
    private var dismissalTimer: Timer?
    private var keyboardFrame: CGRect = .zero
    private var overlayCoordinator: SceneOverlayCoordinator // Shared presentation surface
    
    // Presentation lifecycle with overlay isolation
    func present(_ item: ToastItem)
    func dismiss(animated: Bool = true)
    
    // Keyboard avoidance
    private func observeKeyboard()
    private func adjustForKeyboard(_ frame: CGRect)
    
    // Safe area calculation
    private func calculateSafeAreaInsets() -> EdgeInsets
    
    // Overlay management for gesture isolation
    private func configureOverlayWindow()
    private func isolateGestureHandling()
}

// Shared presentation surface for memory efficiency
private final class SceneOverlayCoordinator {
    private var hostingController: UIHostingController<ToastOverlayView>?
    private weak var overlayWindow: UIWindow?
    
    func presentToast(_ item: ToastItem, in scene: UIScene)
    func dismissCurrentToast(animated: Bool)
    func reuseOverlayForTransition()
}
```

### ToastView (SwiftUI)

```swift
public struct ToastView: View {
    let item: ToastItem
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    
    public var body: some View {
        // Liquid Glass implementation with content layout
    }
}
```

## Visual Design Specifications

### Liquid Glass Material Stack

```swift
// Background material with iOS 26 Liquid Glass
ZStack {
    // Base blur layer
    RoundedRectangle(cornerRadius: 18)
        .fill(.ultraThinMaterial)
        .environment(\.colorScheme, colorScheme)
    
    // Vibrancy layer for content
    RoundedRectangle(cornerRadius: 18)
        .fill(.clear)
        .overlay {
            contentView
                .foregroundStyle(.primary)
                .blendMode(.overlay)
        }
    
    // Subtle border highlight
    RoundedRectangle(cornerRadius: 18)
        .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
}
.shadow(color: .black.opacity(0.1), radius: 8, y: 4)
```

### Typography Hierarchy

- **Single Line**: `.title3` weight `.semibold` (20pt)
- **Multi-line**: `.body` weight `.medium` (17pt) with 1.2 line spacing
- **Maximum Lines**: 2 lines with tail truncation
- **Dynamic Type**: Support up to `.xxxLarge` with graceful overflow handling

### Icon Specifications

- **Size**: 20pt cap height with 17pt baseline alignment
- **Symbols**: SF Symbols with automatic weight matching
- **Semantic Colors**: 
  - Success: `.green`
  - Error: `.red` 
  - Warning: `.orange`
  - Info: `.blue`
  - Custom: User-provided accent color

### Layout Metrics

- **Padding**: 16pt horizontal, 12pt vertical
- **Icon Spacing**: 12pt trailing from icon to text
- **Action Spacing**: 16pt leading from text to action button
- **Corner Radius**: 18pt for modern iOS aesthetic
- **Maximum Width**: 600pt (iPad/landscape constraint)
- **Minimum Height**: 44pt for accessibility compliance

## Animation Specifications

### Appearance Animation

```swift
// Spring-based scale and opacity
.scaleEffect(isPresented ? 1.0 : 0.96)
.opacity(isPresented ? 1.0 : 0.0)
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
```

### Dismissal Animation

```swift
// Fade with directional translation
.opacity(isPresented ? 1.0 : 0.0)
.offset(y: isPresented ? 0 : (edge == .top ? -20 : 20))
.animation(.easeInOut(duration: 0.24), value: isPresented)
```

### Reduce Motion Adaptation

```swift
// Cross-fade only when reduce motion is enabled
if reduceMotion {
    .opacity(isPresented ? 1.0 : 0.0)
    .animation(.easeInOut(duration: 0.24), value: isPresented)
} else {
    // Full animation suite
}
```

### Interactive Dismissal

- **Gesture Recognition**: Pan gesture with directional constraints
- **Progress Tracking**: Linear interpolation of opacity and translation
- **Completion Threshold**: 30% drag distance or 200pt/s velocity
- **Spring Back**: Elastic return animation when gesture is cancelled

## Accessibility Implementation

### VoiceOver Integration

```swift
.accessibilityElement(children: .combine)
.accessibilityLabel(item.message)
.accessibilityHint(item.action != nil ? "Double tap to perform action" : "Double tap to dismiss")
.accessibilityActions {
    if let action = item.action {
        AccessibilityActionButton(action.title) {
            action.handler()
        }
    }
    AccessibilityActionButton("Dismiss") {
        onDismiss()
    }
}
```

### Announcement Strategy

```swift
// Post announcement when toast appears
UIAccessibility.post(
    notification: item.options.accessibilityPolite ? .announcement : .layoutChanged,
    argument: item.message
)
```

### Dynamic Type Support

```swift
@ViewBuilder
private var adaptiveLayout: some View {
    if dynamicTypeSize >= .xxxLarge {
        VStack(alignment: .leading, spacing: 8) {
            iconAndTextRow
            actionButton
        }
    } else {
        HStack(spacing: 12) {
            iconAndTextRow
            actionButton
        }
    }
}
```

## Performance Optimizations

### Rendering Efficiency

- **Blur View Reuse**: Single blur view per presenter, reused across toasts
- **Layer Limitation**: Maximum 3 sublayers (background, content, border)
- **Shadow Optimization**: Disable shadows in Low Power Mode
- **Texture Caching**: Cache SF Symbol renders for repeated use

### Memory Management

- **Weak References**: ToastPresenter holds weak scene references
- **Automatic Cleanup**: Remove presenters when scenes deallocate
- **Queue Bounds**: Limit queue size to 10 items maximum
- **Timer Invalidation**: Proper cleanup of dismissal timers

### Battery Considerations

```swift
// Adapt rendering quality based on power state
private var shouldUseLowPowerRendering: Bool {
    ProcessInfo.processInfo.isLowPowerModeEnabled
}

private var adaptiveBlurRadius: CGFloat {
    shouldUseLowPowerRendering ? 4.0 : 8.0
}

private var adaptiveShadowRadius: CGFloat {
    shouldUseLowPowerRendering ? 0.0 : 8.0
}
```

## Error Handling

### Graceful Degradation

- **Material Fallback**: Use solid colors when blur is unavailable
- **Animation Fallback**: Instant transitions when animations fail
- **Scene Recovery**: Recreate presenters when scene references become invalid
- **Queue Recovery**: Persist critical toasts through app lifecycle events

### Logging and Telemetry

```swift
public protocol ToastTelemetry {
    func toastShown(kind: ToastKind, duration: Duration) async
    func toastDismissed(id: ToastID, method: DismissalMethod) async
    func toastCoalesced(originalId: ToastID, updatedId: ToastID) async
    func toastDropped(reason: DropReason) async
    func animationPerformance(frameDrops: Int, duration: Duration) async
    func stateTransition(from: PresentationState, to: PresentationState) async
}

// Analytics integration with async telemetry
public final class ToastAnalyticsHook: ToastTelemetry {
    private let analytics: AnalyticsProviding
    
    public func toastShown(kind: ToastKind, duration: Duration) async {
        // Async telemetry dispatch to maintain silky UX
        await analytics.track("toast_shown", properties: [
            "kind": kind.analyticsValue,
            "duration_ms": duration.milliseconds
        ])
    }
    
    // Additional async implementations...
}
```

### Configurable Rate Limiting

```swift
public struct ToastPolicy: Sendable {
    public var minimumInterval: Duration = .milliseconds(800)
    public var maxQueueSize: Int = 10
    public var coalescingWindow: Duration = .seconds(2)
    public var criticalInterruptionDelay: Duration = .milliseconds(120)
    
    public static let `default` = ToastPolicy()
    public static let aggressive = ToastPolicy(minimumInterval: .milliseconds(400))
    public static let conservative = ToastPolicy(minimumInterval: .seconds(1.5))
}

// Environment integration for policy configuration
public struct ToastPolicyKey: EnvironmentKey {
    public static let defaultValue = ToastPolicy.default
}

public extension EnvironmentValues {
    var toastPolicy: ToastPolicy {
        get { self[ToastPolicyKey.self] }
        set { self[ToastPolicyKey.self] = newValue }
    }
}
```

## Testing Strategy

### Unit Testing

- **Queue Logic**: Priority interruption, coalescing, rate limiting
- **Timer Management**: Background/foreground lifecycle
- **Scene Coordination**: Multi-window presenter management
- **Accessibility**: VoiceOver announcement verification

### Snapshot Testing

- **Visual Variants**: Light/dark mode, all toast kinds
- **Accessibility States**: Reduce transparency, high contrast
- **Dynamic Type**: All supported sizes with layout verification
- **Device Classes**: iPhone, iPad, landscape orientations

### Performance Testing

- **Animation Smoothness**: Frame rate measurement during transitions
- **Memory Usage**: Leak detection and memory pressure testing
- **Battery Impact**: Power consumption measurement
- **Rendering Cost**: Core Animation instrument profiling

### Integration Testing

- **Keyboard Avoidance**: Bottom toast repositioning
- **Multi-Scene**: Proper toast isolation between windows
- **System Conflicts**: Behavior with system banners and alerts
- **Gesture Handling**: Interactive dismissal accuracy
- **Scene Restoration**: Cold launch behavior with queued toasts
- **State Transitions**: Deterministic behavior under interruption scenarios
- **Overlay Isolation**: Gesture leakage prevention into app content

## Security and Privacy

### Content Safety

- **PII Protection**: No automatic logging of toast content
- **Sensitive Announcements**: Opt-in only for sensitive VoiceOver content
- **Screenshot Protection**: Exclude toasts from sensitive screen recordings

### Data Handling

- **Ephemeral Storage**: No persistent storage of toast content
- **Memory Clearing**: Explicit cleanup of dismissed toast data
- **Telemetry Anonymization**: No user-identifiable information in metrics