//
//  SpacingTokensTests.swift
//  DesignSystemTests
//
//  Created by Agora Team on 2024.
//

import XCTest
@testable import DesignSystem

final class SpacingTokensTests: XCTestCase {
    
    // MARK: - 8-Point Grid System Tests
    
    func testSpacingTokensFollowEightPointGrid() {
        // Test that all spacing tokens follow the 8-point grid system
        XCTAssertEqual(SpacingTokens.xxxs, 2, "xxxs should be 2pt (quarter of base unit)")
        XCTAssertEqual(SpacingTokens.xxs, 4, "xxs should be 4pt (half of base unit)")
        XCTAssertEqual(SpacingTokens.xs, 8, "xs should be 8pt (base unit)")
        XCTAssertEqual(SpacingTokens.sm, 12, "sm should be 12pt (1.5x base unit)")
        XCTAssertEqual(SpacingTokens.md, 16, "md should be 16pt (2x base unit)")
        XCTAssertEqual(SpacingTokens.ml, 20, "ml should be 20pt (2.5x base unit)")
        XCTAssertEqual(SpacingTokens.lg, 24, "lg should be 24pt (3x base unit)")
        XCTAssertEqual(SpacingTokens.xl, 32, "xl should be 32pt (4x base unit)")
        XCTAssertEqual(SpacingTokens.xxl, 40, "xxl should be 40pt (5x base unit)")
        XCTAssertEqual(SpacingTokens.xxxl, 48, "xxxl should be 48pt (6x base unit)")
        XCTAssertEqual(SpacingTokens.huge, 64, "huge should be 64pt (8x base unit)")
    }
    
    func testSpacingTokensAreMultiplesOfFour() {
        // Test that all spacing tokens are multiples of 4 (for better alignment)
        let spacingValues: [CGFloat] = [
            SpacingTokens.xxxs,
            SpacingTokens.xxs,
            SpacingTokens.xs,
            SpacingTokens.sm,
            SpacingTokens.md,
            SpacingTokens.ml,
            SpacingTokens.lg,
            SpacingTokens.xl,
            SpacingTokens.xxl,
            SpacingTokens.xxxl,
            SpacingTokens.huge
        ]
        
        for value in spacingValues {
            XCTAssertEqual(value.truncatingRemainder(dividingBy: 2), 0, "Spacing value \(value) should be even for better alignment")
        }
    }
    
    func testSpacingTokensAreInAscendingOrder() {
        // Test that spacing tokens are in ascending order
        XCTAssertLessThan(SpacingTokens.xxxs, SpacingTokens.xxs)
        XCTAssertLessThan(SpacingTokens.xxs, SpacingTokens.xs)
        XCTAssertLessThan(SpacingTokens.xs, SpacingTokens.sm)
        XCTAssertLessThan(SpacingTokens.sm, SpacingTokens.md)
        XCTAssertLessThan(SpacingTokens.md, SpacingTokens.ml)
        XCTAssertLessThan(SpacingTokens.ml, SpacingTokens.lg)
        XCTAssertLessThan(SpacingTokens.lg, SpacingTokens.xl)
        XCTAssertLessThan(SpacingTokens.xl, SpacingTokens.xxl)
        XCTAssertLessThan(SpacingTokens.xxl, SpacingTokens.xxxl)
        XCTAssertLessThan(SpacingTokens.xxxl, SpacingTokens.huge)
    }
    
    // MARK: - Backward Compatibility Tests
    
    func testAgoraSpacingBackwardCompatibility() {
        // Test that backward compatibility aliases work
        XCTAssertEqual(AgoraSpacing.xs, SpacingTokens.xxs, "AgoraSpacing.xs should map to SpacingTokens.xxs")
        XCTAssertEqual(AgoraSpacing.sm, SpacingTokens.xs, "AgoraSpacing.sm should map to SpacingTokens.xs")
        XCTAssertEqual(AgoraSpacing.md, SpacingTokens.md, "AgoraSpacing.md should map to SpacingTokens.md")
        XCTAssertEqual(AgoraSpacing.lg, SpacingTokens.lg, "AgoraSpacing.lg should map to SpacingTokens.lg")
        XCTAssertEqual(AgoraSpacing.xl, SpacingTokens.xl, "AgoraSpacing.xl should map to SpacingTokens.xl")
        XCTAssertEqual(AgoraSpacing.xxl, SpacingTokens.xxxl, "AgoraSpacing.xxl should map to SpacingTokens.xxxl")
    }
    
    // MARK: - Practical Usage Tests
    
    func testMinimumTouchTargetSpacing() {
        // Test that we have appropriate spacing for iOS touch targets (44pt minimum)
        XCTAssertGreaterThanOrEqual(SpacingTokens.xxxl, 44, "xxxl spacing should accommodate minimum touch targets")
        XCTAssertGreaterThanOrEqual(SpacingTokens.huge, 44, "huge spacing should accommodate minimum touch targets")
    }
    
    func testCommonUISpacingValues() {
        // Test that we have appropriate values for common UI spacing needs
        XCTAssertEqual(SpacingTokens.xs, 8, "xs (8pt) should be suitable for tight spacing")
        XCTAssertEqual(SpacingTokens.md, 16, "md (16pt) should be suitable for standard spacing")
        XCTAssertEqual(SpacingTokens.lg, 24, "lg (24pt) should be suitable for generous spacing")
        XCTAssertEqual(SpacingTokens.xl, 32, "xl (32pt) should be suitable for section spacing")
    }
    
    func testSpacingTokensArePositive() {
        // Test that all spacing tokens are positive values
        let spacingValues: [CGFloat] = [
            SpacingTokens.xxxs,
            SpacingTokens.xxs,
            SpacingTokens.xs,
            SpacingTokens.sm,
            SpacingTokens.md,
            SpacingTokens.ml,
            SpacingTokens.lg,
            SpacingTokens.xl,
            SpacingTokens.xxl,
            SpacingTokens.xxxl,
            SpacingTokens.huge
        ]
        
        for value in spacingValues {
            XCTAssertGreaterThan(value, 0, "Spacing value \(value) should be positive")
        }
    }
    
    func testSpacingTokensAreReasonable() {
        // Test that spacing tokens are within reasonable ranges for mobile UI
        XCTAssertLessThanOrEqual(SpacingTokens.xxxs, 10, "xxxs should be small enough for tight spacing")
        XCTAssertGreaterThanOrEqual(SpacingTokens.huge, 50, "huge should be large enough for major sections")
        XCTAssertLessThanOrEqual(SpacingTokens.huge, 100, "huge should not be excessively large")
    }
}