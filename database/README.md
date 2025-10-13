# Agora Database Setup

This directory contains database migrations and setup scripts for the Agora Supabase project.

## Project Setup

You have the following Supabase projects configured:

- **Development**: Your development Supabase project
- **Staging**: (to be created)
- **Production**: Your production Supabase project

> **Note**: Actual project URLs and credentials are stored in environment-specific plist files (gitignored)

## Initial Schema Setup

1. **Log into Supabase Dashboard**: Go to https://supabase.com/dashboard
2. **Select your project**: Choose your environment's project (agora-dev or agora-prod)
3. **Go to SQL Editor**: In the left sidebar, click "SQL Editor"
4. **Run the initial migration**:
   - Copy the contents of `migrations/001_initial_schema.sql`
   - Paste into the SQL Editor
   - Click "Run" to execute

> **Important**: Run the schema migration on both development and production projects to keep them in sync.

## Database Schema Overview

The schema includes all tables from the MVP blueprint:

### Core Tables
- `users` - User profiles and authentication data
- `devices` - App Attest and DeviceCheck data
- `sessions` - Authentication session management
- `posts` - Main content posts with media support

### Social Features
- `follows` - User following relationships
- `likes` - Post likes and interactions
- `reposts` - Post reposts and quotes

### Content & Media
- `media_bundles` - Images and videos with Cloudflare integration
- `posts` - Text content with media references

### Communication
- `dms_threads` - Direct message conversations
- `dms_participants` - Users in DM conversations
- `dms_messages` - Individual DM messages

### Moderation & Safety
- `reports` - User reports for content moderation
- `moderation_actions` - Admin moderation actions
- `rate_limits` - Anti-abuse rate limiting

### Recommendation System
- `feed_scores` - Personalized content scoring for For You feed
- `post_impressions` - User impression tracking for 7-day suppression
- `post_events` - Event log for user interactions (likes, views, etc.)
- `post_aggregates` - Materialized view of engagement rollups
- `graph_proximity` - Cached social graph proximity weights
- `bandit_stats` - Multi-armed bandit statistics for exploration
- `reco_config` - Centralized algorithm configuration (JSONB)

### Notifications
- `notifications` - Push notification tracking

## Row Level Security (RLS)

All tables have RLS enabled with appropriate policies:

- **Posts**: Public read, authenticated write
- **Users**: Public read, self-update only
- **Follows/Likes**: Authenticated users only
- **DMs**: Participants only
- **Reports**: Users can only see their own reports
- **Notifications**: Users can only see their own notifications

## Next Steps

After running the initial schema:

1. **Set up authentication providers** in Supabase Dashboard
2. **Configure Cloudflare integration** for media storage
3. **Create Edge Functions** for write operations
4. **Test the schema** with sample data

## Migration Management

### Deployed Migrations (Staging)

1. **001_initial_schema.sql** - Base tables (users, posts, follows, likes, etc.)
2. **002_add_display_handle.sql** - Display handle support
3. **003_feed_foundation.sql** - Feed infrastructure (impressions, events, aggregates, proximity)
4. **004_count_triggers.sql** - Auto-maintain engagement counts
5. **005_feed_helpers.sql** - Feed candidate generation functions
6. **006_bandit_system.sql** - Multi-armed bandit for exploration
7. **007_reco_config.sql** - Centralized algorithm configuration
8. **008_cron_jobs.sql** - Automated maintenance (refresh aggregates, prune old data)
9. **009_auth_integration.sql** - Supabase Auth integration, RLS policies for user creation

### Authentication Flow

Agora uses hybrid authentication with Supabase Auth + custom user creation:

1. **Sign in with Apple** → Supabase Auth mints JWT (user session)
2. **Client checks** `/users/me` (Edge Function) for existing profile
3. **If no profile** → Show onboarding to collect handle/display name
4. **Client calls** `/create-profile` (Edge Function) with onboarding data
5. **Edge Function validates** and creates user record atomically
6. **Client proceeds** to main app with authenticated profile

**Why Edge Functions for User Creation?**

We use Supabase Edge Functions rather than direct database inserts to:
- Enforce verification gates (device attestation, phone verify, rate limits)
- Atomically reserve handles and create user records
- Centralize business logic server-side for auditability
- Maintain flexibility to add checks without client updates

See `../supabase/functions/README.md` for Edge Function details.

### Applying New Migrations

For future schema changes:

1. Create new migration files: `migrations/00X_*.sql`
2. Test migrations in development first
3. Apply to staging for validation using Supabase MCP or Dashboard
4. Deploy to production

## Environment Configuration

Make sure your environment-specific plist files have the correct Supabase credentials:

### Development (`Resources/Configs/Development.plist`)
```xml
<key>supabaseURL</key>
<string>https://your-dev-project.supabase.co</string>

<key>supabaseAnonKey</key>
<string>your-development-anon-key-here</string>
```

### Production (`Resources/Configs/Production.plist`)
```xml
<key>supabaseURL</key>
<string>https://your-prod-project.supabase.co</string>

<key>supabaseAnonKey</key>
<string>your-production-anon-key-here</string>
```

## Troubleshooting

If you encounter issues:

1. **Check RLS policies** - Ensure they're correctly configured
2. **Verify indexes** - Performance issues may require additional indexes
3. **Test in development** - Always test schema changes in dev first
4. **Check Supabase logs** - Use the dashboard to debug issues
