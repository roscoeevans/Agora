import XCTest
@testable import Recommender

final class RecommenderTests: XCTestCase {
    
    func testRecommenderModuleExists() {
        let recommender = Recommender.shared
        XCTAssertNotNil(recommender)
    }
    
    func testSignalCollectorInitialization() {
        let signalCollector = SignalCollector.shared
        XCTAssertNotNil(signalCollector)
    }
    
    func testFeedMixerInitialization() {
        let feedMixer = FeedMixer.shared
        XCTAssertNotNil(feedMixer)
    }
    
    func testDeviceContextCreation() {
        let context = DeviceContext()
        
        XCTAssertNotNil(context.timeOfDay)
        XCTAssertTrue(["morning", "afternoon", "evening", "night"].contains(context.timeOfDay))
        XCTAssertNotNil(context.networkType)
        XCTAssertNotNil(context.isLowPowerMode)
    }
    
    func testSignalMetadataCreation() {
        let metadata = SignalMetadata(
            sessionId: "test-session",
            feedPosition: 5,
            feedType: "for_you"
        )
        
        XCTAssertEqual(metadata.sessionId, "test-session")
        XCTAssertEqual(metadata.feedPosition, 5)
        XCTAssertEqual(metadata.feedType, "for_you")
        XCTAssertNotNil(metadata.timestamp)
        XCTAssertNotNil(metadata.deviceContext)
    }
    
    func testCollectedSignalCreation() {
        let signal = InteractionSignal.like(postId: "post123")
        let metadata = SignalMetadata(sessionId: "test-session")
        let collectedSignal = CollectedSignal(signal: signal, metadata: metadata)
        
        if case .like(let postId) = collectedSignal.signal {
            XCTAssertEqual(postId, "post123")
        } else {
            XCTFail("Expected like signal")
        }
        
        XCTAssertEqual(collectedSignal.metadata.sessionId, "test-session")
    }
    
    func testPostItemCreation() {
        let post = PostItem(
            id: "post123",
            authorId: "user456",
            content: "Test post content",
            score: 0.85,
            timestamp: Date(),
            mediaCount: 2,
            isRepost: false
        )
        
        XCTAssertEqual(post.id, "post123")
        XCTAssertEqual(post.authorId, "user456")
        XCTAssertEqual(post.content, "Test post content")
        XCTAssertEqual(post.score, 0.85)
        XCTAssertEqual(post.mediaCount, 2)
        XCTAssertFalse(post.isRepost)
        XCTAssertNil(post.originalPostId)
    }
    
    func testAdItemCreation() {
        let ad = AdItem(
            id: "ad123",
            campaignId: "campaign456",
            content: "Test ad content",
            targetingScore: 0.9,
            bidAmount: 1.50
        )
        
        XCTAssertEqual(ad.id, "ad123")
        XCTAssertEqual(ad.campaignId, "campaign456")
        XCTAssertEqual(ad.content, "Test ad content")
        XCTAssertEqual(ad.targetingScore, 0.9)
        XCTAssertEqual(ad.bidAmount, 1.50)
    }
    
    func testSuggestionItemCreation() {
        let suggestion = SuggestionItem(
            id: "suggestion123",
            type: .followUser,
            userId: "user789",
            title: "Follow @user789",
            description: "You might know this person",
            relevanceScore: 0.7
        )
        
        XCTAssertEqual(suggestion.id, "suggestion123")
        XCTAssertEqual(suggestion.type, .followUser)
        XCTAssertEqual(suggestion.userId, "user789")
        XCTAssertEqual(suggestion.title, "Follow @user789")
        XCTAssertEqual(suggestion.description, "You might know this person")
        XCTAssertEqual(suggestion.relevanceScore, 0.7)
    }
    
    func testFeedMixingConfigDefaults() {
        let config = FeedMixingConfig.default
        
        XCTAssertEqual(config.maxAdFrequency, 5)
        XCTAssertEqual(config.minPostsBetweenAds, 3)
        XCTAssertEqual(config.suggestionFrequency, 10)
        XCTAssertEqual(config.diversityThreshold, 0.3)
        XCTAssertEqual(config.recencyWeight, 0.2)
        XCTAssertEqual(config.qualityThreshold, 0.1)
    }
    
    func testFeedMixingBasic() {
        let feedMixer = FeedMixer.shared
        
        let posts = [
            PostItem(id: "1", authorId: "user1", content: "Post 1", score: 0.9, timestamp: Date()),
            PostItem(id: "2", authorId: "user2", content: "Post 2", score: 0.8, timestamp: Date()),
            PostItem(id: "3", authorId: "user3", content: "Post 3", score: 0.7, timestamp: Date())
        ]
        
        let mixedFeed = feedMixer.mixFeed(posts: posts)
        
        XCTAssertEqual(mixedFeed.count, 3) // Should have 3 posts
        
        // Check that posts are sorted by score
        if case .post(let firstPost) = mixedFeed[0] {
            XCTAssertEqual(firstPost.score, 0.9)
        } else {
            XCTFail("Expected first item to be a post")
        }
    }
    
    func testFeedMixingWithAds() {
        let feedMixer = FeedMixer.shared
        
        let posts = Array(1...10).map { i in
            PostItem(id: "\(i)", authorId: "user\(i)", content: "Post \(i)", score: Double(10 - i) / 10, timestamp: Date())
        }
        
        let ads = [
            AdItem(id: "ad1", campaignId: "camp1", content: "Ad 1", targetingScore: 0.8, bidAmount: 2.0)
        ]
        
        let mixedFeed = feedMixer.mixFeed(posts: posts, ads: ads)
        
        // Should have posts + ads
        XCTAssertGreaterThan(mixedFeed.count, posts.count)
        
        // Check that at least one ad is included
        let hasAd = mixedFeed.contains { item in
            if case .ad = item { return true }
            return false
        }
        XCTAssertTrue(hasAd)
    }
    
    func testQualityFiltering() {
        let feedMixer = FeedMixer.shared
        
        let posts = [
            PostItem(id: "1", authorId: "user1", content: "High quality", score: 0.8, timestamp: Date()),
            PostItem(id: "2", authorId: "user2", content: "Low quality", score: 0.05, timestamp: Date()),
            PostItem(id: "3", authorId: "user3", content: "Medium quality", score: 0.5, timestamp: Date())
        ]
        
        let filteredPosts = feedMixer.filterByQuality(posts: posts)
        
        // Should filter out the low quality post (score < 0.1)
        XCTAssertEqual(filteredPosts.count, 2)
        XCTAssertFalse(filteredPosts.contains { $0.id == "2" })
    }
    
    func testDiversityFilter() {
        let feedMixer = FeedMixer.shared
        
        let posts = [
            PostItem(id: "1", authorId: "user1", content: "Post 1", score: 0.9, timestamp: Date()),
            PostItem(id: "2", authorId: "user1", content: "Post 2", score: 0.8, timestamp: Date()),
            PostItem(id: "3", authorId: "user1", content: "Post 3", score: 0.7, timestamp: Date()), // Should be filtered
            PostItem(id: "4", authorId: "user2", content: "Post 4", score: 0.6, timestamp: Date())
        ]
        
        let diversePosts = feedMixer.applyDiversityFilter(posts: posts)
        
        // Should limit consecutive posts from same author
        XCTAssertLessThan(diversePosts.count, posts.count)
    }
    
    func testRecencyBoost() {
        let feedMixer = FeedMixer.shared
        
        let now = Date()
        let oldPost = PostItem(
            id: "old",
            authorId: "user1",
            content: "Old post",
            score: 0.5,
            timestamp: now.addingTimeInterval(-48 * 3600) // 48 hours ago
        )
        
        let recentPost = PostItem(
            id: "recent",
            authorId: "user2",
            content: "Recent post",
            score: 0.5,
            timestamp: now.addingTimeInterval(-1 * 3600) // 1 hour ago
        )
        
        let boostedPosts = feedMixer.applyRecencyBoost(posts: [oldPost, recentPost])
        
        // Recent post should have higher score after boost
        let boostedRecentPost = boostedPosts.first { $0.id == "recent" }!
        let boostedOldPost = boostedPosts.first { $0.id == "old" }!
        
        XCTAssertGreaterThan(boostedRecentPost.score, boostedOldPost.score)
    }
    
    func testSkipReasons() {
        let reasons = SkipReason.allCases
        
        XCTAssertTrue(reasons.contains(.notInterested))
        XCTAssertTrue(reasons.contains(.tooSimilar))
        XCTAssertTrue(reasons.contains(.inappropriate))
        XCTAssertTrue(reasons.contains(.spam))
        XCTAssertTrue(reasons.contains(.fastScroll))
        XCTAssertTrue(reasons.contains(.lowQuality))
    }
}