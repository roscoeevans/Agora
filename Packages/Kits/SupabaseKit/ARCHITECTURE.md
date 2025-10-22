# SupabaseKit Architecture

## Before vs After

### BEFORE (Problematic Architecture)
```
┌─────────────────┐    ┌─────────────────┐
│   AppFoundation │────│  supabase-swift │
└─────────────────┘    └─────────────────┘
         │
         ▼
┌─────────────────┐
│  Other Modules  │ (can't use Supabase directly)
└─────────────────┘

Problems:
❌ Tight coupling to Supabase SDK
❌ Type-erased: `supabase: (any Sendable)?`
❌ Hard to test (can't mock Supabase)
❌ Only AppFoundation can use Supabase
❌ Circular dependency risks
```

### AFTER (Clean Architecture)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AppFoundation │────│   SupabaseKit   │────│  supabase-swift │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│  Other Modules  │    │  Other Modules  │
│ (via AppFoundation)  │ (direct access) │
└─────────────────┘    └─────────────────┘

Benefits:
✅ Decoupled from Supabase SDK
✅ Type-safe: `supabase: (any SupabaseClientProtocol)?`
✅ Easy to test (protocol-based mocking)
✅ Any module can use SupabaseKit directly
✅ Clean dependency hierarchy
```

## Module Dependencies

### SupabaseKit Dependencies
```
SupabaseKit
├── supabase-swift (Supabase SDK)
└── AppFoundation (for Post model)
```

### AppFoundation Dependencies
```
AppFoundation
├── SupabaseKit (instead of direct supabase-swift)
└── (other dependencies...)
```

### Other Modules Can Now Use SupabaseKit
```
Engagement Kit
├── SupabaseKit (for realtime updates)
└── AppFoundation

Media Kit
├── SupabaseKit (for file uploads)
└── AppFoundation

Notifications Kit
├── SupabaseKit (for realtime notifications)
└── AppFoundation
```

## Key Improvements

### 1. **Protocol-Based Design**
```swift
// Clean, testable interface
protocol SupabaseClientProtocol {
    var auth: SupabaseAuthProtocol { get }
    var realtime: SupabaseRealtimeProtocol { get }
    var storage: SupabaseStorageProtocol { get }
    var database: SupabaseDatabaseProtocol { get }
}
```

### 2. **Easy Testing**
```swift
// Mock implementation for tests
let mockSupabase = SupabaseClientMock(
    realtime: SupabaseRealtimeMock(mockUpdates: [...]),
    storage: SupabaseStorageMock(shouldSucceed: false)
)
```

### 3. **Type Safety**
```swift
// Before: Type-erased
public let supabase: (any Sendable)?

// After: Type-safe
public let supabase: (any SupabaseClientProtocol)?
```

### 4. **Reusability**
```swift
// Any module can now use Supabase directly
import SupabaseKit

class MyService {
    init(supabase: any SupabaseClientProtocol) {
        // Use Supabase features
    }
}
```

## Usage Examples

### Realtime Updates
```swift
// In Engagement Kit
for await update in supabase.realtime.subscribeToPostEngagement(postId: "123") {
    // Handle live engagement updates
}
```

### File Uploads
```swift
// In Media Kit
let url = try await supabase.storage.uploadImage(data: imageData, path: "images/photo.jpg")
```

### Database Queries
```swift
// In any module
let posts = try await supabase.database.fetchPosts(limit: 20, cursor: nil)
```

## Testing Strategy

### Unit Tests
```swift
func testEngagementService() async {
    let mockSupabase = SupabaseClientMock(
        realtime: SupabaseRealtimeMock(mockUpdates: [...])
    )
    
    let service = EngagementServiceLive(supabase: mockSupabase)
    // Test with predictable mock data
}
```

### Integration Tests
```swift
func testWithRealSupabase() async {
    let realSupabase = SupabaseClientLive(url: testURL, key: testKey)
    let service = EngagementServiceLive(supabase: realSupabase)
    // Test with real Supabase instance
}
```

## Migration Path

1. ✅ Create SupabaseKit package
2. ✅ Move Supabase code from AppFoundation to SupabaseKit
3. ✅ Update AppFoundation to use SupabaseKit
4. ✅ Update Dependencies to use proper types
5. 🔄 Update other modules to use SupabaseKit directly (optional)
6. 🔄 Remove old Supabase integration code

## Benefits Summary

- **Better Architecture**: Clean separation of concerns
- **Easier Testing**: Protocol-based mocking
- **Type Safety**: No more type-erased dependencies
- **Reusability**: Any module can use Supabase features
- **Maintainability**: Single place for Supabase integration logic
- **Flexibility**: Easy to swap implementations (live vs mock)
