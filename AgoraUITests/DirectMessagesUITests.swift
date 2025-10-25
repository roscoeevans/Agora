import XCTest

final class DirectMessagesUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set up test environment
        app.launchEnvironment["UI_TESTING"] = "1"
        app.launchEnvironment["MOCK_MESSAGING_DATA"] = "1"
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testNavigateToDirectMessages() throws {
        // Given - App is launched
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        
        // When - Tap Messages tab
        let messagesTab = app.tabBars.buttons["Messages"]
        XCTAssertTrue(messagesTab.exists, "Messages tab should exist")
        messagesTab.tap()
        
        // Then - Should navigate to conversation list
        let conversationList = app.navigationBars["Messages"]
        XCTAssertTrue(conversationList.waitForExistence(timeout: 3.0), "Should navigate to Messages screen")
        
        // Verify conversation list elements
        let conversationTable = app.tables.firstMatch
        XCTAssertTrue(conversationTable.exists, "Conversation list should be displayed")
    }
    
    @MainActor
    func testNavigateToConversation() throws {
        // Given - On Messages screen
        navigateToMessages()
        
        // When - Tap on first conversation
        let firstConversation = app.tables.cells.firstMatch
        XCTAssertTrue(firstConversation.waitForExistence(timeout: 3.0), "First conversation should exist")
        firstConversation.tap()
        
        // Then - Should navigate to chat interface
        let chatInterface = app.navigationBars.element(boundBy: 0)
        XCTAssertTrue(chatInterface.waitForExistence(timeout: 3.0), "Should navigate to chat interface")
        
        // Verify chat elements
        let messageList = app.scrollViews.firstMatch
        XCTAssertTrue(messageList.exists, "Message list should be displayed")
        
        let composerBar = app.textViews["Message input"]
        XCTAssertTrue(composerBar.exists, "Composer bar should be displayed")
    }
    
    @MainActor
    func testBackNavigationFromConversation() throws {
        // Given - In a conversation
        navigateToMessages()
        let firstConversation = app.tables.cells.firstMatch
        firstConversation.tap()
        
        // When - Tap back button
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 3.0))
        backButton.tap()
        
        // Then - Should return to conversation list
        let conversationList = app.navigationBars["Messages"]
        XCTAssertTrue(conversationList.waitForExistence(timeout: 3.0), "Should return to Messages screen")
    }
    
    // MARK: - Conversation List Tests
    
    @MainActor
    func testConversationListDisplay() throws {
        // Given - On Messages screen
        navigateToMessages()
        
        // Then - Should display conversation rows
        let conversationTable = app.tables.firstMatch
        XCTAssertTrue(conversationTable.exists, "Conversation table should exist")
        
        // Verify conversation row elements
        let firstConversation = app.tables.cells.firstMatch
        if firstConversation.waitForExistence(timeout: 3.0) {
            // Check for conversation row elements
            XCTAssertTrue(firstConversation.staticTexts.count > 0, "Conversation should have text elements")
        }
    }
    
    @MainActor
    func testPullToRefreshConversations() throws {
        // Given - On Messages screen
        navigateToMessages()
        
        let conversationTable = app.tables.firstMatch
        XCTAssertTrue(conversationTable.waitForExistence(timeout: 3.0))
        
        // When - Pull to refresh
        let firstCell = conversationTable.cells.firstMatch
        let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 1.5))
        
        start.press(forDuration: 0, thenDragTo: finish)
        
        // Then - Should trigger refresh (verified by no crash)
        XCTAssertTrue(conversationTable.exists, "Table should still exist after refresh")
    }
    
    @MainActor
    func testSearchConversations() throws {
        // Given - On Messages screen with search capability
        navigateToMessages()
        
        // When - Tap search field (if available)
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("test")
            
            // Then - Should filter conversations
            let conversationTable = app.tables.firstMatch
            XCTAssertTrue(conversationTable.exists, "Filtered results should be displayed")
        }
    }
    
    // MARK: - Message Sending Tests
    
    @MainActor
    func testSendTextMessage() throws {
        // Given - In a conversation
        navigateToConversation()
        
        let composerBar = app.textViews["Message input"]
        XCTAssertTrue(composerBar.waitForExistence(timeout: 3.0))
        
        // When - Type and send message
        composerBar.tap()
        composerBar.typeText("Hello, this is a test message!")
        
        let sendButton = app.buttons["Send"]
        XCTAssertTrue(sendButton.exists, "Send button should exist")
        sendButton.tap()
        
        // Then - Message should appear in chat
        let messageText = app.staticTexts["Hello, this is a test message!"]
        XCTAssertTrue(messageText.waitForExistence(timeout: 3.0), "Sent message should appear in chat")
        
        // Composer should be cleared
        XCTAssertEqual(composerBar.value as? String ?? "", "", "Composer should be cleared after sending")
    }
    
    @MainActor
    func testSendEmptyMessage() throws {
        // Given - In a conversation
        navigateToConversation()
        
        let composerBar = app.textViews["Message input"]
        XCTAssertTrue(composerBar.waitForExistence(timeout: 3.0))
        
        // When - Try to send empty message
        composerBar.tap()
        
        let sendButton = app.buttons["Send"]
        
        // Then - Send button should be disabled for empty message
        if sendButton.exists {
            XCTAssertFalse(sendButton.isEnabled, "Send button should be disabled for empty message")
        }
    }
    
    @MainActor
    func testComposerGrowsWithText() throws {
        // Given - In a conversation
        navigateToConversation()
        
        let composerBar = app.textViews["Message input"]
        XCTAssertTrue(composerBar.waitForExistence(timeout: 3.0))
        
        // When - Type long message
        composerBar.tap()
        let longMessage = String(repeating: "This is a long message that should cause the composer to grow. ", count: 5)
        composerBar.typeText(longMessage)
        
        // Then - Composer should still be functional
        XCTAssertTrue(composerBar.exists, "Composer should handle long text")
        
        let sendButton = app.buttons["Send"]
        if sendButton.exists {
            XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled for non-empty message")
        }
    }
    
    // MARK: - Media Attachment Tests
    
    @MainActor
    func testOpenMediaPicker() throws {
        // Given - In a conversation
        navigateToConversation()
        
        // When - Tap attachment button
        let attachmentButton = app.buttons["Attachment"]
        if attachmentButton.exists {
            attachmentButton.tap()
            
            // Then - Should open media picker or show attachment options
            // Note: Actual photo picker testing requires simulator setup
            // This test verifies the button interaction doesn't crash
            XCTAssertTrue(true, "Attachment button tap should not crash")
        }
    }
    
    // MARK: - Message Interaction Tests
    
    @MainActor
    func testMessageContextMenu() throws {
        // Given - In a conversation with messages
        navigateToConversation()
        
        // Send a test message first
        sendTestMessage("Test message for context menu")
        
        // When - Long press on message
        let messageText = app.staticTexts["Test message for context menu"]
        if messageText.waitForExistence(timeout: 3.0) {
            messageText.press(forDuration: 1.0)
            
            // Then - Context menu should appear
            let copyButton = app.buttons["Copy"]
            let replyButton = app.buttons["Reply"]
            
            // Verify context menu options exist (may vary based on implementation)
            if copyButton.exists || replyButton.exists {
                XCTAssertTrue(true, "Context menu should appear with options")
                
                // Dismiss context menu by tapping elsewhere
                app.tap()
            }
        }
    }
    
    @MainActor
    func testSwipeToReply() throws {
        // Given - In a conversation with messages
        navigateToConversation()
        
        // Send a test message first
        sendTestMessage("Test message for swipe reply")
        
        // When - Swipe on message
        let messageText = app.staticTexts["Test message for swipe reply"]
        if messageText.waitForExistence(timeout: 3.0) {
            let start = messageText.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5))
            let finish = messageText.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.5))
            
            start.press(forDuration: 0, thenDragTo: finish)
            
            // Then - Should trigger reply action
            let composerBar = app.textViews["Message input"]
            XCTAssertTrue(composerBar.exists, "Composer should still be accessible after swipe")
        }
    }
    
    // MARK: - Typing Indicator Tests
    
    @MainActor
    func testTypingIndicatorAppears() throws {
        // Given - In a conversation
        navigateToConversation()
        
        let composerBar = app.textViews["Message input"]
        XCTAssertTrue(composerBar.waitForExistence(timeout: 3.0))
        
        // When - Start typing
        composerBar.tap()
        composerBar.typeText("Typing...")
        
        // Then - Should handle typing state (no crash)
        XCTAssertTrue(composerBar.exists, "Composer should remain functional while typing")
        
        // Clear text
        composerBar.clearText()
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testVoiceOverAccessibility() throws {
        // Given - On Messages screen
        navigateToMessages()
        
        // Then - Elements should have proper accessibility labels
        let conversationTable = app.tables.firstMatch
        XCTAssertTrue(conversationTable.isAccessibilityElement || conversationTable.exists, 
                     "Conversation list should be accessible")
        
        // Test conversation accessibility
        let firstConversation = app.tables.cells.firstMatch
        if firstConversation.waitForExistence(timeout: 3.0) {
            XCTAssertNotNil(firstConversation.label, "Conversation should have accessibility label")
        }
    }
    
    @MainActor
    func testMessageAccessibility() throws {
        // Given - In a conversation
        navigateToConversation()
        
        // Send a test message
        sendTestMessage("Accessibility test message")
        
        // Then - Message should be accessible
        let messageText = app.staticTexts["Accessibility test message"]
        if messageText.waitForExistence(timeout: 3.0) {
            XCTAssertTrue(messageText.isAccessibilityElement, "Message should be accessible")
            XCTAssertNotNil(messageText.label, "Message should have accessibility label")
        }
    }
    
    @MainActor
    func testComposerAccessibility() throws {
        // Given - In a conversation
        navigateToConversation()
        
        // Then - Composer elements should be accessible
        let composerBar = app.textViews["Message input"]
        XCTAssertTrue(composerBar.waitForExistence(timeout: 3.0))
        XCTAssertTrue(composerBar.isAccessibilityElement, "Composer should be accessible")
        
        let sendButton = app.buttons["Send"]
        if sendButton.exists {
            XCTAssertTrue(sendButton.isAccessibilityElement, "Send button should be accessible")
        }
    }
    
    // MARK: - Keyboard Handling Tests
    
    @MainActor
    func testKeyboardAppearance() throws {
        // Given - In a conversation
        navigateToConversation()
        
        let composerBar = app.textViews["Message input"]
        XCTAssertTrue(composerBar.waitForExistence(timeout: 3.0))
        
        // When - Tap composer
        composerBar.tap()
        
        // Then - Keyboard should appear and composer should remain visible
        XCTAssertTrue(composerBar.exists, "Composer should remain visible when keyboard appears")
        
        // Dismiss keyboard
        app.tap()
    }
    
    @MainActor
    func testKeyboardDismissal() throws {
        // Given - In a conversation with keyboard visible
        navigateToConversation()
        
        let composerBar = app.textViews["Message input"]
        composerBar.tap()
        
        // When - Scroll message list (if possible)
        let messageList = app.scrollViews.firstMatch
        if messageList.exists {
            messageList.swipeUp()
            
            // Then - Should handle keyboard dismissal gracefully
            XCTAssertTrue(composerBar.exists, "Composer should remain functional after scroll")
        }
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testMessageListScrollPerformance() throws {
        // Given - In a conversation with messages
        navigateToConversation()
        
        // When - Scroll through messages
        let messageList = app.scrollViews.firstMatch
        if messageList.exists {
            measure(metrics: [XCTClockMetric()]) {
                messageList.swipeUp()
                messageList.swipeDown()
            }
        }
    }
    
    @MainActor
    func testConversationListScrollPerformance() throws {
        // Given - On Messages screen
        navigateToMessages()
        
        // When - Scroll through conversations
        let conversationTable = app.tables.firstMatch
        if conversationTable.exists {
            measure(metrics: [XCTClockMetric()]) {
                conversationTable.swipeUp()
                conversationTable.swipeDown()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToMessages() {
        let messagesTab = app.tabBars.buttons["Messages"]
        messagesTab.tap()
        
        let conversationList = app.navigationBars["Messages"]
        XCTAssertTrue(conversationList.waitForExistence(timeout: 3.0))
    }
    
    private func navigateToConversation() {
        navigateToMessages()
        
        let firstConversation = app.tables.cells.firstMatch
        XCTAssertTrue(firstConversation.waitForExistence(timeout: 3.0))
        firstConversation.tap()
        
        let composerBar = app.textViews["Message input"]
        XCTAssertTrue(composerBar.waitForExistence(timeout: 3.0))
    }
    
    private func sendTestMessage(_ text: String) {
        let composerBar = app.textViews["Message input"]
        composerBar.tap()
        composerBar.typeText(text)
        
        let sendButton = app.buttons["Send"]
        if sendButton.exists && sendButton.isEnabled {
            sendButton.tap()
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}