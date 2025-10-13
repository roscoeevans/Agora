# Supabase Edge Functions

This directory contains Supabase Edge Functions for Agora's backend logic.

## Functions

### create-profile

Creates a new user profile after authentication. This function enforces verification gates and atomically creates the user record in the database.

**Endpoint**: `POST /functions/v1/create-profile`

**Auth**: Requires valid Supabase JWT token (Bearer auth)

**Request Body**:
```json
{
  "handle": "johndoe",
  "displayHandle": "JohnDoe",
  "displayName": "John Doe",
  "bio": "Optional bio text"
}
```

**Response** (201 Created):
```json
{
  "id": "uuid",
  "handle": "johndoe",
  "display_handle": "JohnDoe",
  "display_name": "John Doe",
  "bio": "",
  "avatar_url": null,
  "apple_sub": "...",
  "phone_e164": null,
  "trust_level": 0,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

**Validation Gates**:
- Handle must match regex: `^[a-z0-9_]{3,15}$`
- Handle must be unique
- User must not already have a profile
- displayHandle and displayName are required

**Future Gates** (TODO):
- Device attestation verification
- Phone verification check
- Rate limiting per user/IP
- Disposable email/phone detection

### get-current-profile

Retrieves the current authenticated user's profile.

**Endpoint**: `GET /functions/v1/get-current-profile`

**Auth**: Requires valid Supabase JWT token (Bearer auth)

**Response** (200 OK):
```json
{
  "id": "uuid",
  "handle": "johndoe",
  "display_handle": "JohnDoe",
  "display_name": "John Doe",
  "bio": "My bio",
  "avatar_url": null,
  "created_at": "2025-01-01T00:00:00Z"
}
```

**Response** (404 Not Found) - Profile doesn't exist:
```json
{
  "error": "Profile not found",
  "message": "User profile does not exist"
}
```

## Development

### Local Testing

1. Start Supabase local development:
```bash
supabase start
```

2. Deploy functions locally:
```bash
supabase functions deploy create-profile --no-verify-jwt
supabase functions deploy get-current-profile --no-verify-jwt
```

3. Test with curl:
```bash
# Get your local auth token first
TOKEN="your-jwt-token-here"

# Create profile
curl -i --location --request POST 'http://localhost:54321/functions/v1/create-profile' \
  --header "Authorization: Bearer ${TOKEN}" \
  --header 'Content-Type: application/json' \
  --data '{"handle":"testuser","displayHandle":"TestUser","displayName":"Test User"}'

# Get current profile
curl -i --location --request GET 'http://localhost:54321/functions/v1/get-current-profile' \
  --header "Authorization: Bearer ${TOKEN}"
```

### Deployment

#### Staging
```bash
supabase functions deploy create-profile --project-ref YOUR_STAGING_PROJECT_REF
supabase functions deploy get-current-profile --project-ref YOUR_STAGING_PROJECT_REF
```

#### Production
```bash
supabase functions deploy create-profile --project-ref YOUR_PROD_PROJECT_REF
supabase functions deploy get-current-profile --project-ref YOUR_PROD_PROJECT_REF
```

## Architecture Notes

### Why Edge Functions?

We use Supabase Edge Functions for user creation (rather than direct database inserts) to:

1. **Enforce verification gates** - Device attestation, phone verification, rate limits
2. **Atomic operations** - Handle reservation and user creation in one transaction
3. **Centralized logic** - Keep business rules server-side and auditable
4. **Flexibility** - Easy to add new checks without client updates
5. **Security** - Validate inputs and prevent malicious profile creation

### Auth Flow

1. User signs in with Apple → Supabase Auth creates session
2. Client checks if user has profile via `get-current-profile`
3. If 404, show onboarding to collect handle/name
4. Client calls `create-profile` with onboarding data
5. Edge Function validates and creates user record
6. Client transitions to main app with authenticated profile

### RLS and Edge Functions

Supabase RLS policies work with Edge Functions when:
- Edge Function uses `createClient` with user's JWT token
- All database operations inherit the user's permissions
- RLS policy `auth.uid()` matches the JWT's `sub` claim

Our policy allows users to insert their own profile:
```sql
CREATE POLICY "Users can create own profile" ON users 
  FOR INSERT 
  WITH CHECK (auth.uid() = id);
```

## Monitoring

View function logs:
```bash
# Local
supabase functions logs create-profile

# Production
supabase functions logs create-profile --project-ref YOUR_PROD_PROJECT_REF
```

## Future Enhancements

- [ ] Add device attestation verification
- [ ] Add phone verification check
- [ ] Implement rate limiting (per user, per IP, per device)
- [ ] Add disposable email/phone detection
- [ ] Add profanity filter for display names
- [ ] Add reserved handle list (admin, system, etc.)
- [ ] Add analytics events for profile creation
- [ ] Add webhook for new user notifications

