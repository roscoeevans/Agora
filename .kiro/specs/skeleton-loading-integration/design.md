# Design Document

## Overview

The Skeleton Loading Integration system provides a comprehensive, performance-optimized loading experience across Agora's feed interfaces. The design centers around a modular architecture that separates skeleton theming, component geometry, and animation timing to ensure consistent visual experiences while maintaining 60 FPS performance and accessibility compliance.

The system implements a three-tier architecture: a foundational theming layer, reusable skeleton components, and feed-specific integration points. This approach enables rapid deployment across Recommended feeds, Following feeds, Profile posts, and CommentSheet replies while maintaining visual consistency and performance standards.

## Architecture

### Core Components

```
Packages/Kits/DesignSystem/Sources/DesignSystem/Skeleton/
├── SkeletonTheme.swift              # Tokens bridge (ColorTokens/SpacingTokens/etc)
├── SkeletonViewStyle.swift          # Protocol for styling variants
├── SkeletonModifier.swift           # .skeleton(isActive:) SwiftUI modifier
├── ShimmerView.swift                # SwiftUI TimelineView gradient animation
├── SkeletonA11y.swift               # VoiceOver and accessibility helpers
├── MotionPreferences.swift          # Reduced Motion preference queries
├── FeedPostSkeletonView.swift       # Generic post-shaped placeholder
└── CommentSkeletonView.swift        # Compact reply placeholder

Packages/Features/HomeForYou/Sources/HomeForYou/
└── FeedSkeletonIntegration.swift    # HomeForYou skeleton integration

Packages/Features/HomeFollowing/Sources/HomeFollowing/
└── FeedSkeletonIntegration.swift    # HomeFollowing skeleton integration

Packages/Features/Profile/Sources/Profile/
└── ProfileSkeletonIntegration.swift # Profile posts skeleton integration

Packages/Features/PostDetail/Sources/PostDetail/
└── CommentSheetSkeleton.swift       # CommentSheet skeleton integration

Packages/Kits/Analytics/Sources/Analytics/
└── SkeletonAnalytics.swift          # Performance and timing metrics (optional)
```

### Data Flow Architecture

The skeleton system operates through a decentralized architecture where each Feature manages its own skeleton integration:

1. **Loading State Management**: Feature ViewModels emit loading states through `@Published` properties
2. **Skeleton Activation**: SwiftUI views respond to loading states via `.skeleton(isActive: isLoading || post == nil)` modifier
3. **Progressive Hydration**: Individual rows replace skeleton placeholders as data becomes available using index-replacement (no insert/delete animations)
4. **Performance Monitoring**: Optional Analytics Kit integration tracks timing metrics from Feature level

## Components and Interfaces

### SkeletonTheme Protocol

```swift
protocol SkeletonTheme {
    // Color Management (bridges existing DesignSystem tokens)
    var backgroundColor: Color { get } // ColorTokens.background
    var placeholderColor: Color { get } // ColorTokens.separator.opacity(0.3)
    var shimmerGradient: LinearGradient { get }
    
    // Animation Parameters
    var shimmerDuration: TimeInterval { get } // 1.5s default
    var crossfadeDuration: TimeInterval { get } // 300ms
    var staggerDelay: TimeInterval { get } // 50ms
    
    // Geometry Tokens (wraps existing DesignSystem tokens)
    var avatarSizes: (sm: CGFloat, md: CGFloat, lg: CGFloat) { get } // 40, 80, 120
    var spacingScale: SpacingTokens { get }
    var cornerRadii: BorderRadiusTokens { get }
    var typography: TypographyScale { get }
}
```

### FeedPostSkeletonView Component

The primary skeleton component mirrors FeedPostView geometry without content-specific details:

**Header Section**:
- 40×40pt circular avatar placeholder
- 120pt width name line with rounded rectangle
- 80pt handle + 60pt timestamp placeholders
- 16pt horizontal padding alignment

**Body Section**:
- 2-3 text line placeholders using TypographyScale.body
- Variable width lines (100%, 85%, 60%) for natural text appearance
- 1.2 line height matching final content

**Footer Section**:
- 44pt height engagement button row
- 16pt icon placeholders with 24pt spacing
- Touch target preservation for accessibility

### CommentSkeletonView Component

Compact skeleton for reply interfaces with reduced dimensions:

- 32×32pt avatar (smaller than feed posts)
- 100pt name width for compact layout
- 1-2 text lines with shorter content simulation
- Consistent spacing with parent CommentSheet design

### Shimmer Animation System

The shimmer effect uses SwiftUI TimelineView for smooth animation that respects accessibility preferences:

```swift
struct ShimmerView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) var increaseContrast
    
    var body: some View {
        if reduceMotion {
            // Static placeholder with increased contrast if needed
            RoundedRectangle(cornerRadius: 8)
                .fill(increaseContrast ? ColorTokens.separator : ColorTokens.separator.opacity(0.3))
        } else {
            // Animated shimmer using TimelineView
            TimelineView(.animation) { timeline in
                LinearGradient(...)
                    .mask(content)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false))
            }
        }
    }
}
```

## Data Models

### SkeletonConfiguration

```swift
struct SkeletonConfiguration {
    let placeholderCount: Int
    let preloadThreshold: Int
    let maxSimultaneousShimmers: Int
    let memoryLimit: Int // MB
    let analyticsEnabled: Bool
    
    static let recommended = SkeletonConfiguration(
        placeholderCount: 5,
        preloadThreshold: 5,
        maxSimultaneousShimmers: 10,
        memoryLimit: 100,
        analyticsEnabled: true
    )
}
```

### LoadingState Enumeration (per Feature)

```swift
// Lives in each Feature's integration file, not shared
enum LoadingState {
    case idle
    case loading(placeholderCount: Int)
    case hydrating(loadedIndices: Set<Int>)
    case loaded
    case error(Error)
}

// Feature ViewModel usage example
class HomeForYouViewModel: ObservableObject {
    @Published var loadingState: LoadingState = .idle
    @Published var posts: [Post?] = [] // nil entries show skeletons
}
```

## Error Handling

### Network Error Recovery

When network requests fail during skeleton loading phases:

1. **Inline Error Display**: Replace skeleton placeholders with retry chips containing error messages
2. **Graceful Degradation**: Maintain existing content visibility during refresh failures
3. **Progressive Retry**: Allow individual row retry without affecting entire feed state
4. **Analytics Tracking**: Log skeleton_error events with failure context

### Performance Error Handling

Memory and performance monitoring with automatic fallbacks:

- **Memory Pressure**: Reduce simultaneous shimmer count when approaching 100MB limit
- **Frame Rate Drops**: Disable shimmer animations if FPS drops below 55 for 3 consecutive seconds
- **Device Capability**: Automatically adjust skeleton complexity on older devices

## Testing Strategy

### Unit Testing Approach

**SkeletonTheme Tests**:
- Verify design token integration with DesignSystem
- Test dark mode color adaptation
- Validate accessibility color contrast ratios

**Component Geometry Tests**:
- Snapshot testing for FeedPostSkeletonView layout accuracy
- Verify CommentSkeletonView dimensions match CommentSheet design
- Test responsive behavior across device sizes

**Animation Performance Tests**:
- Measure shimmer animation CPU usage
- Verify 60 FPS maintenance during skeleton display
- Test memory usage during maximum skeleton load

### Integration Testing

**Feed Integration Tests**:
- Test skeleton-to-content transitions in HomeForYou and HomeFollowing
- Verify pagination skeleton behavior
- Test CommentSheet skeleton presentation timing

**Accessibility Integration Tests**:
- VoiceOver navigation with skeleton content hidden
- Reduced Motion preference handling
- Dynamic Type scaling verification

### Performance Testing

**Memory Benchmarks**:
- Maximum memory usage during 20+ skeleton display
- Memory cleanup after skeleton-to-content transition
- Background memory retention testing

**Animation Benchmarks**:
- FPS measurement during simultaneous shimmer animations
- CPU usage profiling for shimmer gradient calculations
- Battery impact assessment on device testing

## Implementation Phases

### Phase 1: Foundation Layer (Week 1)
- Implement SkeletonTheme protocol with DesignSystem integration
- Create base SkeletonViewStyle and .skeleton() modifier
- Build ShimmerView with accessibility support
- Add MotionPreferences handling for Reduced Motion

### Phase 2: Core Components (Week 2)
- Develop FeedPostSkeletonView with generic post-shaped geometry (no content-specific logic)
- Create CommentSkeletonView for reply interfaces
- Add SkeletonConfiguration per Feature (not shared)
- Build LoadingState enumeration in each Feature integration file

### Phase 3: Feed Integration (Week 3)
- Create FeedSkeletonIntegration.swift in HomeForYou and HomeFollowing Features
- Implement progressive hydration with index-replacement (no insert/delete animations)
- Add pagination skeleton support (pre-seed 5 placeholders, threshold=5 rows)
- Apply `.skeleton(isActive: isLoading || post == nil)` at row level

### Phase 4: CommentSheet Integration (Week 4)
- Create CommentSheetSkeleton.swift in PostDetail Feature
- Implement parent post immediate display with 6-8 skeleton replies
- Add sheet presentation with .presentationDetents([.fraction(0.65)])
- Test accessibility and motion preferences integration

### Phase 5: Analytics and Polish (Week 5)
- Add optional SkeletonAnalytics.swift in Analytics Kit (called from Features)
- Implement error recovery with retry chips and inline messages
- Performance optimization and memory monitoring in Features
- Final accessibility audit (.accessibilityHidden(true) on skeletons, "Loading..." announcements)

## Performance Considerations

### Memory Management
- Limit simultaneous skeleton views to 10 maximum on screen (per requirement)
- Use LazyVStack natural recycling for skeleton components
- Monitor memory pressure in Features and disable shimmer when approaching 100MB limit
- Implement simple "disable shimmer while fast-scrolling" flag in Feature ViewModels

### Animation Optimization
- Use SwiftUI TimelineView for 60/120 FPS shimmer timing (stays in SwiftUI land)
- Leverage SwiftUI's built-in animation batching and optimization
- Provide automatic animation disable for Reduced Motion accessibility
- Features can temporarily suspend shimmer during high-velocity scrolling

### Network Coordination
- Coordinate skeleton display timing with network request lifecycle in Features
- Implement intelligent preloading based on scroll velocity (Feature-level logic)
- Cache skeleton configurations locally within each Feature
- Use background queues for skeleton layout calculations when needed

## Dependency Architecture Compliance

### Package Dependencies
```
Features (HomeForYou, HomeFollowing, Profile, PostDetail)
├─ import DesignSystem   (Skeleton UI primitives)
└─ import Analytics      (optional: telemetry calls)

DesignSystem
└─ import AppFoundation  (tokens/types only)

Analytics Kit
└─ import AppFoundation  (foundation protocols)
```

### Forbidden Dependencies (Maintained)
- DesignSystem MUST NOT import Engagement/Networking/Features
- Features MUST NOT import other Features
- All skeleton business logic stays in Features, not DesignSystem
- DesignSystem provides only UI primitives and token bridges

### Integration Points
- **DesignSystem**: Pure UI components, no business logic, no service dependencies
- **Features**: Own their skeleton integration, loading states, and performance monitoring
- **Analytics**: Optional telemetry called from Features, not from DesignSystem