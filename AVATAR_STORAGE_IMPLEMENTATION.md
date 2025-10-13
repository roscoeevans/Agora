# Avatar Storage Implementation

## Overview

Complete implementation of user profile picture (avatar) storage and upload functionality. Users can now upload profile pictures during onboarding, which are stored in Supabase Storage and linked to their user profile.

## What Was Implemented

### 1. Supabase Storage Setup

**New Migration:** `database/migrations/011_avatar_storage.sql`

- Created `avatars` storage bucket
  - Public bucket (avatars are publicly viewable)
  - 5MB file size limit
  - Allowed formats: JPEG, PNG, WebP, HEIC
  
- Storage policies:
  - Public read access (anyone can view avatars)
  - Authenticated users can upload to their own folder (`{user_id}/avatar-*.jpg`)
  - Users can update/delete their own avatars
  
- Folder structure: `avatars/{user_id}/avatar-{uuid}.jpg`

**Status:** ✅ Deployed to agora-staging

### 2. StorageService

**New File:** `Packages/Shared/AppFoundation/Sources/AppFoundation/StorageService.swift`

Provides image upload functionality with the following features:

- **Image Processing:**
  - Automatic resizing to 512x512 (maintains aspect ratio)
  - JPEG compression at 85% quality
  - Handles UIImage input from PhotoPicker
  
- **Upload:**
  - Uploads to Supabase Storage bucket
  - Returns public URL for storage in database
  - Organized by user ID for easy management
  
- **Delete:**
  - Can delete avatars by URL
  - Extracts storage path from full URL
  
- **Error Handling:**
  - Custom `StorageError` enum
  - Clear error messages for troubleshooting

### 3. Auth Integration

**Modified Files:**
- `Packages/Features/Auth/Sources/Auth/AuthStateManager.swift`
- `Packages/Features/Auth/Sources/Auth/OnboardingView.swift`

**Changes:**

1. **AuthStateManager:**
   - Added `StorageService` dependency
   - Updated `createProfile()` to accept optional `avatarImage: UIImage?`
   - Uploads avatar before creating profile
   - Passes avatar URL to API in `CreateProfileRequest`
   
2. **OnboardingView:**
   - Already had image picker UI (lines 119-161)
   - Updated to pass `profileImage` to `createProfile()`
   - No UI changes needed (was already collecting the image!)

### 4. API Changes

**OpenAPI Schema:** `OpenAPI/agora.yaml`

Added `avatarUrl` field to `CreateProfileRequest`:
```yaml
avatarUrl:
  type: string
  format: uri
  description: Optional URL to user's avatar image in Supabase Storage
```

**OpenAPI Client:** Regenerated with `make api-gen`

### 5. Edge Function

**Modified:** `supabase/functions/create-profile/index.ts`

- Updated `CreateProfileRequest` interface to include `avatarUrl?: string`
- Extracts `avatarUrl` from request body
- Saves to `users.avatar_url` column in database

**Status:** ✅ Deployed to agora-staging (version 2)

## Flow

### User Onboarding with Avatar

1. **Handle Step:** User enters their handle
2. **Display Name Step:** 
   - User enters display name
   - User taps "Add Photo" button
   - iOS PhotoPicker opens
   - User selects image from library
   - Preview shows selected image
3. **Create Profile:**
   - User taps "Create Profile"
   - `OnboardingView` calls `authManager.createProfile()`
   - `AuthStateManager.createProfile()`:
     a. Validates handle
     b. **Uploads avatar to Supabase Storage** (if provided)
     c. Creates profile via API with avatar URL
   - Profile created successfully with avatar!

### Storage URL Format

```
https://iqebtllzptardlgpdnge.supabase.co/storage/v1/object/public/avatars/{user_id}/avatar-{uuid}.jpg
```

Example:
```
https://iqebtllzptardlgpdnge.supabase.co/storage/v1/object/public/avatars/12345678-1234-1234-1234-123456789abc/avatar-abcdef12-3456-7890-abcd-ef1234567890.jpg
```

## Database Schema

The `users.avatar_url` column was already present in the schema (from migration `001_initial_schema.sql`):

```sql
avatar_url TEXT
```

This column stores the full public URL to the user's avatar in Supabase Storage.

## Security

### Storage Policies (RLS)

- ✅ Public read access (avatars are public by design)
- ✅ Users can only upload to their own folder (enforced by `auth.uid()`)
- ✅ Users can only update/delete their own avatars
- ✅ 5MB file size limit prevents abuse
- ✅ MIME type restrictions (images only)

### Upload Flow

1. User must be authenticated (JWT required)
2. Storage service uses user's JWT for upload
3. Path includes user ID: `{user_id}/avatar-*.jpg`
4. Supabase RLS ensures user can only write to their own folder

## Testing

### Manual Test Flow

1. Delete test user from database (if exists)
2. Open Agora app in iOS Simulator
3. Tap "Sign in with Apple"
4. Complete Apple authentication
5. Enter handle (e.g., `test.user`)
6. Tap "Continue"
7. **Tap "Add Photo" button**
8. Select an image from photo library
9. Verify preview shows the image
10. Enter display name (e.g., `Test User`)
11. Tap "Create Profile"
12. Wait for upload and profile creation
13. Profile should be created with avatar visible!

### Verify in Supabase

1. Go to Supabase Dashboard → Storage → avatars bucket
2. You should see: `{user_id}/avatar-{uuid}.jpg`
3. Click file to view the uploaded image
4. Go to Table Editor → users table
5. Find your test user
6. Verify `avatar_url` column contains the public URL

## Files Changed

### New Files
- `database/migrations/011_avatar_storage.sql` - Storage bucket and policies
- `Packages/Shared/AppFoundation/Sources/AppFoundation/StorageService.swift` - Image upload service

### Modified Files
- `Packages/Features/Auth/Sources/Auth/AuthStateManager.swift` - Avatar upload integration
- `Packages/Features/Auth/Sources/Auth/OnboardingView.swift` - Pass image to create profile
- `OpenAPI/agora.yaml` - Added avatarUrl to CreateProfileRequest
- `supabase/functions/create-profile/index.ts` - Save avatar URL to database
- `Packages/Kits/Networking/Sources/Networking/Generated/Types.swift` - Regenerated from OpenAPI

### Deployed
- ✅ Migration applied to agora-staging
- ✅ Edge Function deployed to agora-staging (version 2)
- ✅ Storage bucket created with policies

## Notes

- Avatar upload is **optional** (users can skip it)
- Default avatar is shown as user's initial letter in a colored circle
- Images are automatically resized to 512x512 to save storage
- JPEG compression (85%) balances quality and file size
- Public bucket means no auth needed to display avatars in UI
- Each upload gets unique UUID to prevent caching issues

## Next Steps (Optional Enhancements)

- [ ] Add avatar editing/updating in profile settings
- [ ] Implement avatar deletion (remove old avatar when uploading new one)
- [ ] Add image cropping UI before upload
- [ ] Support for video avatars (short loops)
- [ ] CDN integration for faster avatar loading
- [ ] Avatar moderation (NSFW detection)
- [ ] Default avatar generation service (DiceBear, Boring Avatars, etc.)

## Architecture Notes

### Dependency Injection

Follows the project's DI pattern (per `ios-di-injection.mdc`):

```swift
// StorageService injectable via init
class AuthStateManager {
    private let storageService: StorageService
    
    init(storageService: StorageService? = nil) {
        self.storageService = storageService ?? StorageService()
    }
}

// Tests can inject mock storage service
let mockStorage = MockStorageService()
let authManager = AuthStateManager(storageService: mockStorage)
```

### SwiftUI Integration

- Uses `@State private var profileImage: UIImage?` in OnboardingView
- Native PhotosPicker integration via `PHPickerViewController`
- Async/await for storage upload (Swift Concurrency)
- MainActor isolation for UI thread safety

## Summary

✅ **Complete avatar storage system implemented and deployed!**

Users can now upload profile pictures during onboarding. The system handles image processing, storage upload, and database integration seamlessly. All security policies are in place, and the feature is ready for testing.

