# Next Steps: Completing the Posting System

## What's Been Built

### ✅ Backend Infrastructure (100% Complete)
- **Database**: Migration 012 applied, all tables and RLS policies active
- **Edge Functions**: 5 functions deployed and running on agora-staging
- **Storage**: post-media bucket created (50MB, images/videos)
- **API Spec**: OpenAPI updated with all endpoints

### ✅ Media Handling (100% Complete)
- **StorageService**: Upload/delete for images and videos
- **VideoProcessor**: Validation, compression, thumbnails
- **MediaBundleService**: Bundle creation and management

### ✅ Compose Foundation (60% Complete)
- **ComposeViewModel**: Extended with new properties (selfDestructDuration, linkPreview, etc.)
- **SelfDestructPicker**: Full UI component ready
- **Character limit**: Updated to 280

## What Needs to Be Done

### Priority 1: Complete Compose UI (4-6 hours)

#### 1. Update ComposeView.swift
Add self-destruct picker to the UI:

```swift
// In ComposeView body, after media section:
SelfDestructPicker(selectedDuration: Binding(
    get: { vm.selfDestructDuration },
    set: { vm.selfDestructDuration = $0 }
))
```

#### 2. Real Media Picker Integration
Replace `MediaPickerButtonView` with actual PhotosPicker:

```swift
import PhotosUI

@State private var selectedPhotosPickerItems: [PhotosPickerItem] = []

PhotosPicker(
    selection: $selectedPhotosPickerItems,
    maxSelectionCount: 4,
    matching: .any(of: [.images, .videos])
) {
    // Your button UI
}
.onChange(of: selectedPhotosPickerItems) { items in
    Task {
        for item in items {
            // Convert PhotosPickerItem to MediaItem
            // Add to vm.selectedMedia
        }
    }
}
```

#### 3. Create LinkPreviewCard.swift
Simple card component:

```swift
struct LinkPreviewCard: View {
    let preview: LinkPreview
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            // Preview image (AsyncImage)
            VStack(alignment: .leading) {
                Text(preview.title ?? "")
                Text(preview.siteName ?? "")
            }
            Spacer()
            Button("✕") { onRemove() }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}
```

Add to ComposeView when `vm.linkPreview != nil`.

#### 4. Link Detection
Add to ComposeView:

```swift
.onChange(of: vm.text) { newValue in
    Task {
        try? await Task.sleep(nanoseconds: 500_000_000) // Debounce
        await vm.detectAndFetchLinkPreview()
    }
}
```

### Priority 2: Code Generation (5 minutes)

Run this command to generate Swift client from OpenAPI spec:

```bash
make api-gen
```

This will create type-safe API client methods in `Packages/Kits/Networking/Sources/Networking/Generated/`.

### Priority 3: Wire Up API Calls (2-3 hours)

Update `ComposeViewModel.post()` to actually call the API:

```swift
public func post() async {
    guard canPost else { return }
    
    isPosting = true
    defer { isPosting = false }
    
    do {
        // 1. Get user session
        guard let userId = /* get from session */ else {
            throw PostError.notAuthenticated
        }
        
        // 2. Upload media if any
        var mediaBundleId: String?
        if !selectedMedia.isEmpty {
            let mediaService = MediaBundleService()
            // Upload images or video
            mediaBundleId = try await mediaService.createImageBundle(...)
        }
        
        // 3. Calculate self-destruct timestamp
        let selfDestructAt = selfDestructDuration.date()?.ISO8601Format()
        
        // 4. Call create-post Edge Function
        let request = CreatePostRequest(
            text: text,
            mediaBundleId: mediaBundleId,
            linkUrl: linkPreview?.url,
            quotePostId: quotePostId,
            selfDestructAt: selfDestructAt
        )
        
        let post = try await networking.createPost(request)
        
        // 5. Success - clear and dismiss
        clearDraft()
        
    } catch {
        self.error = error
    }
}
```

### Priority 4: PostCard Component (6-8 hours)

Create `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/PostCard.swift`:

**Key Features:**
- Author info (avatar, handle, name)
- Post text
- Media display (images/video)
- Link preview
- Quoted post
- Engagement counts
- "Edited" indicator
- Action buttons (like, repost, reply, share)

**Start Simple:**
```swift
public struct PostCard: View {
    let post: Post
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author row
            HStack {
                // Avatar
                Text("@\(post.authorDisplayHandle)")
            }
            
            // Post text
            Text(post.text)
            
            // Media/Links/Quote here
            
            // Engagement bar
            HStack {
                Button { } label: { Image(systemName: "heart") }
                Text("\(post.likeCount)")
                // More actions...
            }
        }
        .padding()
    }
}
```

### Priority 5: Display Posts in Feed (2-3 hours)

Update `HomeForYouView.swift` to use PostCard:

```swift
ScrollView {
    LazyVStack {
        ForEach(posts) { post in
            PostCard(post: post)
                .onTapGesture {
                    // Navigate to PostDetailView
                }
        }
    }
}
```

### Priority 6: Edit History UI (3-4 hours)

1. Create `EditHistorySheet.swift`:

```swift
struct EditHistorySheet: View {
    let postId: String
    @State private var edits: [PostEdit] = []
    
    var body: some View {
        NavigationStack {
            List {
                // Current version
                Section("Current") {
                    // Show current post text
                }
                
                // Previous versions
                Section("Edit History") {
                    ForEach(edits) { edit in
                        VStack(alignment: .leading) {
                            Text(edit.previousText)
                            Text(edit.editedAt, style: .relative)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Edit History")
        }
        .task {
            await loadEditHistory()
        }
    }
}
```

2. Add "Edited" indicator to PostCard
3. Call get-edit-history Edge Function

### Priority 7: Self-Destruct Cron (1-2 hours)

Create and apply migration:

```sql
-- database/migrations/013_self_destruct_cron.sql

SELECT cron.schedule(
  'delete-expired-posts',
  '*/5 * * * *',
  $$
  DELETE FROM posts 
  WHERE self_destruct_at IS NOT NULL 
    AND self_destruct_at <= NOW();
  $$
);
```

Apply with:
```bash
# Via Supabase dashboard or CLI
```

### Priority 8: Navigation (2-3 hours)

1. Update `Routes.swift`:

```swift
public enum HomeRoute: Hashable, Codable {
    case post(id: UUID)
    case profile(id: UUID)
    case compose(quotePostId: String? = nil)
    case editHistory(postId: String)
}
```

2. Wire up in `ContentView.swift`:

```swift
.sheet(item: $composeRoute) { route in
    ComposeView(quotePostId: route.quotePostId)
}
```

3. Add deep links in `DeepLinkRouter.swift`

## Testing Plan

### Manual Testing

1. **Basic Posting**
   - [ ] Text-only post
   - [ ] Post with 1 image
   - [ ] Post with 4 images
   - [ ] Post with 1 video (<5 min)
   - [ ] Reject video >5 min

2. **Features**
   - [ ] Self-destruct: 24h, 3d, 1w
   - [ ] Link preview auto-fetches
   - [ ] Character counter turns red at >280
   - [ ] Post button disabled when over limit

3. **Editing**
   - [ ] Edit post within 15 min
   - [ ] Can't edit after 15 min
   - [ ] Edit history shows correctly
   - [ ] "Edited" indicator appears

4. **Display**
   - [ ] Posts show in feed
   - [ ] Images display in grid
   - [ ] Video plays inline
   - [ ] Link previews work
   - [ ] Quoted posts display

5. **Self-Destruct**
   - [ ] Posts delete at scheduled time
   - [ ] Notification sent (once OneSignal integrated)

## Time Estimates

- **Priority 1-3** (Compose UI + API): ~8 hours
- **Priority 4-5** (PostCard + Feed): ~10 hours
- **Priority 6-7** (Edit + Cron): ~5 hours
- **Priority 8** (Navigation): ~3 hours
- **Testing**: ~4 hours

**Total: ~30 hours** for full implementation

## Quick Wins (Do These First!)

1. Run `make api-gen` (5 min)
2. Add SelfDestructPicker to ComposeView (10 min)
3. Wire up basic post() API call without media (1 hour)
4. Create basic PostCard without media (2 hours)
5. Display posts in feed (1 hour)

**You'll have basic posting working in ~4 hours!**

## Files Ready to Use

All these files are complete and ready:
- `database/migrations/012_posting_system.sql`
- All 5 Edge Functions (deployed)
- `VideoProcessor.swift`
- `MediaBundleService.swift`
- `StorageService.swift` (extended)
- `SelfDestructPicker.swift`
- `ComposeViewModel.swift` (needs API call implementation)

## Questions?

Review `POSTING_IMPLEMENTATION_STATUS.md` for full details on what's been built.

The foundation is solid - now it's time to connect the UI to the backend and build the display components!

