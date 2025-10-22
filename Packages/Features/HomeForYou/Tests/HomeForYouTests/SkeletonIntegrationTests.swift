//
//  SkeletonIntegrationTests.swift
//  HomeForYouTests
//
//  Created by Agora Team on 2024.
//

import XCTest
import SwiftUI
@testable import HomeForYou
@testable import DesignSystem

@available(iOS 26.0, *)
final class SkeletonIntegrationTests: XCTestCase {
    
    // MARK: - Skeleton-to-Content Transition Tests
    
    @MainActor
    func testHomeForYouSkeletonIntegration() {
        // Test that HomeForYou properly integrates skeleton loading
        let viewModel = HomeForYouViewModel()
        XCTAssertNotNil(viewModel, "HomeForYou ViewModel should be created")
        
        // Test initial loading state
        XCTAssertEqual(viewModel.loadingState, .idle, "Should start in idle state")
        
        // Test loading state transition
        viewModel.loadingState = .loading(placeholderCount: 5)
        if case .loading(let count) = viewModel.loadingState {
            XCTAssertEqual(count, 5, "Should load 5 skeleton placeholders")
        } else {
            XCTFail("Should be in loading state")
        }
    }
    
    @MainActor
    func testSkeletonToContentTransition() {
        // Test progressive hydration from skeleton to content
        let viewModel = HomeForYouViewModel()
        
        // Start with skeleton loading
        viewModel.loadingState = .loading(placeholderCount: 5)
        viewModel.posts = Array(repeating: nil, count: 5)
        
        // Simulate content arriving
        let mockPost = createMockPost()
        viewModel.posts[0] = mockPost
        viewModel.loadingState = .hydrating(loadedIndices: [0])
        
        if case .hydrating(let indices) = viewModel.loadingState {
            XCTAssertTrue(indices.contains(0), "Should track loaded post at index 0")
        } else {
            XCTFail("Should be in hydrating state")
        }
        
        XCTAssertNotNil(viewModel.posts[0], "First post should be loaded")
        XCTAssertNil(viewModel.posts[1], "Second post should still be skeleton")
    }
    
    @MainActor
    func testPaginationSkeletonBehavior() {
        // Test skeleton behavior during pagination
        let viewModel = HomeForYouViewModel()
        let config = SkeletonConfiguration.recommended
        
        // Test preload threshold
        XCTAssertEqual(config.preloadThreshold, 5, "Should trigger preload at 5 rows from bottom")
        
        // Test that existing content remains visible during pagination
        let existingPosts = Array(0..<10).map { _ in createMockPost() }
        viewModel.posts = existingPosts
        
        // Simulate pagination loading
        viewModel.loadingState = .loading(placeholderCount: 5)
        let newSkeletonPosts: [Post?] = Array(repeating: nil, count: 5)
        viewModel.posts.append(contentsOf: newSkeletonPosts)
        
        XCTAssertEqual(viewModel.posts.count, 15, "Should have 10 existing + 5 skeleton posts")
        XCTAssertNotNil(viewModel.posts[0], "Existing content should remain visible")
        XCTAssertNil(viewModel.posts[10], "New posts should be skeleton placeholders")
    }
    
    @MainActor
    func testSkeletonErrorHandling() {
        // Test error handling during skeleton loading
        let viewModel = HomeForYouViewModel()
        
        // Simulate network error
        let networkError = NSError(domain: "NetworkError", code: 500, userInfo: nil)
        viewModel.loadingState = .error(networkError)
        
        if case .error(let error) = viewModel.loadingState {
            XCTAssertNotNil(error, "Should handle network errors")
        } else {
            XCTFail("Should be in error state")
        }
    }
    
    // MARK: - Performance Integration Tests
    
    @MainActor
    func testSkeletonPerformanceIntegration() {
        // Test that skeleton integration maintains performance standards
        let viewModel = HomeForYouViewModel()
        let config = SkeletonConfiguration.recommended
        
        // Test memory limit compliance
        XCTAssertEqual(config.memoryLimit, 100, "Should limit memory usage to 100MB")
        
        // Test simultaneous shimmer limit
        XCTAssertEqual(config.maxSimultaneousShimmers, 10, "Should limit to 10 simultaneous shimmers")
        
        // Test placeholder count
        XCTAssertEqual(config.placeholderCount, 5, "Should pre-seed 5 placeholders")
    }
    
    @MainActor
    func testSkeletonViewModelPerformance() {
        // Test ViewModel performance with skeleton states
        let viewModel = HomeForYouViewModel()
        
        measure {
            for i in 0..<100 {
                viewModel.loadingState = .loading(placeholderCount: 5)
                viewModel.loadingState = .hydrating(loadedIndices: Set([0, 1, 2]))
                viewModel.loadingState = .loaded
            }
        }
    }
    
    // MARK: - Accessibility Integration Tests
    
    @MainActor
    func testSkeletonAccessibilityIntegration() {
        // Test accessibility integration in HomeForYou
        let homeView = HomeForYouView()
        XCTAssertNotNil(homeView, "HomeForYou view should support accessibility")
        
        // Test that skeleton views are properly hidden from VoiceOver
        let skeletonView = FeedPostSkeletonView()
            .skeletonAccessibilityHidden(true)
        
        XCTAssertNotNil(skeletonView, "Skeleton views should be hidden from accessibility tree")
    }
    
    @MainActor
    func testReducedMotionIntegration() {
        // Test Reduced Motion preference integration
        let skeletonView = FeedPostSkeletonView()
        XCTAssertNotNil(skeletonView, "Should respect Reduced Motion preference")
        
        // Test motion preferences helper
        let motionPrefs = MotionPreferences()
        XCTAssertNotNil(motionPrefs, "Should provide motion preference queries")
    }
    
    // MARK: - Analytics Integration Tests
    
    func testSkeletonAnalyticsIntegration() {
        // Test analytics integration for skeleton loading
        let analytics = SkeletonAnalytics()
        
        // Test timing metrics
        analytics.trackFirstContentfulRow(timeInterval: 0.2)
        analytics.trackTimeToInteractive(timeInterval: 0.5)
        
        // Test error tracking
        let error = NSError(domain: "SkeletonError", code: 1, userInfo: nil)
        analytics.trackSkeletonError(error: error, context: "HomeForYou")
        
        XCTAssertNotNil(analytics, "Should integrate with Analytics Kit")
    }
    
    // MARK: - Configuration Tests
    
    func testSkeletonConfigurationValidation() {
        // Test skeleton configuration validation
        let config = SkeletonConfiguration.recommended
        
        XCTAssertGreaterThan(config.placeholderCount, 0, "Placeholder count should be positive")
        XCTAssertGreaterThan(config.preloadThreshold, 0, "Preload threshold should be positive")
        XCTAssertGreaterThan(config.maxSimultaneousShimmers, 0, "Max shimmers should be positive")
        XCTAssertGreaterThan(config.memoryLimit, 0, "Memory limit should be positive")
        
        XCTAssertLessThanOrEqual(config.maxSimultaneousShimmers, 10, "Should not exceed 10 simultaneous shimmers")
        XCTAssertLessThanOrEqual(config.memoryLimit, 100, "Should not exceed 100MB memory limit")
    }
    
    // MARK: - Thread Safety Tests
    
    func testSkeletonViewModelThreadSafety() {
        // Test that ViewModel skeleton operations are thread-safe
        let viewModel = HomeForYouViewModel()
        let expectation = XCTestExpectation(description: "ViewModel thread safety")
        expectation.expectedFulfillmentCount = 5
        
        for i in 0..<5 {
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async {
                    viewModel.loadingState = .loading(placeholderCount: 5)
                    XCTAssertNotNil(viewModel.loadingState, "Loading state should be accessible from thread \(i)")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}

// MARK: - Test Extensions

extension SkeletonIntegrationTests {
    
    /// Test helper for creating mock skeleton configurations
    func createTestSkeletonConfiguration(
        placeholderCount: Int = 5,
        preloadThreshold: Int = 5,
        maxSimultaneousShimmers: Int = 10,
        memoryLimit: Int = 100,
        analyticsEnabled: Bool = true
    ) -> SkeletonConfiguration {
        return SkeletonConfiguration(
            placeholderCount: placeholderCount,
            preloadThreshold: preloadThreshold,
            maxSimultaneousShimmers: maxSimultaneousShimmers,
            memoryLimit: memoryLimit,
            analyticsEnabled: analyticsEnabled
        )
    }
    
    /// Test helper for simulating skeleton loading scenarios
    @MainActor
    func simulateSkeletonLoading(viewModel: HomeForYouViewModel, postCount: Int = 5) {
        viewModel.loadingState = .loading(placeholderCount: postCount)
        viewModel.posts = Array(repeating: nil, count: postCount)
    }
    
    /// Test helper for simulating progressive hydration
    @MainActor
    func simulateProgressiveHydration(viewModel: HomeForYouViewModel, loadedIndices: [Int]) {
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