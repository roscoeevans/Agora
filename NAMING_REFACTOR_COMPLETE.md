# Naming Refactor Complete

## Overview
Renamed view components throughout the codebase to follow the `ios-naming` conventions, using **`Screen`** for top-level features and **`View`** for reusable components.

## Changes Made

### 1. PostCard → FeedPostView
**File:** `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/PostCard.swift` → `FeedPostView.swift`

**Reason:** 
- Makes it clear this component is specifically for displaying posts in feed lists
- Follows naming convention: descriptive role-based name

**Updated in:**
- ✅ ProfileView (using FeedPostView from DesignSystem)

### 2. PostDetailView → PostDetailScreen
**File:** `Packages/Features/PostDetail/Sources/PostDetail/PostDetailView.swift` → `PostDetailScreen.swift`

**Reason:**
- This is a full-screen feature with navigation bar, not a component
- `Screen` suffix indicates top-level feature
- Avoids confusion with the post component (now PostDetailView)

**Updated in:**
- ✅ ContentView (all navigation destinations)
  - HomeFlow: `.post(let id)` → `PostDetailScreen`
  - SearchFlow: `.result(let id)` → `PostDetailScreen`
  - NotificationsFlow: `.detail(let id)` → `PostDetailScreen`
  - ProfileFlow: `.post(let id)` → `PostDetailScreen`

### 3. PostDetailCard → PostDetailView
**File:** `Packages/Features/PostDetail/Sources/PostDetail/PostDetailCard.swift` → `PostDetailView.swift`

**Reason:**
- Reusable component displaying post content
- `View` suffix indicates it's a component, not a screen
- Now clearly distinguished from `PostDetailScreen` (the screen that contains it)

**Updated in:**
- ✅ PostDetailScreen (uses PostDetailView component)

### 4. ReplyCard → ReplyView
**File:** `Packages/Features/PostDetail/Sources/PostDetail/ReplyCard.swift` → `ReplyView.swift`

**Reason:**
- Component displaying individual replies
- `View` suffix is more descriptive than `Card`
- Consistent with other view component naming

**Updated in:**
- ✅ PostDetailScreen (uses ReplyView component)

## Naming Convention Applied

Following `ios-naming` rule:

```swift
// ✅ Root screens use Screen suffix
struct PostDetailScreen: View { }      // Feature screen with navigation
struct SettingsScreen: View { }        // Full screen experience

// ✅ Components use View suffix
struct FeedPostView: View { }          // Reusable post component for feeds
struct PostDetailView: View { }        // Post component for detail screen
struct ReplyView: View { }             // Reply component
```

## Benefits

1. **Clear hierarchy:** Immediately obvious what's a screen vs component
2. **No naming conflicts:** PostDetailScreen vs PostDetailView are distinct
3. **Consistency:** All components follow the same pattern
4. **Discoverability:** Developers can quickly understand the structure
5. **Follows conventions:** Aligns with Apple's naming patterns and our own rules

## Files Modified

### Created/Renamed:
- ✅ `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/FeedPostView.swift` (was PostCard.swift)
- ✅ `Packages/Features/PostDetail/Sources/PostDetail/PostDetailScreen.swift` (was PostDetailView.swift)
- ✅ `Packages/Features/PostDetail/Sources/PostDetail/PostDetailView.swift` (was PostDetailCard.swift)
- ✅ `Packages/Features/PostDetail/Sources/PostDetail/ReplyView.swift` (was ReplyCard.swift)

### Updated:
- ✅ `Resources/ContentView.swift` (all navigation destinations)
- ✅ `Packages/Features/Profile/Sources/Profile/ProfileView.swift` (uses FeedPostView)

## Notes

- **HomeForYouView** and **HomeFollowingView** have their own local `PostCardView` components
  - These are NOT the same as the DesignSystem's FeedPostView
  - Consider consolidating these to use FeedPostView in the future
  - For now, left as-is to avoid breaking changes

## Verification

- ✅ All linter checks pass
- ✅ No compilation errors
- ✅ All usages updated
- ✅ Navigation routing updated
- ✅ Preview names updated

## Next Steps

Optional improvements:
1. Consider consolidating HomeForYouView's and HomeFollowingView's local PostCardView to use DesignSystem's FeedPostView
2. Update any documentation/diagrams that reference the old names
3. Update any deep link documentation if it references PostDetailView


