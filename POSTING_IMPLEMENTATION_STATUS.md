# Posting System Implementation Status

**Date:** October 15, 2025  
**Project:** Agora Posting System  
**Environment:** agora-staging

## ✅ Completed Components

### Phase 1: Database Schema & Storage
- ✅ **Migration 012 applied to agora-staging**
  - Added `edited_at` and `self_destruct_at` columns to posts table
  - Created `post_edits` history table with proper foreign keys
  - Created `post-media` storage bucket (50MB limit, supports images and videos)
  - Added RLS policies for post creation, editing, deletion
  - Added helper function `is_within_edit_window()`

### Phase 2: Backend API (Edge Functions)
All deployed and active on agora-staging:

1. **`create-post`** - Creates new posts
   - Validates text (1-280 characters)
   - Supports media_bundle_id, link_url, quote_post_id, reply_to_post_id
   - Supports self_destruct_at scheduling
   - Returns created post with ID

2. **`edit-post`** - Edits existing posts
   - Validates 15-minute edit window
   - Saves previous text to post_edits history
   - Updates post.edited_at timestamp
   - Returns updated post

3. **`delete-post`** - Deletes posts
   - Validates ownership
   - Cascades to post_edits, likes, etc.
   - Returns success confirmation

4. **`get-edit-history`** - Retrieves edit history
   - Returns array of PostEdit objects
   - Ordered by edited_at (newest first)

5. **`fetch-link-preview`** - Fetches link metadata
   - Parses Open Graph tags (og:title, og:description, og:image)
   - Falls back to standard meta tags
   - 5-second timeout for safety

### Phase 3: OpenAPI Specification
- ✅ **Updated `OpenAPI/agora.yaml`** with:
  - New endpoints: `/posts/create`, `/posts/{id}/edit`, `/posts/{id}`, `/posts/{id}/edit-history`, `/link-preview`
  - Updated Post schema (280 char limit, added edited_at, self_destruct_at, canEdit)
  - New schemas: CreatePostRequest, EditPostRequest, PostEdit, LinkPreview, MediaBundle
  - Proper error responses (400, 401, 403, 404, 500)

**⚠️ Action Required:** Run `make api-gen` to generate Swift client code

### Phase 4: Media Kit Enhancements
All files created in `Packages/Kits/Media/Sources/Media/`:

1. **`StorageService.swift`** - Extended with:
   - `uploadPostImage()` - Single image upload (max 2048x2048, 85% quality)
   - `uploadPostImages()` - Batch upload (1-4 images)
   - `uploadPostVideo()` - Video upload (max 50MB, supports mp4/mov)
   - `deletePostMedia()` - Cleanup on post deletion
   - New error cases: tooManyImages, videoReadFailed, videoTooLarge

2. **`VideoProcessor.swift`** (NEW) - Video processing utilities:
   - `validateDuration()` - Enforces 5-minute maximum
   - `extractDimensions()` - Gets video width/height
   - `generateThumbnail()` - Creates thumbnail at 1-second mark
   - `compressIfNeeded()` - Compresses videos over 50MB
   - `validateAndExtractMetadata()` - Full validation pipeline

3. **`MediaBundleService.swift`** (NEW) - Media bundle management:
   - `createImageBundle()` - Upload images and create DB record
   - `createVideoBundle()` - Upload video, generate thumbnail, create DB record
   - `getMediaURLs()` - Retrieve media URLs from bundle ID
   - Stores URLs as JSON in existing Cloudflare ID fields (temporary workaround)

### Phase 5: Compose Feature (Partial)
- ✅ **Character limit updated** from 70 to 280 in:
  - `ComposeViewModel.swift`
  - `ComposeView.swift`

- ✅ **`SelfDestructPicker.swift`** (NEW) - Self-destruct UI component:
  - Options: Never, 24 hours, 3 days, 1 week
  - Apple-style menu picker
  - SF Symbols icons
  - Proper accessibility labels

## ⏳ Remaining Work

### Phase 5: Compose Feature (Continue)

#### 1. Update ComposeViewModel
**File:** `Packages/Features/Compose/Sources/Compose/ComposeViewModel.swift`

Add properties:
```swift
public var selfDestructDuration: SelfDestructDuration = .none
public var linkPreview: LinkPreview?
public var quotePostId: String?
public var isLoadingLinkPreview = false
```

Update `post()` method:
1. Upload media via MediaBundleService if selectedMedia exists
2. Fetch link preview if URL detected in text
3. Call create-post Edge Function with all data
4. Handle success/error
5. Clear form and dismiss

#### 2. Real Media Picker Integration
**File:** `Packages/Features/Compose/Sources/Compose/ComposeView.swift`

- Replace placeholder `MediaPickerButtonView` with real `PhotosPicker`
- Import from Media Kit
- Limit to 4 images OR 1 video (mutually exclusive)
- Display actual thumbnails with file info
- Validate video duration on selection

#### 3. Link Preview Card
**File:** `Packages/Features/Compose/Sources/Compose/LinkPreviewCard.swift` (NEW)

- Detect URLs in text with regex
- Auto-fetch preview when URL pasted
- Show card with image, title, description, domain
- Allow removal with X button
- Liquid Glass effect background

#### 4. Quote Post View
**File:** `Packages/Features/Compose/Sources/Compose/QuotePostView.swift` (NEW)

- Compact, read-only post display
- Show author, text, media thumbnail
- Gray border, rounded corners
- Non-interactive

#### 5. Update ComposeView
Add to UI:
- SelfDestructPicker above media section
- LinkPreviewCard when URL detected
- QuotePostView when quoting

### Phase 6: Post Display Components

All new files in `Packages/Kits/DesignSystem/Sources/DesignSystem/Components/`:

#### 1. PostCard.swift (NEW)
Main reusable post display component:
- Author info (avatar, handle, name)
- Post text with proper line breaking
- Media grid or video player
- Link preview card
- Quoted post display
- Engagement metrics (likes, reposts, replies)
- "Edited" indicator if edited
- Timestamp
- Action buttons (like, repost, reply, share, more menu)

#### 2. ImageGridView.swift (NEW)
Smart grid layout for 1-4 images:
- 1 image: full width
- 2 images: side-by-side
- 3 images: 1 large + 2 stacked
- 4 images: 2x2 grid
- Tap to expand full screen

#### 3. PostVideoPlayer.swift (NEW)
Native video playback:
- AVPlayer integration
- Thumbnail + play button overlay
- Mute button
- Duration badge
- Auto-pause when scrolled offscreen

#### 4. LinkPreviewCard.swift (NEW)
Display-only link preview:
- Tappable (opens Safari)
- Image, title, domain
- Liquid Glass effect
- Smooth press animation

#### 5. QuotedPostCard.swift (NEW)
Embedded quoted post:
- Smaller font (footnote)
- Gray border
- Author + text
- Tap navigates to post detail

### Phase 7: Edit History

#### 1. EditHistorySheet.swift (NEW)
**File:** `Packages/Features/PostDetail/Sources/PostDetail/EditHistorySheet.swift`

- Full-screen sheet
- List of previous versions
- Show timestamp for each edit
- Current version at top
- Dismiss with swipe or button

#### 2. Update PostCard
Add "Edited" indicator:
- Light gray text
- SF Symbol: pencil.circle
- Tappable, opens EditHistorySheet
- Only show if post.editedAt != null

### Phase 8: Navigation & Integration

#### 1. Update Routes.swift
**File:** `Packages/Shared/AppFoundation/Sources/AppFoundation/Routes.swift`

Add:
```swift
case compose(quotePostId: String? = nil)
case editHistory(postId: String)
```

#### 2. Wire up ContentView
**File:** `Resources/ContentView.swift`

- Present ComposeView as sheet from compose tab
- Pass quotePostId when quoting

#### 3. Deep Links
**File:** `Packages/Shared/AppFoundation/Sources/AppFoundation/DeepLinkRouter.swift`

Add patterns:
- `agora://post/{id}` → PostDetailView
- `agora://compose?quote={id}` → ComposeView

### Phase 9: Self-Destruct Cron Job

#### 1. Create Cron Job
**File:** `database/migrations/013_self_destruct_cron.sql` (NEW)

```sql
-- Schedule cron job to run every 5 minutes
SELECT cron.schedule(
  'delete-expired-posts',
  '*/5 * * * *',
  $$
  SELECT delete_expired_posts();
  $$
);

-- Function to delete expired posts
CREATE OR REPLACE FUNCTION delete_expired_posts()
RETURNS void AS $$
DECLARE
  expired_post RECORD;
BEGIN
  FOR expired_post IN 
    SELECT id, author_id 
    FROM posts 
    WHERE self_destruct_at IS NOT NULL 
      AND self_destruct_at <= NOW()
  LOOP
    -- Delete post (cascades automatically)
    DELETE FROM posts WHERE id = expired_post.id;
    
    -- TODO: Send notification to author via OneSignal
    -- This requires OneSignal integration
  END LOOP;
END;
$$ LANGUAGE plpgsql;
```

#### 2. OneSignal Notification
When post self-destructs:
- Send push notification to post author
- Message: "Your post from [time] has been deleted"

### Phase 10: Testing

**Manual Testing Checklist:**
- [ ] Create text-only post
- [ ] Create post with 1-4 images
- [ ] Create post with 1 video
- [ ] Reject video > 5 minutes
- [ ] Reject text > 280 chars
- [ ] Link preview auto-fetches
- [ ] Quote post displays correctly
- [ ] Self-destruct scheduling works
- [ ] Edit within 15 minutes succeeds
- [ ] Edit after 15 minutes fails
- [ ] Edit history displays correctly
- [ ] "Edited" indicator appears
- [ ] Posts render in feed
- [ ] Images display in grids
- [ ] Videos play inline
- [ ] Cron job deletes expired posts

## Files Created (Local)

### Database
- `database/migrations/012_posting_system.sql`

### Edge Functions
- `supabase/functions/create-post/index.ts`
- `supabase/functions/edit-post/index.ts`
- `supabase/functions/delete-post/index.ts`
- `supabase/functions/get-edit-history/index.ts`
- `supabase/functions/fetch-link-preview/index.ts`

### OpenAPI
- `OpenAPI/agora.yaml` (updated)

### Media Kit
- `Packages/Kits/Media/Sources/Media/StorageService.swift` (updated)
- `Packages/Kits/Media/Sources/Media/VideoProcessor.swift` (NEW)
- `Packages/Kits/Media/Sources/Media/MediaBundleService.swift` (NEW)

### Compose Feature
- `Packages/Features/Compose/Sources/Compose/ComposeViewModel.swift` (updated)
- `Packages/Features/Compose/Sources/Compose/ComposeView.swift` (updated)
- `Packages/Features/Compose/Sources/Compose/SelfDestructPicker.swift` (NEW)

## Next Steps

1. **Run code generation:** `make api-gen` to generate Swift clients from OpenAPI spec
2. **Complete Compose UI:** Integrate media picker, link preview, quote post display
3. **Implement post submission:** Wire up MediaBundleService and Edge Function calls
4. **Build PostCard component:** Core display component for feeds
5. **Add edit history UI:** Sheet and "Edited" indicator
6. **Set up cron job:** Self-destruct automation
7. **Test end-to-end:** Full posting flow from compose to display

## Dependencies

### Required Packages
- SwiftUI (iOS 26)
- AVFoundation (video processing)
- Supabase Swift SDK
- PhotosUI (media picker)

### Supabase Configuration
- Project: agora-staging (iqebtllzptardlgpdnge)
- Region: us-east-2
- Storage buckets: avatars, post-media
- Edge Functions: 5 deployed and active

## Notes

- Media bundle storage uses temporary JSON workaround for Cloudflare ID fields
- Consider adding proper `urls` column to media_bundles table in future migration
- Self-destruct notifications require OneSignal integration (not yet implemented)
- Link preview caching not yet implemented (consider adding later)

