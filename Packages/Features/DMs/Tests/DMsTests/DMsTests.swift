import XCTest
@testable import DMs

final class DMsTests: XCTestCase {
    func testDMThreadsViewModelInitialization() {
        let viewModel = DMThreadsViewModel()
        XCTAssertTrue(viewModel.threads.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
}