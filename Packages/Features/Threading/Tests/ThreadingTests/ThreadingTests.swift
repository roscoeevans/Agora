import XCTest
@testable import Threading

final class ThreadingTests: XCTestCase {
    func testThreadViewModelInitialization() {
        let viewModel = ThreadViewModel(threadId: "test-id")
        XCTAssertTrue(viewModel.threadPosts.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
}