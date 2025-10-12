//
//  HomeTests.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import XCTest
@testable import Home

final class HomeTests: XCTestCase {
    
    func testHomeModuleInitialization() {
        // Given
        let home = Home()
        
        // Then
        XCTAssertNotNil(home)
    }
    
    func testFeedTypeCases() {
        // Given
        let allCases = FeedType.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.forYou))
        XCTAssertTrue(allCases.contains(.following))
    }
    
    func testFeedTypeTitles() {
        // Given & When & Then
        XCTAssertEqual(FeedType.forYou.title, "For You")
        XCTAssertEqual(FeedType.following.title, "Following")
    }
    
    func testFeedTypeRawValues() {
        // Given & When & Then
        XCTAssertEqual(FeedType.forYou.rawValue, "forYou")
        XCTAssertEqual(FeedType.following.rawValue, "following")
    }
}


