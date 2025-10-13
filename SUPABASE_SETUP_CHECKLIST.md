# Supabase Setup Checklist for agora-staging

## ✅ Already Completed

- ✅ **Database Migration Applied**: `009_auth_integration`
- ✅ **Tables Created**: All tables exist with RLS enabled
  - `users` table with `apple_sub` column ✓
  - `devices`, `sessions`, etc. all set up ✓
- ✅ **Edge Functions Deployed**:
  - `create-profile` ✓
  - `get-current-profile` ✓
- ✅ **Indexes Created**: apple_sub, phone_e164, sessions, devices ✓

## 🔲 Required: Sign in with Apple Setup

### Step 1: Enable Apple Provider

1. **Open Supabase Dashboard**:
   - Go to: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/providers

2. **Enable Apple Provider**:
   - Find "Apple" in the list of providers
   - Toggle it **ON**
   - Click "Save" (you'll configure credentials next)

### Step 2: Configure Apple Developer Account

You need to set up Sign in with Apple in your Apple Developer account:

1. **Go to Apple Developer**:
   - Visit: https://developer.apple.com/account/resources/identifiers/list
   
2. **Create/Configure App ID**:
   - Select your App ID (e.g., `com.agora.ios` or create new)
   - Enable "Sign in with Apple" capability
   - Click "Configure" next to Sign in with Apple
   - Add your domain (if needed): `iqebtllzptardlgpdnge.supabase.co`
   
3. **Create Services ID** (for OAuth):
   - Click "+" to create new Identifier
   - Select "Services IDs"
   - Description: "Agora Staging Sign in with Apple"
   - Identifier: `Ergo-Sum.Agora.staging.signin` (recommended)
   - Enable "Sign in with Apple"
   - Click "Configure"
   - Set **Primary App ID** to `Ergo-Sum.Agora.staging`
   - Add **Return URLs**:
     ```
     https://iqebtllzptardlgpdnge.supabase.co/auth/v1/callback
     ```
   - Save

4. **Create Private Key**:
   - Go to "Keys" section
   - Click "+" to create new key
   - Name: "Agora Sign in with Apple Key"
   - Enable "Sign in with Apple"
   - Click "Configure" and select your Primary App ID
   - Click "Continue" and "Register"
   - **Download the .p8 file** (you only get one chance!)
   - Note the **Key ID** (yours is `8928T6Y3K8`)

### Step 3: Configure Supabase with Apple Credentials

Back in Supabase Dashboard (Auth > Providers > Apple):

1. **Services ID**: `Ergo-Sum.Agora.staging.signin` (the Services ID you created)
2. **Team ID**: `R86N73ZKCW` (your Team ID from screenshot)
3. **Key ID**: The Key ID from the private key you created (e.g., `ABC123XYZ`)
4. **Private Key**: Paste the contents of your .p8 file
5. **Redirect URL** (should auto-populate):
   ```
   https://iqebtllzptardlgpdnge.supabase.co/auth/v1/callback
   ```
6. Click **Save**

## 🔲 Optional but Recommended

### Configure Auth Settings

Go to: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/settings

1. **Session Management**:
   - ✅ Enable "Secure session cookie" (HTTPS only)
   - ✅ JWT expiry: 3600 seconds (1 hour) - default is fine
   - ✅ Refresh token rotation: Enabled
   
2. **Email Auth** (disable if not using):
   - ❌ Disable "Enable email signups" (since you're Apple-only)
   - ❌ Disable "Enable email confirmations"

3. **Security**:
   - ✅ Enable "PKCE flow" (more secure)
   - ✅ Enable "Hook validations"

### Configure URL Configuration

Go to: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/url-configuration

Add your app's redirect URLs:
```
Ergo-Sum.Agora.staging://auth/callback
agora://auth/callback
```

## 🔲 Test Authentication

### Manual Test via Dashboard

1. **Go to SQL Editor**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/sql/new
2. **Run this query** to check if auth is working:
   ```sql
   SELECT * FROM auth.users;
   ```
   (Should be empty initially)

3. **Test Edge Functions**:
   - Go to: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/functions
   - Click on `create-profile`
   - Click "Test" (you'll need a valid JWT)

### Test from iOS App

1. **Build and run** your app
2. **Tap "Sign in with Apple"**
3. **Complete Apple authentication**
4. **Check Supabase Dashboard**:
   - Go to: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/users
   - You should see a new user!
5. **Complete onboarding** (enter handle)
6. **Check users table**:
   ```sql
   SELECT * FROM users;
   ```
   Should show your new profile!

## Common Issues & Solutions

### Issue: "Invalid OAuth configuration"

**Solution**: Double-check in Apple Developer:
- Services ID is exactly: `Ergo-Sum.Agora.staging.signin`
- Primary App ID is: `Ergo-Sum.Agora.staging`
- Return URL is exactly: `https://iqebtllzptardlgpdnge.supabase.co/auth/v1/callback`
- Private key (.p8) contents are pasted correctly (entire file)
- Team ID is: `R86N73ZKCW`

### Issue: "User created but no profile"

**Solution**: This is expected! The flow is:
1. Apple Sign In → Supabase creates auth.users entry
2. Onboarding → Edge Function creates public.users entry
3. The auth.users and public.users are linked by `id`

### Issue: "Edge Function returns 401"

**Solution**: Check that:
- JWT token is being sent in Authorization header
- Token is valid (not expired)
- User exists in auth.users table

### Issue: "Handle already taken"

**Solution**: This is working correctly! The Edge Function checks for duplicates.

## Verification Checklist

Before testing in your iOS app:

- [ ] Apple provider is enabled in Supabase Auth
- [ ] Services ID is configured in Apple Developer
- [ ] Private key (.p8) is uploaded to Supabase
- [ ] Return URL matches exactly
- [ ] Edge Functions are deployed and active
- [ ] Database migration is applied
- [ ] iOS app has correct SUPABASE_URL and SUPABASE_ANON_KEY

## Next Steps After Setup

Once Sign in with Apple is working:

1. **Add phone verification** (Twilio Verify)
2. **Add device attestation** (App Attest)
3. **Implement rate limiting** in Edge Functions
4. **Add profile image upload**
5. **Set up monitoring** and alerts

## Dashboard Quick Links

- **Project Dashboard**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge
- **Auth Settings**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/settings
- **Auth Providers**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/providers
- **Auth Users**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/users
- **Edge Functions**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/functions
- **Database Editor**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/editor
- **SQL Editor**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/sql/new

---

## Current Status

✅ **Database**: Fully set up  
✅ **Edge Functions**: Deployed and running  
✅ **iOS App**: Configured and ready  
🔲 **Sign in with Apple**: Needs Apple Developer configuration  

**Once you configure Sign in with Apple, you're ready to test!** 🚀

