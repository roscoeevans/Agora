//
//  AgoraUITestsLaunchTests.swift
//  AgoraUITests
//
//  Created by Rocky Evans on 10/7/25.
//

import XCTest

final class AgoraUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify app launches successfully by checking for main UI elements
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10.0), "App should launch and display tab bar within 10 seconds")

        // Verify all expected tabs are present after launch
        let expectedTabs = ["For You", "Following", "Search", "Notifications", "Profile"]
        for tabName in expectedTabs {
            let tab = app.tabBars.buttons[tabName]
            XCTAssertTrue(tab.exists, "\(tabName) tab should be present after launch")
        }

        // Verify For You tab is selected by default
        let forYouTab = app.tabBars.buttons["For You"]
        XCTAssertTrue(forYouTab.isSelected, "For You tab should be selected by default")

        // Take screenshot for visual verification
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // Test that app launches within reasonable time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launch()
            
            // Ensure app is fully loaded by waiting for tab bar
            let tabBar = app.tabBars.firstMatch
            _ = tabBar.waitForExistence(timeout: 5.0)
        }
    }
    
    @MainActor
    func testLaunchStability() throws {
        // Test multiple launches to ensure stability
        for i in 1...3 {
            let app = XCUIApplication()
            app.launch()
            
            // Verify successful launch
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0), "Launch \(i) should be successful")
            
            // Terminate app for next iteration
            app.terminate()
            
            // Brief pause between launches
            Thread.sleep(forTimeInterval: 1.0)
        }
    }
    
    @MainActor
    func testLaunchInDifferentOrientations() throws {
        let app = XCUIApplication()
        
        // Test portrait launch (default)
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0), "App should launch successfully in portrait")
        
        app.terminate()
        
        // Test landscape launch
        XCUIDevice.shared.orientation = .landscapeLeft
        app.launch()
        
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5.0), "App should launch successfully in landscape")
        
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
    }
}
