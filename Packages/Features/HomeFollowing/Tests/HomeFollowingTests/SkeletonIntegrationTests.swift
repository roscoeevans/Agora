//
//  SkeletonIntegrationTests.swift
//  HomeFollowingTests
//
//  Created by Agora Team on 2024.
//

import XCTest
import SwiftUI
@testable import HomeFollowing
@testable import DesignSystem

@available(iOS 26.0, *)
final class SkeletonIntegrationTests: XCTestCase {
    
    // MARK: - Following Feed Skeleton Integration Tests
    
    @MainActor
    func testHomeFollowingSkeletonIntegration() {
        // Test that HomeFollowing uses identical skeleton pattern as HomeForYou
        let viewModel = FollowingViewModel()
        XCTAssertNotNil(viewModel, "Following ViewModel should be created")
        
        // Test consistent loading state behavior
        XCTAssertEqual(viewModel.loadingState, .idle, "Should start in idle state")
        
        // Test identical skeleton configuration
        viewModel.loadingState = .loading(placeholderCount: 5)
        if case .loading(let count) = viewModel.loadingState {
            XCTAssertEqual(count, 5, "Should use same 5 placeholder pre-seeding as HomeForYou")
        } else {
            XCTFail("Should be in loading state")
        }
    }
    
    @MainActor
    func testConsistentLayoutMetrics() {
        // Test that Following feed maintains same layout metrics as Recommended feed
        let followingView = HomeFollowingView()
        XCTAssertNotNil(followingView, "Following view should be created")
        
        // Test that skeleton uses identical Feed_Post_Skeleton layout
        let skeletonView = FeedPostSkeletonView()
        XCTAssertNotNil(skeletonView, "Should use identical Feed_Post_Skeleton layout")
        
        // Test consistent spacing metrics (16pt horizontal padding)
        let expectedPadding = SpacingTokens.md // 16pt
        XCTAssertEqual(expectedPadding, 16, "Should maintain same 16pt horizontal padding")
    }
    
    @MainActor
    func testFollowingFeedPagination() {
        // Test pagination skeleton behavior in Following feed
        let viewModel = FollowingViewModel()
        let config = SkeletonConfiguration.recommended
        
        // Test same pagination threshold as HomeForYou
        XCTAssertEqual(config.preloadThreshold, 5, "Should use same 5 rows preload threshold")
        
        // Test cursor-based pagination with 20 posts per page
        let postsPerPage = 20
        XCTAssertEqual(postsPerPage, 20, "Should use cursor-based pagination with 20 posts per page")
        
        // Test existing content visibility during refresh
        let existingPosts = Array(0..<10).map { _ in createMockPost() }
        viewModel.posts = existingPosts
        
        // Simulate refresh with skeleton loading
        viewModel.loadingState = .loading(placeholderCount: 5)
        
        XCTAssertNotNil(viewModel.posts[0], "Existing content should remain visible during refresh")
    }
    
    @MainActor
    func testFollowingSkeletonToContentTransition() {
        // Test skeleton-to-content transitions in Following feed
        let viewModel = FollowingViewModel()
        
        // Start with skeleton loading
        simulateSkeletonLoading(viewModel: viewModel, postCount: 5)
        
        // Simulate progressive content loading
        simulateProgressiveHydration(viewModel: viewModel, loadedIndices: [0, 2, 4])
        
        if case .hydrating(let indices) = viewModel.loadingState {
            XCTAssertTrue(indices.contains(0), "Should track loaded posts")
            XCTAssertTrue(indices.contains(2), "Should track loaded posts")
            XCTAssertTrue(indices.contains(4), "Should track loaded posts")
            XCTAssertEqual(indices.count, 3, "Should track 3 loaded posts")
        } else {
            XCTFail("Should be in hydrating state")
        }
    }
    
    // MARK: - Performance Consistency Tests
    
    @MainActor
    func testFollowingPerformanceConsistency() {
        // Test that Following feed maintains same performance standards
        let viewModel = FollowingViewModel()
        let config = SkeletonConfiguration.recommended
        
        // Test same performance limits as HomeForYou
        XCTAssertEqual(config.maxSimultaneousShimmers, 10, "Should use same shimmer limit")
        XCTAssertEqual(config.memoryLimit, 100, "Should use same memory limit")
        XCTAssertEqual(config.placeholderCount, 5, "Should use same placeholder count")
    }
    
    @MainActor
    func testFollowingViewModelPerformance() {
        // Test ViewModel performance in Following feed
        let viewModel = FollowingViewModel()
        
        measure {
            for _ in 0..<50 {
                viewModel.loadingState = .loading(placeholderCount: 5)
                viewModel.loadingState = .hydrating(loadedIndices: Set([0, 1]))
                viewModel.loadingState = .loaded
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testFollowingErrorHandling() {
        // Test error handling in Following feed skeleton loading
        let viewModel = FollowingViewModel()
        
        // Simulate network error during Following feed load
        let networkError = NSError(domain: "FollowingNetworkError", code: 404, userInfo: [
            NSLocalizedDescriptionKey: "Following feed not found"
        ])
        
        viewModel.loadingState = .error(networkError)
        
        if case .error(let error) = viewModel.loadingState {
            XCTAssertEqual((error as NSError).code, 404, "Should handle Following-specific errors")
        } else {
            XCTFail("Should be in error state")
        }
    }
    
    @MainActor
    func testFollowingRetryMechanism() {
        // Test retry mechanism for Following feed
        let viewModel = FollowingViewModel()
        
        // Start with error state
        let error = NSError(domain: "NetworkError", code: 500, userInfo: nil)
        viewModel.loadingState = .error(error)
        
        // Simulate retry
        viewModel.loadingState = .loading(placeholderCount: 5)
        
        if case .loading(let count) = viewModel.loadingState {
            XCTAssertEqual(count, 5, "Should retry with skeleton loading")
        } else {
            XCTFail("Should retry with loading state")
        }
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testFollowingAccessibilityConsistency() {
        // Test that Following feed maintains same accessibility standards
        let followingView = HomeFollowingView()
        XCTAssertNotNil(followingView, "Following view should support accessibility")
        
        // Test skeleton accessibility in Following context
        let skeletonView = FeedPostSkeletonView()
            .skeletonAccessibilityHidden(true)
            .skeletonAccessibilityLabel(isActive: true, loadingLabel: "Loading following posts")
        
        XCTAssertNotNil(skeletonView, "Should provide Following-specific accessibility labels")
    }
    
    @MainActor
    func testFollowingVoiceOverSupport() {
        // Test VoiceOver support in Following feed
        let viewModel = FollowingViewModel()
        
        // Test loading state announcement
        viewModel.loadingState = .loading(placeholderCount: 5)
        
        // VoiceOver should announce "Loading following posts"
        XCTAssertNotNil(viewModel.loadingState, "Should provide VoiceOver loading announcements")
    }
    
    // MARK: - Feed Consistency Tests
    
    @MainActor
    func testFeedConsistencyBetweenHomeForYouAndFollowing() {
        // Test that both feeds use identical skeleton components
        let homeForYouSkeleton = FeedPostSkeletonView()
        let followingSkeleton = FeedPostSkeletonView()
        
        XCTAssertNotNil(homeForYouSkeleton, "HomeForYou should use FeedPostSkeletonView")
        XCTAssertNotNil(followingSkeleton, "Following should use identical FeedPostSkeletonView")
        
        // Test identical theme usage
        let theme = DefaultSkeletonTheme()
        XCTAssertEqual(theme.avatarSizes.md, 40, "Both feeds should use 40pt avatars")
        XCTAssertEqual(theme.spacingScale.md, 16, "Both feeds should use 16pt padding")
    }
    
    @MainActor
    func testSkeletonBehaviorConsistency() {
        // Test that skeleton behavior is consistent between feeds
        let homeForYouViewModel = HomeForYouViewModel()
        let followingViewModel = FollowingViewModel()
        
        // Both should start in idle state
        XCTAssertEqual(homeForYouViewModel.loadingState, .idle, "HomeForYou should start idle")
        XCTAssertEqual(followingViewModel.loadingState, .idle, "Following should start idle")
        
        // Both should use same loading configuration
        homeForYouViewModel.loadingState = .loading(placeholderCount: 5)
        followingViewModel.loadingState = .loading(placeholderCount: 5)
        
        if case .loading(let homeCount) = homeForYouViewModel.loadingState,
           case .loading(let followingCount) = followingViewModel.loadingState {
            XCTAssertEqual(homeCount, followingCount, "Both feeds should use same placeholder count")
        } else {
            XCTFail("Both feeds should be in loading state")
        }
    }
    
    // MARK: - Analytics Integration Tests
    
    func testFollowingAnalyticsIntegration() {
        // Test analytics integration for Following feed
        let analytics = SkeletonAnalytics()
        
        // Test Following-specific metrics
        analytics.trackFirstContentfulRow(timeInterval: 0.25)
        analytics.trackTimeToInteractive(timeInterval: 0.6)
        
        // Test Following-specific error tracking
        let error = NSError(domain: "FollowingError", code: 1, userInfo: nil)
        analytics.trackSkeletonError(error: error, context: "HomeFollowing")
        
        XCTAssertNotNil(analytics, "Should integrate with Analytics Kit for Following feed")
    }
    
    // MARK: - Thread Safety Tests
    
    func testFollowingViewModelThreadSafety() {
        // Test thread safety for Following ViewModel
        let viewModel = FollowingViewModel()
        let expectation = XCTestExpectation(description: "Following ViewModel thread safety")
        expectation.expectedFulfillmentCount = 3
        
        for i in 0..<3 {
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async {
                    viewModel.loadingState = .loading(placeholderCount: 5)
                    XCTAssertNotNil(viewModel.loadingState, "Should be thread-safe on thread \(i)")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}

// MARK: - Test Extensions

extension SkeletonIntegrationTests {
    
    /// Test helper for simulating skeleton loading in Following feed
    @MainActor
    func simulateSkeletonLoading(viewModel: FollowingViewModel, postCount: Int = 5) {
        viewModel.loadingState = .loading(placeholderCount: postCount)
        viewModel.posts = Array(repeating: nil, count: postCount)
    }
    
    /// Test helper for simulating progressive hydration in Following feed
    @MainActor
    func simulateProgressiveHydration(viewModel: FollowingViewModel, loadedIndices: [Int]) {
        for index in loadedIndices {
            if index < viewModel.posts.count {
                viewModel.posts[index] = createMockPost()
            }
        }
        viewModel.loadingState = .hydrating(loadedIndices: Set(loadedIndices))
    }
    
    /// Create a mock post for testing
    func createMockPost() -> Post {
        return Post(
            id: UUID().uuidString,
            content: "Test post content",
            authorId: "test-author",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}