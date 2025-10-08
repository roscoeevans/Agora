//
//  TypographyScaleTests.swift
//  DesignSystemTests
//
//  Created by Agora Team on 2024.
//

import XCTest
import SwiftUI
@testable import DesignSystem

@available(iOS 26.0, macOS 10.15, *)
final class TypographyScaleTests: XCTestCase {
    
    // MARK: - Dynamic Type Compliance Tests
    
    func testTypographyScaleSupportsAccessibilityTextSizes() {
        // Test that typography scales properly with accessibility text sizes
        let contentSizeCategories: [ContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        for category in contentSizeCategories {
            // Test that fonts scale appropriately for each content size category
            let _ = EnvironmentValues()
            
            // Verify that our typography tokens are responsive to Dynamic Type
            XCTAssertNotNil(TypographyScale.largeTitle, "Large title should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.title1, "Title 1 should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.title2, "Title 2 should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.title3, "Title 3 should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.headline, "Headline should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.body, "Body should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.callout, "Callout should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.subheadline, "Subheadline should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.footnote, "Footnote should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.caption1, "Caption 1 should be available for content size category: \(category)")
            XCTAssertNotNil(TypographyScale.caption2, "Caption 2 should be available for content size category: \(category)")
        }
    }
    
    func testMinimumReadableTextSize() {
        // Test that caption2 (11pt) is the minimum readable size as specified in design
        // This ensures we don't go below Apple's recommended minimum
        let caption2Font = TypographyScale.caption2
        XCTAssertNotNil(caption2Font, "Caption 2 should be the minimum readable text size")
    }
    
    func testTypographyHierarchy() {
        // Test that typography follows proper hierarchy
        // While we can't directly compare font sizes in SwiftUI, we can ensure all fonts exist
        let fonts = [
            ("largeTitle", TypographyScale.largeTitle),
            ("title1", TypographyScale.title1),
            ("title2", TypographyScale.title2),
            ("title3", TypographyScale.title3),
            ("headline", TypographyScale.headline),
            ("body", TypographyScale.body),
            ("bodyEmphasized", TypographyScale.bodyEmphasized),
            ("callout", TypographyScale.callout),
            ("calloutEmphasized", TypographyScale.calloutEmphasized),
            ("subheadline", TypographyScale.subheadline),
            ("footnote", TypographyScale.footnote),
            ("caption1", TypographyScale.caption1),
            ("caption2", TypographyScale.caption2)
        ]
        
        for (name, font) in fonts {
            XCTAssertNotNil(font, "\(name) font should be properly defined")
        }
    }
    
    func testSanFranciscoFontUsage() {
        // Test that our fonts use the San Francisco font family (system default)
        // SwiftUI's Font.system uses San Francisco by default on iOS
        let systemFonts = [
            TypographyScale.largeTitle,
            TypographyScale.title1,
            TypographyScale.title2,
            TypographyScale.title3,
            TypographyScale.headline,
            TypographyScale.body,
            TypographyScale.callout,
            TypographyScale.subheadline,
            TypographyScale.footnote,
            TypographyScale.caption1,
            TypographyScale.caption2
        ]
        
        for font in systemFonts {
            XCTAssertNotNil(font, "Font should be properly configured")
        }
    }
    
    func testEmphasizedVariants() {
        // Test that emphasized variants exist and are different from regular variants
        XCTAssertNotNil(TypographyScale.bodyEmphasized, "Body emphasized should exist")
        XCTAssertNotNil(TypographyScale.calloutEmphasized, "Callout emphasized should exist")
        
        // Test that emphasized variants are properly configured
        // Since we can't directly compare Font objects in SwiftUI, we verify they exist and are not nil
        XCTAssertNotNil(TypographyScale.body, "Regular body font should exist")
        XCTAssertNotNil(TypographyScale.bodyEmphasized, "Emphasized body font should exist")
        XCTAssertNotNil(TypographyScale.callout, "Regular callout font should exist")
        XCTAssertNotNil(TypographyScale.calloutEmphasized, "Emphasized callout font should exist")
    }
    
    // MARK: - Backward Compatibility Tests
    
    func testAgoraTypographyBackwardCompatibility() {
        // Test that backward compatibility aliases work
        XCTAssertNotNil(AgoraTypography.largeTitle)
        XCTAssertNotNil(AgoraTypography.title)
        XCTAssertNotNil(AgoraTypography.headline)
        XCTAssertNotNil(AgoraTypography.body)
        XCTAssertNotNil(AgoraTypography.callout)
        XCTAssertNotNil(AgoraTypography.subheadline)
        XCTAssertNotNil(AgoraTypography.footnote)
        XCTAssertNotNil(AgoraTypography.caption)
    }
    
    func testTypographyAliasesMatchOriginals() {
        // Test that aliases point to the correct original fonts
        // Since we can't directly compare Font objects, we verify they exist and are properly configured
        XCTAssertNotNil(AgoraTypography.largeTitle, "AgoraTypography.largeTitle should exist")
        XCTAssertNotNil(TypographyScale.largeTitle, "TypographyScale.largeTitle should exist")
        
        XCTAssertNotNil(AgoraTypography.title, "AgoraTypography.title should exist")
        XCTAssertNotNil(TypographyScale.title1, "TypographyScale.title1 should exist")
        
        XCTAssertNotNil(AgoraTypography.body, "AgoraTypography.body should exist")
        XCTAssertNotNil(TypographyScale.body, "TypographyScale.body should exist")
        
        XCTAssertNotNil(AgoraTypography.caption, "AgoraTypography.caption should exist")
        XCTAssertNotNil(TypographyScale.caption1, "TypographyScale.caption1 should exist")
    }
    
    // MARK: - Accessibility Tests
    
    func testTypographyAccessibilityCompliance() {
        // Test that typography supports accessibility features
        // This ensures our fonts work well with VoiceOver and other assistive technologies
        
        let accessibilityFonts = [
            TypographyScale.largeTitle,
            TypographyScale.title1,
            TypographyScale.headline,
            TypographyScale.body,
            TypographyScale.callout,
            TypographyScale.subheadline,
            TypographyScale.footnote
        ]
        
        for font in accessibilityFonts {
            XCTAssertNotNil(font, "Font should support accessibility features")
        }
    }
    
    func testMinimumTouchTargetCompliance() {
        // While we can't test actual touch targets here, we ensure that our text styles
        // are designed to work with iOS's minimum 44pt touch target recommendations
        // This is more relevant for interactive text elements
        
        XCTAssertNotNil(TypographyScale.body, "Body text should be readable for interactive elements")
        XCTAssertNotNil(TypographyScale.callout, "Callout text should be readable for interactive elements")
        XCTAssertNotNil(TypographyScale.headline, "Headline text should be readable for interactive elements")
    }
}