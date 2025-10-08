# Recommender Kit

The Recommender kit provides For You feed recommendation functionality for the Agora iOS app.

## Overview

This module handles:
- User interaction signal collection
- Feed mixing and UI arrangement
- Content diversity and quality filtering
- Recency boosting for fresh content
- Analytics integration for recommendation signals

## Components

### SignalCollector
Tracks user interactions for recommendation signals.

```swift
let signalCollector = SignalCollector.shared

// Track post interactions
signalCollector.trackPostView(postId: "post123", dwellTime: 5.2, feedPosition: 3)
signalCollector.trackPostLike(postId: "post123", feedPosition: 3)
signalCollector.trackPostSkip(postId: "post456", reason: .notInterested, feedPosition: 4)

// Track user interactions
signalCollector.trackUserFollow(userId: "user789")
signalCollector.trackProfileView(userId: "user789", dwellTime: 10.5)

// Track content actions
signalCollector.trackPostShare(postId: "post123", method: "copy_link")
signalCollector.trackContentReport(postId: "post456", reason: "spam")
```

### FeedMixer
Handles UI-level feed mixing (all scoring happens server-side).

```swift
let feedMixer = FeedMixer.shared

// Create feed items
let posts = [
    PostItem(id: "1", authorId: "user1", content: "Great post!", score: 0.9, timestamp: Date()),
    PostItem(id: "2", authorId: "user2", content: "Another post", score: 0.8, timestamp: Date())
]

let ads = [
    AdItem(id: "ad1", campaignId: "camp1", content: "Check this out!", targetingScore: 0.7, bidAmount: 1.5)
]

let suggestions = [
    SuggestionItem(id: "sug1", type: .followUser, userId: "user3", title: "Follow @user3", description: "You might know them", relevanceScore: 0.6)
]

// Mix feed
let mixedFeed = feedMixer.mixFeed(posts: posts, ads: ads, suggestions: suggestions)

// Apply filters
let qualityFiltered = feedMixer.filterByQuality(posts: posts)
let diverseFiltered = feedMixer.applyDiversityFilter(posts: qualityFiltered)
let recencyBoosted = feedMixer.applyRecencyBoost(posts: diverseFiltered)
```

## Signal Types

### Interaction Signals
- **View**: Post viewed with dwell time
- **Like/Unlike**: Post engagement
- **Repost**: Content sharing
- **Skip**: Content skipped with reason
- **Share**: External sharing
- **Report/Hide**: Negative feedback

### User Signals
- **Follow/Unfollow**: User relationship changes
- **Profile View**: Profile engagement

### Skip Reasons
- Not interested
- Too similar to previous content
- Inappropriate content
- Spam content
- Fast scroll (low engagement)
- Low quality content

## Feed Item Types

### PostItem
Regular user-generated content with server-side scoring.

```swift
let post = PostItem(
    id: "post123",
    authorId: "user456",
    content: "This is a great post!",
    score: 0.85, // Server-calculated score
    timestamp: Date(),
    mediaCount: 2,
    isRepost: false
)
```

### AdItem
Sponsored content with targeting and bid information.

```swift
let ad = AdItem(
    id: "ad123",
    campaignId: "campaign456",
    content: "Check out our product!",
    targetingScore: 0.9,
    bidAmount: 2.50
)
```

### SuggestionItem
User suggestions and recommendations.

```swift
let suggestion = SuggestionItem(
    id: "suggestion123",
    type: .followUser,
    userId: "user789",
    title: "Follow @user789",
    description: "Based on your interests",
    relevanceScore: 0.7
)
```

## Configuration

### Feed Mixing Config
Customize feed mixing behavior:

```swift
let config = FeedMixingConfig(
    maxAdFrequency: 5,        // 1 ad per 5 posts
    minPostsBetweenAds: 3,    // Minimum posts between ads
    suggestionFrequency: 10,   // 1 suggestion per 10 posts
    diversityThreshold: 0.3,   // Minimum diversity score
    recencyWeight: 0.2,        // Boost for recent content
    qualityThreshold: 0.1      // Minimum quality score
)
```

## Architecture

### Signal Flow
1. User interacts with content
2. SignalCollector captures interaction
3. Analytics event is tracked
4. Signal is sent to recommendation service
5. Server updates user model and content scores

### Feed Generation
1. Server provides scored content
2. FeedMixer applies UI-level filtering
3. Content is mixed with ads and suggestions
4. Diversity and quality filters are applied
5. Final feed is presented to user

## Dependencies

- Analytics (for event tracking)
- Networking (for API communication)
- UIKit (for device context)
- Foundation

## Usage

Import the module in your Swift files:

```swift
import Recommender
```

## Testing

Run tests using:

```bash
swift test --package-path Packages/Kits/Recommender
```

## Integration

### SwiftUI Integration
```swift
struct ForYouFeedView: View {
    @State private var feedItems: [FeedItemType] = []
    
    var body: some View {
        LazyVStack {
            ForEach(feedItems.indices, id: \.self) { index in
                let item = feedItems[index]
                
                switch item {
                case .post(let post):
                    PostView(post: post)
                        .onAppear {
                            SignalCollector.shared.trackPostView(
                                postId: post.id,
                                dwellTime: 0, // Track actual dwell time
                                feedPosition: index
                            )
                        }
                        .onTapGesture {
                            SignalCollector.shared.trackPostLike(
                                postId: post.id,
                                feedPosition: index
                            )
                        }
                
                case .ad(let ad):
                    AdView(ad: ad)
                
                case .suggestion(let suggestion):
                    SuggestionView(suggestion: suggestion)
                
                case .separator(let separator):
                    SeparatorView(separator: separator)
                }
            }
        }
    }
}
```

## Privacy & Ethics

The Recommender kit is designed with privacy in mind:
- Signals are anonymized and aggregated
- No personal information is stored in signals
- Users can opt out of personalization
- Transparent about data usage
- Compliant with privacy regulations

## Performance

- Efficient signal batching
- Minimal memory footprint
- Background processing for heavy operations
- Optimized for smooth scrolling
- Lazy loading of feed content