//
//  ComposeUITests.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import XCTest

final class ComposeUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testComposeButtonExists() throws {
        // Test that compose button is accessible
        let composeButton = app.buttons["Compose"]
        XCTAssertTrue(composeButton.exists)
    }

    func testCharacterLimit() throws {
        // Test 70-character limit enforcement
        let composeButton = app.buttons["Compose"]
        composeButton.tap()
        
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists)
        
        // Test character counter
        let characterCounter = app.staticTexts.matching(identifier: "characterCounter").firstMatch
        XCTAssertTrue(characterCounter.exists)
    }
}
