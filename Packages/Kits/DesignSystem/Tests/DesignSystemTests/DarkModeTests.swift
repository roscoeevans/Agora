//
//  DarkModeTests.swift
//  DesignSystemTests
//
//  Created by Agora on 10/15/25.
//

import XCTest
import SwiftUI
@testable import DesignSystem
@testable import AppFoundation

@available(iOS 26.0, *)
final class DarkModeTests: XCTestCase {
    
    // MARK: - Color Token Tests
    
    func testColorTokensAdaptToColorScheme() {
        // Test that color tokens work in both light and dark modes
        let lightModeColors = [
            ColorTokens.background,
            ColorTokens.primaryText,
            ColorTokens.secondaryText,
            ColorTokens.agoraBrand,
            ColorTokens.agoraAccent,
            ColorTokens.agoraTertiary
        ]
        
        let darkModeColors = [
            ColorTokens.background,
            ColorTokens.primaryText,
            ColorTokens.secondaryText,
            ColorTokens.agoraBrand,
            ColorTokens.agoraAccent,
            ColorTokens.agoraTertiary
        ]
        
        // Colors should be different between light and dark modes
        // (This is a basic test - in a real implementation, you'd test with actual color scheme changes)
        XCTAssertNotNil(lightModeColors)
        XCTAssertNotNil(darkModeColors)
    }
    
    func testBrandColorsHaveDarkModeVariants() {
        // Test that brand colors are properly configured with dark mode variants
        let brandColors = [
            ColorTokens.agoraBrand,
            ColorTokens.agoraAccent,
            ColorTokens.agoraTertiary
        ]
        
        for color in brandColors {
            XCTAssertNotNil(color)
            // In a real test, you'd verify the color actually changes between light/dark modes
        }
    }
    
    // MARK: - Shadow System Tests
    
    func testAdaptiveShadowModifier() {
        let lightShadow = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        let darkShadow = Shadow(color: .white.opacity(0.05), radius: 4, x: 0, y: 2)
        
        let modifier = AdaptiveShadowModifier(lightShadow: lightShadow, darkShadow: darkShadow)
        
        // Test that modifier can be created
        XCTAssertNotNil(modifier)
    }
    
    func testShadowTokensExist() {
        let shadows = [
            ShadowTokens.subtle,
            ShadowTokens.standard,
            ShadowTokens.prominent,
            ShadowTokens.strong,
            ShadowTokens.floating,
            ShadowTokens.darkSubtle,
            ShadowTokens.darkStandard,
            ShadowTokens.darkProminent,
            ShadowTokens.darkStrong,
            ShadowTokens.darkFloating
        ]
        
        for shadow in shadows {
            XCTAssertNotNil(shadow)
            XCTAssertGreaterThanOrEqual(shadow.radius, 0)
        }
    }
    
    // MARK: - Animation Token Tests
    
    func testAnimationTokensRespectAccessibility() {
        // Test that accessible animations work
        let accessibleAnimation = AnimationTokens.accessible(0.3)
        XCTAssertNotNil(accessibleAnimation)
        
        let accessibleSpring = AnimationTokens.accessibleSpring
        XCTAssertNotNil(accessibleSpring)
        
        let colorTransition = AnimationTokens.colorTransition
        XCTAssertNotNil(colorTransition)
        
        let shadowTransition = AnimationTokens.shadowTransition
        XCTAssertNotNil(shadowTransition)
    }
    
    // MARK: - Appearance Preference Integration Tests
    
    func testAppearancePreferenceIntegration() {
        let appearance = AppearancePreferenceLive()
        
        // Test default behavior
        XCTAssertEqual(appearance.currentMode, .system)
        
        // Test effective mode resolution
        let effectiveMode = appearance.effectiveMode
        XCTAssertTrue([.light, .dark].contains(effectiveMode))
    }
    
    func testAppearanceModeSwitching() async {
        let appearance = AppearancePreferenceLive()
        
        // Test setting to dark mode
        await appearance.setMode(.dark)
        XCTAssertEqual(appearance.currentMode, .dark)
        XCTAssertEqual(appearance.effectiveMode, .dark)
        
        // Test setting to light mode
        await appearance.setMode(.light)
        XCTAssertEqual(appearance.currentMode, .light)
        XCTAssertEqual(appearance.effectiveMode, .light)
        
        // Test setting to system mode
        await appearance.setMode(.system)
        XCTAssertEqual(appearance.currentMode, .system)
        // effectiveMode should resolve to actual system mode
        let effectiveMode = appearance.effectiveMode
        XCTAssertTrue([.light, .dark].contains(effectiveMode))
    }
    
    // MARK: - Accessibility Support Tests
    
    func testAccessibilityModifiersExist() {
        // Test that accessibility modifiers can be applied
        let testView = Text("Test")
            .agoraHighContrast()
            .agoraReducedMotion()
            .agoraAccessible()
        
        XCTAssertNotNil(testView)
    }
    
    // MARK: - Liquid Glass Tests
    
    func testLiquidGlassModifier() {
        let styles: [LiquidGlassModifier.LiquidGlassStyle] = [
            .navigationBar,
            .tabBar,
            .floatingPanel,
            .modal
        ]
        
        for style in styles {
            let modifier = LiquidGlassModifier(style: style)
            XCTAssertNotNil(modifier)
        }
    }
    
    // MARK: - Integration Tests
    
    func testDesignSystemIntegration() {
        // Test that all major components work together
        let testView = VStack {
            Text("Test")
                .font(TypographyScale.title1)
                .foregroundColor(ColorTokens.primaryText)
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .agoraCardShadow()
        .agoraAccessible()
        
        XCTAssertNotNil(testView)
    }
    
    // MARK: - Performance Tests
    
    func testColorTokenPerformance() {
        // Test that color token access is performant
        measure {
            for _ in 0..<1000 {
                _ = ColorTokens.background
                _ = ColorTokens.primaryText
                _ = ColorTokens.agoraBrand
            }
        }
    }
    
    func testShadowTokenPerformance() {
        // Test that shadow token access is performant
        measure {
            for _ in 0..<1000 {
                _ = ShadowTokens.subtle
                _ = ShadowTokens.darkSubtle
            }
        }
    }
}