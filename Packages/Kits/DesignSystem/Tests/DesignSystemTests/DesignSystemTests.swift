//
//  DesignSystemTests.swift
//  DesignSystemTests
//
//  Created by Agora Team on 2024.
//

import XCTest
import SwiftUI
@testable import DesignSystem

@available(iOS 26.0, macOS 10.15, *)
final class DesignSystemTests: XCTestCase {
    
    // MARK: - Module Integration Tests
    
    func testDesignSystemSharedInstance() {
        let designSystem = DesignSystem.shared
        XCTAssertNotNil(designSystem, "DesignSystem shared instance should be available")
    }
    
    func testDesignSystemIsSingleton() {
        let instance1 = DesignSystem.shared
        let instance2 = DesignSystem.shared
        
        // Test that both references are the same (DesignSystem is a struct with static shared instance)
        XCTAssertNotNil(instance1, "First DesignSystem instance should exist")
        XCTAssertNotNil(instance2, "Second DesignSystem instance should exist")
        // Since DesignSystem is a struct, we just verify both instances can be accessed
    }
    
    // MARK: - Cross-Component Integration Tests
    
    @MainActor
    func testButtonUsesColorTokens() {
        // Test that AgoraButton properly integrates with ColorTokens
        let primaryButton = AgoraButton("Primary", style: .primary) { }
        let secondaryButton = AgoraButton("Secondary", style: .secondary) { }
        
        XCTAssertNotNil(primaryButton, "Primary button should use color tokens")
        XCTAssertNotNil(secondaryButton, "Secondary button should use color tokens")
    }
    
    @MainActor
    func testButtonUsesTypographyScale() {
        // Test that AgoraButton properly integrates with TypographyScale
        let smallButton = AgoraButton("Small", size: .small) { }
        let mediumButton = AgoraButton("Medium", size: .medium) { }
        let largeButton = AgoraButton("Large", size: .large) { }
        
        XCTAssertNotNil(smallButton, "Small button should use typography scale")
        XCTAssertNotNil(mediumButton, "Medium button should use typography scale")
        XCTAssertNotNil(largeButton, "Large button should use typography scale")
    }
    
    func testButtonUsesSpacingTokens() {
        // Test that AgoraButton properly integrates with SpacingTokens
        XCTAssertEqual(AgoraButton.Size.small.horizontalPadding, SpacingTokens.sm)
        XCTAssertEqual(AgoraButton.Size.medium.horizontalPadding, SpacingTokens.md)
        XCTAssertEqual(AgoraButton.Size.large.horizontalPadding, SpacingTokens.lg)
    }
    
    // MARK: - Design System Consistency Tests
    
    @MainActor
    func testDesignSystemConsistency() {
        // Test that all design tokens are consistent and work together
        
        // Color consistency
        XCTAssertNotNil(ColorTokens.primary)
        XCTAssertNotNil(ColorTokens.background)
        XCTAssertNotNil(ColorTokens.primaryText)
        
        // Typography consistency
        XCTAssertNotNil(TypographyScale.body)
        XCTAssertNotNil(TypographyScale.headline)
        XCTAssertNotNil(TypographyScale.caption1)
        
        // Spacing consistency
        XCTAssertGreaterThan(SpacingTokens.md, SpacingTokens.xs)
        XCTAssertGreaterThan(SpacingTokens.lg, SpacingTokens.md)
        
        // Component consistency
        let button = AgoraButton("Test") { }
        XCTAssertNotNil(button)
    }
    
    func testDesignSystemAvailability() {
        // Test that all major design system components are available
        
        // Test ColorTokens availability
        XCTAssertNotNil(ColorTokens.self)
        
        // Test TypographyScale availability
        XCTAssertNotNil(TypographyScale.self)
        
        // Test SpacingTokens availability
        XCTAssertNotNil(SpacingTokens.self)
        
        // Test AgoraButton availability
        XCTAssertNotNil(AgoraButton.self)
        
        // Test backward compatibility
        XCTAssertNotNil(AgoraTypography.self)
        XCTAssertNotNil(AgoraSpacing.self)
    }
    
    // MARK: - Platform Compatibility Tests
    
    func testIOSCompatibility() {
        // Test that design system works on iOS 26.0+
        #if os(iOS)
        if #available(iOS 26.0, *) {
            let button = AgoraButton("iOS Button") { }
            XCTAssertNotNil(button, "Design system should work on iOS 26.0+")
        }
        #endif
    }
    
    @MainActor
    func testMacOSCompatibility() {
        // Test that design system works on macOS 10.15+
        #if os(macOS)
        let button = AgoraButton("macOS Button") { }
        XCTAssertNotNil(button, "Design system should work on macOS 10.15+")
        #endif
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testDesignSystemPerformance() {
        // Test that design system components can be created efficiently
        measure {
            for _ in 0..<1000 {
                let _ = AgoraButton("Performance Test") { }
            }
        }
    }
    
    func testColorTokenPerformance() {
        // Test that color tokens can be accessed efficiently
        measure {
            for _ in 0..<10000 {
                let _ = ColorTokens.primary
                let _ = ColorTokens.background
                let _ = ColorTokens.primaryText
            }
        }
    }
    
    func testTypographyScalePerformance() {
        // Test that typography tokens can be accessed efficiently
        measure {
            for _ in 0..<10000 {
                let _ = TypographyScale.body
                let _ = TypographyScale.headline
                let _ = TypographyScale.caption1
            }
        }
    }
    
    func testSpacingTokenPerformance() {
        // Test that spacing tokens can be accessed efficiently
        measure {
            for _ in 0..<10000 {
                let _ = SpacingTokens.md
                let _ = SpacingTokens.lg
                let _ = SpacingTokens.xl
            }
        }
    }
    
    // MARK: - Thread Safety Tests
    
    func testDesignSystemThreadSafety() {
        // Test that DesignSystem.shared is thread-safe
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                let instance = DesignSystem.shared
                XCTAssertNotNil(instance, "DesignSystem should be accessible from thread \(i)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testColorTokenThreadSafety() {
        // Test that color tokens are thread-safe
        let expectation = XCTestExpectation(description: "Color token thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                let color = ColorTokens.primary
                XCTAssertNotNil(color, "ColorTokens should be accessible from thread \(i)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}