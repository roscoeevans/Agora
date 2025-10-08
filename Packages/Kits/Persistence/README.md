# Persistence Kit

The Persistence kit provides local data storage and caching functionality for the Agora iOS app.

## Overview

This module handles:
- SwiftData integration for persistent storage
- In-memory and disk caching
- Compose draft persistence
- Data model management

## Components

### SwiftDataStore
Manages SwiftData model container and contexts for persistent storage.

```swift
let store = SwiftDataStore.shared
let context = store.mainContext
```

### CacheManager
Provides both in-memory and disk caching capabilities.

```swift
let cache = CacheManager.shared

// Memory cache
cache.setMemoryCache(object, forKey: "key")
let object = cache.getMemoryCache(forKey: "key", type: MyObject.self)

// Disk cache
try await cache.setDiskCache(data, forKey: "key")
let data = try await cache.getDiskCache(forKey: "key")
```

### DraftStore
Manages compose draft persistence using UserDefaults.

```swift
let draftStore = DraftStore.shared

// Create and save draft
let draft = try await draftStore.createDraft(text: "Draft content")

// Retrieve draft
let savedDraft = try await draftStore.getDraft(id: draft.id)

// Update draft
try await draftStore.updateDraftText(id: draft.id, text: "Updated content")
```

## Dependencies

- SwiftData (iOS 26+)
- Foundation

## Usage

Import the module in your Swift files:

```swift
import Persistence
```

## Architecture

The Persistence kit is designed to be:
- Thread-safe with proper async/await patterns
- Memory efficient with configurable cache limits
- Reliable with error handling and data validation
- Testable with dependency injection support

## Testing

Run tests using:

```bash
swift test --package-path Packages/Kits/Persistence
```