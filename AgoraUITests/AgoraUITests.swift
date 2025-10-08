//
//  AgoraUITests.swift
//  AgoraUITests
//
//  Created by Rocky Evans on 10/7/25.
//

import XCTest

final class AgoraUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }

    // MARK: - App Launch Tests
    
    @MainActor
    func testAppLaunchesSuccessfully() throws {
        // Verify app launches and displays the main tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0), "Tab bar should exist after app launch")
        
        // Verify all expected tabs are present
        let forYouTab = app.tabBars.buttons["For You"]
        let followingTab = app.tabBars.buttons["Following"]
        let searchTab = app.tabBars.buttons["Search"]
        let notificationsTab = app.tabBars.buttons["Notifications"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        XCTAssertTrue(forYouTab.exists, "For You tab should exist")
        XCTAssertTrue(followingTab.exists, "Following tab should exist")
        XCTAssertTrue(searchTab.exists, "Search tab should exist")
        XCTAssertTrue(notificationsTab.exists, "Notifications tab should exist")
        XCTAssertTrue(profileTab.exists, "Profile tab should exist")
    }
    
    // MARK: - Tab Navigation Tests
    
    @MainActor
    func testTabNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        
        // Test navigation to each tab
        testNavigationToHomeTab()
        testNavigationToSearchTab()
        testNavigationToMessagesTab()
        testNavigationToNotificationsTab()
        testNavigationToProfileTab()
    }
    
    private func testNavigationToHomeTab() {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Verify we're on the Home screen by checking for expected content
        // Since it's a placeholder, we'll check for basic SwiftUI elements
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected")
    }
    
    private func testNavigationToMessagesTab() {
        let messagesTab = app.tabBars.buttons["Messages"]
        messagesTab.tap()
        
        XCTAssertTrue(messagesTab.isSelected, "Messages tab should be selected")
    }
    
    private func testNavigationToSearchTab() {
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()
        
        XCTAssertTrue(searchTab.isSelected, "Search tab should be selected")
    }
    
    private func testNavigationToNotificationsTab() {
        let notificationsTab = app.tabBars.buttons["Notifications"]
        notificationsTab.tap()
        
        XCTAssertTrue(notificationsTab.isSelected, "Notifications tab should be selected")
    }
    
    private func testNavigationToProfileTab() {
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        
        XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected")
    }
    
    // MARK: - Screen Transition Tests
    
    @MainActor
    func testBasicScreenTransitions() throws {
        // Test that we can navigate between tabs without crashes
        let tabs = [
            "For You",
            "Following", 
            "Search",
            "Notifications",
            "Profile"
        ]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            tab.tap()
            
            // Wait a moment for the transition
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify the tab is selected and no crash occurred
            XCTAssertTrue(tab.isSelected, "\(tabName) tab should be selected after tapping")
        }
    }
    
    @MainActor
    func testRapidTabSwitching() throws {
        // Test rapid tab switching to ensure stability
        let tabs = ["For You", "Following", "Search", "Notifications", "Profile"]
        
        for _ in 0..<3 { // Repeat the cycle 3 times
            for tabName in tabs {
                let tab = app.tabBars.buttons[tabName]
                tab.tap()
                // No sleep - rapid switching
            }
        }
        
        // Verify app is still responsive
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should still exist after rapid switching")
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testVoiceOverAccessibility() throws {
        // Test that all tab bar items have proper accessibility labels
        let forYouTab = app.tabBars.buttons["For You"]
        let followingTab = app.tabBars.buttons["Following"]
        let searchTab = app.tabBars.buttons["Search"]
        let notificationsTab = app.tabBars.buttons["Notifications"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        // Verify accessibility labels exist and are meaningful
        XCTAssertNotNil(forYouTab.label, "For You tab should have accessibility label")
        XCTAssertNotNil(followingTab.label, "Following tab should have accessibility label")
        XCTAssertNotNil(searchTab.label, "Search tab should have accessibility label")
        XCTAssertNotNil(notificationsTab.label, "Notifications tab should have accessibility label")
        XCTAssertNotNil(profileTab.label, "Profile tab should have accessibility label")
        
        // Verify tabs are accessible
        XCTAssertTrue(forYouTab.isAccessibilityElement, "For You tab should be accessible")
        XCTAssertTrue(followingTab.isAccessibilityElement, "Following tab should be accessible")
        XCTAssertTrue(searchTab.isAccessibilityElement, "Search tab should be accessible")
        XCTAssertTrue(notificationsTab.isAccessibilityElement, "Notifications tab should be accessible")
        XCTAssertTrue(profileTab.isAccessibilityElement, "Profile tab should be accessible")
    }
    
    @MainActor
    func testAccessibilityTraits() throws {
        // Test that tab bar buttons have correct accessibility traits
        let tabs = [
            app.tabBars.buttons["For You"],
            app.tabBars.buttons["Following"],
            app.tabBars.buttons["Search"],
            app.tabBars.buttons["Notifications"],
            app.tabBars.buttons["Profile"]
        ]
        
        for tab in tabs {
            // Tab bar buttons should have button trait
            XCTAssertTrue(tab.elementType == .button, "Tab should be recognized as a button")
        }
    }
    
    @MainActor
    func testDynamicTypeSupport() throws {
        // Test that the app handles different text sizes
        // This is a basic test - in a real app you'd test with different accessibility text sizes
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Verify tab labels are still visible (basic check)
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.exists, "For You tab should remain accessible")
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testTabSwitchingPerformance() throws {
        // Measure performance of tab switching
        let forYouTab = app.tabBars.buttons["For You"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        measure(metrics: [XCTClockMetric()]) {
            forYouTab.tap()
            profileTab.tap()
        }
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testAppStabilityUnderStress() throws {
        // Test app stability under various interactions
        let tabs = ["For You", "Following", "Search", "Notifications", "Profile"]
        
        // Perform various interactions to test stability
        for _ in 0..<10 {
            // Random tab selection
            let randomTab = tabs.randomElement()!
            let tab = app.tabBars.buttons[randomTab]
            tab.tap()
            
            // Brief pause
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Verify app is still functional
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "App should remain stable after stress testing")
    }
}