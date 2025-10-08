import XCTest
@testable import Search

final class SearchTests: XCTestCase {
    func testSearchViewModelInitialization() {
        let viewModel = SearchViewModel()
        XCTAssertTrue(viewModel.searchResults.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
}