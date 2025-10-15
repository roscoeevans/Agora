# Navigation Architecture Audit

**Audit Date:** October 15, 2025  
**Auditor:** AI Assistant  
**Reference:** `.cursor/rules/ios-navigation.mdc`

## Executive Summary

Your app uses NavigationStack (✅) but has **significant structural issues** that prevent proper tab-scoped navigation, state restoration, and deep linking. The most critical issue is **nested NavigationStacks** that break the recommended pattern.

**Overall Compliance:** 🔴 **3/10** - Requires major refactoring

---

## Critical Issues (Must Fix)

### 1. ❌ Nested NavigationStack Anti-Pattern

**Location:** `HomeView.swift` + `HomeForYouView.swift`

**Problem:**
```swift
// HomeView.swift (line 18)
NavigationStack {
    switch selectedFeed {
    case .forYou:
        HomeForYouView()  // ← This creates ANOTHER NavigationStack!
    }
}

// HomeForYouView.swift (line 24)
NavigationStack(path: ...) {  // ← NESTED STACK!
    ScrollView { ... }
}
```

**Why It's Wrong:**
- Creates competing navigation hierarchies
- Breaks back button behavior
- Makes deep linking impossible
- State restoration won't work

**Guideline Violated:** "Don't Stack Stacks Unintentionally" (line 594-615 in rule)

**Fix Required:** HomeView should NOT wrap in NavigationStack. The child views (HomeForYouView, FollowingView) should provide the stack.

---

### 2. ❌ Multiple NavigationStacks Per Tab

**Locations:**
- `HomeView.swift:18` - Creates NavigationStack
- `HomeForYouView.swift:24` - Creates ANOTHER NavigationStack
- `FollowingView.swift:26` - Creates ANOTHER NavigationStack

**Problem:** When switching between For You ↔ Following, you're creating entirely new navigation stacks, losing all navigation state.

**Fix Required:** One NavigationStack per tab flow, managed at the ContentView level.

---

### 3. ❌ No Tab-Scoped Route Enums

**Location:** None exist (except unused `ForYouDestination` in `ForYouCoordinator.swift:55-58`)

**Current State:**
```swift
// ContentView.swift - uses raw integers
@State private var selectedTab = 0  // ← Type-unsafe
```

**Required:**
```swift
enum Tab: Hashable { 
    case home, search, messages, notifications, profile 
}

enum HomeRoute: Hashable, Codable {
    case post(id: UUID)
    case profile(id: UUID)
}

enum SearchRoute: Hashable, Codable {
    case result(id: UUID)
}
// ... etc for each tab
```

**Guideline Violated:** "Route as Data (Type-Safe)" (line 33-62 in rule)

---

### 4. ❌ No Navigation Path Management at Tab Level

**Location:** `ContentView.swift`

**Current State:**
```swift
TabView(selection: $selectedTab) {
    HomeView()  // ← No path binding
        .tag(0)
    SearchView()  // ← No path binding
        .tag(1)
    // ...
}
```

**Required:**
```swift
@State private var homePath: [HomeRoute] = []
@State private var searchPath: [SearchRoute] = []

TabView(selection: $selectedTab) {
    HomeFlow(path: $homePath)
        .tag(Tab.home)
    SearchFlow(path: $searchPath)
        .tag(Tab.search)
}
```

**Guideline Violated:** "One Stack Per Independent Flow" (line 152-174 in rule)

---

### 5. ❌ No State Restoration / Deep Link Support

**Location:** Nowhere implemented

**Missing:**
- No `@SceneStorage` for tab selection
- No `@SceneStorage` for navigation paths
- No Codable routes
- No `.onOpenURL` handler

**Required:** See lines 118-148 and 276-341 in rule

---

### 6. ❌ No Tab Reselection Handler

**Location:** `ContentView.swift`

**Missing:**
```swift
.onTabItemReselected(selection: selection) { tab in
    // Pop to root when tapping active tab
}
```

**Expected Behavior:** Tapping the active tab should pop to root (standard iOS pattern).

**Guideline Violated:** Line 320-328 in rule

---

## Major Issues (Should Fix Soon)

### 7. ⚠️ Unused Navigation Infrastructure

**Location:** `ForYouCoordinator.swift`

**Problem:**
- `ForYouDestination` enum defined but never used
- Coordinator has `navigateToPost()` but just logs, doesn't navigate (line 33: "TODO: Implement navigation")
- NavigationPath exists but no `navigationDestination` modifiers to consume it

**Impact:** Navigation infrastructure exists but doesn't actually navigate.

---

### 8. ⚠️ Mixed NavigationStack Creation

**Pattern Inconsistency:**
- ✅ SearchView, NotificationsView, DMThreadsView, ProfileView create their own stacks (good for isolated views)
- ❌ HomeView + HomeForYouView both create stacks (creates nesting)

**Decision Needed:** Choose ONE pattern:
- **Option A (Recommended):** ContentView owns all NavigationStacks, passes path bindings down
- **Option B:** Each tab root creates its own stack (but then HomeView shouldn't create one)

---

### 9. ⚠️ No `navigationDestination` Registrations

**Locations:** All tab views

**Problem:** None of the views register `.navigationDestination(for:)` modifiers, so even if you append to the path, nothing would happen.

**Required:**
```swift
NavigationStack(path: $homePath) {
    FeedView()
        .navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case .post(let id): PostDetailView(id: id)
            case .profile(let id): ProfileView(id: id)
            }
        }
}
```

**Guideline:** Lines 93-113 in rule

---

## Minor Issues (Nice to Have)

### 10. 🟡 No Route Factories

**Missing:** Centralized route construction for common flows (useful for previews and tests)

**Guideline:** Lines 426-455 in rule

---

### 11. 🟡 Integer Tab Tags

**Location:** `ContentView.swift`

**Current:** `.tag(0)`, `.tag(1)`, etc.  
**Better:** `.tag(Tab.home)`, `.tag(Tab.search)` with enum

**Impact:** Low (works but not type-safe)

---

## What You Got Right ✅

1. ✅ **Using NavigationStack** (not deprecated NavigationView)
2. ✅ **Using searchable** modifier correctly on NavigationStack descendants
3. ✅ **Separate view models** for each tab
4. ✅ **DI through environment** (`.environment(\.deps, deps)`)
5. ✅ **Modern Observable macro** for coordinator
6. ✅ **Started with coordinator pattern** (just needs completion)

---

## Compliance Checklist

| Guideline | Status | Location |
|-----------|--------|----------|
| Use NavigationStack | ✅ Pass | Multiple files |
| Route as Data (typed enums) | ❌ Fail | Missing everywhere |
| Programmatic navigation via path | ❌ Fail | Coordinator exists but unused |
| Keep destinations near stack | ❌ Fail | No destinations registered |
| Deep links & restoration | ❌ Fail | Not implemented |
| One stack per independent flow | ❌ Fail | Nested stacks in Home |
| Prefer value-based APIs | 🟡 Partial | Enum exists but unused |
| Don't nest stacks | ❌ Fail | HomeView + HomeForYouView |
| Don't use global state across tabs | ✅ Pass | Each view isolated |
| Tab-scoped routes | ❌ Fail | No route enums per tab |
| @SceneStorage for paths | ❌ Fail | Not implemented |
| Tab reselection handler | ❌ Fail | Not implemented |

**Score: 3/12 (25%)**

---

## Recommended Refactoring Plan

### Phase 1: Fix Critical Structure Issues
1. **Remove nested NavigationStacks**
   - Option A: Move all stacks to ContentView
   - Option B: Ensure HomeView doesn't wrap in NavigationStack if children do
2. **Create Tab enum** with proper Hashable conformance
3. **Create route enums** for each tab (HomeRoute, SearchRoute, etc.)

### Phase 2: Implement Navigation Paths
1. **Add @State path arrays** in ContentView for each tab
2. **Pass path bindings** to each tab flow
3. **Register navigationDestination** modifiers in each flow
4. **Wire up coordinator actions** to append to paths

### Phase 3: Add Persistence & Deep Links
1. **Add @SceneStorage** for tab selection
2. **Add @SceneStorage** for each tab's path (Codable routes)
3. **Implement .onOpenURL** handler
4. **Add state restoration** encode/decode logic

### Phase 4: Polish
1. **Add tab reselection** to pop to root
2. **Add route factories** for testing
3. **Add snapshot tests** with predefined paths
4. **Update previews** to use RouteFactory

---

## Example: How ContentView Should Look

```swift
import SwiftUI

enum Tab: String, Hashable {
    case home, search, messages, notifications, profile
}

enum HomeRoute: Hashable, Codable { 
    case post(id: UUID)
    case profile(id: UUID) 
}
enum SearchRoute: Hashable, Codable { 
    case result(id: UUID) 
}
enum MessagesRoute: Hashable, Codable { 
    case thread(id: UUID) 
}
enum NotificationsRoute: Hashable, Codable { 
    case detail(id: UUID) 
}
enum ProfileRoute: Hashable, Codable { 
    case settings
    case followers 
}

struct ContentView: View {
    // Tab selection with persistence
    @SceneStorage("tab.selection") private var selectionRaw: String = "home"
    private var selection: Binding<Tab> {
        Binding(
            get: { Tab(rawValue: selectionRaw) ?? .home },
            set: { selectionRaw = $0.rawValue }
        )
    }
    
    // Navigation paths with persistence
    @SceneStorage("tab.home.path") private var homePathData: Data?
    @SceneStorage("tab.search.path") private var searchPathData: Data?
    @SceneStorage("tab.messages.path") private var messagesPathData: Data?
    @SceneStorage("tab.notifications.path") private var notificationsPathData: Data?
    @SceneStorage("tab.profile.path") private var profilePathData: Data?
    
    @State private var homePath: [HomeRoute] = []
    @State private var searchPath: [SearchRoute] = []
    @State private var messagesPath: [MessagesRoute] = []
    @State private var notificationsPath: [NotificationsRoute] = []
    @State private var profilePath: [ProfileRoute] = []
    
    var body: some View {
        TabView(selection: selection) {
            HomeFlow(path: $homePath)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)
            
            SearchFlow(path: $searchPath)
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(Tab.search)
            
            MessagesFlow(path: $messagesPath)
                .tabItem { Label("Messages", systemImage: "message.fill") }
                .tag(Tab.messages)
            
            NotificationsFlow(path: $notificationsPath)
                .tabItem { Label("Notifications", systemImage: "bell.fill") }
                .tag(Tab.notifications)
            
            ProfileFlow(path: $profilePath)
                .tabItem { Label("Profile", systemImage: "person.circle.fill") }
                .tag(Tab.profile)
        }
        .onTabItemReselected(selection: selection) { tab in
            switch tab {
            case .home: homePath = []
            case .search: searchPath = []
            case .messages: messagesPath = []
            case .notifications: notificationsPath = []
            case .profile: profilePath = []
            }
        }
        .task {
            homePath = decode(homePathData) ?? []
            searchPath = decode(searchPathData) ?? []
            messagesPath = decode(messagesPathData) ?? []
            notificationsPath = decode(notificationsPathData) ?? []
            profilePath = decode(profilePathData) ?? []
        }
        .onChange(of: homePath) { homePathData = encode($0) }
        .onChange(of: searchPath) { searchPathData = encode($0) }
        .onChange(of: messagesPath) { messagesPathData = encode($0) }
        .onChange(of: notificationsPath) { notificationsPathData = encode($0) }
        .onChange(of: profilePath) { profilePathData = encode($0) }
    }
}

private struct HomeFlow: View {
    @Binding var path: [HomeRoute]
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView()  // ← HomeView should NOT create another NavigationStack
                .navigationDestination(for: HomeRoute.self) { route in
                    switch route {
                    case .post(let id): PostDetailView(id: id)
                    case .profile(let id): ProfileView(userId: id)
                    }
                }
        }
    }
}

// ... similar for other flows

private func encode<T: Codable>(_ value: T) -> Data? { 
    try? JSONEncoder().encode(value) 
}

private func decode<T: Codable>(_ data: Data?) -> T? {
    guard let data else { return nil }
    return try? JSONDecoder().decode(T.self, from: data)
}
```

---

## High-Impact Changes (Priority Order)

1. **Fix nested NavigationStack** (HomeView + HomeForYouView) → **Immediate**
2. **Create route enums** for all tabs → **Immediate**
3. **Move path management** to ContentView → **High Priority**
4. **Register navigationDestination** modifiers → **High Priority**
5. **Add @SceneStorage** for persistence → **Medium Priority**
6. **Implement tab reselection** → **Medium Priority**
7. **Add deep link handler** → **Low Priority** (when needed)

---

## Conclusion

Your app has the **right foundation** (NavigationStack, coordinators) but the **execution is incomplete**. The nested NavigationStack issue is the most critical problem and will break navigation completely once you start implementing actual navigation actions.

**Effort Required:** ~2-3 days for one developer to properly refactor
**Risk Level:** Medium (requires careful migration, easy to introduce bugs)
**Payoff:** Proper deep links, state restoration, predictable navigation, easy testing

**Recommendation:** Refactor now before building more features on broken foundation.

