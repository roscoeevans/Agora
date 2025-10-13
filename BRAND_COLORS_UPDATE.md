# Brand Colors Update

## Overview

The Agora design system brand colors have been updated to the new color palette.

## New Brand Colors

| Color | Hex Code | RGB (0-1) | Usage |
|-------|----------|-----------|-------|
| **Primary** | `#FF3466` | RGB(1.000, 0.204, 0.400) | Main brand color, primary actions |
| **Accent** | `#ED90FC` | RGB(0.929, 0.565, 0.988) | Accent color, secondary highlights |
| **Tertiary** | `#34C3FC` | RGB(0.204, 0.765, 0.988) | Tertiary brand elements, highlights |

## Changes Made

### 1. Updated Color Assets

- **AgoraBrand.colorset**: Updated to Primary color (#FF3466)
  - Light mode: RGB(1.000, 0.204, 0.400)
  - Dark mode: RGB(1.000, 0.300, 0.500) - slightly brighter for dark backgrounds

- **AgoraAccent.colorset**: Updated to Accent color (#ED90FC)
  - Light mode: RGB(0.929, 0.565, 0.988)
  - Dark mode: RGB(0.950, 0.600, 1.000) - slightly brighter for dark backgrounds

- **AgoraTertiary.colorset**: Created new color asset for Tertiary color (#34C3FC)
  - Light mode: RGB(0.204, 0.765, 0.988)
  - Dark mode: RGB(0.250, 0.800, 1.000) - slightly brighter for dark backgrounds

### 2. Updated DesignSystem.swift

Added the new tertiary color token:
```swift
public static let agoraTertiaryCustom = Color("AgoraTertiary", bundle: .module)
```

Added backward compatibility extension:
```swift
static let agoraTertiary = ColorTokens.agoraTertiaryCustom
```

### 3. Updated Tests

Updated `ColorTokensTests.swift` to include assertions for the new color:
- Added `agoraTertiaryCustom` to the color token existence tests
- Added `agoraTertiary` to the backward compatibility tests

### 4. Updated Documentation

Updated `DesignSystem/README.md` to document all three brand colors with their hex codes.

## Usage

### Access the new colors in SwiftUI:

```swift
// Using ColorTokens
Text("Hello")
    .foregroundColor(ColorTokens.agoraBrandCustom)     // Primary #FF3466
    
Text("World")
    .foregroundColor(ColorTokens.agoraAccentCustom)    // Accent #ED90FC
    
Text("!")
    .foregroundColor(ColorTokens.agoraTertiaryCustom)  // Tertiary #34C3FC

// Using convenience extensions
Text("Hello")
    .foregroundColor(.agoraPrimary)    // Maps to primary/accentColor
    
Text("World")  
    .foregroundColor(.agoraTertiary)   // Maps to agoraTertiaryCustom
```

## Dark Mode Support

All three colors have been optimized for both light and dark modes:
- Dark mode variants are slightly brighter to ensure proper visibility on dark backgrounds
- Colors maintain their distinctive character while adapting to the color scheme
- Automatic adaptation based on system/app appearance settings

## Files Modified

- `/Packages/Kits/DesignSystem/Sources/DesignSystem/Resources/Colors.xcassets/AgoraBrand.colorset/Contents.json`
- `/Packages/Kits/DesignSystem/Sources/DesignSystem/Resources/Colors.xcassets/AgoraAccent.colorset/Contents.json`
- `/Packages/Kits/DesignSystem/Sources/DesignSystem/Resources/Colors.xcassets/AgoraTertiary.colorset/Contents.json` (new)
- `/Packages/Kits/DesignSystem/Sources/DesignSystem/DesignSystem.swift`
- `/Packages/Kits/DesignSystem/Tests/DesignSystemTests/ColorTokensTests.swift`
- `/Packages/Kits/DesignSystem/README.md`

## System Blue Removal

All references to the default iOS system blue color have been removed and replaced with your custom brand colors:

### Global App Tint Color / AccentColor
**Important**: `AccentColor` IS our PRIMARY brand color (#FF3466). This is the global iOS accent color.

- **AccentColor.colorset** (in Resources/Assets.xcassets): Set to PRIMARY color #FF3466
  - This is the app-wide tint color used throughout iOS
  - Same color as `AgoraBrand` in DesignSystem, but accessible from UIKit
  - Used by `ColorTokens.primary` which is `Color.accentColor`

- **UITabBar.appearance().tintColor**: Loads AccentColor (PRIMARY brand color #FF3466)
  - Configured in `AgoraApp.swift` 
  - Unselected items use `UIColor.secondaryLabel` for proper contrast

### ColorTokens Updates
- `primaryVariant`: Changed from `Color.blue` → Primary brand color
- `link`: Changed from `UIColor.link` → Primary brand color  
- `info`: Changed from `Color(.systemBlue)` → Tertiary brand color (#34C3FC)
- `agoraBrand`: Changed from `Color(.systemBlue)` → Primary brand color
- `agoraBrandDark`: Changed from `Color(.systemBlue)` → Primary brand color
- `agoraBrandLight`: Changed from `Color(.systemBlue)` → Primary brand color
- `agoraAccent`: Changed from `Color(.systemPink)` → Accent color (#ED90FC)
- `agoraAccentDark`: Changed from `Color(.systemPink)` → Accent color
- `agoraAccentLight`: Changed from `Color(.systemPink)` → Accent color

**Result**: No system blue colors remain in the app. All tints, links, and brand colors now use your custom color palette.

## Next Steps

Your brand colors are now fully integrated:

1. ✅ Global accent color set to Primary (#FF3466)
2. ✅ All system blue references replaced
3. ✅ Link colors use Primary brand color
4. ✅ Info colors use Tertiary brand color
5. Build and run the app to see your new brand colors throughout the UI!

## Testing

Run the design system tests to verify all colors are properly configured:
```bash
swift test --package-path Packages/Kits/DesignSystem
```

Note: There are pre-existing macOS platform availability warnings in the DesignSystem package that are unrelated to these color changes.

