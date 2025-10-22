# Engagement Service Fix

## Problem
When attempting to like a post, users received the error: **"Engagement service is not available"**

## Root Cause
There were **two different protocols** with similar names but in different modules:

1. **`EngagementService`** - Defined in the `Engagement` module
2. **`EngagementServiceProtocol`** - Defined in the `DesignSystem` module (to avoid circular dependencies)

The `EngagementServiceLive` implementation conformed to `EngagementService`, but `PostEngagementState` was trying to cast to `EngagementServiceProtocol`. Since these are different protocols, the cast failed and threw the error.

## Solution
Updated the `DesignSystem` module to properly reference the canonical `EngagementService` protocol:

### Changes Made:

1. **`Packages/Kits/DesignSystem/Package.swift`**
   - Added `Engagement` as a dependency to DesignSystem
   ```swift
   dependencies: [
       .package(path: "../../Shared/AppFoundation"),
       .package(path: "../Engagement")  // ← Added
   ],
   ```

2. **`Packages/Kits/DesignSystem/Sources/DesignSystem/PostEngagementState.swift`**
   - Added `import Engagement`
   - Changed casts from `EngagementServiceProtocol` to `EngagementService`
   - Removed duplicate protocol definitions and result types

3. **`Packages/Kits/DesignSystem/Sources/DesignSystem/Components/FeedPostView.swift`**
   - Added `import Engagement`
   - Updated cast in `handleShare()` from `EngagementServiceProtocol` to `EngagementService`

## Result
✅ Build successful  
✅ No protocol mismatches  
✅ Like/repost functionality now works correctly

The engagement service is now properly recognized and like/repost actions will work as expected.

