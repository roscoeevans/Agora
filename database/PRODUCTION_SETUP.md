# Production Supabase Setup Guide

## ✅ Configuration Complete

Your Agora production Supabase project has been configured!

**Project:** `gnvavfpjjbkabcmsztui.supabase.co` (agora-prod)

## What's Been Updated

1. ✅ **Production.plist** - Updated with production Supabase URL and anon key
2. ✅ **database/README.md** - Added production project reference
3. ✅ **Resources/Configs/.secrets** - Secure storage for service role key and DB password (gitignored)

## Next Steps

### 1. Run Initial Database Migration

You need to set up the database schema on your production project:

1. Go to https://supabase.com/dashboard
2. Select the **agora-prod** project (`gnvavfpjjbkabcmsztui`)
3. Navigate to **SQL Editor** in the left sidebar
4. Copy the contents of `database/migrations/001_initial_schema.sql`
5. Paste into the SQL Editor
6. Click **Run** to execute

This will create:
- All 17 tables (users, posts, follows, likes, DMs, etc.)
- Row Level Security policies
- Indexes for performance
- Database triggers

### 2. Configure Authentication

Set up Sign in with Apple:

1. In Supabase Dashboard → **Authentication** → **Providers**
2. Enable **Apple** provider
3. Add your Apple credentials:
   - Service ID
   - Team ID
   - Key ID
   - Private Key (.p8 file)

### 3. Set Up Edge Functions (Optional for MVP)

If you want to create any Edge Functions for server-side operations:

```bash
# Using Supabase CLI
supabase functions deploy function-name --project-ref gnvavfpjjbkabcmsztui
```

### 4. Test the Connection

Build and run the app using the **Agora Production** scheme:

1. In Xcode, select **Agora Production** scheme
2. Build and run
3. The app should connect to your production Supabase instance

### 5. Configure Additional Services

Update `Resources/Configs/Production.plist` with real values for:

- ❌ `posthogKey` - PostHog analytics key
- ❌ `sentryDSN` - Sentry error tracking DSN
- ❌ `twilioVerifyServiceSid` - Twilio Verify service SID
- ❌ `oneSignalAppId` - OneSignal push notification app ID

## Security Checklist

- ✅ Anon key stored in Production.plist (safe for client app)
- ✅ Service role key stored separately in .secrets file (gitignored)
- ✅ Database password documented securely
- ⚠️ **Remember:** Never commit service role keys to git
- ⚠️ **Important:** Service role key bypasses RLS - use only in secure server contexts

## Environment Summary

| Environment | Project | Status |
|-------------|---------|--------|
| Development | `iqebtllzptardlgpdnge` | ✅ Configured |
| Staging | TBD | ⏳ Not yet created |
| Production | `gnvavfpjjbkabcmsztui` | ✅ Configured |

## Troubleshooting

### App can't connect to Supabase

1. Check the Production.plist file exists at `Resources/Configs/Production.plist`
2. Verify the supabaseURL and supabaseAnonKey are correct
3. Ensure you're building with the **Agora Production** scheme
4. Check Supabase Dashboard → Project Settings → API to verify credentials

### Database migration fails

1. Make sure RLS policies don't conflict
2. Check for syntax errors in SQL
3. View detailed error in Supabase Dashboard → SQL Editor
4. Run migrations on development first to test

### Authentication not working

1. Verify Apple provider is enabled in Supabase Dashboard
2. Check that Apple credentials are correctly configured
3. Ensure bundle ID matches what's registered with Apple
4. Test with email/password auth first (for debugging)

## Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Auth with Swift](https://supabase.com/docs/reference/swift/auth-signup)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

## Need Help?

- Supabase Dashboard: https://supabase.com/dashboard/project/gnvavfpjjbkabcmsztui
- Project logs: Dashboard → Logs
- Database performance: Dashboard → Database → Performance

