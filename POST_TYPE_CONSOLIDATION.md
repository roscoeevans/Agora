# Post Type Consolidation

## Problem
We had **5 different `Post` types** scattered across the codebase, violating both naming conventions and project structure rules:

1. **AppFoundation.Post** - Most complete (feed metadata, visibility, all IDs)
2. **DesignSystem.Post** - Had presentation fields but missing domain fields
3. **PostDetail.Post** - Minimal duplicate with just basic fields
4. **HomeFollowing.Post** - Identical to PostDetail (complete duplicate)
5. **TestSupport.Post** - Test fixture with different structure

This caused:
- Type ambiguity errors requiring explicit module qualification
- Code duplication and maintenance burden
- Unclear source of truth for domain models
- Violation of DRY principle

## Solution

Following **ios-naming.mdc** and **project-structure.mdc** rules:

> Domain models (like Post) should live in AppFoundation (Shared layer)
> If types serve different purposes, name them distinctly. If they're the same, reuse.

### Changes Made

#### 1. Enhanced AppFoundation.Post (Canonical Model)
**File:** `Packages/Shared/AppFoundation/Sources/AppFoundation/Dependencies.swift`

Added missing presentation fields from DesignSystem:
```swift
// Presentation fields (for UI display)
public let authorDisplayName: String?
public let authorAvatarUrl: String?
public let editedAt: Date?
public let selfDestructAt: Date?
```

This single `Post` type now has **everything**:
- Core domain fields (id, authorId, text, etc.)
- Relationships (replyToPostId, quotePostId, mediaBundleId)
- Engagement metrics (likeCount, repostCount, replyCount)
- Presentation fields (displayName, avatarUrl, editedAt, selfDestructAt)
- Feed metadata (score, reasons, explore)
- Visibility settings

#### 2. Updated DesignSystem to Use Canonical Post
**File:** `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/PostCard.swift`

- Removed duplicate `Post` struct (60+ lines)
- Added `import AppFoundation`
- Updated `PostCard` component to use `AppFoundation.Post`
- Updated previews to use full initializer

#### 3. Removed PostDetail Duplicate
**File:** `Packages/Features/PostDetail/Sources/PostDetail/PostDetailViewModel.swift`

- Removed duplicate `Post` struct
- Updated placeholder data to use canonical `Post` initializer
- Added clarifying comment that `Post` comes from Networking (which re-exports AppFoundation)

#### 4. Removed HomeFollowing Duplicate
**File:** `Packages/Features/HomeFollowing/Sources/HomeFollowing/FollowingViewModel.swift`

- Removed duplicate `Post` struct
- Updated all placeholder posts to use canonical `Post` initializer
- Added clarifying comment about import source

#### 5. Converted TestSupport to Extensions
**File:** `Packages/Shared/TestSupport/Sources/TestSupport/TestFixtures.swift`

- Removed duplicate `Post` struct
- Added `import AppFoundation`
- Created `Post.sample()` static factory method for testing
- Now extends canonical type instead of duplicating it

## Benefits

### 1. Single Source of Truth ✅
- One canonical `Post` in `AppFoundation`
- All modules reference the same type
- No more ambiguity or module qualification needed

### 2. No Code Duplication ✅
- Eliminated ~150 lines of duplicate code
- Single place to add/modify Post properties
- Changes propagate automatically to all consumers

### 3. Type Safety ✅
- Compiler enforces consistent usage
- No more type ambiguity errors
- Clear import paths (via Networking)

### 4. Follows Architecture Rules ✅
- **project-structure.mdc**: Domain models in AppFoundation (Shared)
- **ios-naming.mdc**: Reuse types or differentiate names clearly
- **ios-module-standards.mdc**: Proper dependency hierarchy

### 5. Better Testing ✅
- TestSupport extends canonical type with `.sample()` helper
- Tests use real domain model, not simplified version
- More realistic test scenarios

## Module Dependency Flow

```
Features (HomeForYou, PostDetail, HomeFollowing)
    ↓ import
Networking (re-exports AppFoundation via @_exported import)
    ↓ provides
Post (canonical domain model)
    ↓ also used by
DesignSystem (UI components)
    ↓ extended by
TestSupport (test helpers)
```

## Migration Notes

### For Future Post Changes
When adding properties to `Post`:
1. Add to `AppFoundation.Post` only
2. Update initializer
3. All consumers automatically get the new field
4. Update `TestSupport.Post.sample()` if needed for testing

### Import Pattern
Modules should import Post via:
- **Features**: `import Networking` (re-exports AppFoundation)
- **Kits**: `import AppFoundation` (direct)
- **Tests**: `import TestSupport` (extends AppFoundation.Post)

### Breaking Changes
This consolidation required updating:
- Placeholder data in PostDetail and HomeFollowing
- Preview data in DesignSystem.PostCard
- Test fixtures in TestSupport

All changes are backward compatible with the API layer since OpenAPI types map to this canonical Post.

## Verification

- ✅ No linter errors in any modified files
- ✅ All type references resolved correctly
- ✅ Test helpers work as extensions
- ✅ UI components use canonical type
- ✅ Follows naming and structure conventions

## Related Documentation
- **ios-naming.mdc**: Type naming and reuse guidelines
- **project-structure.mdc**: Module organization and dependency rules
- **ios-module-standards.mdc**: Package standards and best practices

