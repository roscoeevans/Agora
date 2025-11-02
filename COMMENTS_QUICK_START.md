# 🚀 Threaded Comments - Quick Start Guide

**Backend Status**: ✅ Deployed to Staging (Oct 31, 2025)  
**iOS Status**: ⏳ Ready to implement  
**Estimated iOS Time**: 8-12 hours (1-2 days)

---

## ✅ What's Already Done

### Backend (100% Complete)
- ✅ `comments` table with threading support
- ✅ 4 RPC functions (fetch, create, reply, pagination)
- ✅ Depth enforcement (max depth = 2, YouTube-style)
- ✅ Reply count maintenance (automatic)
- ✅ Keyset pagination indexes
- ✅ RLS policies (secure by default)
- ✅ Realtime enabled (live comment delivery)

### Database Features
- **Max Depth**: 2 levels (enforced by trigger)
- **Pagination**: Keyset-based (stable, fast)
- **Real-time**: Instant comment/reply delivery
- **Security**: Only authors can edit/delete

---

## 🎯 iOS Implementation Plan

### Phase 1: Domain Models (30 min)
Create in `Packages/Shared/AppFoundation/Sources/AppFoundation/Domain/Comment.swift`:

```swift
public struct Comment: Identifiable, Codable, Equatable, Sendable {
    public struct ID: RawRepresentable, Codable, Equatable, Hashable, Sendable {
        public let rawValue: String
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

### Phase 2: Service Protocol (15 min)
Add to `Packages/Shared/AppFoundation/Sources/AppFoundation/ServiceProtocols.swift`:

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
    
    func createComment(postID: Post.ID, body: String) async throws -> Comment
    func createReply(parentID: Comment.ID, body: String) async throws -> Comment
}
```

### Phase 3: Comments Kit (2-3 hours)

**Create package**:
```bash
mkdir -p Packages/Kits/Comments/{Sources/Comments,Tests/CommentsTests}
```

**Package.swift**:
```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Comments",
    platforms: [.iOS(.v26)],
    products: [.library(name: "Comments", targets: ["Comments"])],
    dependencies: [
        .package(path: "../SupabaseKit"),
        .package(path: "../../Shared/AppFoundation"),
    ],
    targets: [
        .target(name: "Comments", dependencies: ["SupabaseKit", "AppFoundation"]),
        .testTarget(name: "CommentsTests", dependencies: ["Comments"]),
    ]
)
```

**CommentServiceLive.swift**:
- Call `fetch_post_comments` RPC
- Call `fetch_comment_replies` RPC
- Call `create_comment` RPC
- Call `create_reply` RPC
- Map database models to domain models

**CommentServiceFake.swift**:
- Return fixture data
- Support for previews/tests

### Phase 4: UI Components (3-4 hours)

**ThreadedCommentView.swift** (in `Packages/Features/Threading/`):
- Single comment with depth-based indentation
- Avatar size decreases with depth (40px → 32px → 28px)
- Indentation: 0px, 32px, 64px for depths 0, 1, 2
- Reply button
- "View X replies" button (if replies exist)

**CommentThreadContainer.swift**:
- Manages collapse/expand state
- Handles pagination per thread
- Smooth animations

### Phase 5: Integration (1-2 hours)

1. Wire Comments Kit into Dependencies (`Resources/AgoraApp.swift`)
2. Update PostDetail to use CommentService
3. Replace stub data in CommentSheet
4. Test with Staging backend

---

## 📝 Implementation Checklist

```
Phase 1: Domain Models (30 min)
[ ] Create Comment.swift in AppFoundation/Domain/
[ ] Create CommentCursor struct

Phase 2: Service Protocol (15 min)
[ ] Add CommentServiceProtocol to ServiceProtocols.swift

Phase 3: Comments Kit (2-3 hours)
[ ] Create Packages/Kits/Comments/ package
[ ] Implement CommentServiceLive with RPC calls
[ ] Create DatabaseComment model and mappers
[ ] Implement CommentServiceFake for tests/previews
[ ] Add unit tests for service

Phase 4: UI Components (3-4 hours)
[ ] Create ThreadedCommentView component
[ ] Create CommentThreadContainer
[ ] Update CommentSheet to use threaded layout
[ ] Implement collapse/expand animations
[ ] Wire up reply composer

Phase 5: Integration (1-2 hours)
[ ] Add Comments to Dependencies
[ ] Update PostDetailViewModel
[ ] Test with Staging backend
[ ] Verify real-time delivery
[ ] Test pagination

Phase 6: Testing (1 hour)
[ ] Test create top-level comment
[ ] Test create reply
[ ] Test depth-2 replies
[ ] Test pagination (top-level)
[ ] Test pagination (replies)
[ ] Test real-time delivery
[ ] Test collapse/expand
```

---

## 🧪 Test the Backend Now

```sql
-- Connect to Staging in Supabase SQL Editor

-- 1. Create test comment
SELECT * FROM create_comment(
  'YOUR_POST_ID'::uuid,
  'Test comment from backend!'
);

-- 2. Create reply
SELECT * FROM create_reply(
  'COMMENT_ID_FROM_STEP_1'::uuid,
  'Test reply!'
);

-- 3. Fetch comments
SELECT * FROM fetch_post_comments(
  'YOUR_POST_ID'::uuid,
  50, NULL, NULL
);

-- 4. Fetch replies
SELECT * FROM fetch_comment_replies(
  'COMMENT_ID_FROM_STEP_1'::uuid,
  25, NULL, NULL
);
```

---

## 🎨 UI Design Reference

```
Top-level comment (depth 0) [0px indent]
├─ Reply 1 (depth 1) [32px indent]
│  ├─ Sub-reply 1.1 (depth 2) [64px indent]
│  ├─ Sub-reply 1.2 (depth 2) [64px indent]
│  └─ [Load more replies...]
├─ Reply 2 (depth 1) [32px indent]
│  └─ Sub-reply 2.1 (depth 2) [64px indent]
└─ [Load more comments...]
```

**Avatar Sizes**:
- Depth 0: 40px
- Depth 1: 32px
- Depth 2: 28px

**Colors** (Liquid Glass):
- Background: Frosted glass effect
- Text: Primary text color
- Actions: Secondary text color
- Connecting lines: Subtle gray

---

## 📚 Documentation

**Full Deployment Guide**: `COMMENTS_DEPLOYMENT_COMPLETE.md`  
**MVP Checklist**: `MVP_CHECKLIST.md` (updated)  
**Migration File**: `database/migrations/20251031_001_comments_threading.sql`

---

## 🔗 Key RPC Functions

| Function | Purpose | Parameters |
|----------|---------|-----------|
| `fetch_post_comments` | Load top-level | post_id, limit, cursor |
| `fetch_comment_replies` | Load replies | parent_id, limit, cursor |
| `create_comment` | Top-level comment | post_id, body |
| `create_reply` | Reply to comment | parent_id, body |

**All functions**:
- ✅ Use keyset pagination (stable, fast)
- ✅ Enforce security via RLS
- ✅ Auto-calculate depth
- ✅ Maintain reply counts

---

## ⚡️ Quick Commands

```bash
# Create Comments Kit
mkdir -p Packages/Kits/Comments/Sources/Comments
mkdir -p Packages/Kits/Comments/Tests/CommentsTests

# Build Comments Kit
agctl build Comments

# Test Comments Kit
agctl test Comments

# Build entire project
agctl build
```

---

## 🚀 Next Steps

1. **Start with Phase 1** (30 min) - Create domain models
2. **Build Comments Kit** (2-3 hours) - Service implementation
3. **Build UI Components** (3-4 hours) - ThreadedCommentView
4. **Integrate & Test** (2-3 hours) - Wire everything together

**Total Estimated Time**: 8-12 hours (1-2 days)

---

**Backend**: ✅ 100% Ready  
**iOS Implementation**: ⏳ Your turn!  

**Questions?** Check `COMMENTS_DEPLOYMENT_COMPLETE.md` for full details.


