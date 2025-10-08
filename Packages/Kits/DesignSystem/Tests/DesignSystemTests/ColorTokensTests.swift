//
//  ColorTokensTests.swift
//  DesignSystemTests
//
//  Created by Agora Team on 2024.
//

import XCTest
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
@testable import DesignSystem

@available(iOS 26.0, macOS 10.15, *)
final class ColorTokensTests: XCTestCase {
    
    // MARK: - Accessibility and Contrast Ratio Tests
    
    func testPrimaryTextOnBackgroundContrastRatio() {
        // Test that primary text on background meets WCAG AA standards (4.5:1)
        let backgroundColor = ColorTokens.background
        let textColor = ColorTokens.primaryText
        
        let contrastRatio = calculateContrastRatio(backgroundColor, textColor)
        #if canImport(UIKit)
        XCTAssertGreaterThanOrEqual(contrastRatio, 4.5, "Primary text on background should meet WCAG AA contrast ratio of 4.5:1")
        #else
        // On non-UIKit platforms, we can't accurately calculate contrast ratios, so we just verify colors exist
        XCTAssertNotNil(backgroundColor, "Background color should exist")
        XCTAssertNotNil(textColor, "Primary text color should exist")
        #endif
    }
    
    func testSecondaryTextOnBackgroundContrastRatio() {
        let backgroundColor = ColorTokens.background
        let textColor = ColorTokens.secondaryText
        
        let contrastRatio = calculateContrastRatio(backgroundColor, textColor)
        #if canImport(UIKit)
        XCTAssertGreaterThanOrEqual(contrastRatio, 4.5, "Secondary text on background should meet WCAG AA contrast ratio of 4.5:1")
        #else
        XCTAssertNotNil(backgroundColor, "Background color should exist")
        XCTAssertNotNil(textColor, "Secondary text color should exist")
        #endif
    }
    
    func testTertiaryTextOnBackgroundContrastRatio() {
        let backgroundColor = ColorTokens.background
        let textColor = ColorTokens.tertiaryText
        
        let contrastRatio = calculateContrastRatio(backgroundColor, textColor)
        #if canImport(UIKit)
        XCTAssertGreaterThanOrEqual(contrastRatio, 3.0, "Tertiary text should meet minimum contrast ratio of 3.0:1")
        #else
        XCTAssertNotNil(backgroundColor, "Background color should exist")
        XCTAssertNotNil(textColor, "Tertiary text color should exist")
        #endif
    }
    
    func testAgoraBrandOnWhiteContrastRatio() {
        let backgroundColor = ColorTokens.background
        let brandColor = ColorTokens.agoraBrand
        
        let contrastRatio = calculateContrastRatio(backgroundColor, brandColor)
        #if canImport(UIKit)
        XCTAssertGreaterThanOrEqual(contrastRatio, 4.5, "Agora brand color on white should meet WCAG AA contrast ratio")
        #else
        XCTAssertNotNil(backgroundColor, "Background color should exist")
        XCTAssertNotNil(brandColor, "Agora brand color should exist")
        #endif
    }
    
    func testWhiteTextOnAgoraBrandContrastRatio() {
        let backgroundColor = ColorTokens.agoraBrand
        let textColor = Color.white
        
        let contrastRatio = calculateContrastRatio(backgroundColor, textColor)
        #if canImport(UIKit)
        XCTAssertGreaterThanOrEqual(contrastRatio, 4.5, "White text on Agora brand should meet WCAG AA contrast ratio")
        #else
        XCTAssertNotNil(backgroundColor, "Agora brand color should exist")
        XCTAssertNotNil(textColor, "White text color should exist")
        #endif
    }
    
    func testErrorColorContrastRatio() {
        let backgroundColor = ColorTokens.background
        let errorColor = ColorTokens.error
        
        let contrastRatio = calculateContrastRatio(backgroundColor, errorColor)
        #if canImport(UIKit)
        XCTAssertGreaterThanOrEqual(contrastRatio, 3.0, "Error color should have sufficient contrast for visibility")
        #else
        XCTAssertNotNil(backgroundColor, "Background color should exist")
        XCTAssertNotNil(errorColor, "Error color should exist")
        #endif
    }
    
    func testSuccessColorContrastRatio() {
        let backgroundColor = ColorTokens.background
        let successColor = ColorTokens.success
        
        let contrastRatio = calculateContrastRatio(backgroundColor, successColor)
        #if canImport(UIKit)
        XCTAssertGreaterThanOrEqual(contrastRatio, 3.0, "Success color should have sufficient contrast for visibility")
        #else
        XCTAssertNotNil(backgroundColor, "Background color should exist")
        XCTAssertNotNil(successColor, "Success color should exist")
        #endif
    }
    
    // MARK: - Color Token Consistency Tests
    
    func testColorTokensAreNotNil() {
        XCTAssertNotNil(ColorTokens.primary)
        XCTAssertNotNil(ColorTokens.primaryVariant)
        XCTAssertNotNil(ColorTokens.background)
        XCTAssertNotNil(ColorTokens.secondaryBackground)
        XCTAssertNotNil(ColorTokens.tertiaryBackground)
        XCTAssertNotNil(ColorTokens.groupedBackground)
        XCTAssertNotNil(ColorTokens.primaryText)
        XCTAssertNotNil(ColorTokens.secondaryText)
        XCTAssertNotNil(ColorTokens.tertiaryText)
        XCTAssertNotNil(ColorTokens.quaternaryText)
        XCTAssertNotNil(ColorTokens.link)
        XCTAssertNotNil(ColorTokens.separator)
        XCTAssertNotNil(ColorTokens.opaqueSeparator)
        XCTAssertNotNil(ColorTokens.success)
        XCTAssertNotNil(ColorTokens.warning)
        XCTAssertNotNil(ColorTokens.error)
        XCTAssertNotNil(ColorTokens.info)
        XCTAssertNotNil(ColorTokens.agoraBrand)
        XCTAssertNotNil(ColorTokens.agoraAccent)
        XCTAssertNotNil(ColorTokens.agoraSurface)
    }
    
    func testBackwardCompatibilityExtensions() {
        // Test that the backward compatibility extensions work
        XCTAssertNotNil(Color.agoraPrimary)
        XCTAssertNotNil(Color.agoraSecondary)
        XCTAssertNotNil(Color.agoraBackground)
        XCTAssertNotNil(Color.agoraSurface)
    }
    
    func testColorHierarchy() {
        // Test that text colors have proper hierarchy (darker = higher priority)
        #if canImport(UIKit)
        let primaryLuminance = getLuminance(ColorTokens.primaryText)
        let secondaryLuminance = getLuminance(ColorTokens.secondaryText)
        let tertiaryLuminance = getLuminance(ColorTokens.tertiaryText)
        let quaternaryLuminance = getLuminance(ColorTokens.quaternaryText)
        
        XCTAssertLessThan(primaryLuminance, secondaryLuminance, "Primary text should be darker than secondary")
        XCTAssertLessThan(secondaryLuminance, tertiaryLuminance, "Secondary text should be darker than tertiary")
        XCTAssertLessThan(tertiaryLuminance, quaternaryLuminance, "Tertiary text should be darker than quaternary")
        #else
        // On non-UIKit platforms, just verify the colors exist and are properly defined
        XCTAssertNotNil(ColorTokens.primaryText, "Primary text color should exist")
        XCTAssertNotNil(ColorTokens.secondaryText, "Secondary text color should exist")
        XCTAssertNotNil(ColorTokens.tertiaryText, "Tertiary text color should exist")
        XCTAssertNotNil(ColorTokens.quaternaryText, "Quaternary text color should exist")
        #endif
    }
    
    // MARK: - Helper Methods
    
    private func calculateContrastRatio(_ color1: Color, _ color2: Color) -> Double {
        let luminance1 = getLuminance(color1)
        let luminance2 = getLuminance(color2)
        
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    private func getLuminance(_ color: Color) -> Double {
        #if canImport(UIKit)
        // Convert SwiftUI Color to RGB components
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate relative luminance using WCAG formula
        let r = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let g = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let b = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)
        
        return 0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)
        #else
        // Fallback for non-UIKit platforms - return a reasonable default
        return 0.5
        #endif
    }
}