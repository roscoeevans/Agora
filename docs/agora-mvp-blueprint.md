# Agora — Human-Only Social (MVP Blueprint)

**Platform**: iOS-only • iOS 26 • Swift 6.2 • SwiftUI 6
**Principle**: No AI‑generated **user content**; strong anti‑bot; For You (recommendations) is the default feed.
**Brand tone**: Clean, Apple‑native, humans only; safe‑by‑default; gorgeous, minimal motion following iOS 26 Liquid Glass design language.

---

## 1) Product Scope (Day‑One)

* **Surfaces**: For You (default), Following (chronological), Compose, Post Detail, Replies/Threads, Profiles, Search (people + posts), Notifications, DMs (basic).
* **Content**: Text (≤ 70 chars), links, images (JPEG/HEIC/PNG), video (≤ 10 minutes, ≤ 1080p for MVP).
* **Interactions**: Like, Repost, Quote, Reply, Mention (@username). No hashtags.
* **Sharing**: System share sheet + **read‑only Post Permalink Pages** for rich previews (Messages, etc.).
* **Moderation**: Block/Mute, Report post/account, Keyword mute, 3‑strike policy for AI‑gen infractions + appeal.

---

## 2) iOS App Architecture (SPM‑First)

**Targets**: One app target + Swift Package modules.

### Feature Modules (`Features/*`)

* `Features/HomeForYou`
* `Features/HomeFollowing`
* `Features/Compose`
* `Features/PostDetail`
* `Features/Threading`
* `Features/Profile`
* `Features/Search`
* `Features/Notifications`
* `Features/DMs`

### Shared Kits (`Kits/*`)

* `Kits/DesignSystem` — SF Symbols integration, San Francisco typography hierarchy, system color tokens, Liquid Glass materials, 8-point grid spacing, 44×44pt touch targets, haptic feedback patterns, accessibility support (Dynamic Type, VoiceOver, Reduce Motion).
* `Kits/Networking` — typed client (OpenAPI‑generated), retry/backoff, auth interceptors.
* `Kits/Persistence` — SwiftData models (caches, drafts), background migration helpers.
* `Kits/Auth` — Sign in with Apple, phone verify flows, keychain, device attestation handshake.
* `Kits/Media` — capture, picker, transcoding hints, upload tickets, progress UI.
* `Kits/Analytics` — PostHog wrapper (events, props), Sentry breadcrumbs, privacy guard.
* `Kits/Moderation` — report composer, keyword mute engine, client policy checks.
* `Kits/Verification` — App Attest + DeviceCheck, phone verify UI, risk challenges (hCaptcha view).
* `Kits/Recommender` — client signals (dwell, completions, skips), prefetchers.

**Style**: SwiftUI 6 + `@Observable` models, `NavigationStack`, `ViewThatFits`,
Task‑driven async flows, `Phase` rendering, Structured Concurrency, `Actors` for shared state.

---

## 3) Backend (Supabase‑centric)

* **DB**: Postgres 15/16 (Supabase) with **RLS on**.
* **Object Storage**: Cloudflare **Images** for images; **Stream** for video (transcode/ABR); optional R2 for raw.
* **API**: Supabase **Edge Functions** (Deno) or Cloudflare Workers for write paths (rate‑limited, attestation‑checked). OpenAPI spec for client generation.
* **Queues**: `pgmq` or Supabase Queues: media moderation, link unfurl, recs compute, notifications fanout.
* **Search**: Postgres FTS (trigram + GIN) for MVP; Typesense/Meilisearch optional later.
* **Recs Compute**: Start with lightweight CF: interactions + follow graph; gradually add embeddings and watch features. Store user × post scores in `feed_scores`.
* **Share Previews**: Minimal **Share Renderer** (Edge) serving OG tags for `https://agora.app/p/<id>`.

---

## 4) Identity, Verification & Anti‑Bot

**Auth**:

* **Required**: Sign in with Apple (SWA) **and** phone verification (Twilio Verify).
* **Device Integrity**: Apple **App Attest** + **DeviceCheck** attestation required for posting; renewed periodically.
* **Risk Gates**: New accounts: posting cooldowns, link/media posting blocked for first 24–48h or until higher trust. On spikes, show **hCaptcha** challenge.

**Strikes**:

* 3‑strike for AI‑generated media: each strike removes violating content, escalating time‑outs; 3rd = temp ban + manual review. Simple in‑app appeal (free‑text + attachments).

**Signals captured**: device attestation, SIM/region, IP ASN, disposable email/phone checks, velocity limits, reputation score per **account + device + IP** tuple.

---

## 5) Data Model (ERD + Tables)

> Postgres with RLS. All user‑generated content rows include `author_id`, `created_at`, `visibility`, `is_deleted`, `moderation_state`.

### Core Entities

* `users`: id (uuid), handle (unique), display_name, bio, avatar_url, phone_e164, apple_sub, trust_level (enum), created_at.
* `devices`: id, user_id, app_attest_key_id, devicecheck_token_hash, last_attested_at.
* `sessions`: id, user_id, refresh_token_hash, expires_at, revoked_at.
* `posts`: id (bigint, ULID or snowflake), author_id, text (varchar(70)), link_url, media_bundle_id, reply_to_post_id, quote_post_id, like_count, repost_count, reply_count, visibility, moderation_state.
* `media_bundles`: id, type (image|video), cf_image_id, cf_stream_id, width, height, duration_sec, nsfw_flag, ai_detect_score.
* `follows`: follower_id, followee_id, created_at.
* `likes`: user_id, post_id, created_at.
* `reposts`: user_id, post_id, created_at, is_quote, quote_text (≤70).
* `reports`: id, reporter_id, target_type (post|user), target_id, reason(enum), notes, evidence_urls[], status(enum).
* `moderation_actions`: id, actor_id, subject_type, subject_id, action(enum), notes, created_at.
* `dms_threads`: id, kind (1:1 / group), created_at.
* `dms_participants`: thread_id, user_id, joined_at.
* `dms_messages`: id, thread_id, author_id, text, media_bundle_id, created_at.
* `feed_scores`: user_id, post_id, score (float), reason jsonb, scored_at.
* `notifications`: id, user_id, kind, actor_id, post_id, read_at, created_at.
* `rate_limits`: key, window_start, count.

### Key Indexes (examples)

* `users(handle) unique`, GIN trigram on `users.display_name`.
* `posts(author_id, created_at desc)`, GIN on `to_tsvector('simple', text)`.
* `likes(post_id)`, `likes(user_id, created_at)`.
* `follows(follower_id, followee_id) unique`.
* `feed_scores(user_id, score desc)`.

### RLS Sketches

* `USING (is_deleted = false AND (visibility = 'public'))` on posts for anon;
* Author can `UPDATE/DELETE` own posts: `USING (author_id = auth.uid())`.
* DMs: `dms_messages` `USING EXISTS (SELECT 1 FROM dms_participants dp WHERE dp.thread_id = thread_id AND dp.user_id = auth.uid())`.

---

## 6) API (Minimal)

* `POST /auth/swa/begin`, `POST /auth/swa/finish`
* `POST /verify/phone/start`, `POST /verify/phone/confirm`
* `POST /attest/appattest/verify`
* `GET /feed/for-you` (cursor, soft‑realtime), `GET /feed/following`
* `POST /posts`, `GET /posts/{id}`, `DELETE /posts/{id}`
* `POST /posts/{id}/like` (idempotent), `/repost`, `/quote`, `/reply`
* `GET /profiles/{handle}`, `POST /follow/{userId}`, `DELETE /follow/{userId}`
* `GET /search?q=…` (people + posts)
* `POST /reports`
* `GET /notifications`, `POST /notifications/read`
* `GET /dms/threads`, `POST /dms/threads`, `GET /dms/threads/{id}`, `POST /dms/messages`

All write endpoints require valid session, phone‑verified, recent device attestation, and pass rate‑limits.

---

## 7) Recommendation System v1 (For You)

**Goal**: TikTok‑style reliance on For You, but simple enough for MVP.

**Signals**

* Positive: post views (dwell > x sec), likes, replies, reposts, profile taps, follows after view.
* Negative: rapid scroll (skip), mute/keyword mute, block, report.

**Logic**

1. **Candidate generation**

   * Recent posts from followees of followees (2‑hop), popular in region, author affinity, and topical similarity (simple n‑gram).
2. **Scoring** (weighted linear model)

   * `score = w1*dwell + w2*like + w3*reply + w4*repost + w5*profile_tap - w6*skip - w7*mute - w8*report + freshness_decay`.
3. **Mixing**

   * 70% personalized, 20% explore (long tail), 10% followees.
4. **Feedback loop**

   * Online update of user vector (counts/ratios) + nightly batch refresh of weights.

**No "AI‑content" generated** — ranking uses statistics/ML on metadata, not generative output.

---

## 8) Media Pipeline (Images & 10‑min Video)

* **Upload**: Client requests **direct upload ticket**; uploads to Cloudflare (Images/Stream); gets `media_bundle_id` back.
* **Transcode**: Stream ABR ladder (240p–1080p); poster; thumbnails.
* **Validation**: Size/duration caps, format checks on server; compute **AI‑gen likelihood** + NSFW/violence via third‑party detectors; mark `ai_detect_score` and `nsfw_flag`.
* **Policy**: If `ai_detect_score` > threshold → queue for manual review; if confirmed → strike + takedown.

---

## 9) Moderation & Safety

* **User tools**: Report (reasons: abuse, spam, AI‑gen, NSFW, illegal, other), Block/Mute, Keyword mute.
* **Internal console (v0)**: Simple web admin (Supabase Auth) → queues: New reports, Auto‑flags (NSFW/high ai score), Strikes review, Appeals inbox; actions: remove, strike, timeout, restore.
* **Auto rules**: New accounts cannot DM until N hours and cannot include links/media until trust≥L1.

---

## 10) Notifications

* Push kinds: like, reply, repost, quote, mention, follow, DM.
* Fanout via queue; de‑dupe bursts; quiet hours preference.
* Provider: OneSignal for MVP or native APNs if minimizing deps.

---

## 11) Third‑Party & Apple Services (MVP)

* **Auth**: Sign in with Apple (required)
* **Phone Verify**: Twilio Verify (global), fallback providers later
* **Device Integrity**: App Attest + DeviceCheck
* **Risk Challenge**: hCaptcha iOS SDK
* **Media**: Cloudflare Images & Stream
* **Analytics**: PostHog (self‑hosted or EU/US cloud)
* **Crash**: Sentry
* **Push**: OneSignal (or APNs direct)
* **Error/Logs**: Sentry + Supabase logs; optional Datadog later

---

## 12) Client UX Notes

### Navigation & Layout
* **Tab Bar**: Standard iOS tab bar at bottom (For You, Following, Search, Notifications, Profile) with SF Symbols
* **Navigation**: Large titles on primary screens, standard back gestures, edge-swipe navigation
* **Safe Areas**: All content respects safe area insets, no elements hidden under notch

### Feed Experience
* **For You**: Pull‑to‑refresh with gentle bounce animation, prefetch next 5 posts, progressive media loading
* **Reason Pills**: Apple-style pill design showing recommendation reasons ("Because you liked …")
* **Content Focus**: Posts take center stage with minimal UI chrome, auto-hide toolbar on scroll

### Compose Experience
* **Character Counter**: 70‑char limit with Apple-style counter, inline validation
* **Media Picker**: Native iOS photo picker with SF Symbols, upload progress with haptic feedback
* **Drafts**: Auto-save with Apple-style confirmation, failure retry with encouraging messaging
* **Link Preview**: Native unfurl preview with system share sheet integration

### Accessibility & Inclusivity
* **Dynamic Type**: Full support for all text size preferences, minimum 11pt body text
* **VoiceOver**: Comprehensive labels and hints for all interactive elements
* **Motion**: Respect Reduce Motion setting with cross-fade transitions
* **Contrast**: Support Increase Contrast mode, ensure high contrast ratios

### Animations & Feedback
* **Micro-interactions**: Heart icon filling with quick pop on like, gentle bounce on pull-to-refresh
* **Haptics**: Light tap for interactions, success haptic for confirmations, match intensity to action
* **Performance**: Maintain 60 FPS (120 FPS on ProMotion), lazy loading for media
* **Transitions**: SwiftUI spring animations, contextual transitions between screens

### Error Handling & Recovery
* **Messaging**: Plain language, solution-oriented tone ("Couldn't send. Please check your connection.")
* **Placement**: Error messages near relevant UI areas, clear call-to-action buttons
* **Prevention**: Inline validation, confirmations for destructive actions, soft deletes where possible

---

## 13) Rate Limits (MVP Defaults)

* New accounts (<48h): 5 posts/day, 10 replies/hr, no links/media.
* Verified + 48h: 50 posts/day, replies burst 30/hr; DMs 20/day.
* Per‑device & per‑IP buckets; exponential backoff with Apple-style messaging ("You're posting too fast. Please wait a moment and try again.").

---

## 14) Policy & Age Gate

* **Age**: Recommend **16+** globally for simplicity; can relax to 13+ later with parental/region logic.
* **ToS**: Explicit ban on uploading AI‑generated images/video; 3‑strike enforcement; appeal within app.
* **Privacy**: No sale of data; analytics limited; DM content end‑to‑end encryption later.

---

## 15) Minimal SQL (illustrative)

```sql
create table users (
  id uuid primary key default gen_random_uuid(),
  handle text unique not null check (handle ~ '^[a-z0-9_]{3,15}$'),
  display_name text not null,
  bio text default '',
  avatar_url text,
  apple_sub text unique not null,
  phone_e164 text unique not null,
  trust_level smallint not null default 0,
  created_at timestamptz not null default now()
);

create table posts (
  id bigserial primary key,
  author_id uuid not null references users(id) on delete cascade,
  text varchar(70) not null,
  link_url text,
  media_bundle_id bigint references media_bundles(id),
  reply_to_post_id bigint references posts(id),
  quote_post_id bigint references posts(id),
  like_count int not null default 0,
  repost_count int not null default 0,
  reply_count int not null default 0,
  visibility text not null default 'public',
  moderation_state text not null default 'clean',
  created_at timestamptz not null default now()
);
create index on posts (author_id, created_at desc);
create index on posts using gin (to_tsvector('simple', text));

create table follows (
  follower_id uuid references users(id) on delete cascade,
  followee_id uuid references users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, followee_id)
);

create table likes (
  user_id uuid references users(id) on delete cascade,
  post_id bigint references posts(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);
```

(Additional tables analogous to the ERD above.)

---

## 16) RLS Examples

```sql
alter table posts enable row level security;
create policy public_posts on posts for select using (
  true -- public for MVP (moderation_state != 'removed') in production
);
create policy own_posts_update on posts for update using (
  author_id = auth.uid()
);
```

---

## 17) Delivery Plan (6–8 week MVP)

**Week 1-2**: Auth + phone verify + attestation; Compose + Media upload; Post read/write API; basic Following feed.
**Week 3-4**: For You v1 (signals, scoring, mixing); Profiles; Notifications; Search; Moderation v0; Share Renderer.
**Week 5**: DMs basic; Reports/Strikes; Push polish; rate‑limits.
**Week 6**: QA, perf passes, App Review hardening (Sign in with Apple, content policies), launch batch.

---

## 18) Open Decisions (Defaults proposed)

* **Age gate**: Default 16+ (switchable to 13+).
* **hCaptcha vs Turnstile**: Proposed hCaptcha (iOS SDK).
* **OneSignal vs APNs**: Proposed OneSignal for speed.
* **Typesense** search later if FTS feels weak.
* **Embeddings for recs**: Optional v1.1 — non‑generative, used only for ranking.

---

## 19) iOS Implementation Notes

### Sharing & Universal Links
* Use `ShareLink` + custom `Transferable` for posts; Universal Links to `agora.app/p/<id>` for rich previews
* System share sheet integration with native iOS sharing patterns
* Rich link previews with proper Open Graph metadata

### Media & Performance
* Media cell uses AVFoundation + `AVQueuePlayer` with prewarm; pause off‑screen; picture‑in‑picture disabled for MVP
* Lazy loading for images with progressive enhancement
* Maintain 60 FPS (120 FPS on ProMotion) for smooth scrolling

### Design System Implementation
* SF Symbols for all icons with consistent weight and sizing
* San Francisco font with proper hierarchy (Title, Headline, Body, Footnote)
* 8-point grid spacing throughout all layouts
* 44×44pt minimum touch targets for all interactive elements
* Liquid Glass effects for navigation bars and floating panels

### Testing & Quality
* Strong unit/UI snapshot tests with deterministic timing
* Test on all iPhone sizes with different accessibility settings
* Network via `URLSession` with `AsyncHTTPClient` if needed
* Strict content length enforcement in UI and server

### Accessibility Implementation
* Full Dynamic Type support with minimum 11pt body text
* Comprehensive VoiceOver labels and hints
* Reduce Motion and Increase Contrast mode support
* Safe area insets respected throughout

---

## 20) Event Taxonomy (PostHog)

* `post_view` {post_id, dwell_ms, autoplay}
* `post_like` / `unlike`
* `repost` / `quote`
* `reply_create`
* `profile_view` {author_id}
* `follow` / `unfollow`
* `share` {channel}
* `feed_request` {kind: for_you|following, count}
* `challenge_shown` / `challenge_passed`
* `strike_issued` {reason}

---

## 21) Apple Design Compliance

### Visual Design Standards
* **Icons**: SF Symbols exclusively, no custom graphics or mixed icon styles
* **Typography**: San Francisco system font with proper hierarchy (Title, Headline, Body, Footnote)
* **Colors**: System accent color for primary actions, red for destructive actions, high contrast ratios
* **Spacing**: 8-point grid system, 16pt standard margins, proper safe area insets
* **Materials**: Liquid Glass effects for navigation elements, `.ultraThinMaterial` for overlays

### Interaction Patterns
* **Navigation**: Standard tab bar (For You, Following, Search, Notifications, Profile) with large titles
* **Gestures**: Pull-to-refresh, swipe actions, edge-swipe back, system share sheet
* **Touch Targets**: Minimum 44×44pt for all interactive elements
* **Feedback**: Immediate visual response, haptic feedback, progress indicators

### Motion & Animation
* **Performance**: 60 FPS (120 FPS on ProMotion), lazy loading, smooth transitions
* **Micro-interactions**: Heart fill animation, gentle bounce on refresh, contextual transitions
* **Accessibility**: Respect Reduce Motion setting with cross-fade alternatives
* **SwiftUI**: Use `.animation` with `.easeInOut` or `.spring()` modifiers

### Voice & Tone
* **Language**: Plain, direct communication ("Edit Profile" not "Modify user configuration")
* **Errors**: Solution-oriented messaging ("Couldn't send. Please check your connection.")
* **Consistency**: Friendly but not goofy, helpful but not condescending
* **Inclusive**: Non-gendered terms, considerate language, localization-ready

### Accessibility Requirements
* **Dynamic Type**: Full support with minimum 11pt body text
* **VoiceOver**: Comprehensive labels and hints for all elements
* **Contrast**: Support Increase Contrast mode
* **Motion**: Adapt to Reduce Motion preferences
* **Testing**: Verify on all iPhone sizes with accessibility settings enabled

---

**Done.** Ready to tailor any piece (e.g., stricter RLS, recs scoring function, DM schema) and generate an OpenAPI + SPM skeleton next.
