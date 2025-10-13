# Handle Validation Implementation

## Overview
Implemented real-time handle availability checking during profile creation. The system validates both format and availability against the Supabase database.

## Changes Made

### 1. UI Improvements (`HandleInputView.swift`)
- **Removed** the "Display As" preview section (redundant since user sees their capitalization in the input field)
- **Fixed** validation timing issue where the Continue button wouldn't enable
- **Improved** validation flow to trigger immediately when user types

**Key fixes:**
- Validation now uses the actual parameter value instead of reading from binding (prevents race conditions)
- Empty handles immediately set `isValid = false` without async call
- Validation triggers on `displayHandle` changes, not just `handle` changes

### 2. Backend: Supabase Edge Function
**Created:** `supabase/functions/check-handle/index.ts`

**Endpoint:** `GET /check-handle?handle={handle}`

**Note:** Supabase Edge Functions use flat paths (function name = endpoint path). In staging/dev environments using Supabase directly, the endpoint is at `/check-handle`. In production with a custom API gateway, you can route `/users/check-handle` to the appropriate function.

**Features:**
- Validates handle format (3-15 characters, lowercase letters, numbers, underscores)
- Queries the `users` table to check if handle is already taken
- Returns availability status and suggestions if handle is unavailable
- No authentication required (public endpoint)
- Handles CORS for web clients

**Response format:**
```json
{
  "available": true,
  "suggestions": []
}
```

Or if taken:
```json
{
  "available": false,
  "suggestions": ["handle1", "handle2", "handle_", "handle2025", "handle123"]
}
```

### 3. API Client Integration
**Updated:** `OpenAPIAgoraClient.swift`

- Wired up the previously unimplemented `checkHandle()` method
- Now calls the generated OpenAPI client code: `get_sol_users_sol_check_hyphen_handle()`
- Proper error handling for bad requests and server errors

## How It Works

### User Flow
1. User types handle (e.g., "Sitch") on profile creation screen
2. System immediately:
   - Converts to lowercase ("sitch")
   - Validates format (3-15 chars, valid characters)
   - Shows spinner next to input field
3. After 300ms debounce, makes API call to check availability
4. Shows green checkmark ✓ if available, red X if taken
5. If taken, displays suggestions below input field
6. Continue button enables only when handle is valid AND available

### Data Storage
- `handle`: "sitch" (lowercase, used for lookups and @ mentions)
- `display_handle`: "Sitch" (user's preferred capitalization, shown on profile)

## Environment Configuration

### Staging
- **Project ID:** iqebtllzptardlgpdnge
- **API Base URL:** https://iqebtllzptardlgpdnge.supabase.co/functions/v1
- **Edge Function:** Deployed and active (version 1)

### Production
- **Project ID:** gnvavfpjjbkabcmsztui
- **API Base URL:** https://api.agora.com (not deployed yet)

## Testing

### Manual Testing
1. Build and run app in Staging configuration
2. Sign in with Apple
3. On "Choose Your Handle" screen:
   - Try an invalid handle (< 3 chars): Should show validation error
   - Try a valid handle: Should show checkmark after brief loading
   - Try an existing handle: Should show red X and suggestions
   - Type in mixed case: Input field shows your capitalization

### Testing Handle Availability Directly
```bash
# Test available handle
curl "https://iqebtllzptardlgpdnge.supabase.co/functions/v1/check-handle?handle=testuser123"

# Test invalid format
curl "https://iqebtllzptardlgpdnge.supabase.co/functions/v1/check-handle?handle=ab"

# Test taken handle (if any exist in staging DB)
curl "https://iqebtllzptardlgpdnge.supabase.co/functions/v1/check-handle?handle=admin"
```

## Validation Rules

### Client-Side (Instant)
- Length: 3-15 characters
- Characters: lowercase letters, numbers, underscores
- Cannot start with underscore
- Cannot be all numbers
- Reserved handles: admin, root, system, agora, support, help, moderator, mod, official, team, staff

### Server-Side (Debounced)
- Checks database uniqueness
- Returns suggestions if taken

## Database Schema
```sql
-- users table (relevant columns)
CREATE TABLE users (
  id UUID PRIMARY KEY,
  handle TEXT UNIQUE NOT NULL CHECK (handle ~ '^[a-z0-9_]{3,15}$'),
  display_handle TEXT NOT NULL,
  -- ... other columns
);
```

## Next Steps

### Required Before Production Launch
1. **Deploy to production:**
   ```bash
   # Deploy check-handle function to prod
   supabase functions deploy check-handle --project-ref gnvavfpjjbkabcmsztui
   ```

2. **Update Production API URL** in `Resources/Configs/Production.xcconfig`:
   ```
   API_BASE_URL = https://gnvavfpjjbkabcmsztui.supabase.co/functions/v1
   ```
   (Or keep `https://api.agora.com` if you're using a custom domain with reverse proxy)

3. **Add rate limiting** to check-handle endpoint to prevent abuse
4. **Monitor logs** for errors or unusual patterns

### Nice-to-Have Improvements
1. **Smarter suggestions:** Check which suggested handles are actually available
2. **Real-time suggestions:** As user types, show available similar handles
3. **Handle history:** Prevent users from rapidly changing handles
4. **Reserved handle management:** Move reserved list to database for easier updates
5. **Analytics:** Track which handles are most commonly attempted

## Files Modified
- `Packages/Features/Auth/Sources/Auth/HandleInputView.swift` - Fixed validation timing and removed redundant UI
- `Packages/Kits/Networking/Sources/Networking/OpenAPIAgoraClient.swift` - Wired up checkHandle method
- `OpenAPI/agora.yaml` - Updated endpoint path from `/users/check-handle` to `/check-handle` to match Supabase Edge Functions structure
- `Packages/Kits/Networking/Sources/Networking/Generated/` - Regenerated OpenAPI client code

## Files Created
- `supabase/functions/check-handle/index.ts` - Handle availability checking Edge Function

## Important Notes

### API Path Structure
Supabase Edge Functions use a flat path structure where the function name IS the endpoint path. This differs from typical REST API conventions:

- **Supabase:** Function named `check-handle` → `https://{project}.supabase.co/functions/v1/check-handle`
- **Traditional API:** Might use nested paths like `/users/check-handle`

For the staging environment using Supabase directly, we use the flat structure. In production, you can use an API gateway (like Cloudflare Workers or AWS API Gateway) to route traditional paths to your Supabase functions if desired.

## Dependencies
- Supabase Edge Functions (Deno runtime)
- OpenAPI Swift Generator (already configured)
- HandleValidator actor (existing)

## Related Documentation
- [Supabase Edge Functions README](../supabase/functions/README.md)
- [OpenAPI Integration](../OPENAPI_INTEGRATION.md)
- [Auth Implementation](../AUTH_IMPLEMENTATION_COMPLETE.md)

