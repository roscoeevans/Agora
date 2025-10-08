//
//  TabNavigationUITests.swift
//  AgoraUITests
//
//  Created by Agora Team on 2024.
//

import XCTest

final class TabNavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Tab Existence Tests
    
    @MainActor
    func testAllTabsExist() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0), "Tab bar should exist")
        
        // Test each tab exists with correct labels and icons
        let expectedTabs = [
            ("Home", "house"),
            ("Search", "magnifyingglass"),
            ("Messages", "message"),
            ("Notifications", "bell"),
            ("Profile", "person.circle")
        ]
        
        for (tabName, _) in expectedTabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists, "\(tabName) tab should exist")
        }
    }
    
    // MARK: - Tab Selection Tests
    
    @MainActor
    func testTabSelection() throws {
        let tabs = ["Home", "Search", "Messages", "Notifications", "Profile"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            tab.tap()
            
            // Verify tab is selected
            XCTAssertTrue(tab.isSelected, "\(tabName) tab should be selected after tapping")
            
            // Verify other tabs are not selected
            for otherTabName in tabs where otherTabName != tabName {
                let otherTab = app.tabBars.buttons[otherTabName]
                XCTAssertFalse(otherTab.isSelected, "\(otherTabName) tab should not be selected when \(tabName) is selected")
            }
        }
    }
    
    @MainActor
    func testDefaultTabSelection() throws {
        // Test that Home tab is selected by default
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected by default")
    }
    
    // MARK: - Tab Content Tests
    
    @MainActor
    func testHomeTabContent() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        // Since we have placeholder content, we'll test basic presence
        // In a real implementation, you'd test for specific UI elements
        XCTAssertTrue(homeTab.isSelected, "Home tab should be active")
    }
    
    @MainActor
    func testMessagesTabContent() throws {
        let messagesTab = app.tabBars.buttons["Messages"]
        messagesTab.tap()
        
        XCTAssertTrue(messagesTab.isSelected, "Messages tab should be active")
    }
    
    @MainActor
    func testSearchTabContent() throws {
        let searchTab = app.tabBars.buttons["Search"]
        searchTab.tap()
        
        XCTAssertTrue(searchTab.isSelected, "Search tab should be active")
    }
    
    @MainActor
    func testNotificationsTabContent() throws {
        let notificationsTab = app.tabBars.buttons["Notifications"]
        notificationsTab.tap()
        
        XCTAssertTrue(notificationsTab.isSelected, "Notifications tab should be active")
    }
    
    @MainActor
    func testProfileTabContent() throws {
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        
        XCTAssertTrue(profileTab.isSelected, "Profile tab should be active")
    }
    
    // MARK: - Navigation State Tests
    
    @MainActor
    func testTabStatePreservation() throws {
        // Test that tab states are preserved when switching between tabs
        let forYouTab = app.tabBars.buttons["For You"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        // Go to For You tab
        forYouTab.tap()
        XCTAssertTrue(forYouTab.isSelected)
        
        // Switch to Profile tab
        profileTab.tap()
        XCTAssertTrue(profileTab.isSelected)
        
        // Switch back to For You tab
        forYouTab.tap()
        XCTAssertTrue(forYouTab.isSelected)
    }
    
    @MainActor
    func testMultipleTabSwitches() throws {
        // Test switching between multiple tabs in sequence
        let switchSequence = ["Search", "Profile", "For You", "Notifications", "Following"]
        
        for tabName in switchSequence {
            let tab = app.tabBars.buttons[tabName]
            tab.tap()
            XCTAssertTrue(tab.isSelected, "\(tabName) should be selected")
            
            // Small delay to ensure UI updates
            Thread.sleep(forTimeInterval: 0.2)
        }
    }
}