# Test Data Setup Complete ✅

## What Was Created

### Test Users (5 total)

| Handle | Display Name | Verified | Followers | Trust Level | Specialty |
|--------|-------------|----------|-----------|-------------|-----------|
| **sarah.designer** | Sarah Designer | ✓ | 2,300 | 2 | Design & UX |
| **rocky.test** | Rocky Test User | ✓ | 1,500 | 2 | Engineering |
| **mike.product** | Mike PM | - | 680 | 1 | Product |
| **jane.smith** | Jane Smith | - | 450 | 1 | Development |
| **john.dev** | John Developer | - | 120 | 0 | Junior Dev |

**Your Account**: You're now following all 5 test users ✅

### Test Posts (28 total)

**Engagement Distribution**:
- 🔥 **Viral** (500+ likes): 1 post
- 📈 **High engagement** (150-300 likes): 7 posts
- 💬 **Moderate** (60-150 likes): 12 posts
- 🌱 **Growing** (<60 likes): 8 posts

**Content Mix**:
- Tech/Engineering: 40%
- Design/UX: 30%
- Product/Strategy: 20%
- Casual/Lifestyle: 10%

**Post Features**:
- ✅ Varied lengths (short punchy to detailed)
- ✅ Some with links, some without
- ✅ Realistic engagement (likes, reposts, comments)
- ✅ Natural conversation tone
- ✅ Spread over last 4 days
- ✅ Different posting times (realistic activity)

### Top Quality Posts (By Feed Algorithm)

Based on formula: `quality_score = likes + (4 × reposts) + (5 × comments)`

| Rank | Quality Score | Author | Preview | Engagement |
|------|---------------|---------|---------|------------|
| 1 | 1093 | mike.product | "100k users announcement" | 512 likes, 89 reposts, 45 comments |
| 2 | 727 | sarah.designer | "Ship v1 imperfect" | 289 likes, 67 reposts, 34 comments |
| 3 | 702 | jane.smith | "Unit tests hot take" | 187 likes, 45 reposts, 67 comments |
| 4 | 543 | mike.product | "Features don't ship" | 245 likes, 52 reposts, 18 comments |
| 5 | 412 | sarah.designer | "Users don't care about tech stack" | 201 likes, 34 reposts, 15 comments |

**These posts WILL appear in your For You feed** ranked by quality + recency + personalization!

---

## How to Test

### 1. Following Feed (Chronological)

**Expected Behavior**:
- Shows 28 posts from your 5 followed users
- Ordered by most recent first
- Sarah's "major redesign" post (2 hours ago) should be at top
- No recommendation algorithm - pure chronological

**Test in App**:
```
1. Run app (⌘R in Xcode)
2. Tap "Following" tab
3. Should see posts in reverse chronological order
```

### 2. For You Feed (Recommended)

**Expected Behavior**:
- Shows popular posts ranked by quality score
- Mike's "100k users" post should rank very high (quality score: 1093)
- Sarah's motivational posts should appear prominently (verified + popular)
- Mix of recency and popularity
- Some "explore" posts (5% epsilon) for discovery

**Test in App**:
```
1. Run app
2. Tap "For You" tab (default)
3. Should see high-quality posts from followed users
4. Order: viral posts → popular → recent → explore
```

**Quality Score Rankings**:
1. Mike: "100k users" - 1093 points 🔥
2. Sarah: "Ship v1" - 727 points
3. Jane: "Unit tests" - 702 points (controversial = lots of comments)
4. Mike: "Features don't ship" - 543 points
5. Sarah: "Tech stack" - 412 points

### 3. Search (People Discovery)

**Test Queries**:
- `rocky` → finds "Rocky Test User" (not you!)
- `@sarah.designer` → exact match, score = 1.0
- `designer` → finds Sarah by display name
- `dev` → finds both "John Developer" and "Jane" (dev community)
- `product` → finds Mike PM

---

## Realistic Test Scenarios

### Scenario 1: Fresh User Experience

**Setup**: You're following 5 people, haven't engaged much yet

**Expected For You Feed**:
1. Viral post (Mike's 100k announcement) - Everyone sees this
2. Popular verified user posts (Sarah's design insights)
3. Recent high-engagement posts (Jane's hot takes)
4. Mix from people you follow
5. 5% explore posts (discover new content)

### Scenario 2: Engaged User

**Setup**: You've liked 5 posts (already done!)

**Expected For You Feed**:
- More posts similar to what you liked
- Personalization kicks in
- Authors you engage with rank higher
- Topics you interact with appear more

### Scenario 3: Following Feed

**Setup**: Following 5 users

**Expected**:
- Pure chronological stream
- All 28 posts appear
- Most recent at top
- No algorithmic ranking

---

## Feed Algorithm Insights

### What Makes Posts Rank Higher in For You

**Quality Score** (60% weight):
- **Comments** (5× multiplier) - Most valuable signal
- **Reposts** (4× multiplier) - Strong endorsement
- **Likes** (1× multiplier) - Baseline engagement

**Relationship Score** (25% weight):
- Posts from people you follow get 0.2 boost
- Authors you've engaged with rank higher
- Your follow graph influences recommendations

**Similarity Score** (15% weight):
- Posts similar to ones you've liked
- Topic/content matching (future: embeddings)

**Freshness Decay**:
- Posts decay with τ = 12 hours
- Recent posts get temporary boost
- Old viral posts can still rank if quality is exceptional

**Exploration** (5% epsilon):
- Random posts for discovery
- Max 3 in top 10 slots
- 0.25 novelty bonus
- Trust level 0+ can appear (inclusive)

### Diversity Rules

- No back-to-back posts from same author
- Author repeat window: 5 posts
- Prevents feed from feeling spammy

---

## Verification Queries

**Check Following Feed Returns Data**:
```sql
SELECT count(*) FROM posts 
WHERE author_id IN (
  SELECT followee_id FROM follows 
  WHERE follower_id = 'd557ffae-107d-4871-a33b-722c5b7b7d68'
);
-- Expected: 28 posts
```

**Check Top Quality Posts**:
```sql
SELECT 
  left(text, 40) as preview,
  (like_count + 4*repost_count + 5*reply_count) as quality_score
FROM posts 
ORDER BY quality_score DESC 
LIMIT 5;
-- Expected: 1093, 727, 702, 543, 412
```

**Check You're Following Test Users**:
```sql
SELECT u.handle, u.display_name, u.verified
FROM follows f
JOIN users u ON f.followee_id = u.id
WHERE f.follower_id = 'd557ffae-107d-4871-a33b-722c5b7b7d68'
ORDER BY u.followers_count DESC;
-- Expected: 5 users (sarah, rocky, mike, jane, john)
```

---

## What Makes These Posts Realistic

### 1. Natural Language
- Conversational tone ("lol", "tbh", emojis)
- Industry-specific terminology
- Personal anecdotes and experiences
- Mix of serious and casual

### 2. Engagement Patterns
- Popular users (Sarah, Rocky) get more likes
- Controversial takes (Jane's unit test post) get more comments
- Announcements (Mike's 100k users) go viral
- Junior devs (John) get less engagement but still valuable

### 3. Content Variety
- Technical deep dives
- Hot takes and opinions
- Product insights
- Learning moments
- Celebrations and milestones
- Weekend casual posts

### 4. Timing Realism
- Posts spread over 4 days
- Different hours (morning updates, evening thoughts)
- Weekend activity (lower engagement)
- Weekday peak times (higher engagement)

### 5. Link Integration
- Some posts have external links
- Blog posts, articles, resources
- Not every post needs a link (feels natural)

---

## Expected Feed Behavior

### For You Feed Order (Approximate)

**Top of Feed** (Quality + Recency):
1. Mike's "100k users" announcement (viral, recent)
2. Sarah's "Ship v1 imperfect" (high quality, motivational)
3. Jane's "Unit tests" hot take (controversial, lots of discussion)
4. Sarah's "AI content" post (very recent, verified author)
5. Mike's "Features don't ship" (short viral quote)

**Middle of Feed** (Balanced):
6. Sarah's various design insights
7. Rocky's engineering posts
8. Jane's development experiences
9. Mike's product wisdom

**Bottom of Feed** (Older/Lower Engagement):
10. John's learning posts (valuable but junior dev)
11. Weekend casual posts
12. Older technical posts

**Explore Slots** (5% random):
- Occasionally see posts from outside your network
- Helps discovery

### Following Feed Order

**Purely Chronological**:
1. Sarah's "major redesign" (2 hours ago)
2. Rocky's "CI/CD pipeline" (4 hours ago)  
3. Sarah's "AI content" (5 hours ago)
4. Mike's "user research" (6 hours ago)
... and so on

---

## Testing Checklist

### Feed Testing
- [ ] Open app and check For You feed shows posts
- [ ] Verify top posts are high-quality (100k announcement at/near top)
- [ ] Switch to Following feed
- [ ] Verify posts are in chronological order
- [ ] Pull to refresh works on both feeds
- [ ] Scroll to load more posts
- [ ] Like a post and verify count increases
- [ ] Repost a post and verify it works

### Search Testing  
- [ ] Search for `rocky` → finds Rocky Test User
- [ ] Search for `@sarah.designer` → exact match
- [ ] Search for `designer` → finds Sarah
- [ ] Search for `sitch` → returns empty (you're excluded)
- [ ] Verify empty state is centered
- [ ] Tap a user → navigate to their profile

### Profile Testing
- [ ] Tap on a test user in search
- [ ] Should see their profile with posts
- [ ] Follow/unfollow button works
- [ ] Their posts appear in Following feed after following

---

## Current State Summary

✅ **5 test users created** (various popularity levels)  
✅ **28 realistic posts created** (tech, design, product content)  
✅ **You're following all 5 users** (posts appear in Following feed)  
✅ **Engagement signals created** (likes, impressions, events)  
✅ **Quality scores distributed** (1093 down to 31)  
✅ **Both feeds should work** (For You + Following)  
✅ **Search is functional** (find users by handle/name)  

---

## Run the App Now!

```bash
cd /Users/roscoeevans/Developer/Agora
open Agora.xcodeproj
# Press ⌘R to run
```

You should see:
- **For You Feed**: Populated with 28 high-quality posts
- **Following Feed**: Same 28 posts in chronological order
- **Search**: Find all 5 test users (excluding yourself)

The test data is production-quality and will help you test:
- Feed ranking algorithm
- Engagement features (likes, reposts)
- User discovery (search)
- Profile views
- Following relationships

**Everything is ready to test! 🚀**



