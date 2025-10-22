# SupabaseKit

A Swift Package wrapper for Supabase services in the Agora app.

## Purpose

SupabaseKit provides a clean, protocol-based interface to Supabase's built-in services:
- **Authentication** (Sign in with Apple, session management)
- **Realtime** (live updates for engagement, notifications)
- **Storage** (image/video uploads)
- **Database** (direct queries with Row Level Security)

## Architecture

```
AppFoundation → SupabaseKit → supabase-swift
     ↓              ↓
Other modules → SupabaseKit (direct, clean dependency)
```

## Key Benefits

1. **Decoupled**: Other modules can use Supabase without depending on AppFoundation
2. **Testable**: Protocol-based design enables easy mocking
3. **Type Safe**: No more type-erased `(any Sendable)?` in Dependencies
4. **Reusable**: Multiple modules can use Supabase features independently

## Usage

```swift
// In any module that needs Supabase
import SupabaseKit

// Get Supabase client from dependencies
let supabase = deps.supabase

// Use realtime for live updates
let subscription = supabase.realtime().subscribeToPostEngagement(postId: "123")

// Use storage for file uploads
let url = try await supabase.storage().uploadImage(data: imageData)

// Use database for direct queries
let posts = try await supabase.database().fetchPosts(limit: 20)
```

## Difference from OpenAPI

- **OpenAPI**: Calls your custom backend endpoints (`/posts`, `/users`)
- **SupabaseKit**: Uses Supabase's native services (realtime, storage, auth)
