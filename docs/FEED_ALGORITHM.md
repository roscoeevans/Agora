# Agora Feed Recommendation Algorithm

## Overview

Agora uses a sophisticated recommendation system that balances content quality, social relevance, freshness, and exploration. The algorithm is designed to:

1. **Avoid filter bubbles** - Light follow influence (20% boost) with exploration
2. **Prevent repetition** - 7-day suppression window ensures no duplicate posts
3. **Encourage discovery** - 12% of feed is exploratory content via multi-armed bandits
4. **Stay transparent** - Every post includes `reasons[]` explaining why it appears
5. **Be tunable** - All weights centralized in `reco_config` table

## Architecture

### Core Components

1. **Candidate Generation** - Three pools of potential posts
2. **Suppression** - Filter out recently seen posts (7 days)
3. **Scoring** - Rank posts by multiple signals
4. **Exploration** - Thompson Sampling for adventurous picks
5. **Diversity** - Author variety and follow catch-up slots
6. **Impression Logging** - Track what was shown for analytics

### Data Flow

```
User Request
    ↓
Load Config (reco_config table)
    ↓
Generate Candidates:
  - Followees' recent posts (48h)
  - Global quality posts (48h)
  - Explore pool (quality posts outside user's graph)
    ↓
Filter Suppression (7-day window via post_impressions)
    ↓
Score All Candidates:
  - Freshness decay (exponential)
  - Quality (weighted engagement)
  - Relation (follow boost + graph proximity)
  - Similarity (placeholder for future)
    ↓
Apply Exploration (Thompson Sampling + novelty bonus)
    ↓
Mix & Diversify:
  - Avoid back-to-back same author
  - Follow catch-up slots (every 12 posts)
  - Explore quota (12% of feed)
    ↓
Log Impressions (post_impressions with reasons)
    ↓
Return Feed (posts with score, reasons[], explore flag)
```

## Scoring Formula

### Main Score

```
score = freshness × (α·quality + β·relation + γ·similarity)
```

Where:
- **freshness** = exp(-age_hours / tau_hours)
- **alpha (α)** = 0.6 (quality weight)
- **beta (β)** = 0.25 (relation weight)
- **gamma (γ)** = 0.15 (similarity weight)

### Quality Signal

```
quality = 
    1.0  × likes +
    5.0  × comments +
    4.0  × reposts +
    1.5  × expands +
    3.0  × profile_visits +
    8.0  × follow_after_views +
  -12.0  × hides +
  -25.0  × mutes +
  -50.0  × blocks
```

### Relation Signal

```
relation = 
    0.2 (if user follows author) +
    graph_proximity_weight (from graph_proximity table)
```

### Similarity Signal

Placeholder (0.0 for MVP). Future: cosine similarity over follow/like vectors.

## Exploration: Multi-Armed Bandits

### Thompson Sampling

For each explore candidate, we:
1. Look up `bandit_stats` (successes, trials)
2. Sample from Beta(α₀ + successes, β₀ + trials - successes)
3. Add novelty bonus for unseen posts
4. Rank by sampled value + bonus

**Priors:**
- α₀ = 1.0 (optimistic uniform)
- β₀ = 3.0 (slightly conservative)

**Novelty Bonus:** 0.25 for posts with no bandit history

### Recording Outcomes

**Success** (call `bandit_record_success('post', post_id, 1)`):
- expand (>2s dwell OR explicit expand action)
- comment
- repost
- profile_visit
- follow_after_view
- like (lighter weight in practice)

**Failure** (call `bandit_record_success('post', post_id, 0)`):
- hide
- mute
- block

## Configuration Tuning

All algorithm knobs live in the `reco_config` table as JSONB:

### Current Staging Config (v2025-10-12a)

```json
{
  "freshness": {
    "tau_hours": 12
  },
  "weights": {
    "like": 1.0,
    "comment": 5.0,
    "repost": 4.0,
    "expand": 1.5,
    "profile_visit": 3.0,
    "follow_after_view": 8.0,
    "hide": -12.0,
    "mute": -25.0,
    "block": -50.0
  },
  "mixing": {
    "alpha_quality": 0.6,
    "beta_relation": 0.25,
    "gamma_similarity": 0.15
  },
  "follow": {
    "boost": 0.2,
    "catchup_every": 12,
    "min_quality_floor": 0
  },
  "explore": {
    "curiosity_ratio": 0.12,
    "epsilon": 0.05,
    "novelty_bonus": 0.25,
    "min_trust_for_explore": 0,
    "max_in_top10": 3
  },
  "diversity": {
    "avoid_back_to_back_author": true,
    "topic_penalty": 0.0,
    "author_repeat_window": 5
  },
  "suppression": {
    "dedupe_days": 7
  },
  "quality_pool": {
    "lookback_hours": 48,
    "limit": 5000
  }
}
```

### Updating Configuration

1. Insert new row with incremented version:
   ```sql
   INSERT INTO reco_config (env, version, is_active, description, config)
   VALUES ('staging', '2025-10-12b', false, 'Increased explore ratio', '{...}'::jsonb);
   ```

2. Activate new version (deactivates all others):
   ```sql
   SELECT activate_reco_config('staging', '2025-10-12b');
   ```

3. Changes take effect immediately (no Edge Function redeploy needed)

### Tuning Guide

**To increase exploration:**
- Raise `explore.curiosity_ratio` (0.12 → 0.15)
- Raise `explore.novelty_bonus` (0.25 → 0.35)
- Lower `follow.boost` (0.2 → 0.15)

**To favor quality:**
- Raise `mixing.alpha_quality` (0.6 → 0.7)
- Lower `mixing.beta_relation` (0.25 → 0.2)

**To boost follows more:**
- Raise `follow.boost` (0.2 → 0.3)
- Lower `follow.catchup_every` (12 → 8)

**To reduce recency bias:**
- Raise `freshness.tau_hours` (12 → 18)

## Key Tables

### `post_impressions`
Tracks every impression shown to users. Used for:
- 7-day suppression (no repeats)
- Analytics (CTR, dwell, conversion)
- A/B testing (by `page_id`)

**Retention:** 90 days (auto-pruned daily via pg_cron)

### `post_events`
Event log for all user interactions. Used for:
- Trust-weighted quality (Phase 2)
- Bandit feedback
- Abuse detection

### `post_aggregates`
Materialized view refreshed every 2 minutes. Pre-computed engagement counts for fast scoring.

### `graph_proximity`
Cached social graph distances. Currently empty; can be populated by batch job computing:
- Direct follow: weight = 0.5
- Follow-of-follow (FOAF): weight = 0.2
- Recent interaction: weight += 0.1

### `bandit_stats`
Trial and success counts for Thompson Sampling. Updated via:
- `bandit_record_trial('post', post_id)` - when explore item shown
- `bandit_record_success('post', post_id, 1)` - on positive signal
- `bandit_record_success('post', post_id, 0)` - on negative signal

## Transparent Reasoning

Every post in the feed includes a `reasons[]` array:

```json
{
  "id": "...",
  "text": "...",
  "score": 12.45,
  "reasons": [
    { "signal": "fresh", "weight": 0.89 },
    { "signal": "quality", "weight": 7.2 },
    { "signal": "relation", "weight": 0.05 },
    { "signal": "similarity", "weight": 0.0 },
    { "signal": "follow_boost", "weight": 0.2 }
  ],
  "explore": false
}
```

**UI Ideas (future):**
- "Because you liked similar posts" (quality signal high)
- "From people you follow" (relation + follow_boost)
- "Taking a chance on something new ✨" (explore = true)

## Performance Targets

- **Feed load latency:** <200ms p95
- **No duplicates:** 0% within 7 days per user
- **Explore ratio:** 12% ±2%
- **Bandit success rate:** >15% (vs ~30% for main feed)

## Future Enhancements

### Phase 2: Trust-Weighted Quality
Replace raw engagement counts with trust-weighted sums:
```sql
CREATE MATERIALIZED VIEW post_aggregates_v2 AS
SELECT
  post_id,
  SUM(CASE WHEN type = 'like' THEN u.trust_level * 1.0 ELSE 0 END) AS weighted_likes,
  ...
FROM post_events e
JOIN users u ON e.user_id = u.id
GROUP BY post_id;
```

### Phase 3: Similarity via Embeddings
- Compute user vectors (follow + like history)
- Store in `user_similarities` table
- Join into scoring as `gamma * sim`

### Phase 4: Explore Lanes
Multiple explore strategies:
- New authors lane (authors with <N followers)
- Cross-community lane (low overlap with user's graph)
- Long-tail topic lane (de-popularized topics)
- Fresh wildcard lane (posts <30m old, high author trust)

Each lane gets its own bandit stats and quota.

## Monitoring & Metrics

Track these in PostHog/analytics:

- `feed_refresh_completed` → post_count, explore_count
- `explore_impression` → post_id, position, reasons
- `explore_success` → post_id, action (like, comment, repost, etc.)
- `explore_failure` → post_id, action (hide, mute, block)

Compute daily:
- Explore success rate by bucket (novelty, FOAF, cross-community)
- 7-day retention lift for users with >X% explore exposure
- Diversity score (unique authors per 20 posts)

## Troubleshooting

**Feed returns no items:**
- Check if user has seen everything (suppression too aggressive)
- Check `post_aggregates` is refreshing (should be every 2 min)
- Verify staging has recent posts (created_at within 48h)

**Too many explore items:**
- Lower `explore.curiosity_ratio` in config
- Check diversity logic isn't filtering too aggressively

**Same posts repeating:**
- Verify `post_impressions` inserts are succeeding
- Check suppression window (`suppression.dedupe_days`)

**Slow feed loads:**
- Check indexes on `post_impressions(user_id, created_at)`
- Check `post_aggregates` materialized view size
- Consider partitioning `post_impressions` by month

## References

- [Multi-Armed Bandit Tutorial](https://en.wikipedia.org/wiki/Thompson_sampling)
- [TikTok Recommendation System](https://newsroom.tiktok.com/en-us/how-tiktok-recommends-videos-for-you)
- [Reddit's Exploration Strategy](https://www.reddit.com/r/MachineLearning/comments/ihk3ai/)

