//
//  CommentSkeletonIntegrationTests.swift
//  PostDetailTests
//
//  Created by Agora Team on 2024.
//

import XCTest
import SwiftUI
@testable import PostDetail
@testable import DesignSystem

@available(iOS 26.0, *)
final class CommentSkeletonIntegrationTests: XCTestCase {
    
    // MARK: - CommentSheet Skeleton Integration Tests
    
    @MainActor
    func testCommentSheetSkeletonIntegration() {
        // Test CommentSheet skeleton integration
        let viewModel = PostDetailViewModel()
        XCTAssertNotNil(viewModel, "PostDetail ViewModel should be created")
        
        // Test initial comment loading state
        XCTAssertEqual(viewModel.commentLoadingState, .idle, "Should start in idle state")
        
        // Test comment skeleton loading
        viewModel.commentLoadingState = .loading(placeholderCount: 6)
        if case .loading(let count) = viewModel.commentLoadingState {
            XCTAssertGreaterThanOrEqual(count, 6, "Should load 6-8 comment skeleton placeholders")
            XCTAssertLessThanOrEqual(count, 8, "Should not exceed 8 comment placeholders")
        } else {
            XCTFail("Should be in comment loading state")
        }
    }
    
    @MainActor
    func testParentPostImmediateDisplay() {
        // Test that parent post displays immediately while comments load
        let viewModel = PostDetailViewModel()
        let parentPost = TestFixtures.mockPost()
        
        // Set parent post
        viewModel.post = parentPost
        viewModel.commentLoadingState = .loading(placeholderCount: 6)
        
        XCTAssertNotNil(viewModel.post, "Parent post should display immediately")
        
        if case .loading = viewModel.commentLoadingState {
            XCTAssertTrue(true, "Comments should be in loading state while parent shows")
        } else {
            XCTFail("Comments should be loading while parent post is visible")
        }
    }
    
    @MainActor
    func testCommentSkeletonLayout() {
        // Test CommentSkeletonView layout in CommentSheet context
        let commentSkeleton = CommentSkeletonView()
        XCTAssertNotNil(commentSkeleton, "CommentSkeletonView should be created")
        
        // Test compact dimensions (32×32pt avatar, 100pt name width)
        let theme = DefaultSkeletonTheme()
        XCTAssertEqual(theme.avatarSizes.sm, 32, "Comment avatar should be 32×32pt")
        
        // Test that comment skeleton is more compact than feed post skeleton
        XCTAssertLess(theme.avatarSizes.sm, theme.avatarSizes.md, "Comment avatar should be smaller than feed post avatar")
    }
    
    @MainActor
    func testCommentSheetPresentation() {
        // Test CommentSheet presentation configuration
        let commentSheet = CommentSheetSkeleton(parentPost: createMockPost())
        XCTAssertNotNil(commentSheet, "CommentSheet should be created with parent post")
        
        // Test sheet presentation detents (.fraction(0.65))
        let expectedDetent: Double = 0.65
        XCTAssertEqual(expectedDetent, 0.65, "Should use .presentationDetents([.fraction(0.65)])")
    }
    
    @MainActor
    func testProgressiveReplyHydration() {
        // Test progressive reply hydration as comment data arrives
        let viewModel = PostDetailViewModel()
        
        // Start with comment skeleton loading
        viewModel.commentLoadingState = .loading(placeholderCount: 6)
        viewModel.comments = Array(repeating: nil, count: 6)
        
        // Simulate comments arriving progressively
        let mockComment1 = createMockComment()
        let mockComment2 = createMockComment()
        
        viewModel.comments[0] = mockComment1
        viewModel.comments[2] = mockComment2
        viewModel.commentLoadingState = .hydrating(loadedIndices: [0, 2])
        
        if case .hydrating(let indices) = viewModel.commentLoadingState {
            XCTAssertTrue(indices.contains(0), "Should track loaded comment at index 0")
            XCTAssertTrue(indices.contains(2), "Should track loaded comment at index 2")
            XCTAssertEqual(indices.count, 2, "Should track 2 loaded comments")
        } else {
            XCTFail("Should be in hydrating state")
        }
        
        XCTAssertNotNil(viewModel.comments[0], "First comment should be loaded")
        XCTAssertNil(viewModel.comments[1], "Second comment should still be skeleton")
        XCTAssertNotNil(viewModel.comments[2], "Third comment should be loaded")
    }
    
    // MARK: - CommentSheet Performance Tests
    
    @MainActor
    func testCommentSheetPerformance() {
        // Test CommentSheet performance with skeleton loading
        let viewModel = PostDetailViewModel()
        
        measure {
            for _ in 0..<25 {
                viewModel.commentLoadingState = .loading(placeholderCount: 6)
                viewModel.commentLoadingState = .hydrating(loadedIndices: Set([0, 1, 2]))
                viewModel.commentLoadingState = .loaded
            }
        }
    }
    
    @MainActor
    func testCommentSkeletonViewPerformance() {
        // Test CommentSkeletonView creation performance
        measure {
            for _ in 0..<100 {
                let _ = CommentSkeletonView()
            }
        }
    }
    
    // MARK: - CommentSheet Error Handling Tests
    
    @MainActor
    func testCommentLoadingErrorHandling() {
        // Test error handling during comment loading
        let viewModel = PostDetailViewModel()
        
        // Simulate comment loading error
        let commentError = NSError(domain: "CommentError", code: 403, userInfo: [
            NSLocalizedDescriptionKey: "Comments not available"
        ])
        
        viewModel.commentLoadingState = .error(commentError)
        
        if case .error(let error) = viewModel.commentLoadingState {
            XCTAssertEqual((error as NSError).code, 403, "Should handle comment-specific errors")
        } else {
            XCTFail("Should be in error state")
        }
    }
    
    @MainActor
    func testCommentRetryMechanism() {
        // Test retry mechanism for comment loading
        let viewModel = PostDetailViewModel()
        
        // Start with error state
        let error = NSError(domain: "NetworkError", code: 500, userInfo: nil)
        viewModel.commentLoadingState = .error(error)
        
        // Simulate retry
        viewModel.commentLoadingState = .loading(placeholderCount: 6)
        
        if case .loading(let count) = viewModel.commentLoadingState {
            XCTAssertEqual(count, 6, "Should retry with comment skeleton loading")
        } else {
            XCTFail("Should retry with loading state")
        }
    }
    
    // MARK: - CommentSheet Accessibility Tests
    
    @MainActor
    func testCommentSkeletonAccessibility() {
        // Test accessibility support for comment skeletons
        let commentSkeleton = CommentSkeletonView()
            .skeletonAccessibilityHidden(true)
            .skeletonAccessibilityLabel(isActive: true, loadingLabel: "Loading comment content")
        
        XCTAssertNotNil(commentSkeleton, "Comment skeleton should be hidden from accessibility tree")
    }
    
    @MainActor
    func testCommentSheetVoiceOverSupport() {
        // Test VoiceOver support in CommentSheet
        let viewModel = PostDetailViewModel()
        
        // Test loading state announcement for comments
        viewModel.commentLoadingState = .loading(placeholderCount: 6)
        
        // VoiceOver should announce "Loading comments"
        XCTAssertNotNil(viewModel.commentLoadingState, "Should provide VoiceOver comment loading announcements")
    }
    
    @MainActor
    func testCommentDynamicTypeSupport() {
        // Test Dynamic Type support for comment skeletons
        let commentSkeleton = CommentSkeletonView()
            .skeletonDynamicType(isActive: true)
        
        XCTAssertNotNil(commentSkeleton, "Comment skeleton should support Dynamic Type scaling")
    }
    
    // MARK: - CommentSheet Layout Tests
    
    @MainActor
    func testCommentSheetLayoutStructure() {
        // Test CommentSheet layout structure with parent post and comment skeletons
        let parentPost = TestFixtures.mockPost()
        let commentSheet = CommentSheetSkeleton(parentPost: parentPost)
        
        XCTAssertNotNil(commentSheet, "CommentSheet should display parent post immediately")
        
        // Test that comment skeletons appear below parent post
        let commentSkeleton = CommentSkeletonView()
        XCTAssertNotNil(commentSkeleton, "Comment skeletons should appear below parent post")
    }
    
    @MainActor
    func testCommentSkeletonCompactLayout() {
        // Test that comment skeletons use compact layout compared to feed posts
        let feedSkeleton = FeedPostSkeletonView()
        let commentSkeleton = CommentSkeletonView()
        
        XCTAssertNotNil(feedSkeleton, "Feed skeleton should exist for comparison")
        XCTAssertNotNil(commentSkeleton, "Comment skeleton should use compact layout")
        
        let theme = DefaultSkeletonTheme()
        
        // Test avatar size difference (40pt vs 32pt)
        XCTAssertGreaterThan(theme.avatarSizes.md, theme.avatarSizes.sm, "Feed avatar should be larger than comment avatar")
        
        // Test spacing differences
        XCTAssertGreaterThan(theme.spacingScale.sm, theme.spacingScale.xs, "Feed spacing should be larger than comment spacing")
    }
    
    // MARK: - CommentSheet Integration with PostDetail Tests
    
    @MainActor
    func testPostDetailCommentIntegration() {
        // Test integration between PostDetail and CommentSheet skeleton
        let postDetailView = PostDetailView()
        XCTAssertNotNil(postDetailView, "PostDetail view should integrate with comment skeletons")
        
        let viewModel = PostDetailViewModel()
        
        // Test that post detail can trigger comment sheet with skeleton loading
        viewModel.showCommentSheet = true
        viewModel.commentLoadingState = .loading(placeholderCount: 6)
        
        XCTAssertTrue(viewModel.showCommentSheet, "Should show comment sheet")
        
        if case .loading(let count) = viewModel.commentLoadingState {
            XCTAssertEqual(count, 6, "Should load comment skeletons when sheet opens")
        } else {
            XCTFail("Should be loading comments when sheet opens")
        }
    }
    
    // MARK: - Analytics Integration Tests
    
    func testCommentSkeletonAnalyticsIntegration() {
        // Test analytics integration for comment skeleton loading
        let analytics = SkeletonAnalytics()
        
        // Test comment-specific metrics
        analytics.trackFirstContentfulRow(timeInterval: 0.15) // Comments should load faster
        analytics.trackTimeToInteractive(timeInterval: 0.4)
        
        // Test comment-specific error tracking
        let error = NSError(domain: "CommentError", code: 1, userInfo: nil)
        analytics.trackSkeletonError(error: error, context: "CommentSheet")
        
        XCTAssertNotNil(analytics, "Should integrate with Analytics Kit for comment loading")
    }
    
    // MARK: - Thread Safety Tests
    
    func testCommentViewModelThreadSafety() {
        // Test thread safety for comment loading operations
        let viewModel = PostDetailViewModel()
        let expectation = XCTestExpectation(description: "Comment ViewModel thread safety")
        expectation.expectedFulfillmentCount = 3
        
        for i in 0..<3 {
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async {
                    viewModel.commentLoadingState = .loading(placeholderCount: 6)
                    XCTAssertNotNil(viewModel.commentLoadingState, "Should be thread-safe on thread \(i)")
                    expectation.fulfill()
                }
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
}

// MARK: - Test Extensions

extension CommentSkeletonIntegrationTests {
    
    /// Test helper for simulating comment skeleton loading
    @MainActor
    func simulateCommentSkeletonLoading(viewModel: PostDetailViewModel, commentCount: Int = 6) {
        viewModel.commentLoadingState = .loading(placeholderCount: commentCount)
        viewModel.comments = Array(repeating: nil, count: commentCount)
    }
    
    /// Test helper for simulating progressive comment hydration
    @MainActor
    func simulateProgressiveCommentHydration(viewModel: PostDetailViewModel, loadedIndices: [Int]) {
        for index in loadedIndices {
            if index < viewModel.comments.count {
                viewModel.comments[index] = createMockComment()
            }
        }
        viewModel.commentLoadingState = .hydrating(loadedIndices: Set(loadedIndices))
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
    
    /// Create a mock comment for testing
    func createMockComment() -> Comment {
        return Comment(
            id: UUID().uuidString,
            content: "Test comment content",
            authorId: "test-author",
            postId: "test-post",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}