import XCTest
@testable import PostDetail

final class PostDetailTests: XCTestCase {
    func testPostDetailViewModelInitialization() {
        let viewModel = PostDetailViewModel(postId: "test-id")
        XCTAssertNil(viewModel.post)
        XCTAssertTrue(viewModel.replies.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
}