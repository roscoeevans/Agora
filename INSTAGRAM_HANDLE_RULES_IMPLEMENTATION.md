# Instagram/Threads-Style Handle Rules Implementation

## Overview
Updated handle validation to match Instagram and Threads requirements, following their widely-documented handle constraints. The new rules allow for more flexible and familiar handle patterns while maintaining uniqueness and preventing abuse.

## Rule Changes

### Old Rules (Twitter-style)
- Length: 3-15 characters
- Characters: lowercase letters, numbers, underscores only
- Cannot start with underscore
- Cannot be all numbers
- Case-insensitive storage and lookup

### New Rules (Instagram/Threads-style)
- **Length: 3-30 characters** (doubled max length)
- **Characters: letters (A-Z, a-z), numbers (0-9), periods (.), underscores (_)**
- **Cannot have consecutive periods** (e.g., `test..handle`)
- **Must contain at least one letter** (cannot be all numbers/punctuation)
- **Case-insensitive** (stored as lowercase, display with user's preferred capitalization)
- **Unique across platform**
- **No spaces, emojis, or special characters** (only letters, numbers, periods, underscores)

## Examples

### Valid Handles ✅
- `Rocky.Evans` → stored as `rocky.evans`
- `user_123` → stored as `user_123`
- `John.Doe.2025` → stored as `john.doe.2025`
- `___test___` → stored as `___test___`
- `Site.Admin` → stored as `site.admin`

### Invalid Handles ❌
- `ab` - Too short (< 3 characters)
- `this_is_a_very_long_handle_over_thirty` - Too long (> 30 characters)
- `test..handle` - Consecutive periods
- `123456` - No letters (all numbers)
- `___.__` - No letters
- `test handle` - Contains space
- `test@handle` - Invalid character (@)
- `test#tag` - Invalid character (#)

## UI/UX Changes

### Error-Only Display
Following Apple's design guidelines, the UI now **only shows unmet requirements** (errors), not success messages:

**Before:**
- ✅ "Handle is available" (green) - Always shown when valid
- Character counter always visible

**After:**
- Only shows errors when they exist:
  - ❌ "Handle must be at least 3 characters"
  - ❌ "Use only letters, numbers, periods, and underscores"
  - ❌ "Cannot use consecutive periods"
  - ❌ "This handle is already taken"
- Character counter only appears when approaching limit (26+ characters)
- Clean, minimal interface when requirements are met
- Continue button enables silently when handle is valid and available

### Visual Indicators
- **Red X** icon appears in input field when handle is unavailable
- **Border turns red** when format is invalid
- **Border turns green** when handle is valid and available (subtle feedback)
- **Spinner** shows during availability check

## Implementation Details

### Files Modified

#### 1. HandleValidator.swift
**Changes:**
- Updated `HandleFormatValidation` enum:
  - Removed `.startsWithUnderscore` (now allowed)
  - Added `.consecutivePeriods`
  - Updated error messages
- Updated validation logic:
  - Max length: 15 → 30
  - Allowed characters: `[a-z0-9_]` → `[a-zA-Z0-9._]`
  - Added consecutive period check
  - Improved "all numbers" check to exclude punctuation

#### 2. HandleInputView.swift
**Changes:**
- Character limit: 15 → 30
- Updated placeholder hint: "3 to 15" → "3 to 30"
- Simplified validation feedback to only show errors
- Character counter only shows when approaching/exceeding limit (26+ chars)
- Removed success messages ("Handle is available")

#### 3. OpenAPI Specification (agora.yaml)
**Changes:**
- Updated regex patterns:
  - `^[a-z0-9_]{3,15}$` → `^[a-zA-Z0-9._]{3,30}$`
- Updated descriptions to mention Instagram/Threads rules
- Updated `CreateProfileRequest` schema constraints

#### 4. Supabase Edge Functions
**Files:**
- `supabase/functions/check-handle/index.ts`
- `supabase/functions/create-profile/index.ts`

**Changes:**
- Updated validation regex to allow periods and longer handles
- Added consecutive period check
- Added "must contain letter" validation
- Case-insensitive database lookups (convert to lowercase before query)

#### 5. Database Migration
**File:** `database/migrations/010_update_handle_constraints.sql`

**Changes:**
- Dropped old CHECK constraint
- Added new constraint:
  ```sql
  CHECK (
    handle ~ '^[a-z0-9._]{3,30}$' 
    AND handle !~ '\.\.'  -- No consecutive periods
    AND handle ~ '[a-z]'  -- Must contain at least one letter
  )
  ```
- Added helpful comments for developers

### Generated Code
- Regenerated OpenAPI Swift client with new schemas
- Type-safe handle validation in Swift

## Testing

### Manual Testing
1. **Valid handles with periods:**
   ```
   Rocky.Evans ✅
   site.admin ✅
   john.doe.123 ✅
   ```

2. **Consecutive periods:**
   ```
   test..handle ❌
   site...admin ❌
   ```

3. **Length limits:**
   ```
   ab ❌ (too short)
   this_is_exactly_thirty_chars ✅
   this_handle_is_way_too_long_over_thirty ❌
   ```

4. **All numbers:**
   ```
   123456 ❌
   user123 ✅
   ```

5. **Special characters:**
   ```
   test@handle ❌
   test_handle ✅
   test.handle ✅
   ```

### API Testing
```bash
# Test valid handle with periods
curl "https://iqebtllzptardlgpdnge.supabase.co/functions/v1/check-handle?handle=Rocky.Evans" \
  -H "Authorization: Bearer {ANON_KEY}"
# Response: {"available":true,"suggestions":[]}

# Test consecutive periods
curl "https://iqebtllzptardlgpdnge.supabase.co/functions/v1/check-handle?handle=test..handle" \
  -H "Authorization: Bearer {ANON_KEY}"
# Response: {"error":"Invalid handle format","message":"Handle cannot contain consecutive periods"}
```

## Migration Path

### For Existing Users
**No action required.** All existing handles remain valid:
- Old handles (3-15 chars, no periods) are a subset of new rules
- Database constraint is backward-compatible
- No data migration needed

### For New Users
- Can immediately use new format (periods, up to 30 chars)
- UI guides them through validation errors
- Real-time availability checking

## Production Deployment

### ✅ Already Deployed to Staging
- Database migration applied
- Edge Functions updated (version 2)
- OpenAPI client regenerated

### 🔜 Required for Production
1. **Apply database migration:**
   ```sql
   -- Run migration 010_update_handle_constraints.sql
   ```

2. **Deploy Edge Functions:**
   ```bash
   supabase functions deploy check-handle --project-ref gnvavfpjjbkabcmsztui
   supabase functions deploy create-profile --project-ref gnvavfpjjbkabcmsztui
   ```

3. **Test endpoints** before going live

## Benefits

### User Benefits
- More familiar handle format (matches Instagram/Threads)
- More flexibility in handle choice
- Cleaner, less cluttered UI (only see errors, not noise)
- Longer handles for better branding

### Platform Benefits
- Aligns with widely-understood conventions
- Future-proofs for Instagram/Threads integration
- Maintains uniqueness and data integrity
- Professional, polished user experience

## Related Documentation
- [Handle Validation Implementation](./HANDLE_VALIDATION_IMPLEMENTATION.md)
- [Apple UI/UX Design Guidelines](./.cursor/rules/apple-ui-ux-design.mdc)
- [OpenAPI Integration](./OPENAPI_INTEGRATION.md)

## Validation Rules Summary

| Rule | Requirement | Example |
|------|-------------|---------|
| **Minimum Length** | 3 characters | `joe` ✅, `ab` ❌ |
| **Maximum Length** | 30 characters | `this_is_exactly_thirty_chars` ✅ |
| **Allowed Characters** | Letters, numbers, periods, underscores | `Rocky.Evans_123` ✅ |
| **Consecutive Periods** | Not allowed | `test..handle` ❌ |
| **Must Have Letter** | At least one letter required | `user123` ✅, `123` ❌ |
| **Case Sensitivity** | Case-insensitive (stored lowercase) | `Rocky` = `rocky` |
| **Uniqueness** | Must be unique platform-wide | Checked via database |
| **Spaces** | Not allowed | `test handle` ❌ |
| **Special Characters** | Not allowed (except . and _) | `test@handle` ❌ |

## Future Enhancements

1. **Smart suggestions:** Check suggested handles for availability
2. **Reserved handles:** Expandable list in database
3. **Handle history:** Track handle changes, prevent rapid switching
4. **Profanity filter:** Block offensive handles
5. **Trademark protection:** Flag trademarked terms
6. **Rate limiting:** Prevent handle squatting attacks

