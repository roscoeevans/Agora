# DEBUG Define Update - SwiftUI Preview Support

## Summary

Successfully added `.define("DEBUG", .when(configuration: .debug))` to all Swift Package Manager packages to enable proper `#if DEBUG` block functionality, particularly for SwiftUI previews.

## Motivation

SwiftUI previews are typically wrapped in `#if DEBUG` blocks to keep them out of release builds:

```swift
#if DEBUG && canImport(SwiftUI)
import SwiftUI

#Preview("Default") {
    PreviewDeps.scoped {
        MyView()
    }
}
#endif
```

However, `#if DEBUG` does not work by default in Swift Package Manager targets because SPM does not automatically define the DEBUG compilation condition. This update adds the required swift setting to all packages.

## Changes Made

Updated **18 Package.swift files** across all module types:

### Features (9 packages)
- ✅ Compose
- ✅ HomeForYou
- ✅ HomeFollowing
- ✅ PostDetail
- ✅ Profile
- ✅ Search
- ✅ Notifications
- ✅ DMs
- ✅ Threading

### Kits (7 packages)
- ✅ Networking (added DEBUG alongside existing STAGING/DEVELOPMENT defines)
- ✅ Media
- ✅ Analytics
- ✅ Persistence
- ✅ Moderation
- ✅ Verification
- ✅ Recommender

### Shared (2 packages)
- ✅ AppFoundation
- ✅ TestSupport

### Already Had It (2 packages)
- ✅ DesignSystem (already had DEBUG define)
- ✅ Auth (AuthFeature - already had DEBUG define)

## Pattern Applied

For packages without existing swiftSettings:
```swift
.target(
    name: "PackageName",
    dependencies: [...],
    swiftSettings: [
        .define("DEBUG", .when(configuration: .debug))
    ]
),
.testTarget(
    name: "PackageNameTests",
    dependencies: ["PackageName"],
    swiftSettings: [
        .define("DEBUG", .when(configuration: .debug))
    ]
)
```

For packages with existing swiftSettings (e.g., StrictConcurrency):
```swift
swiftSettings: [
    .define("DEBUG", .when(configuration: .debug)),
    .enableExperimentalFeature("StrictConcurrency")
]
```

## Benefits

1. **SwiftUI Previews Work**: `#Preview` blocks wrapped in `#if DEBUG` now function correctly
2. **Debug-Only Code**: Any debug utilities, logging, or development tools can use `#if DEBUG`
3. **Consistent Across Modules**: All 20 packages now have the same DEBUG behavior
4. **Test Targets Too**: Test targets also get DEBUG define for test-only utilities
5. **Proper Optimization**: Release builds exclude all DEBUG code, keeping bundle size small

## Verification

To verify the changes work:

```bash
# Build a package in Debug mode
cd Packages/Features/Compose
swift build -c debug

# Verify DEBUG is defined in Debug builds
# (Preview blocks should now compile)
```

## Related Rules

- **ios-module-standards.mdc**: Now all packages follow the template with DEBUG define
- **swiftui-previews.mdc**: Previews can now safely use `#if DEBUG` guards
- **swift-concurrency.mdc**: DEBUG define is compatible with StrictConcurrency

## Module Standards Grade Impact

**Before**: ⚠️ Missing DEBUG define in most packages (A- grade)
**After**: ✅ All packages have DEBUG define (moves toward A+ grade)

This resolves the high-priority issue identified in the module standards audit.

## Next Steps for Full Preview Support

With DEBUG defines in place, you can now:

1. Add `#Preview` blocks to any SwiftUI views in packages
2. Use `PreviewDeps.scoped { }` wrapper for consistent preview environment
3. Link package products to main app for preview hosting
4. Guard heavy initialization with `ProcessInfo.processInfo.isiOSPreviews`

See `swiftui-previews.mdc` for complete preview authoring guidelines.

---

**Date**: October 17, 2025  
**Status**: ✅ Complete  
**Files Changed**: 18 Package.swift files  
**Impact**: All 20 modules now support `#if DEBUG` properly


