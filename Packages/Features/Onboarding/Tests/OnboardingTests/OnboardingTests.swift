//
//  OnboardingTests.swift
//  OnboardingTests
//
//  Tests for Onboarding feature
//

import XCTest
@testable import Onboarding

@MainActor
final class OnboardingTests: XCTestCase {
    
    func testOnboardingModule_currentVersion() {
        // Verify version is set
        XCTAssertEqual(OnboardingModule.currentVersion, 1)
        XCTAssertGreaterThan(OnboardingModule.currentVersion, 0)
    }
    
    func testOnboardingPage_hasAllPages() {
        let pages = OnboardingPage.pages
        
        // Should have exactly 4 pages
        XCTAssertEqual(pages.count, 4)
        
        // Verify page IDs are sequential
        for (index, page) in pages.enumerated() {
            XCTAssertEqual(page.id, index)
        }
    }
    
    func testOnboardingPage_firstPageIsWelcome() {
        let firstPage = OnboardingPage.pages.first
        
        XCTAssertNotNil(firstPage)
        XCTAssertEqual(firstPage?.symbolName, "sparkles")
        XCTAssertEqual(firstPage?.title, "Welcome to Agora")
        XCTAssertTrue(firstPage?.body.contains("genuine human connection") ?? false)
    }
    
    func testOnboardingPage_secondPageIsHumanityFirst() {
        guard OnboardingPage.pages.count > 1 else {
            XCTFail("Not enough pages")
            return
        }
        
        let secondPage = OnboardingPage.pages[1]
        
        XCTAssertEqual(secondPage.symbolName, "person.fill.checkmark")
        XCTAssertEqual(secondPage.title, "Humanity First")
        XCTAssertTrue(secondPage.body.contains("no AI-generated content") || secondPage.body.contains("no AI"))
    }
    
    func testOnboardingPage_thirdPageIsSelfDestruct() {
        guard OnboardingPage.pages.count > 2 else {
            XCTFail("Not enough pages")
            return
        }
        
        let thirdPage = OnboardingPage.pages[2]
        
        XCTAssertEqual(thirdPage.symbolName, "timer")
        XCTAssertEqual(thirdPage.title, "Posts That Self-Destruct")
        XCTAssertTrue(thirdPage.body.contains("self-destruct") || thirdPage.body.contains("disappear"))
    }
    
    func testOnboardingPage_fourthPageIsFeed() {
        guard OnboardingPage.pages.count > 3 else {
            XCTFail("Not enough pages")
            return
        }
        
        let fourthPage = OnboardingPage.pages[3]
        
        XCTAssertEqual(fourthPage.symbolName, "chart.line.uptrend.xyaxis")
        XCTAssertTrue(fourthPage.title.contains("Feed") || fourthPage.title.contains("Your Way"))
        XCTAssertTrue(fourthPage.body.contains("For You") || fourthPage.body.contains("Following"))
    }
    
    func testOnboardingPage_allPagesHaveUniqueIDs() {
        let pages = OnboardingPage.pages
        let ids = Set(pages.map(\.id))
        
        // All IDs should be unique
        XCTAssertEqual(ids.count, pages.count)
    }
    
    func testOnboardingPage_allPagesHaveContent() {
        let pages = OnboardingPage.pages
        
        for page in pages {
            XCTAssertFalse(page.symbolName.isEmpty, "Page \(page.id) missing symbol")
            XCTAssertFalse(page.title.isEmpty, "Page \(page.id) missing title")
            XCTAssertFalse(page.body.isEmpty, "Page \(page.id) missing body")
        }
    }
    
    func testOnboardingPage_identifiable() {
        let page = OnboardingPage.pages.first!
        
        // Identifiable conformance
        XCTAssertEqual(page.id, 0)
    }
    
    func testOnboardingPage_equatable() {
        let page1 = OnboardingPage.pages[0]
        let page2 = OnboardingPage.pages[0]
        let page3 = OnboardingPage.pages[1]
        
        // Equatable conformance
        XCTAssertEqual(page1, page2)
        XCTAssertNotEqual(page1, page3)
    }
}

