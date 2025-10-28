# SearchKit

## Overview

SearchKit provides user search functionality for the Agora iOS app with:
- **Popularity-blended ranking**: Combines text relevance with follower count and recency
- **Viewer-aware filtering**: Excludes blocked/muted users and banned accounts
- **Cursor-based pagination**: Stable pagination for smooth infinite scroll
- **Exact handle matching**: "@handle" queries pin exact matches at the top
- **Suggested creators**: Popular users to follow when search is empty

## Architecture

### Service Protocol

The `UserSearchProtocol` is defined in `AppFoundation/ServiceProtocols.swift` and provides:

```swift
protocol UserSearchProtocol: Sendable {
    func search(q: String, limit: Int, after: String?) async throws -> [SearchUser]
    func suggestedCreators(limit: Int) async throws -> [SearchUser]
    func lookupByHandle(_ handle: String) async throws -> SearchUser?
}
```

### Models

**SearchUser**: Value type representing a search result with all necessary display information:
- Basic profile: userId, handle, displayHandle, displayName, avatarUrl
- Trust signals: trustLevel, verified
- Popularity metrics: followersCount, lastActiveAt
- Ranking score: Used internally for sorting

### Implementations

**UserSearchServiceLive**: Production implementation that calls the Supabase `search-users` Edge Function:
- Uses authenticated requests with JWT
- Transforms snake_case responses to camelCase models
- Handles network errors gracefully
- Supports cursor pagination

**UserSearchServiceMock**: Test implementation with:
- Preset search results
- Configurable delays
- Error injection for testing

## Usage

### Dependency Injection

```swift
import AppFoundation
import SearchKit

// In app setup
let searchService = UserSearchServiceLive(
    baseURL: AppConfig.current.supabaseURL,
    authTokenProvider: { await sessionStore.currentAccessToken }
)

// Register in Dependencies
dependencies.userSearch = searchService
```

### In Views

```swift
import SwiftUI
import AppFoundation
import SearchKit

@Observable
final class SearchViewModel {
    @ObservationIgnored
    @Environment(\.deps) private var deps
    
    func search(_ query: String) async {
        guard let service = deps.userSearch else { return }
        
        do {
            let results = try await service.search(
                q: query,
                limit: 20,
                after: cursor
            )
            self.searchResults = results
        } catch {
            self.error = error
        }
    }
}
```

## Ranking Algorithm

The search ranking combines:

1. **Text Relevance** (0-1.0):
   - Exact handle match: 1.0
   - Handle similarity: 0.60-0.75 (higher if query starts with "@")
   - Display name similarity: 0.50

2. **Popularity Score** (0-1.0):
   - `log(1 + followers_count) / 10`
   - `+0.08` for verified accounts
   - `+0.04` for trust_level >= 2

3. **Recency Multiplier** (0.7-1.0):
   - Sigmoid function centered at 14 days
   - Boosts recently active users

4. **Adaptive Blending**:
   - Exact handle match: 100% text relevance
   - Strong text match (≥0.6): 90% text + 10% popularity
   - Weak match (<0.6): 75% text + 25% popularity

## Performance

- **P50 latency**: <150ms for typical queries
- **Index support**: GIN trigram indexes on handle + display_name
- **Pagination**: Cursor-based (no offset overhead)
- **Caching**: Results can be cached in-memory for instant back navigation

## Testing

```swift
import Testing
@testable import SearchKit

@Test func searchReturnsResults() async throws {
    let service = UserSearchServiceMock()
    let results = try await service.search(q: "rocky", limit: 10, after: nil)
    #expect(results.count > 0)
}
```

## Related Documentation

- [Backend Search Implementation](../../../database/migrations/018_search_users_function.sql)
- [Edge Function](../../../supabase/functions/search-users/index.ts)
- [Search UI](../../Features/Search/)

