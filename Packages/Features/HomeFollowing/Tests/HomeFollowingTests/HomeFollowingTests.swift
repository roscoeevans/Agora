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
        let post = Post(text: "Test post", author: "Test Author")
        XCTAssertEqual(post.text, "Test post")
        XCTAssertEqual(post.author, "Test Author")
        XCTAssertEqual(post.likeCount, 0)
        XCTAssertEqual(post.repostCount, 0)
        XCTAssertEqual(post.replyCount, 0)
    }
}