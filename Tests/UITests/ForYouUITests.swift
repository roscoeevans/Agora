//
//  ForYouUITests.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import XCTest

final class ForYouUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testForYouFeedLoads() throws {
        // Test that the For You feed loads and displays content
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.exists)
        forYouTab.tap()
        
        // Verify we're on the For You screen
        let navigationBar = app.navigationBars["For You"]
        XCTAssertTrue(navigationBar.exists)
    }

    func testPullToRefresh() throws {
        // Test pull-to-refresh functionality
        let forYouTab = app.tabBars.buttons["For You"]
        forYouTab.tap()
        
        // Perform pull-to-refresh gesture
        let scrollView = app.scrollViews.firstMatch
        let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.9))
        start.press(forDuration: 0, thenDragTo: end)
    }
}
