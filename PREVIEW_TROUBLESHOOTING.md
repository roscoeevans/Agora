# SwiftUI Preview Troubleshooting Guide

## Current Issue

**Error**: `NoBuiltTargetDescriptionFoundForTranslationUnit: Could not find target description for "FeedPostView.swift"`

**What it means**: Xcode's preview system can't find the file in the compiled target's build graph.

## Quick Fixes (Try in Order)

### Fix 1: Reset Package Caches (Easiest)

In Xcode with project open:
1. **File** → **Packages** → **Reset Package Caches**
2. Wait for completion
3. **File** → **Packages** → **Update to Latest Package Versions**
4. **Product** → **Clean Build Folder** (Shift-⌘-K)
5. **Product** → **Build** (⌘-B)
6. Try preview again

### Fix 2: Hard Reset (More Thorough)

1. **Quit Xcode completely**
2. Run in Terminal:
   ```bash
   cd /Users/roscoeevans/Developer/Agora
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   rm -rf .build
   swift package reset
   swift package resolve
   ```
3. Reopen Xcode
4. Build project (⌘-B)
5. Try preview

### Fix 3: Clear Xcode Caches (Nuclear Option)

1. **Quit Xcode completely**
2. Run in Terminal:
   ```bash
   # Clear DerivedData
   rm -rf ~/Library/Developer/Xcode/DerivedData/*
   
   # Clear module cache
   rm -rf ~/Library/Caches/org.swift.swiftpm
   
   # Clear Xcode caches
   rm -rf ~/Library/Caches/com.apple.dt.Xcode
   
   # Reset project SPM packages
   cd /Users/roscoeevans/Developer/Agora
   rm -rf .build
   rm -rf .swiftpm
   rm Package.resolved
   
   # Resolve packages fresh
   swift package resolve
   ```
3. Reopen Xcode
4. Build project
5. Try preview

## Testing Strategy

### Test Simple Components First

Start with components that don't need `PreviewDeps`:

1. **AgoraButton** - `Packages/Kits/DesignSystem/Sources/DesignSystem/Buttons/AgoraButton.swift`
   - Simple component, no environment dependencies
   - Should work if preview system is functional

2. **EngagementButton** - `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/EngagementButton.swift`
   - Another simple component

3. **ComposeView** - `Packages/Features/Compose/Sources/Compose/ComposeView.swift`
   - Uses `PreviewDeps`, tests environment injection

If simple components work but `PreviewDeps` ones don't, the issue is with environment setup.

## Common Causes

### 1. Stale Build Cache
**Symptom**: File exists in correct location but preview can't find it
**Fix**: Clean and rebuild

### 2. Package Graph Not Updated
**Symptom**: After adding new files or changing Package.swift
**Fix**: Reset package caches in Xcode

### 3. DerivedData Corruption
**Symptom**: Random preview failures, inconsistent behavior
**Fix**: Delete DerivedData and rebuild

### 4. Preview Simulator Issues
**Symptom**: Previews hang or crash
**Fix**: 
```bash
xcrun simctl --set previews delete all
```

### 5. Xcode Process Issues
**Symptom**: Xcode feels sluggish, previews timeout
**Fix**: Restart Xcode completely

## Diagnostic Commands

Check if package is properly resolved:
```bash
cd /Users/roscoeevans/Developer/Agora
swift package show-dependencies
```

Check if file exists in correct location:
```bash
ls -la Packages/Kits/DesignSystem/Sources/DesignSystem/Components/FeedPostView.swift
```

Check package structure:
```bash
swift package dump-package
```

## Known Working Preview Files

These files have properly configured previews after our fixes:

✅ **Features:**
- `Packages/Features/Compose/Sources/Compose/ComposeView.swift`
- `Packages/Features/HomeForYou/Sources/HomeForYou/HomeForYouView.swift`
- `Packages/Features/Profile/Sources/Profile/ProfileView.swift`
- `Packages/Features/PostDetail/Sources/PostDetail/PostDetailScreen.swift`

✅ **DesignSystem:**
- `Packages/Kits/DesignSystem/Sources/DesignSystem/Buttons/AgoraButton.swift`
- `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/FeedPostView.swift`

## When to File a Bug

If after all troubleshooting:
- ✅ Package builds successfully (`⌘-B` succeeds)
- ✅ Simple previews (AgoraButton) work
- ❌ But FeedPostView preview still fails with "NoBuiltTargetDescriptionFoundForTranslationUnit"

This might be an Xcode bug. Try:
1. Update Xcode to latest version
2. File feedback at https://feedbackassistant.apple.com

## Alternative: Use Traditional PreviewProvider

If `#Preview` macro continues to fail, you can fall back to traditional PreviewProvider:

```swift
#if DEBUG
import SwiftUI

struct FeedPostView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewDeps.scoped {
            FeedPostView(post: PreviewFixtures.shortPost)
        }
        .previewDisplayName("Short Post")
    }
}
#endif
```

This older API sometimes works when the macro fails.

## Success Indicators

Preview is working when you see:
- ✅ Canvas shows "Ready" status
- ✅ Preview renders within 5-10 seconds
- ✅ No error messages in preview diagnostics
- ✅ Changes update live as you type

## Related Files

- `DEBUG_DEFINE_UPDATE.md` - DEBUG compilation conditions fix
- `PREVIEW_FIX_SUMMARY.md` - PreviewDeps environment injection fix
- `swiftui-previews.mdc` - Complete preview authoring guide
- `ios-module-standards.mdc` - Package structure standards

---

**Last Updated**: October 17, 2025
**Status**: Troubleshooting FeedPostView preview error

