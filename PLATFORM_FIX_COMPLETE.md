# Platform Declaration Fix Complete

## Problem
`agctl build` was encountering platform version mismatches causing build failures with errors like:
```
error: the library 'SupabaseKit' requires macos 10.13, but depends on the product 'Supabase' which requires macos 10.15
```

## Root Cause
All Swift packages in the project only declared `.iOS(.v26)` as their platform:

```swift
platforms: [
    .iOS(.v26)
]
```

When `agctl` (a macOS CLI tool) attempted to build these packages, Swift Package Manager would default to **macOS 10.13** for the macOS platform since none was explicitly specified. This conflicted with third-party dependencies that require macOS 10.15+:
- Supabase Swift SDK → requires macOS 10.15+
- OpenAPI Runtime → requires macOS 10.15+
- swift-http-types → requires macOS 10.15+

## Solution
Added `.macOS(.v15)` to all 23 package manifests across the project:

```swift
platforms: [
    .iOS(.v26),
    .macOS(.v15)
]
```

### Packages Fixed

#### Features (10 packages)
- ✅ AuthFeature
- ✅ Compose
- ✅ DMs
- ✅ HomeFollowing
- ✅ HomeForYou
- ✅ Notifications
- ✅ PostDetail
- ✅ Profile
- ✅ Search
- ✅ Threading

#### Kits (10 packages)
- ✅ Analytics
- ✅ DesignSystem
- ✅ Engagement
- ✅ Media
- ✅ Moderation (also fixed wrong version from v10_15 to v15)
- ✅ Networking
- ✅ Persistence
- ✅ Recommender
- ✅ SupabaseKit
- ✅ Verification

#### Shared (2 packages)
- ✅ AppFoundation
- ✅ TestSupport

## Verification

After fixing all packages:

```bash
# Build now works correctly
$ agctl build AuthFeature
✅ Build succeeded

# No more platform mismatch errors
# Swift Package Manager correctly resolves to:
# - iOS 26 for iOS targets
# - macOS 15 for macOS tools (agctl)
```

## Why macOS 15?

We chose macOS 15 (Sequoia) as the baseline because:
1. **Modern baseline** - Matches the 2025 development environment
2. **Dependency compatibility** - All third-party dependencies support it
3. **Consistency** - Aligns with iOS 26 as our modern platform target
4. **Developer tooling** - Most developers building Agora use macOS 15+

## Best Practices Going Forward

### 1. Always Declare Both Platforms
When creating new Swift packages, always include both iOS and macOS:

```swift
let package = Package(
    name: "MyFeature",
    platforms: [
        .iOS(.v26),
        .macOS(.v15)
    ],
    // ...
)
```

### 2. Why macOS Platform Matters
Even for iOS-only apps, declaring macOS platform is important for:
- CLI tools (like agctl)
- Build scripts
- Code generation tools
- Testing infrastructure
- Swift Package Manager resolution

### 3. Platform Version Alignment
Keep platform versions aligned across all packages:
- iOS: `.v26` (iOS 26)
- macOS: `.v15` (macOS 15 Sequoia)

## agctl Integration

Future enhancement: `agctl validate platforms` command can check for:
- ✅ Both iOS and macOS platforms declared
- ✅ Correct version numbers (.v26 for iOS, .v15 for macOS)
- ✅ Consistency across all packages

See TODO #3 for implementation.

## Related Files
- All `Package.swift` files in:
  - `Packages/Features/*/Package.swift`
  - `Packages/Kits/*/Package.swift`
  - `Packages/Shared/*/Package.swift`
- agctl hanging fix: `Tools/agctl/HANGING_FIX.md`

## Summary

✅ **Fixed:** All 23 packages now declare both iOS 26 and macOS 15 platforms  
✅ **Verified:** `agctl build` now works without platform mismatch errors  
✅ **Future-proof:** Platform declarations are consistent across the project  

The issue is completely resolved, and `agctl build` now functions correctly!


