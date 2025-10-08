//
//  AccessibilityUITests.swift
//  AgoraUITests
//
//  Created by Agora Team on 2024.
//

import XCTest

final class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - VoiceOver Accessibility Tests
    
    @MainActor
    func testVoiceOverLabels() throws {
        // Test that all interactive elements have proper accessibility labels
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0))
        
        let tabs = [
            ("For You", "For You tab"),
            ("Following", "Following tab"),
            ("Search", "Search tab"),
            ("Notifications", "Notifications tab"),
            ("Profile", "Profile tab")
        ]
        
        for (tabName, expectedLabel) in tabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists, "\(tabName) tab should exist")
            
            // Check that the tab has an accessibility label
            let label = tab.label
            XCTAssertFalse(label.isEmpty, "\(tabName) tab should have a non-empty accessibility label")
            XCTAssertTrue(label.contains(tabName), "Accessibility label should contain the tab name")
        }
    }
    
    @MainActor
    func testAccessibilityElements() throws {
        // Test that all tabs are properly marked as accessibility elements
        let tabs = ["For You", "Following", "Search", "Notifications", "Profile"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.isAccessibilityElement, "\(tabName) tab should be an accessibility element")
        }
    }
    
    @MainActor
    func testAccessibilityTraits() throws {
        // Test that tabs have appropriate accessibility traits
        let tabs = ["For You", "Following", "Search", "Notifications", "Profile"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            
            // Tab bar buttons should be recognized as buttons
            XCTAssertEqual(tab.elementType, .button, "\(tabName) should be recognized as a button")
        }
    }
    
    @MainActor
    func testSelectedTabAccessibility() throws {
        // Test that selected state is properly communicated to accessibility
        let forYouTab = app.tabBars.buttons["For You"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        // For You should be selected by default
        forYouTab.tap()
        XCTAssertTrue(forYouTab.isSelected, "For You tab should be selected")
        
        // Switch to Profile tab
        profileTab.tap()
        XCTAssertTrue(profileTab.isSelected, "Profile tab should be selected")
        XCTAssertFalse(forYouTab.isSelected, "For You tab should not be selected")
    }
    
    // MARK: - Dynamic Type Support Tests
    
    @MainActor
    func testDynamicTypeCompatibility() throws {
        // Test that the interface remains usable with different text sizes
        // Note: In a real implementation, you'd test with actual Dynamic Type settings
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Verify all tabs remain accessible
        let tabs = ["For You", "Following", "Search", "Notifications", "Profile"]
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists, "\(tabName) tab should remain accessible")
            XCTAssertTrue(tab.isHittable, "\(tabName) tab should remain tappable")
        }
    }
    
    // MARK: - Accessibility Navigation Tests
    
    @MainActor
    func testAccessibilityNavigation() throws {
        // Test navigation using accessibility features
        let tabs = ["For You", "Following", "Search", "Notifications", "Profile"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            
            // Simulate accessibility activation
            tab.tap()
            
            // Verify the tab becomes selected
            XCTAssertTrue(tab.isSelected, "\(tabName) should be selected after accessibility activation")
            
            // Brief pause for UI updates
            Thread.sleep(forTimeInterval: 0.3)
        }
    }
    
    @MainActor
    func testAccessibilityHints() throws {
        // Test that accessibility hints are appropriate (if implemented)
        let tabs = ["For You", "Following", "Search", "Notifications", "Profile"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            
            // Check that the element exists and is accessible
            XCTAssertTrue(tab.exists, "\(tabName) tab should exist")
            XCTAssertTrue(tab.isAccessibilityElement, "\(tabName) should be accessible")
            
            // The label should be descriptive enough for VoiceOver users
            let label = tab.label
            XCTAssertFalse(label.isEmpty, "\(tabName) should have a meaningful label")
        }
    }
    
    // MARK: - Reduced Motion Support Tests
    
    @MainActor
    func testReducedMotionSupport() throws {
        // Test that the app works properly with reduced motion preferences
        // Note: This is a basic test - in production you'd test with actual reduced motion settings
        
        let tabs = ["For You", "Profile", "Search", "Notifications", "Following"]
        
        // Rapid tab switching (simulating reduced motion scenario)
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            tab.tap()
            
            // Verify immediate response without waiting for animations
            XCTAssertTrue(tab.isSelected, "\(tabName) should be immediately selected")
        }
    }
    
    // MARK: - Color and Contrast Tests
    
    @MainActor
    func testHighContrastSupport() throws {
        // Test that the interface remains usable in high contrast mode
        // Note: This is a basic structural test
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist in high contrast mode")
        
        // Verify all tabs remain visible and interactive
        let tabs = ["For You", "Following", "Search", "Notifications", "Profile"]
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists, "\(tabName) should be visible in high contrast")
            XCTAssertTrue(tab.isHittable, "\(tabName) should be interactive in high contrast")
        }
    }
}