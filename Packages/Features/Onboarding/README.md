# Onboarding

Beautiful, Apple-style first-launch onboarding carousel for Agora.

## Purpose

Provides a welcoming introduction to Agora's core features and values through a swipeable carousel shown once per device on first launch (or after app reinstallation).

## Features

- **One-Time Display**: Shows only once per device, tracks completion with version number
- **4 Key Pages**: Welcome, Humanity First, Self-Destruct, Personalized Feeds
- **Apple UX**: SwiftUI-native, liquid glass aesthetics, SF Symbols, haptic feedback
- **Light/Dark Mode**: Full support for both appearance modes
- **Smooth Animations**: Page transitions, symbol effects, sensory feedback
- **Accessibility**: Supports Dynamic Type, VoiceOver, and Reduce Motion

## Usage

Wrap your authentication flow in `OnboardingGate`:

```swift
import Onboarding

@main
struct AgoraApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingGate {
                // Your auth/main content here
                WelcomeView()
            }
        }
    }
}
```

## Architecture

### Components

- **OnboardingGate**: Gate view that checks completion status and shows onboarding or child content
- **OnboardingCarouselView**: Full-screen carousel with swipeable pages
- **OnboardingPageView**: Individual page with icon, title, and body text
- **OnboardingPage**: Model representing page data
- **OnboardingModule**: Constants including current version number

### Persistence

Uses `@AppStorage("onboarding.completed.version")` to track completion:
- First launch: `nil` → Shows onboarding
- After completion: Set to `OnboardingModule.currentVersion` (currently `1`)
- App reinstall: Resets to `nil` → Shows onboarding again

### Version Management

To show onboarding again when content changes:
1. Update content in `OnboardingPage.pages`
2. Increment `OnboardingModule.currentVersion`
3. All users will see updated onboarding once

## Design

### Visual Aesthetics
- **Full-screen pages** for immersion
- **Large SF Symbols** (80pt) with gradient colors
- **Bold titles** (34pt, rounded design)
- **Clear body text** (17pt) with generous line spacing
- **Pagination dots** at bottom
- **Primary CTA button** (rounded, accent color)

### Interaction
- **Swipe** between pages (primary)
- **Next button** for one-handed use
- **Get Started** on final page
- **Haptic feedback** on page change
- **Smooth animations** (0.3s ease-in-out)

### Accessibility
- Semantic colors adapt to light/dark mode
- SF Symbols automatically adapt
- Text uses system fonts with Dynamic Type support
- All interactive elements have proper touch targets (50pt button height)

## Dependencies

- **DesignSystem**: Brand colors, spacing, typography
- **AppFoundation**: PreviewDeps for SwiftUI previews

## Testing

Run tests:
```bash
agctl test Onboarding
```

Preview in Xcode Canvas:
- Open any `.swift` file in the package
- Use `#Preview` blocks at the bottom
- Test both light and dark modes

## Notes

- Onboarding is **pre-authentication** (shown before login/signup)
- Does not require network or authentication
- State is device-local (survives app updates, not reinstalls)
- Analytics integration ready (commented out in OnboardingGate)

