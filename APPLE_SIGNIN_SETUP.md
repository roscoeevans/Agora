# Apple Sign In Setup - Quick Reference

## Your Configuration Values

### From Your App ID (screenshot):
- **Team ID**: `R86N73ZKCW`
- **Bundle ID**: `Ergo-Sum.Agora.staging`
- **Platform**: iOS, iPadOS, macOS, tvOS, watchOS, visionOS

## Step-by-Step Setup

### 1. Create Services ID in Apple Developer

Go to: https://developer.apple.com/account/resources/identifiers/list/serviceId

**Click "+" to create new Services ID:**
- **Description**: `Agora Staging Sign in with Apple`
- **Identifier**: `Ergo-Sum.Agora.staging.signin`
- ✅ Enable "Sign in with Apple"
- **Click "Configure"**:
  - Primary App ID: `Ergo-Sum.Agora.staging` ✅
  - Website URLs:
    - Domains: `iqebtllzptardlgpdnge.supabase.co` ✅
    - Return URLs: `https://iqebtllzptardlgpdnge.supabase.co/auth/v1/callback` ✅
- **Save**

### 2. Create Private Key (.p8)

Go to: https://developer.apple.com/account/resources/authkeys/list

**Click "+" to create new Key:**
- **Name**: `Agora Staging Sign in with Apple Key`
- ✅ Enable "Sign in with Apple"
- **Click "Configure"**:
  - Primary App ID: `Ergo-Sum.Agora.staging` ✅
- **Click "Continue"** then **"Register"**
- **⚠️ DOWNLOAD THE .p8 FILE** (you only get ONE chance!)
- **📝 Note the Key ID** (e.g., `ABC123XYZ`)

### 3. Configure Supabase

Go to: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/providers

**Enable Apple Provider and enter:**

| Field | Value |
|-------|-------|
| **Services ID** | `Ergo-Sum.Agora.staging.signin` |
| **Team ID** | `R86N73ZKCW` |
| **Key ID** | (from the .p8 file you downloaded) |
| **Private Key** | (paste entire contents of .p8 file) |
| **Redirect URL** | `https://iqebtllzptardlgpdnge.supabase.co/auth/v1/callback` |

**Click "Save"** ✅

## Verification Checklist

Before testing your iOS app:

- [ ] Services ID `Ergo-Sum.Agora.staging.signin` is created in Apple Developer
- [ ] Services ID is configured with Primary App ID: `Ergo-Sum.Agora.staging`
- [ ] Return URL is EXACTLY: `https://iqebtllzptardlgpdnge.supabase.co/auth/v1/callback`
- [ ] Private Key (.p8) is downloaded and saved
- [ ] Apple Provider is enabled in Supabase
- [ ] All credentials are entered in Supabase (Services ID, Team ID, Key ID, Private Key)
- [ ] "Save" button clicked in Supabase

## Testing

Once configured:

1. **Build and run your iOS app**
2. **Tap "Sign in with Apple"**
3. **Complete Apple authentication**
4. **App should transition to onboarding** (if first time)
5. **Check Supabase Dashboard**:
   - Users: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/users
   - Should see new user!

## Troubleshooting

### Error: "Invalid OAuth configuration"

**Check these EXACT values:**
- Services ID: `Ergo-Sum.Agora.staging.signin` ✓
- Team ID: `R86N73ZKCW` ✓
- Return URL: `https://iqebtllzptardlgpdnge.supabase.co/auth/v1/callback` ✓
- Primary App ID: `Ergo-Sum.Agora.staging` ✓

### Error: "Invalid client"

- Make sure you clicked "Save" in Supabase after entering credentials
- Double-check the Private Key (.p8) was pasted completely
- Verify the Key ID matches the key you created

### User signs in but gets stuck

- This means Supabase Auth is working! ✅
- Check if profile creation is failing
- View Edge Function logs: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/functions

## Quick Links

- **Apple Services IDs**: https://developer.apple.com/account/resources/identifiers/list/serviceId
- **Apple Keys**: https://developer.apple.com/account/resources/authkeys/list
- **Supabase Auth Providers**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/providers
- **Supabase Auth Users**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/auth/users
- **Supabase Edge Functions**: https://supabase.com/dashboard/project/iqebtllzptardlgpdnge/functions

---

**Everything is configured in your iOS app already!** Just need to complete the Apple Developer + Supabase configuration above. 🚀

