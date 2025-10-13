# Profile Creation 404 Error - Fixed

## Issue
Profile creation was failing during onboarding on staging with HTTP 404 error. The avatar uploaded successfully, but then the profile creation API call failed.

## Root Cause
The OpenAPI spec endpoint paths didn't match the actual Supabase Edge Function names:

**Before (Incorrect):**
- OpenAPI Spec: `/users/profile` (POST)
- Base URL: `https://iqebtllzptardlgpdnge.supabase.co/functions/v1`
- **Resulting URL:** `https://iqebtllzptardlgpdnge.supabase.co/functions/v1/users/profile` ❌

**Actual Edge Function:**
- Function name: `create-profile`
- **Correct URL:** `https://iqebtllzptardlgpdnge.supabase.co/functions/v1/create-profile` ✅

## Changes Made

### 1. Updated OpenAPI Spec (`OpenAPI/agora.yaml`)
Changed endpoint paths to match Supabase Edge Function names:

- `/users/profile` → `/create-profile` (POST - create profile)
- `/users/me` → `/get-current-profile` (GET - get current user)
- `/users/me` → `/update-profile` (PATCH - update profile)

### 2. Regenerated OpenAPI Client
Ran `./Scripts/generate-openapi.sh` to regenerate the Swift client code with the corrected endpoint paths.

### 3. Updated OpenAPIAgoraClient.swift
Updated method calls to use the newly generated method names:

- `post_sol_users_sol_profile` → `post_sol_create_hyphen_profile`
- `get_sol_users_sol_me` → `get_sol_get_hyphen_current_hyphen_profile`

**Note:** The feed endpoint was left unchanged at `/feed/for-you` to avoid breaking existing functionality.

## Verification

### Edge Functions Deployed on Staging:
✅ `create-profile` (version 2)
✅ `get-current-profile` (version 1)
✅ `check-handle` (version 2)
✅ `feed-for-you` (version 1)

### API Endpoints Now Correct:
- `POST /create-profile` - Creates user profile
- `GET /get-current-profile` - Fetches current user profile
- `GET /check-handle?handle=xxx` - Checks handle availability
- `GET /feed-for-you?cursor=xxx&limit=20` - Fetches For You feed

## Testing
The profile creation should now work correctly during onboarding. The flow:
1. User signs in with Apple ✅
2. Avatar uploads to Supabase Storage ✅
3. Profile creation POST to `/create-profile` ✅ (was failing with 404, now fixed)
4. User proceeds to main app ✅

## Notes
- The Edge Function `create-profile` already had proper `displayHandle` support
- All validation (handle format, uniqueness checks) is working correctly
- The 404 error was purely due to incorrect endpoint paths in the OpenAPI spec

