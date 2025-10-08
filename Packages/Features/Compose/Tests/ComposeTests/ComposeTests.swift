import XCTest
@testable import Compose

final class ComposeTests: XCTestCase {
    func testComposeViewModelInitialization() {
        let viewModel = ComposeViewModel()
        XCTAssertTrue(viewModel.text.isEmpty)
        XCTAssertTrue(viewModel.selectedMedia.isEmpty)
        XCTAssertFalse(viewModel.isPosting)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.characterCount, 0)
        XCTAssertFalse(viewModel.isOverLimit)
        XCTAssertFalse(viewModel.canPost)
    }
    
    func testCharacterCount() {
        let viewModel = ComposeViewModel()
        viewModel.text = "Hello, world!"
        XCTAssertEqual(viewModel.characterCount, 13)
        XCTAssertFalse(viewModel.isOverLimit)
        XCTAssertTrue(viewModel.canPost)
    }
    
    func testCharacterLimit() {
        let viewModel = ComposeViewModel()
        viewModel.text = String(repeating: "a", count: 71) // Over 70 character limit
        XCTAssertEqual(viewModel.characterCount, 71)
        XCTAssertTrue(viewModel.isOverLimit)
        XCTAssertFalse(viewModel.canPost)
    }
    
    func testMediaItemInitialization() {
        let mediaItem = MediaItem(type: .photo)
        XCTAssertEqual(mediaItem.type, .photo)
        XCTAssertNotNil(mediaItem.id)
        XCTAssertNil(mediaItem.url)
    }
}