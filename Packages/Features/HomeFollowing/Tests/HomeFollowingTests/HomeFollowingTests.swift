import XCTest
@testable import HomeFollowing

final class HomeFollowingTests: XCTestCase {
    func testFollowingViewModelInitialization() {
        let viewModel = FollowingViewModel()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        XCTAssertFalse(viewModel.posts.isEmpty) // Should have placeholder data
    }
    
    func testPostInitialization() {
        let post = Post(
            id: "test-id",
            authorId: "author-id",
            authorDisplayHandle: "testauthor",
            text: "Test post",
            createdAt: Date(),
            authorDisplayName: "Test Author"
        )
        XCTAssertEqual(post.text, "Test post")
        XCTAssertEqual(post.authorDisplayName, "Test Author")
        XCTAssertEqual(post.authorDisplayHandle, "testauthor")
        XCTAssertEqual(post.likeCount, 0)
        XCTAssertEqual(post.repostCount, 0)
        XCTAssertEqual(post.replyCount, 0)
    }
}