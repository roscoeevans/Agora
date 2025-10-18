# SwiftUI Preview DEBUG Flag Fix ✅

## The Problem

After setting up the preview infrastructure, you encountered compilation errors:

```
Cannot find 'PreviewDeps' in scope
Cannot find 'PreviewFixtures' in scope
```

These errors appeared in `FeedPostView.swift` even though the types were defined in `AppFoundation`.

## Root Cause

The preview infrastructure (`PreviewDeps`, `PreviewFixtures`, `Dependencies.test()`) is wrapped in `#if DEBUG` blocks in `AppFoundation/PreviewDeps.swift` and `AppFoundation/Dependencies.swift`.

**However**, the `#Preview` blocks in `FeedPostView.swift` were **not** wrapped in `#if DEBUG`, causing a mismatch:

- **Package build context**: May not always have `DEBUG` defined
- **Preview types**: Only available when `DEBUG` is defined
- **Result**: Compiler can't find the types

## The Solution

Wrap all `#Preview` blocks that use `PreviewDeps` or `PreviewFixtures` in `#if DEBUG ... #endif`:

### Before (Broken)
```swift
// MARK: - Previews

#Preview("Short Post - Light") {
    PreviewDeps.scoped {
        FeedPostView(post: PreviewFixtures.shortPost)
    }
}
```

### After (Fixed)
```swift
// MARK: - Previews

#if DEBUG
#Preview("Short Post - Light") {
    PreviewDeps.scoped {
        FeedPostView(post: PreviewFixtures.shortPost)
    }
}
#endif
```

## Why This Works

1. **Consistent compilation conditions**: Both the preview infrastructure (in AppFoundation) and preview usage (in DesignSystem) are now guarded by `#if DEBUG`

2. **Package independence**: Even when packages are compiled separately, the `#if DEBUG` ensures preview code is only included when appropriate

3. **Xcode previews always use DEBUG**: When Xcode renders previews, it uses debug configurations, so the code is available

4. **Release builds stay clean**: Preview code is completely stripped from release builds

## Files Changed

1. **`AppFoundation/PreviewDeps.swift`**:
   - Wrapped `PreviewDeps` enum in `#if DEBUG`
   - Wrapped `PreviewFixtures` enum in `#if DEBUG`
   - Left `ProcessInfo.isXcodePreviews` unwrapped (useful in production)

2. **`DesignSystem/Components/FeedPostView.swift`**:
   - Wrapped all `#Preview` blocks in `#if DEBUG ... #endif`

3. **`.cursor/rules/swiftui-previews.mdc`**:
   - Updated all examples to show `#if DEBUG` wrapper
   - Added to checklist: "Wrap preview section in `#if DEBUG ... #endif`"

## The Pattern (Copy-Paste Ready)

```swift
import SwiftUI
import AppFoundation
import DesignSystem

public struct MyView: View {
    let post: Post
    
    public var body: some View {
        Text(post.text)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Default") {
    PreviewDeps.scoped {
        MyView(post: PreviewFixtures.shortPost)
    }
}

#Preview("Dark Mode") {
    PreviewDeps.scopedDark {
        MyView(post: PreviewFixtures.longPost)
    }
}
#endif
```

## Key Takeaways

✅ **Always wrap preview code using `PreviewDeps`/`PreviewFixtures` in `#if DEBUG`**  
✅ **This matches the availability of the preview infrastructure**  
✅ **Previews still work in Xcode (it uses DEBUG builds)**  
✅ **Release builds don't include any preview code**  

## Verification

- [x] No compilation errors in `PreviewDeps.swift`
- [x] No compilation errors in `FeedPostView.swift`
- [x] No compilation errors in `AgoraApp.swift`
- [x] Updated documentation and cursor rules
- [ ] Test in Xcode Canvas (manual verification required)

---

**Status**: ✅ All compilation errors resolved. Ready to test in Xcode!


