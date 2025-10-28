# Liquid Glass Transitions

## Overview

Liquid Glass transitions provide smooth, material-based animations that align with iOS 26 design patterns and Agora's Liquid Glass design language. These transitions combine scale, opacity, and blur effects to create polished, delightful user experiences.

## Available Transitions

### Standard Liquid Glass (`.liquidGlass`)

**Best for:** Empty states, cards, panels, general content

```swift
AgoraEmptyStateView.emptyFeed(action: onComposeAction)
    .transition(.liquidGlass)
```

**Effect:** 
- Scale: 95% → 100%
- Opacity: 0 → 1
- Blur: 8pt → 0pt

**Animation:** Spring (0.5s response, 0.8 damping)

---

### Prominent Liquid Glass (`.liquidGlassProminent`)

**Best for:** Modals, onboarding, important announcements, hero content

```swift
OnboardingView()
    .transition(.liquidGlassProminent)
```

**Effect:**
- Scale: 85% → 100% (more dramatic)
- Opacity: 0 → 1
- Blur: 8pt → 0pt
- Removal: Scale to 95% with opacity

**Animation:** Spring (0.6s response, 0.7 damping - more bouncy)

---

### Subtle Liquid Glass (`.liquidGlassSubtle`)

**Best for:** List items, inline content, frequent state changes

```swift
NotificationRow()
    .transition(.liquidGlassSubtle)
```

**Effect:**
- Scale: 98% → 100% (minimal)
- Opacity: 0 → 1
- Blur: 8pt → 0pt

**Animation:** Spring (0.4s response, 0.9 damping - gentle)

---

### Directional: From Bottom (`.liquidGlassFromBottom`)

**Best for:** Sheets, bottom panels, contextual content

```swift
ActionSheet()
    .transition(.liquidGlassFromBottom)
```

**Effect:**
- Push from bottom
- Opacity: 0 → 1
- Blur: 8pt → 0pt
- Removal: Push to top with opacity

**Animation:** Spring (0.5s response, 0.8 damping)

---

### Directional: From Top (`.liquidGlassFromTop`)

**Best for:** Navigation bars, banners, top-anchored content

```swift
Banner()
    .transition(.liquidGlassFromTop)
```

**Effect:**
- Push from top
- Opacity: 0 → 1
- Blur: 8pt → 0pt
- Removal: Push to bottom with opacity

**Animation:** Spring (0.5s response, 0.8 damping)

---

## Animation Curves

### `.liquidGlass` (Standard)
```swift
.animation(.liquidGlass, value: someState)
// Spring: 0.5s response, 0.8 damping
```

Use for most transitions and content changes.

### `.liquidGlassSubtle` (Gentle)
```swift
.animation(.liquidGlassSubtle, value: someState)
// Spring: 0.4s response, 0.9 damping
```

Use for list items and frequent updates.

### `.liquidGlassProminent` (Dramatic)
```swift
.animation(.liquidGlassProminent, value: someState)
// Spring: 0.6s response, 0.7 damping
```

Use for modals and important announcements.

### `.liquidGlassSmooth` (Predictable)
```swift
.animation(.liquidGlassSmooth, value: someState)
// Ease-in-out: 0.35s duration
```

Use when you need precise timing without spring physics.

---

## Usage Examples

### Empty State Transition

```swift
if posts.isEmpty {
    AgoraEmptyStateView.emptyFeed(action: onComposeAction)
        .transition(.liquidGlass)
} else {
    PostListView(posts: posts)
}
```

With animation:
```swift
Group {
    if posts.isEmpty {
        EmptyStateView()
            .transition(.liquidGlass)
    } else {
        ContentView()
    }
}
.animation(.liquidGlass, value: posts.isEmpty)
```

### Modal Presentation

```swift
if showModal {
    ModalView()
        .transition(.liquidGlassProminent)
}
```

With animation:
```swift
.animation(.liquidGlassProminent, value: showModal)
```

### List Item Insertion

```swift
ForEach(items) { item in
    ItemRow(item: item)
        .transition(.liquidGlassSubtle)
}
```

With animation:
```swift
.animation(.liquidGlassSubtle, value: items.count)
```

### Bottom Sheet

```swift
if showSheet {
    BottomSheet()
        .transition(.liquidGlassFromBottom)
}
```

With animation:
```swift
.animation(.liquidGlass, value: showSheet)
```

---

## Implementation Details

### Custom Blur Transition

Liquid Glass transitions use a custom blur modifier to animate blur radius:

```swift
private struct BlurTransitionModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .blur(radius: isActive ? 0 : 8)
    }
}
```

This creates smooth blur-to-sharp transitions that complement the material design aesthetic.

### Asymmetric Transitions

All Liquid Glass transitions use `.asymmetric()` to provide different insertion and removal animations:

- **Insertion:** Full effect (scale + opacity + blur)
- **Removal:** Simplified effect (usually just opacity)

This creates a more natural feel where content appears with flourish but disappears quickly.

---

## Accessibility

All Liquid Glass animations automatically respect:
- **Reduce Motion:** Blur and scale effects are maintained (structural), but spring animations use reduced motion curves
- **Increase Contrast:** No special handling needed as transitions are opacity-based

The blur effect (8pt) is subtle enough to maintain readability even for users sensitive to motion.

---

## Performance Notes

1. **Blur Performance:** The 8pt blur radius is optimized for performance on iOS 26+. Avoid increasing blur radius beyond 10pt.

2. **Spring Animations:** Spring animations are more performant than keyframe animations in SwiftUI.

3. **Lazy Loading:** Transitions work seamlessly with `LazyVStack` and `LazyHStack` for efficient list rendering.

4. **Material Compatibility:** Liquid Glass transitions work beautifully with `.thinMaterial` and `.regularMaterial` backgrounds.

---

## Design Guidelines

### When to Use Liquid Glass Transitions

✅ **DO use for:**
- Empty states appearing/disappearing
- Modals and sheets
- Cards and panels
- List items with infrequent updates
- Full-screen content changes
- Contextual overlays

❌ **DON'T use for:**
- Navigation stack transitions (use built-in NavigationStack transitions)
- Tab switching (use built-in TabView transitions)
- High-frequency updates (>2 per second)
- Small UI elements (<40pt)

### Choosing the Right Transition

| Content Type | Transition | Why |
|-------------|-----------|-----|
| Empty States | `.liquidGlass` | Standard scale/blur creates pleasant reveal |
| Modals | `.liquidGlassProminent` | Larger scale makes important content feel impactful |
| List Items | `.liquidGlassSubtle` | Minimal scale prevents distraction |
| Bottom Sheets | `.liquidGlassFromBottom` | Directional push matches sheet gesture |
| Banners/Alerts | `.liquidGlassFromTop` | Directional push creates natural flow |
| Cards/Panels | `.liquidGlass` | Standard transition for versatile content |

---

## Migration from Basic Transitions

### Before (Basic SwiftUI)

```swift
if isEmpty {
    EmptyView()
        .transition(.opacity)
}
```

### After (Liquid Glass)

```swift
if isEmpty {
    EmptyView()
        .transition(.liquidGlass)
}
.animation(.liquidGlass, value: isEmpty)
```

**Benefits:**
- More polished appearance
- Material-based blur effect
- Consistent with Agora design language
- Smooth spring physics
- Asymmetric insertion/removal

---

## Testing

Liquid Glass transitions include preview examples in DesignSystem:

```swift
#if DEBUG
@available(iOS 26.0, *)
struct LiquidGlassTransitions_Previews: PreviewProvider {
    static var previews: some View {
        // Interactive demos of all transition variants
    }
}
#endif
```

Run Xcode Previews to see transitions in action:
1. Open `LiquidGlassTransitions.swift` in Xcode
2. Enable Canvas (⌥⌘↵)
3. Interact with preview buttons to test transitions

---

## API Reference

### Transitions
- `AnyTransition.liquidGlass`
- `AnyTransition.liquidGlassProminent`
- `AnyTransition.liquidGlassSubtle`
- `AnyTransition.liquidGlassFromBottom`
- `AnyTransition.liquidGlassFromTop`

### Animations
- `Animation.liquidGlass`
- `Animation.liquidGlassSubtle`
- `Animation.liquidGlassProminent`
- `Animation.liquidGlassSmooth`

### Location
- **File:** `Packages/Kits/DesignSystem/Sources/DesignSystem/Transitions/LiquidGlassTransitions.swift`
- **Module:** `DesignSystem`
- **Availability:** iOS 26.0+

---

## Further Reading

- [SwiftUI Transitions Documentation](https://developer.apple.com/documentation/swiftui/anytransition)
- [Spring Animation Guidelines](https://developer.apple.com/design/human-interface-guidelines/motion)
- [Agora Design System](./DESIGN_SYSTEM.md)
- [Skeleton Loading Integration](../SKELETON_INTEGRATION_COMPLETE.md)



