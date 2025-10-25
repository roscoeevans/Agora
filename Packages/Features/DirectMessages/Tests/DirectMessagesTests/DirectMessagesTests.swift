import XCTest
@testable import DirectMessages
import TestSupport
import AppFoundation

final class DirectMessagesTests: XCTestCase {
    
    func testDirectMessagesViewModelInitialization() {
        let viewModel = DirectMessagesViewModel()
        XCTAssertTrue(viewModel.conversations.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.searchText, "")
    }
    
    func testConversationViewModelInitialization() {
        let conversationId = UUID()
        let viewModel = ConversationViewModel(conversationId: conversationId)
        XCTAssertEqual(viewModel.conversationId, conversationId)
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertFalse(viewModel.isLoadingMessages)
        XCTAssertFalse(viewModel.isLoadingOlderMessages)
        XCTAssertNil(viewModel.conversation)
        XCTAssertTrue(viewModel.typingUsers.isEmpty)
        XCTAssertNil(viewModel.currentDraft)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.hasReachedEnd)
    }
}