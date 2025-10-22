import XCTest
@testable import DirectMessages
import TestSupport

final class DirectMessagesTests: XCTestCase {
    
    func testDirectMessagesViewModelInitialization() {
        let viewModel = DirectMessagesViewModel()
        XCTAssertTrue(viewModel.conversations.isEmpty)
    }
    
    func testConversationViewModelInitialization() {
        let conversationId = UUID()
        let viewModel = ConversationViewModel(conversationId: conversationId)
        XCTAssertEqual(viewModel.conversationId, conversationId)
        XCTAssertTrue(viewModel.messages.isEmpty)
    }
}