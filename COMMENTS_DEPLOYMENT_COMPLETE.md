# Threaded Comments - Backend Deployment Complete ✅

**Status**: Backend Deployed to Staging  
**Deployment Date**: October 31, 2025  
**Project**: agora-staging (`iqebtllzptardlgpdnge`)

---

## 🎉 Deployment Summary

The Threaded Comments backend is now **100% deployed on Staging**. All database components have been successfully deployed and configured, ready for iOS implementation.

### ✅ What Was Deployed

#### 1. Database Schema
**Table**: `public.comments`

```sql
comments (
  id UUID PRIMARY KEY,
  post_id UUID NOT NULL → posts(id),
  author_id UUID NOT NULL → users(id),
  parent_comment_id UUID → comments(id),  -- NULL for top-level
  depth SMALLINT NOT NULL DEFAULT 0,      -- 0, 1, or 2
  body TEXT NOT NULL,
  reply_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
)
```

**Constraints**:
- ✅ Depth check: `depth BETWEEN 0 AND 2`
- ✅ Body check: `length(body) > 0`
- ✅ Foreign keys with CASCADE delete
- ✅ Self-referential parent_comment_id

#### 2. Database Triggers
Automatic depth enforcement and reply count maintenance:

| Trigger | Purpose | Status |
|---------|---------|--------|
| `trg_enforce_comment_depth` | Auto-calculates depth, enforces max depth = 2 | ✅ Active |
| `trg_bump_reply_count` | Increments parent's reply_count on new reply | ✅ Active |
| `trg_touch_updated_at` | Updates updated_at on comment edit | ✅ Active |

**Depth Enforcement**:
- **Depth 0**: Top-level comments (no parent)
- **Depth 1**: Replies to top-level
- **Depth 2**: Replies to depth-1 (max nesting)
- **Depth 3+**: Blocked by trigger exception

#### 3. Performance Indexes
Optimized for keyset pagination:

```sql
✅ idx_comments_post_depth_created   (post_id, depth, created_at DESC, id DESC)
✅ idx_comments_parent_created       (parent_comment_id, created_at DESC, id DESC)
✅ idx_comments_author_created       (author_id, created_at DESC)
```

**Benefits**:
- Fast top-level comment pagination
- Fast reply fetching per thread
- Fast user comment history

#### 4. RPC Functions (4 total)

| Function | Purpose | Pagination | Status |
|----------|---------|-----------|--------|
| `fetch_post_comments` | Load top-level comments (depth=0) | Keyset | ✅ Deployed |
| `fetch_comment_replies` | Load replies for any parent | Keyset | ✅ Deployed |
| `create_comment` | Create top-level comment | N/A | ✅ Deployed |
| `create_reply` | Create reply to any comment | N/A | ✅ Deployed |

**Keyset Pagination Parameters**:
- `in_p_limit` - Page size (max 100)
- `in_p_last_created_at` - Last seen created_at
- `in_p_last_id` - Last seen comment ID

**Why Keyset?**
- ✅ Stable under concurrent writes
- ✅ Fast (uses indexes efficiently)
- ✅ No drift (unlike OFFSET)

#### 5. Row Level Security (RLS)

| Policy | Operation | Rule | Status |
|--------|-----------|------|--------|
| `comments_select_all` | SELECT | Everyone can read | ✅ Active |
| `comments_insert_own` | INSERT | author_id must match auth.uid() | ✅ Active |
| `comments_update_own` | UPDATE | Only author can edit | ✅ Active |
| `comments_delete_own` | DELETE | Only author can delete | ✅ Active |

**Security Notes**:
- ✅ RLS enabled on `comments` table
- ✅ All functions use `SECURITY DEFINER`
- ✅ Author ID enforced via `auth.uid()`

#### 6. Realtime Configuration

**Status**: ✅ Enabled for `public.comments`

```sql
✅ comments table in supabase_realtime publication
```

**Realtime Events**:
- `INSERT` - New comments/replies appear instantly
- `UPDATE` - Comment edits update in real-time
- `DELETE` - Deleted comments removed instantly

---

## 📊 Architecture Overview

### YouTube-Style Threading (Max Depth = 2)

```
Top-level comment (depth 0)
├─ Reply 1 (depth 1)
│  ├─ Sub-reply 1.1 (depth 2)
│  └─ Sub-reply 1.2 (depth 2)
├─ Reply 2 (depth 1)
│  └─ Sub-reply 2.1 (depth 2)
└─ [Load more comments...]
```

**Design Goals**:
- **Depth 0**: Top-level comments on post
- **Depth 1**: Direct replies to top-level
- **Depth 2**: Replies to replies (max)
- **Depth 3+**: Prevented by database trigger

### Data Flow

```
1. iOS calls create_comment(post_id, body)
   ↓
2. Trigger sets depth = 0
   ↓
3. Comment inserted
   ↓
4. Realtime broadcasts INSERT event
   ↓
5. iOS receives new comment instantly

--- Reply Flow ---

1. iOS calls create_reply(parent_comment_id, body)
   ↓
2. Trigger calculates depth = parent.depth + 1
   ↓
3. Trigger verifies depth ≤ 2
   ↓
4. Comment inserted
   ↓
5. Trigger bumps parent.reply_count
   ↓
6. Realtime broadcasts INSERT event
   ↓
7. iOS receives new reply instantly
```

---

## 🧪 Backend Verification

### Test RPC Functions Directly

```sql
-- 1. Create top-level comment
SELECT * FROM create_comment(
  'POST_ID_HERE'::uuid,
  'This is a test comment'
);

-- 2. Create reply
SELECT * FROM create_reply(
  'PARENT_COMMENT_ID_HERE'::uuid,
  'This is a test reply'
);

-- 3. Fetch top-level comments
SELECT * FROM fetch_post_comments(
  'POST_ID_HERE'::uuid,
  50,  -- limit
  NULL,  -- last_created_at (NULL = first page)
  NULL   -- last_id
);

-- 4. Fetch replies
SELECT * FROM fetch_comment_replies(
  'PARENT_COMMENT_ID_HERE'::uuid,
  25,  -- limit
  NULL,  -- last_created_at
  NULL   -- last_id
);
```

### Verify Depth Enforcement

```sql
-- Should succeed (depth 0 → 1)
SELECT * FROM create_reply('DEPTH_0_COMMENT_ID'::uuid, 'Reply to top-level');

-- Should succeed (depth 1 → 2)
SELECT * FROM create_reply('DEPTH_1_COMMENT_ID'::uuid, 'Reply to reply');

-- Should FAIL (depth 2 → 3 blocked)
SELECT * FROM create_reply('DEPTH_2_COMMENT_ID'::uuid, 'Reply to sub-reply');
-- Expected error: "Maximum nesting depth reached"
```

### Verify Reply Count

```sql
-- Check reply_count updates automatically
SELECT id, body, reply_count, depth 
FROM comments 
WHERE post_id = 'POST_ID_HERE'::uuid
ORDER BY created_at DESC;
```

### Verify Realtime

```sql
-- Check comments table is in publication
SELECT schemaname, tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'comments';
-- Expected: 1 row
```

---

## 🚀 iOS Implementation Guide

### Module Structure (Per project-structure.mdc)

#### Domain Model
**Location**: `Packages/Shared/AppFoundation/Sources/AppFoundation/Domain/Comment.swift`

```swift
public struct Comment: Identifiable, Codable, Equatable, Sendable {
    public struct ID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
    
    public let id: ID
    public let postID: Post.ID
    public let authorID: User.ID
    public let parentCommentID: Comment.ID?
    public let depth: Int  // 0, 1, or 2
    public let body: String
    public let replyCount: Int
    public let createdAt: Date
    public let updatedAt: Date
}

public struct CommentCursor: Codable, Equatable, Sendable {
    public let lastCreatedAt: Date
    public let lastID: Comment.ID
}
```

#### Service Protocol
**Location**: `Packages/Shared/AppFoundation/Sources/AppFoundation/ServiceProtocols.swift`

```swift
public protocol CommentServiceProtocol: Sendable {
    func fetchTopLevelComments(
        postID: Post.ID,
        pageSize: Int,
        cursor: CommentCursor?
    ) async throws -> (items: [Comment], next: CommentCursor?)
    
    func fetchReplies(
        parentID: Comment.ID,
        pageSize: Int,
        cursor: CommentCursor?
    ) async throws -> (items: [Comment], next: CommentCursor?)
    
    func createComment(
        postID: Post.ID,
        body: String
    ) async throws -> Comment
    
    func createReply(
        parentID: Comment.ID,
        body: String
    ) async throws -> Comment
}
```

#### Implementation Kit
**Location**: `Packages/Kits/Comments/`

**Create new Kit with:**
```bash
mkdir -p Packages/Kits/Comments/Sources/Comments
mkdir -p Packages/Kits/Comments/Tests/CommentsTests
```

**Package.swift**:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Comments",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Comments", targets: ["Comments"]),
    ],
    dependencies: [
        .package(path: "../SupabaseKit"),
        .package(path: "../../Shared/AppFoundation"),
    ],
    targets: [
        .target(
            name: "Comments",
            dependencies: ["SupabaseKit", "AppFoundation"]
        ),
        .testTarget(
            name: "CommentsTests",
            dependencies: ["Comments"]
        ),
    ]
)
```

**CommentServiceLive.swift**:
```swift
import AppFoundation
import SupabaseKit
import Foundation

public struct CommentServiceLive: CommentServiceProtocol {
    private let supabase: SupabaseClient
    
    public init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    public func fetchTopLevelComments(
        postID: Post.ID,
        pageSize: Int,
        cursor: CommentCursor?
    ) async throws -> (items: [Comment], next: CommentCursor?) {
        let params: [String: Any?] = [
            "in_p_post_id": postID.rawValue,
            "in_p_limit": pageSize,
            "in_p_last_created_at": cursor?.lastCreatedAt.ISO8601Format(),
            "in_p_last_id": cursor?.lastID.rawValue
        ]
        
        let rows: [DatabaseComment] = try await supabase.rpc(
            "fetch_post_comments",
            params: params
        )
        
        let comments = rows.map { $0.toDomain() }
        let nextCursor = comments.last.map { CommentCursor(lastCreatedAt: $0.createdAt, lastID: $0.id) }
        
        return (comments, nextCursor)
    }
    
    // ... implement other methods similarly
}
```

#### UI Components
**Location**: `Packages/Features/Threading/`

**ThreadedCommentView.swift**:
```swift
import SwiftUI
import AppFoundation
import DesignSystem

struct ThreadedCommentView: View {
    let comment: Comment
    let depth: Int  // 0, 1, or 2
    let onReply: () -> Void
    let onToggleReplies: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Indentation based on depth
            if depth > 0 {
                Spacer().frame(width: CGFloat(depth) * 32)
            }
            
            // Avatar (size decreases with depth)
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: avatarSize, height: avatarSize)
            
            VStack(alignment: .leading, spacing: 4) {
                // Author + timestamp
                HStack {
                    Text("@username")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(comment.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Body
                Text(comment.body)
                    .font(.body)
                
                // Actions
                HStack(spacing: 16) {
                    Button("Reply", action: onReply)
                        .font(.caption)
                    
                    if comment.replyCount > 0 {
                        Button("View \(comment.replyCount) replies", action: onToggleReplies)
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var avatarSize: CGFloat {
        switch depth {
        case 0: return 40
        case 1: return 32
        case 2: return 28
        default: return 28
        }
    }
}
```

#### View Model
**Location**: `Packages/Features/PostDetail/Sources/PostDetail/CommentThreadViewModel.swift`

```swift
import AppFoundation
import Observation

@MainActor
@Observable
final class CommentThreadViewModel {
    private(set) var topLevelComments: [Comment] = []
    private(set) var expandedThreads: Set<Comment.ID> = []
    private(set) var isLoading = false
    
    private let service: CommentServiceProtocol
    private var cursors: [Comment.ID?: CommentCursor] = [:]
    
    init(service: CommentServiceProtocol) {
        self.service = service
    }
    
    func loadInitial(postID: Post.ID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let (items, next) = try await service.fetchTopLevelComments(
            postID: postID,
            pageSize: 50,
            cursor: nil
        )
        
        topLevelComments = items
        cursors[nil] = next
    }
    
    func loadMoreTopLevel(postID: Post.ID) async throws {
        guard let cursor = cursors[nil] else { return }
        
        let (items, next) = try await service.fetchTopLevelComments(
            postID: postID,
            pageSize: 50,
            cursor: cursor
        )
        
        topLevelComments.append(contentsOf: items)
        cursors[nil] = next
    }
    
    func toggleReplies(for comment: Comment) async throws {
        if expandedThreads.contains(comment.id) {
            expandedThreads.remove(comment.id)
            // Remove replies from UI
            return
        }
        
        expandedThreads.insert(comment.id)
        
        let (items, next) = try await service.fetchReplies(
            parentID: comment.id,
            pageSize: 20,
            cursor: nil
        )
        
        // Insert replies into UI
        cursors[comment.id] = next
    }
}
```

---

## 📝 Next Steps for iOS Implementation

### Phase 1: Domain & Protocols (30 min)
1. Create `Comment.swift` in `AppFoundation/Domain/`
2. Add `CommentServiceProtocol` to `AppFoundation/ServiceProtocols.swift`
3. Add `CommentCursor` to support pagination

### Phase 2: Comments Kit (2-3 hours)
1. Create `Packages/Kits/Comments/` package
2. Implement `CommentServiceLive` with RPC calls
3. Create database models and mappers (like DMs)
4. Implement `CommentServiceFake` for previews/tests

### Phase 3: UI Components (3-4 hours)
1. Create `ThreadedCommentView` (single comment)
2. Create `CommentThreadContainer` (collapse/expand logic)
3. Update `CommentSheet` to use threaded layout
4. Wire up reply composer

### Phase 4: Integration (1-2 hours)
1. Wire Comments Kit into Dependencies
2. Update PostDetail to fetch comments
3. Test with fake data
4. Test with Staging backend

### Phase 5: Testing (1 hour)
1. Unit tests for tree-building
2. Fake service for previews
3. Manual testing on Staging

---

## 🐛 Known Limitations & Future Enhancements

### Current Limitations (MVP)
- **No comment editing** - Can add post-MVP
- **No comment likes** - Can add post-MVP
- **No comment reactions** - Can add post-MVP
- **No comment sorting** - Always chronological (newest first)
- **No comment search** - Can add post-MVP
- **Simple RLS** - Read policy is `true` (no visibility filtering)

### Future Enhancements
- [ ] Comment editing with edit history
- [ ] Comment likes/reactions
- [ ] Comment pinning (author can pin top comment)
- [ ] Sort options (Top, New, Controversial)
- [ ] Comment search within post
- [ ] Notification mentions in comments
- [ ] Rich text/markdown in comments
- [ ] Comment draft persistence

---

## 🔒 Security Notes

### Current Security Posture
- ✅ RLS enabled and enforced
- ✅ Author ID validated via `auth.uid()`
- ✅ Only authenticated users can comment
- ✅ Only authors can edit/delete their comments
- ✅ Everyone can read comments (adjust if needed)

### Future Security Improvements
- [ ] Respect post visibility in comment read policy
- [ ] Rate limiting on comment creation
- [ ] Spam detection for comment body
- [ ] Content moderation for comments
- [ ] Admin override policies

---

## 📊 Performance Characteristics

### Expected Performance (Staging)
- **Create comment**: < 100ms
- **Fetch top-level (50 items)**: < 200ms
- **Fetch replies (20 items)**: < 150ms
- **Realtime delivery**: < 2 seconds

### Optimization Notes
- ✅ Keyset pagination prevents slow OFFSET queries
- ✅ Composite indexes optimized for query patterns
- ✅ Denormalized `reply_count` avoids COUNT queries
- ✅ Triggers maintain data integrity automatically

---

## 📦 Production Deployment Checklist

**After Staging Tests Pass**:

1. **Deploy to Production** (`gnvavfpjjbkabcmsztui`)
   ```bash
   # Use Supabase MCP or SQL Editor
   # Apply: database/migrations/20251031_001_comments_threading.sql
   ```

2. **Enable Realtime on Production**
   ```sql
   ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
   ```

3. **Verify Production**
   - [ ] Table created with correct schema
   - [ ] Triggers active
   - [ ] RPC functions deployed
   - [ ] RLS policies active
   - [ ] Realtime configured
   - [ ] Indexes created

4. **Test Production**
   - [ ] Create test comment
   - [ ] Create test reply
   - [ ] Verify depth enforcement
   - [ ] Verify reply_count updates
   - [ ] Test pagination

---

## ✅ Deployment Verification

**Backend Deployment**: ✅ Complete (Staging)  
**Realtime Configuration**: ✅ Complete  
**RLS Policies**: ✅ Active  
**RPC Functions**: ✅ Deployed (4 functions)  
**Triggers**: ✅ Active (3 triggers)  
**Indexes**: ✅ Created (3 indexes)  

**Ready for iOS Implementation**: ✅ Yes  
**Ready for Production**: ⏳ After iOS implementation + testing

---

**Deployed By**: AI Assistant via Supabase MCP  
**Reviewed By**: Pending engineering review  
**Tested By**: Pending iOS integration testing

---

## 📞 Support

**Supabase Dashboard**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge  
**Migration File**: `database/migrations/20251031_001_comments_threading.sql`  
**Documentation**: This file + `MVP_CHECKLIST.md`

**Questions?** Check Supabase logs or test RPC functions directly in SQL Editor.


