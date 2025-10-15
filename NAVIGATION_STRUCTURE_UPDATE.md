# Navigation Structure Update

## Summary

Updated `project-structure.mdc` to establish it as the authoritative source for file locations, ensuring consistency with `ios-navigation.mdc`.

## Changes Made

### 1. Updated AppFoundation Contents List (Lines 76-93)

Added navigation-related files to the documented AppFoundation contents:
- ✅ `NavigationEnvironment.swift`: SwiftUI environment for navigation coordination
- ✅ `Routes.swift`: App-wide route definitions (tab-level route enums)
- ✅ `DeepLinkRouter.swift`: Deep link parsing and route construction
- ✅ `AppearancePreference.swift`: User appearance/theme preferences

### 2. Updated Resources/ Directory Structure (Lines 518-531)

- Added missing files: `RootView.swift`, `LoadingView.swift`
- **Removed `Routing/` directory reference** (navigation lives in AppFoundation)
- Added explicit note directing to Navigation Architecture section

### 3. Added New Section: Navigation Architecture (Lines 184-339)

Comprehensive section documenting:
- **Location**: Navigation infrastructure lives in `AppFoundation`, not Resources/
- **Route Organization**: Tab-level routes in Routes.swift, feature-specific routes co-located
- **Navigation Pattern**: How features implement NavigationStack with path bindings
- **Master TabView Container**: Root container location and pattern
- **Deep Link Handling**: DeepLinkRouter integration
- **Why Navigation is Not a Kit**: Rationale for AppFoundation placement
- **Cross-reference**: Points to `ios-navigation.mdc` for complete implementation details

### 4. Updated Related Documentation (Lines 857-865)

Added navigation rule to cross-references:
- ✅ **Navigation Architecture**: See `ios-navigation.mdc` for complete navigation patterns

### 5. Cleaned Up Duplicate Files

Deleted duplicate navigation files in `Resources/Routing/`:
- ❌ Deleted: `Resources/Routing/DeepLinkRouter.swift` (duplicate)
- ❌ Deleted: `Resources/Routing/Routes.swift` (duplicate)

**Canonical Location**: All navigation infrastructure now definitively lives in:
```
Packages/Shared/AppFoundation/Sources/AppFoundation/
├── Routes.swift
├── DeepLinkRouter.swift
├── NavigationEnvironment.swift
└── AppearancePreference.swift
```

## Consistency Achieved

### Before
- ❌ `ios-navigation.mdc` showed navigation patterns but didn't specify file locations
- ❌ `project-structure.mdc` didn't document navigation files at all
- ❌ Navigation files existed in two locations (Resources/Routing/ and AppFoundation)

### After
- ✅ `project-structure.mdc` is the authoritative source for "what goes where"
- ✅ Navigation infrastructure definitively lives in AppFoundation
- ✅ Clear rationale provided (Why Navigation is Not a Kit)
- ✅ Cross-references between rules ensure consistency
- ✅ Duplicate files removed

## Key Principles Established

1. **Navigation in AppFoundation** (not a Kit, not Resources/):
   - Foundation-level concern used by all features
   - Centralized deep link coordination
   - Tab coordination and selection state
   - Avoids circular dependencies

2. **Route Organization**:
   - Tab-level routes: `AppFoundation/Routes.swift`
   - Feature-specific routes: Co-located with features (when appropriate)
   - Route factories: `AppFoundation/Routes.swift` (optional)

3. **Feature Implementation**:
   - Features receive path bindings from root container
   - Each tab owns its NavigationStack + destination registrations
   - Root container (`Resources/RootView.swift`) manages tab selection + paths

4. **Deep Links**:
   - `DeepLinkRouter` parses URLs → (tab, routes)
   - Root container applies deep link navigation
   - All routes Codable for state restoration

## Files Modified

1. `.cursor/rules/project-structure.mdc` - Comprehensive updates
2. Deleted: `Resources/Routing/DeepLinkRouter.swift`
3. Deleted: `Resources/Routing/Routes.swift`

## Verification

- ✅ No linting errors in updated rule file
- ✅ Navigation files confirmed in AppFoundation
- ✅ Duplicate files removed
- ✅ Clear cross-references between rules
- ✅ Rationale documented for architectural decisions

