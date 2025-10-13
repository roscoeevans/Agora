# DesignSystem

The DesignSystem kit module provides shared UI components, design tokens, and styling utilities for the Agora iOS app. This module ensures visual consistency and accessibility across all features.

## Purpose

This module implements Agora's design system with iOS-native components, color tokens, typography scales, and spacing systems. It provides the foundation for all UI elements and ensures consistent visual design throughout the app.

## Key Components

- **ColorTokens**: Adaptive color palette with dark mode support
- **TypographyScale**: San Francisco font hierarchy with Dynamic Type support
- **SpacingTokens**: 8-point grid spacing system
- **AgoraButton**: Standardized button component with multiple styles

## Dependencies

None - This is a foundation UI module with only SwiftUI dependencies.

## Usage

```swift
import DesignSystem
import SwiftUI

struct MyView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            Text("Welcome to Agora")
                .font(TypographyScale.title1)
                .foregroundColor(ColorTokens.primaryText)
            
            AgoraButton("Get Started", style: .primary) {
                // Action
            }
        }
        .padding(SpacingTokens.lg)
        .background(ColorTokens.background)
    }
}
```

## Design Tokens

### Colors

All colors automatically adapt to light and dark modes with **dark mode as the default**:

- **Primary Colors**: `ColorTokens.primary`, `ColorTokens.primaryVariant`
- **Background Colors**: `ColorTokens.background`, `ColorTokens.secondaryBackground`
- **Text Colors**: `ColorTokens.primaryText`, `ColorTokens.secondaryText`
- **Status Colors**: `ColorTokens.success`, `ColorTokens.warning`, `ColorTokens.error`
- **Brand Colors**: `ColorTokens.agoraBrandCustom` (#FF3466), `ColorTokens.agoraAccentCustom` (#ED90FC), `ColorTokens.agoraTertiaryCustom` (#34C3FC) - all with custom dark mode variants

### Typography

Based on San Francisco font with full Dynamic Type support:

- **Titles**: `TypographyScale.largeTitle`, `TypographyScale.title1`, `TypographyScale.title2`
- **Body Text**: `TypographyScale.body`, `TypographyScale.callout`, `TypographyScale.subheadline`
- **Small Text**: `TypographyScale.footnote`, `TypographyScale.caption1`, `TypographyScale.caption2`

### Spacing

8-point grid system for consistent spacing:

- **Small**: `SpacingTokens.xs` (8pt), `SpacingTokens.sm` (12pt)
- **Medium**: `SpacingTokens.md` (16pt), `SpacingTokens.lg` (24pt)
- **Large**: `SpacingTokens.xl` (32pt), `SpacingTokens.xxl` (40pt)

## Components

### AgoraButton

Standardized button component with multiple styles:

```swift
AgoraButton("Primary Action", style: .primary) { }
AgoraButton("Secondary Action", style: .secondary) { }
AgoraButton("Destructive Action", style: .destructive) { }
```

## Dark Mode Support

The design system is optimized for dark mode with it set as the default:

- **Default Dark Mode**: App launches in dark mode by default
- **Adaptive Colors**: All colors automatically adapt to light/dark modes
- **Dark Mode Shadows**: Specialized shadow tokens for dark backgrounds
- **System Integration**: Respects system appearance settings when configured
- **Custom Brand Colors**: Agora brand colors with optimized dark mode variants

### Dark Mode Configuration

```swift
// Set dark mode as default (called automatically in AgoraApp)
DesignSystem.configureDarkModeAsDefault()

// Force dark mode regardless of system setting
DesignSystem.forceDarkMode()

// Force light mode
DesignSystem.forceLightMode()

// Follow system appearance
DesignSystem.followSystemAppearance()

// Check current mode
let isDark = DesignSystem.isDarkMode
```

## Accessibility

All components include:

- **VoiceOver Support**: Proper accessibility labels and hints
- **Dynamic Type**: Automatic text scaling support
- **High Contrast**: Enhanced contrast ratios in accessibility modes
- **Reduce Motion**: Respects motion reduction preferences
- **Dark Mode**: Optimized for dark mode with proper contrast ratios

## Architecture

The module provides:

- **Tokens**: Centralized design values (colors, typography, spacing)
- **Components**: Reusable UI components with consistent styling
- **Modifiers**: SwiftUI view modifiers for common styling patterns
- **Extensions**: Convenience extensions for SwiftUI views

## Testing

Run tests using:
```bash
swift test --package-path Packages/Kits/DesignSystem
```

The module includes comprehensive tests for:
- Color accessibility and contrast ratios
- Typography Dynamic Type compliance
- Component behavior and accessibility
- Dark mode adaptation