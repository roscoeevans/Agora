# Onboarding Flow Improvements

## Overview
Enhanced the profile creation onboarding flow with optional profile picture upload, improved display name validation following Instagram's "Name" field rules, and ensured proper dark mode throughout the authentication flow.

## Changes Made

### 1. Optional Profile Picture Upload
**Location:** Display Name step in onboarding

**Features:**
- ✅ Optional photo selection using native PhotosPicker
- ✅ Circular profile picture preview
- ✅ Add/Remove photo functionality
- ✅ Preview shows selected image in profile card
- ✅ Clean, minimal UI with "Add Photo" button
- ✅ No forced requirement - users can skip this step

**UI Design:**
- 80pt circular button with SF Symbol icon when empty
- Selected image displays in circle with brand-colored border
- "Remove Photo" option appears below when photo is selected
- Preview card shows actual profile picture

### 2. Display Name Field - Instagram "Name" Rules
**Updated from:** Strict 50-character limit
**Updated to:** Flexible 64-character limit with free-form input

**New Validation Rules (Instagram "Name" Style):**
- **Max Length:** 64 characters (matching Instagram)
- **Allowed Characters:** 
  - Letters (A-Z, a-z)
  - Numbers (0-9)
  - Spaces ✅
  - Emojis ✅
  - Special characters & punctuation ✅
  - Accents and non-Latin characters ✅
  - Keywords and descriptors (e.g., "Rocky • Developer")
- **No Auto-Capitalization:** Users can type freely
- **Multi-line Support:** TextField with `.axis(.vertical)` for long names

**What You Can Use:**
- `Rocky Evans` ✅
- `Site • Admin` ✅
- `John Doe 🚀` ✅
- `María García` ✅
- `Developer | Creator` ✅

**Character Counter:**
- Only shows when approaching limit (51+ characters)
- Shows red when exceeding 64 characters
- Automatically truncates at 64 characters

**Differences from Handle:**
- **Handle:** Unique, case-insensitive, 3-30 chars, only letters/numbers/periods/underscores
- **Display Name:** Not unique, flexible formatting, 1-64 chars, allows spaces/emojis/special chars

### 3. Dark Mode Fixes
**Issue:** Onboarding and auth views were showing in light mode despite app defaulting to dark

**Solution:** Added `.preferredColorScheme(.dark)` to:
- `OnboardingView` - Profile creation flow
- `WelcomeView` - Sign-in screen
- `RootView` - Root navigation controller

**Additional Improvements:**
- Added `ColorTokens.background` to ScrollView backgrounds
- Added `.toolbarBackground()` for consistent navigation bar styling
- All views now properly display in dark mode matching ForYou view

## User Experience

### Profile Creation Flow

**Step 1: Handle Selection**
- User types handle with real-time validation
- Only shows errors when requirements aren't met
- Continue button enables when handle is valid and available
- Clean, minimal feedback

**Step 2: Display Name & Photo (This Step)**
1. **Optional Profile Picture:**
   - Tap circular button to select photo from library
   - Preview shows in real-time
   - Can remove and select different photo
   - Can skip entirely and set up later

2. **Display Name Input:**
   - Free-form text field
   - Type name with any formatting desired
   - Supports spaces: "Rocky Evans"
   - Supports emojis: "Rocky 🚀"
   - Supports symbols: "Rocky • Developer"
   - Character count only shows when needed
   - No forced capitalization

3. **Live Preview:**
   - Shows profile card with selected picture (or initial)
   - Displays formatted name exactly as typed
   - Shows handle below name

**Step 3: Profile Creation**
- Continue button enables when display name is 1-64 characters
- Profile created with optional photo and formatted name

## Technical Implementation

### Files Modified

#### 1. OnboardingView.swift
**State Variables Added:**
```swift
@State private var profileImage: UIImage?
@State private var showImagePicker = false
```

**Display Name Field:**
```swift
TextField("Display Name", text: $displayName, axis: .vertical)
    .onChange(of: displayName) { _, newValue in
        if newValue.count > 64 {
            displayName = String(newValue.prefix(64))
        }
    }
```

**Validation:**
```swift
case .displayName:
    return !displayName.isEmpty && displayName.count <= 64
```

**Profile Picture Upload:**
```swift
VStack(spacing: 12) {
    Button {
        showImagePicker = true
    } label: {
        // Circular button with image or placeholder
    }
    Text("Add Photo")
    if profileImage != nil {
        Button("Remove Photo", role: .destructive) {
            profileImage = nil
        }
    }
}
.sheet(isPresented: $showImagePicker) {
    ImagePicker(image: $profileImage)
}
```

#### 2. ImagePicker Component
**New component using PHPickerViewController:**
```swift
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    // Uses PHPickerConfiguration for native photo selection
    // Filters to images only, single selection
}
```

**Dependencies:**
- `PhotosUI` framework
- Native iOS photo picker
- No external dependencies

#### 3. Dark Mode Enforcement
**Files Updated:**
- `OnboardingView.swift` - `.preferredColorScheme(.dark)`
- `WelcomeView.swift` - `.preferredColorScheme(.dark)`
- `RootView.swift` - `.preferredColorScheme(.dark)`
- Added `.toolbarBackground()` for navigation bars
- Added explicit `ColorTokens.background` to backgrounds

## Future Enhancements

### Photo Upload Backend Integration
Currently, the profile picture is captured but not uploaded. To complete:

1. **Image Processing:**
   - Resize/compress image (e.g., 400x400px)
   - Convert to JPEG with quality compression
   - Generate thumbnail

2. **Upload to Storage:**
   - Upload to Cloudflare Images or Supabase Storage
   - Get CDN URL
   - Store URL in user profile

3. **Update Profile Creation:**
   ```swift
   try await authManager.createProfile(
       handle: handle,
       displayHandle: displayHandle,
       displayName: displayName,
       avatarImage: profileImage  // Add this parameter
   )
   ```

4. **API Schema Update:**
   - Add `avatar_url` to CreateProfileRequest (optional)
   - Backend uploads image and returns URL
   - Store in `users.avatar_url` column

### Display Name Enhancements
1. **Smart Validation:**
   - Detect and warn about impersonation attempts
   - Flag potentially offensive names
   - Suggest alternatives if problematic

2. **Character Insights:**
   - Show emoji/special character in preview
   - Preview how name appears in different contexts

3. **Change Restrictions:**
   - Implement Instagram's 2-changes-per-14-days limit
   - Track display name history

## Testing

### Manual Testing Checklist

**Profile Picture:**
- [ ] Can open photo picker
- [ ] Can select photo from library
- [ ] Photo appears in circular preview
- [ ] Photo appears in profile card preview
- [ ] Can remove photo
- [ ] Can skip photo upload entirely
- [ ] Continue button works with and without photo

**Display Name:**
- [ ] Can type spaces: "Rocky Evans"
- [ ] Can type emojis: "Rocky 🚀"
- [ ] Can type special chars: "Rocky • Developer"
- [ ] Can type accents: "María"
- [ ] Character count appears at 51+ chars
- [ ] Truncates at 64 characters
- [ ] Continue button enables with valid name
- [ ] Preview shows name exactly as typed

**Dark Mode:**
- [ ] WelcomeView displays in dark mode
- [ ] HandleInputView displays in dark mode
- [ ] Display Name view displays in dark mode
- [ ] Navigation bars are dark
- [ ] All text is readable
- [ ] Matches ForYou view appearance

### Edge Cases
- Very long name (64 characters)
- Name with only emojis
- Name with mixed scripts (English + Arabic + Emoji)
- Multiple spaces in name
- Name with newline characters (shouldn't be possible but test)

## API Compatibility

### Current Profile Creation
```typescript
interface CreateProfileRequest {
  handle: string          // lowercase, 3-30 chars
  displayHandle: string   // user's capitalization, 3-30 chars
  displayName: string     // 1-64 chars, any characters
  bio?: string           // optional
}
```

### Future with Profile Picture
```typescript
interface CreateProfileRequest {
  handle: string
  displayHandle: string
  displayName: string
  bio?: string
  avatarUrl?: string      // Cloudflare Images URL or Supabase Storage URL
}
```

## Design Rationale

### Why Instagram's "Name" Rules?
1. **Familiarity:** Users already understand Instagram's distinction between username (@handle) and name
2. **Flexibility:** Allows personal expression with emojis, symbols, multilingual names
3. **Searchability:** Instagram indexes both handle and display name
4. **Professional:** Supports titles, roles, keywords in name field

### Why Optional Profile Picture?
1. **Reduced Friction:** Don't block onboarding on photo selection
2. **Better Conversions:** More users complete signup
3. **User Choice:** Some users prefer pseudonymity
4. **Can Add Later:** Profile settings allow adding photo anytime

### Why Dark Mode First?
1. **Brand Identity:** Agora defaults to dark mode for modern aesthetic
2. **Consistency:** Matches main app experience (ForYou view)
3. **Apple Guidelines:** Respect system preference while having strong default
4. **Accessibility:** Proper dark mode reduces eye strain

## Documentation Updates
- Updated onboarding flow documentation
- Added photo upload workflow (pending backend)
- Updated display name validation rules
- Added dark mode guidelines

## Related Files
- `OnboardingView.swift` - Main onboarding UI
- `WelcomeView.swift` - Sign-in screen
- `HandleValidator.swift` - Handle validation logic
- `AuthStateManager.swift` - Auth state management
- `RootView.swift` - Root navigation

