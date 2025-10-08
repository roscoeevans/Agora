import XCTest
@testable import Notifications

final class NotificationsTests: XCTestCase {
    func testNotificationsViewModelInitialization() {
        let viewModel = NotificationsViewModel()
        XCTAssertTrue(viewModel.notifications.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
}