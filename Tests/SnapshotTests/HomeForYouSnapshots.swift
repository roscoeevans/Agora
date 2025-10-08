//
//  HomeForYouSnapshots.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import XCTest
import SwiftUI
@testable import HomeForYou

final class HomeForYouSnapshots: XCTestCase {
    func testHomeForYouView() throws {
        let view = HomeForYouView()
        let hostingController = UIHostingController(rootView: view)
        
        // Configure for snapshot testing
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 375, height: 812)
        hostingController.view.backgroundColor = .systemBackground
        
        // Take snapshot
        let snapshot = hostingController.view.snapshot()
        XCTAssertNotNil(snapshot)
    }
    
    func testEmptyState() throws {
        let viewModel = ForYouViewModel()
        let view = HomeForYouView()
        
        // Test empty state
        XCTAssertTrue(viewModel.posts.isEmpty)
    }
}
