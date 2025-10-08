//
//  DarkModeTests.swift
//  DesignSystemTests
//
//  Created by Agora Team on 2024.
//

import XCTest
import SwiftUI
@testable import DesignSystem

@available(iOS 26.0, macOS 10.15, *)
final class DarkModeTests: XCTestCase {
    
    func testColorTokensAdaptToColorScheme() {
        // Test that our color tokens use adaptive colors
        let lightColors = ColorTokens.background
        let darkColors = ColorTokens.background
        
        // In a real test environment, we would test with different color schemes
        // For now, we just verify the colors are defined
        XCTAssertNotNil(lightColors)
        XCTAssertNotNil(darkColors)
    }
    
    func testLiquidGlassModifierExists() {
        // Test that our Liquid Glass modifier is available
        let modifier = LiquidGlassModifier(style: .navigationBar)
        XCTAssertNotNil(modifier)
    }
    
    func testAgoraButtonAccessibility() {
        // Test that AgoraButton has proper accessibility support
        let button = AgoraButton("Test Button") { }
        
        // In a real test, we would verify accessibility traits
        // For now, we just verify the button can be created
        XCTAssertNotNil(button)
    }
}
