# Dark Mode Support & Type Mismatch Fixes

## Overview

Fixed type mismatch compiler errors in `DesignSystem.swift` and enhanced UIKit bridging for accessibility features related to dark mode support.

## Issues Fixed

### 1. Type Mismatch in `agoraHighContrast()` (Line 590)
**Error**: `Branches have mismatching types 'some View' and 'Self'`

**Problem**: 
- The `if` branch returned `self.overlay(...)` which has type `some View`
- The `else` branch returned `self` which has type `Self`
- Swift couldn't reconcile these different return types

**Solution**:
Wrapped both branches in a `Group` to ensure consistent return type:
```swift
func agoraHighContrast() -> some View {
    Group {
        #if canImport(UIKit)
        if DesignSystemBridge.isDarkerSystemColorsEnabled {
            self
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.primary, lineWidth: 2)
                )
        } else {
            self
        }
        #else
        self
        #endif
    }
}
```

### 2. Type Mismatch in `agoraReducedMotion()` (Line 607)
**Error**: `Branches have mismatching types 'some View' and 'Self'`

**Problem**: 
- The `if` branch returned `self.animation(nil, value: UUID())` which has type `some View`
- The `else` branch returned `self` which has type `Self`

**Solution**:
Wrapped both branches in a `Group` to ensure consistent return type:
```swift
func agoraReducedMotion() -> some View {
    Group {
        #if canImport(UIKit)
        if DesignSystemBridge.isReduceMotionEnabled {
            self
                .animation(nil, value: UUID()) // Disable all animations
        } else {
            self
        }
        #else
        self
        #endif
    }
}
```

## UIKit Bridging Enhancements

### New Accessibility Properties in `DesignSystemBridge`

Added comprehensive accessibility detection properties to `UIKitBridge/DesignSystemBridge.swift`:

#### 1. **High Contrast Support**
```swift
public static var isDarkerSystemColorsEnabled: Bool {
    #if canImport(UIKit)
    return UIAccessibility.isDarkerSystemColorsEnabled
    #else
    return false
    #endif
}
```
- Detects when user has enabled "Increase Contrast" in iOS settings
- Used by `agoraHighContrast()` modifier to add enhanced borders

#### 2. **Reduce Motion Support**
```swift
public static var isReduceMotionEnabled: Bool {
    #if canImport(UIKit)
    return UIAccessibility.isReduceMotionEnabled
    #else
    return false
    #endif
}
```
- Detects when user has enabled "Reduce Motion" in iOS settings
- Used by `agoraReducedMotion()` modifier to disable animations

#### 3. **VoiceOver Support**
```swift
public static var isVoiceOverRunning: Bool {
    #if canImport(UIKit)
    return UIAccessibility.isVoiceOverRunning
    #else
    return false
    #endif
}
```
- Detects when VoiceOver is actively running
- Can be used for enhanced screen reader support

#### 4. **Switch Control Support**
```swift
public static var isSwitchControlRunning: Bool {
    #if canImport(UIKit)
    return UIAccessibility.isSwitchControlRunning
    #else
    return false
    #endif
}
```
- Detects when Switch Control is enabled
- Useful for adjusting touch targets

#### 5. **Bold Text Support**
```swift
public static var isBoldTextEnabled: Bool {
    #if canImport(UIKit)
    return UIAccessibility.isBoldTextEnabled
    #else
    return false
    #endif
}
```
- Detects when user has enabled "Bold Text"
- Can be used to adjust font weights

## Benefits of UIKit Bridging Approach

### 1. **Separation of Concerns**
- SwiftUI design system stays clean and SwiftUI-focused
- UIKit accessibility APIs are properly isolated in UIKitBridge
- Cross-platform support with proper fallbacks

### 2. **Consistency with Existing Architecture**
- Follows established pattern from `swiftui-first-architecture` rule
- Matches existing `DesignSystemBridge` usage for colors and haptics
- All UIKit dependencies go through UIKitBridge package

### 3. **Apple-Native Integration**
- Direct access to UIAccessibility APIs
- Real-time detection of system accessibility settings
- Proper support for iOS 26+ accessibility features

### 4. **Type Safety**
- All properties are properly typed as `Bool`
- Sendable conformance maintained
- No force-unwrapping or unsafe code

## Alignment with iOS Dark Mode Support Rule

These changes follow the principles from `.cursor/rules/ios-dark-mode-support.mdc`:

✅ **System-First Approach**: Using UIAccessibility to detect system settings
✅ **Accessibility Integration**: Support for High Contrast, Reduce Motion, VoiceOver, etc.
✅ **Modern iOS 26 Patterns**: Proper type erasure with `Group`, async-safe APIs
✅ **UIKit Bridge Pattern**: All UIKit code isolated in UIKitBridge package
✅ **Smooth Transitions**: Animation handling respects accessibility preferences

## Build Verification

Both packages build successfully:

```bash
✅ DesignSystem build succeeded (7.8s)
✅ UIKitBridge build succeeded (1.4s)
```

## Files Modified

1. **`Packages/Kits/DesignSystem/Sources/DesignSystem/DesignSystem.swift`**
   - Fixed `agoraHighContrast()` type mismatch
   - Fixed `agoraReducedMotion()` type mismatch
   - Updated to use `DesignSystemBridge` for accessibility checks

2. **`Packages/Kits/UIKitBridge/Sources/UIKitBridge/DesignSystemBridge.swift`**
   - Added `isDarkerSystemColorsEnabled` property
   - Added `isReduceMotionEnabled` property
   - Added `isVoiceOverRunning` property
   - Added `isSwitchControlRunning` property
   - Added `isBoldTextEnabled` property
   - Added non-UIKit fallbacks for all properties

## Usage Example

```swift
import DesignSystem
import UIKitBridge

struct MyView: View {
    var body: some View {
        Text("Hello, Agora!")
            .agoraHighContrast()     // Adds border when High Contrast enabled
            .agoraReducedMotion()    // Disables animations when Reduce Motion enabled
            .agoraAccessible()       // Applies both modifiers
    }
}
```

## Next Steps

Consider extending UIKitBridge with additional accessibility helpers:
- Dynamic Type scaling utilities
- Color contrast validation
- Touch target size helpers
- Screen reader announcements

## Summary

- ✅ Fixed two type mismatch compiler errors
- ✅ Enhanced UIKit bridging for accessibility features
- ✅ Followed SwiftUI-first architecture principles
- ✅ Maintained proper separation of concerns
- ✅ Added comprehensive accessibility support
- ✅ All builds passing successfully

