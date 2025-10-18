# SwiftUI Previews in Local SPM Packages - Setup Complete ✅

## What Was Done

Created a proof-of-concept for SwiftUI previews working inside local SPM packages, starting with `FeedPostView` in the DesignSystem kit.

### 1. Preview Infrastructure (`AppFoundation`)

Created `/Packages/Shared/AppFoundation/Sources/AppFoundation/PreviewDeps.swift`:

- **`PreviewDeps.scoped`**: Wraps views with test dependencies for previews
- **`PreviewDeps.scopedDark`**: Dark mode preview variant
- **`ProcessInfo.isXcodePreviews`**: Detects preview environment
- **`PreviewFixtures`**: Sample data (posts, users, feeds) for consistent previews

### 2. Enhanced FeedPostView Previews

Updated `/Packages/Kits/DesignSystem/Sources/DesignSystem/Components/FeedPostView.swift` with 5 preview variants:

- Short Post (Light Mode)
- Long Post (Light Mode)
- Popular Post (Dark Mode)
- Recent Post (Minimal Engagement)
- Multiple Posts in Feed

Each preview uses `PreviewDeps.scoped` and `PreviewFixtures` for deterministic, fast rendering.

### 3. App Preview Optimization

Updated `/Resources/AgoraApp.swift` to skip heavy initialization in previews:

```swift
if ProcessInfo.processInfo.isXcodePreviews {
    // Use lightweight test dependencies
    self.deps = Dependencies.test()
    // ... skip analytics, networking warmup, etc.
    return
}
```

This keeps preview refresh snappy by avoiding network calls, analytics setup, etc.

## How to Test the Previews

### In Xcode:

1. **Open the project**:
   ```bash
   cd /Users/roscoeevans/Developer/Agora
   open Agora.xcodeproj
   ```

2. **Open the FeedPostView file**:
   - Navigate to: `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/FeedPostView.swift`
   - Or use ⇧⌘O (Open Quickly) and search for "FeedPostView"

3. **Open the Canvas**:
   - Press `⌥⌘↩︎` (Option-Command-Return)
   - Or: Editor menu → Canvas
   - Select a simulator (e.g., "iPhone 16 Pro")

4. **You should see**:
   - 5 different preview tabs in the canvas
   - Each showing different post states
   - Instant feedback as you edit the view

5. **If previews don't appear**:
   - Click "Try Again" in the canvas
   - Clean Build Folder: `⇧⌘K`
   - Build once: `⌘B`
   - Re-open the canvas

## Verification Checklist

- [x] Created `PreviewDeps.swift` with scoping helpers
- [x] Added `ProcessInfo.isXcodePreviews` extension
- [x] Created `PreviewFixtures` with sample data
- [x] Updated `FeedPostView` with 5 preview variants
- [x] Updated `AgoraApp` to skip heavy init in previews
- [ ] **Test in Xcode Canvas** (requires manual verification)
- [ ] Verify app links DesignSystem package

## Next Steps (Optional)

### Verify Package Linking

Ensure the Agora app target links the packages you want to preview:

1. In Xcode: Select `Agora.xcodeproj` in navigator
2. Select the `Agora` app target
3. Go to "Frameworks, Libraries, and Embedded Content"
4. Verify these packages are listed:
   - `DesignSystem`
   - `HomeForYou`
   - `AuthFeature`
   - etc.

If missing, click `+` and add the package products.

### Apply Pattern to Other Components

Copy the preview pattern to other views:

```swift
import SwiftUI
import AppFoundation

public struct MyView: View {
    // ... view code ...
}

#Preview("Default") {
    PreviewDeps.scoped {
        MyView()
            .padding()
    }
}

#Preview("Dark Mode") {
    PreviewDeps.scopedDark {
        MyView()
            .padding()
    }
}
```

### Resources in Packages

For views that load images/colors/fonts from package resources:

1. In `Package.swift`, ensure resources are processed:
   ```swift
   .target(
       name: "DesignSystem",
       resources: [.process("Resources")]
   )
   ```

2. Assets will load via `Bundle.module` automatically

## Benefits

✅ **Fast Iteration**: Edit views and see changes instantly  
✅ **Isolated Testing**: Test components without full app boot  
✅ **Multiple States**: Preview different data/styling scenarios  
✅ **Dark Mode**: Test both light and dark themes side-by-side  
✅ **No Network**: Previews use local data, no API calls  
✅ **Deterministic**: Same fixtures = consistent previews  

## Pattern Summary

1. **In your view file** (e.g., `FeedPostView.swift`):
   ```swift
   #Preview("My Scenario") {
       PreviewDeps.scoped {
           MyView()
       }
   }
   ```

2. **Use fixtures** from `PreviewFixtures` for data:
   ```swift
   #Preview {
       PreviewDeps.scoped {
           FeedPostView(post: PreviewFixtures.shortPost)
       }
   }
   ```

3. **For dark mode**:
   ```swift
   #Preview("Dark") {
       PreviewDeps.scopedDark {
           MyView()
       }
   }
   ```

4. **Guard heavy init** in your app/services:
   ```swift
   guard !ProcessInfo.processInfo.isXcodePreviews else { return }
   ```

---

**Status**: Ready to test in Xcode! Open `FeedPostView.swift` and press `⌥⌘↩︎` to see previews.


