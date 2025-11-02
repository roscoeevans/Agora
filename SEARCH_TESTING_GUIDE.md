# Search Testing Guide

## Quick Start Testing

### 1. Test Database Functions Directly

**Via Supabase SQL Editor** (fastest way to verify):

```sql
-- Test 1: Search for your own handle (should return EMPTY - you're excluded)
SELECT * FROM search_users_v1(
  '@sitch',                                         -- your handle
  'd557ffae-107d-4871-a33b-722c5b7b7d68'::uuid,   -- your user ID
  10,
  null
);
-- Expected: Empty array (you don't see yourself)

-- Test 2: Prefix search
SELECT user_id, handle, display_name, followers_count, score 
FROM search_users_v1(
  'ro',                                             -- prefix
  'd557ffae-107d-4871-a33b-722c5b7b7d68'::uuid,   -- your user ID
  10,
  null
);
-- Expected: Users whose handle/name starts with "ro"

-- Test 3: Typo tolerance
SELECT user_id, handle, display_name, score 
FROM search_users_v1(
  'rokcy',                                          -- typo
  'd557ffae-107d-4871-a33b-722c5b7b7d68'::uuid,   -- your user ID
  10,
  null
);
-- Expected: Should still find "rocky" due to trigram similarity

-- Test 4: Exact handle with @ prefix
SELECT user_id, handle, display_name, score 
FROM search_users_v1(
  '@rocky',                                         -- exact with @
  'd557ffae-107d-4871-a33b-722c5b7b7d68'::uuid,   -- your user ID
  10,
  null
);
-- Expected: Exact match pinned at top (score = 1.0)

-- Test 5: Suggested creators
SELECT user_id, handle, display_name, verified, followers_count
FROM suggested_creators(
  'd557ffae-107d-4871-a33b-722c5b7b7d68'::uuid,   -- your user ID
  10
);
-- Expected: Popular users you don't follow (excluding yourself)

-- Test 6: Lookup by exact handle
SELECT * FROM lookup_user_by_handle('@sitch');
-- Expected: Your profile details
```

**Get Your User ID**:
```sql
SELECT id, handle, display_name FROM users WHERE handle = 'sitch';
```

### 2. Test Edge Functions

**Via curl** (terminal):

```bash
# Set your JWT token (get from app or Supabase dashboard)
export JWT="your-jwt-token-here"
export SUPABASE_URL="https://iqebtllzptardlgpdnge.supabase.co"

# Test 1: Search users
curl -X GET "$SUPABASE_URL/functions/v1/search-users?q=rocky&limit=5" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" | jq

# Expected response:
# {
#   "items": [...],
#   "query": "rocky",
#   "count": 5,
#   "hasMore": false,
#   "nextCursor": null
# }

# Test 2: Empty query (should error)
curl -X GET "$SUPABASE_URL/functions/v1/search-users?q=&limit=5" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" | jq

# Expected: 400 Bad Request

# Test 3: Suggested creators
curl -X GET "$SUPABASE_URL/functions/v1/suggested-creators?limit=10" \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" | jq

# Expected response:
# {
#   "items": [...],
#   "count": 10
# }

# Test 4: Pagination
curl -X GET "$SUPABASE_URL/functions/v1/search-users?q=a&limit=2" \
  -H "Authorization: Bearer $JWT" | jq '.nextCursor'

# Use the cursor for next page
CURSOR=$(curl -X GET "$SUPABASE_URL/functions/v1/search-users?q=a&limit=2" \
  -H "Authorization: Bearer $JWT" | jq -r '.nextCursor')

curl -X GET "$SUPABASE_URL/functions/v1/search-users?q=a&limit=2&after=$CURSOR" \
  -H "Authorization: Bearer $JWT" | jq
```

**Get JWT Token**:
```bash
# From Supabase Dashboard:
# 1. Go to Authentication > Users
# 2. Find your user
# 3. Click "Generate access token" or use existing session

# Or extract from iOS app (add this to debug code):
print("JWT Token: \(try? await deps.auth.currentAccessToken())")
```

### 3. Test in iOS App

**Method 1: Run the App** (recommended)

```bash
# Build the app
cd /Users/roscoeevans/Developer/Agora
agctl build

# Open in Xcode
open Agora.xcodeproj

# Run on simulator (⌘R)
# Navigate to Search tab
# Type in search bar
```

**What to test**:
1. ✅ Empty state shows "Search Agora" message (centered)
2. ✅ Typing triggers search after 300ms debounce
3. ✅ Results show user avatars, names, handles, follower counts
4. ✅ Verified badges appear for verified users
5. ✅ Tapping user navigates to profile
6. ✅ No results shows "No Results Found" (centered)
7. ✅ You don't appear in your own search results
8. ✅ Pagination loads more results when scrolling
9. ✅ Loading spinner shows while searching

**Method 2: SwiftUI Previews** (faster iteration)

```bash
# Open SearchView in Xcode
# Click "Resume" button in preview canvas
# Or use keyboard shortcut: ⌥⌘P
```

The preview uses `UserSearchServiceMock` so results appear instantly without network calls.

**Method 3: Unit Tests**

```bash
# Run SearchKit tests
agctl test SearchKit

# Expected output:
# ✅ SearchUser model encodes/decodes correctly
# ✅ Mock service returns filtered results
# ✅ Mock service handles pagination
# ✅ Mock service handles errors
```

### 4. Create Test Data (If Needed)

If you don't have enough test users:

```sql
-- Create a test user
INSERT INTO public.users (
  handle,
  display_handle,
  display_name,
  verified,
  is_active,
  followers_count,
  trust_level
) VALUES (
  'test.user',
  'Test.User',
  'Test User',
  false,
  true,
  50,
  1
);

-- Create another test user
INSERT INTO public.users (
  handle,
  display_handle,
  display_name,
  verified,
  is_active,
  followers_count,
  trust_level
) VALUES (
  'jane.doe',
  'jane.doe',
  'Jane Doe',
  true,  -- verified
  true,
  1000,  -- popular
  2
);

-- Verify they were created
SELECT handle, display_name, followers_count, verified FROM users ORDER BY created_at DESC LIMIT 5;
```

## End-to-End Test Scenarios

### Scenario 1: Exact Handle Match

**Steps**:
1. Open Search tab
2. Type `@sitch` in search bar
3. Wait 300ms for debounce

**Expected**:
- Your handle does NOT appear (viewer excluded)
- If there's a user named "sitch2" or similar, they might appear

### Scenario 2: Prefix Search

**Steps**:
1. Type `si` in search bar

**Expected**:
- All users with handles/names starting with "si" appear
- Sorted by: exact matches first, then by popularity
- Verified users ranked higher at same relevance

### Scenario 3: Typo Tolerance

**Steps**:
1. Type `rokcy` (typo for "rocky")

**Expected**:
- Users with "rocky" in handle/name still appear
- Trigram similarity threshold allows 1-2 character differences

### Scenario 4: Popularity Ranking

**Steps**:
1. Search for common letter like `a`

**Expected**:
- Results blend text relevance + popularity
- Verified users with high follower counts rank higher
- Recently active users get slight boost

### Scenario 5: Empty State

**Steps**:
1. Open Search tab (don't type anything)

**Expected**:
- Centered card with magnifying glass icon
- "Search Agora" title
- "Find people and posts to discover what's happening." message
- Card width matches "You're All Caught Up"

### Scenario 6: No Results

**Steps**:
1. Search for nonsense: `zxzxzxzxzx`

**Expected**:
- Centered card with magnifying glass icon
- "No Results Found" title
- Helpful message about trying different keywords

### Scenario 7: Pagination

**Steps**:
1. Search for common term with many results
2. Scroll to bottom of list
3. Tap "Load More" or scroll further

**Expected**:
- More results append to list
- No duplicate users
- Cursor tracks last handle for stable pagination

## Debugging Tips

### Check Search Indexes

```sql
-- Verify trigram indexes exist
SELECT indexname, tablename 
FROM pg_indexes 
WHERE indexname LIKE '%trgm%';

-- Expected:
-- idx_users_handle_lower_trgm
-- idx_users_display_name_lower_trgm
```

### Check Counts are Maintained

```sql
-- Verify follower counts are accurate
SELECT 
  u.handle,
  u.followers_count AS cached_count,
  (SELECT count(*) FROM follows f WHERE f.followee_id = u.id) AS actual_count
FROM users u
WHERE u.followers_count != (SELECT count(*) FROM follows f WHERE f.followee_id = u.id);

-- Expected: Empty (counts should match)
```

### View Search Logs

**Edge Function logs** (Supabase dashboard):
1. Go to Edge Functions → search-users
2. Click "Logs" tab
3. Filter by recent invocations
4. Check for errors or slow queries

**iOS app logs**:
```swift
// Add to SearchViewModel.search()
print("🔍 Searching for: \(query)")
print("📊 Results: \(searchResults.count)")
print("⏱️ Took: \(Date().timeIntervalSince(startTime))s")
```

## Performance Benchmarks

**Expected Latency**:
- Database function: <150ms P50
- Edge Function (warm): <100ms
- Edge Function (cold start): ~500ms
- Total iOS → response: <300ms P50

**Measure with**:
```sql
-- Time a search query
EXPLAIN ANALYZE 
SELECT * FROM search_users_v1('rocky', 'd557ffae-107d-4871-a33b-722c5b7b7d68'::uuid, 20, null);

-- Look for:
-- Planning Time: <5ms
-- Execution Time: <150ms
```

## Common Issues

### "No results for any query"
- Check if users have `is_active = true`
- Check if follower counts are backfilled
- Verify trigram indexes exist

### "Search is slow"
- Check EXPLAIN ANALYZE output
- Verify indexes are being used (not seq scans)
- Check Edge Function cold start times

### "Can't authenticate"
- Verify JWT token is valid
- Check token expiration
- Ensure user exists in auth.users

### "Empty state not centered"
- Remove any `ScrollView` wrapping empty states
- Use `VStack { Spacer() ... Spacer() }` pattern
- Check padding is `.horizontal` not all sides

## Success Criteria

✅ Search returns results within 300ms  
✅ Exact @handle matches appear first  
✅ Typos still find correct users (within 2 chars)  
✅ You never see yourself in results  
✅ Blocked users are filtered out  
✅ Empty states are perfectly centered  
✅ Pagination works without duplicates  
✅ UI matches "You're All Caught Up" styling  

---

**Quick Test Command** (copy/paste):
```bash
# Replace with your actual token and user ID
curl -X GET "https://iqebtllzptardlgpdnge.supabase.co/functions/v1/search-users?q=si&limit=5" \
  -H "Authorization: Bearer YOUR_JWT_HERE" | jq
```



