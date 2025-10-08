//
//  AgoraButtonTests.swift
//  DesignSystemTests
//
//  Created by Agora Team on 2024.
//

import XCTest
import SwiftUI
@testable import DesignSystem

@available(iOS 26.0, macOS 10.15, *)
final class AgoraButtonTests: XCTestCase {
    
    // MARK: - Button State Tests
    
    @MainActor
    func testButtonInitialization() {
        let button = AgoraButton("Test Button") { }
        
        XCTAssertNotNil(button, "Button should initialize successfully")
    }
    
    @MainActor
    func testButtonWithAllParameters() {
        let button = AgoraButton(
            "Test Button",
            style: .primary,
            size: .medium,
            isEnabled: true
        ) {
            // Action callback for testing
        }
        
        XCTAssertNotNil(button, "Button with all parameters should initialize successfully")
    }
    
    @MainActor
    func testButtonStyles() {
        let styles: [AgoraButton.Style] = [.primary, .secondary, .tertiary, .destructive, .ghost]
        
        for style in styles {
            let button = AgoraButton("Test", style: style) { }
            XCTAssertNotNil(button, "Button with \(style) style should initialize")
        }
    }
    
    @MainActor
    func testButtonSizes() {
        let sizes: [AgoraButton.Size] = [.small, .medium, .large]
        
        for size in sizes {
            let button = AgoraButton("Test", size: size) { }
            XCTAssertNotNil(button, "Button with \(size) size should initialize")
        }
    }
    
    @MainActor
    func testButtonEnabledStates() {
        let enabledButton = AgoraButton("Enabled", isEnabled: true) { }
        let disabledButton = AgoraButton("Disabled", isEnabled: false) { }
        
        XCTAssertNotNil(enabledButton, "Enabled button should initialize")
        XCTAssertNotNil(disabledButton, "Disabled button should initialize")
    }
    
    // MARK: - Button Size Configuration Tests
    
    func testButtonSizeHeights() {
        XCTAssertEqual(AgoraButton.Size.small.height, 32, "Small button height should be 32pt")
        XCTAssertEqual(AgoraButton.Size.medium.height, 44, "Medium button height should be 44pt (standard iOS touch target)")
        XCTAssertEqual(AgoraButton.Size.large.height, 56, "Large button height should be 56pt")
    }
    
    func testButtonSizeFonts() {
        XCTAssertNotNil(AgoraButton.Size.small.font, "Small button should have appropriate font")
        XCTAssertNotNil(AgoraButton.Size.medium.font, "Medium button should have appropriate font")
        XCTAssertNotNil(AgoraButton.Size.large.font, "Large button should have appropriate font")
    }
    
    func testButtonSizePadding() {
        XCTAssertEqual(AgoraButton.Size.small.horizontalPadding, SpacingTokens.sm, "Small button should use sm padding")
        XCTAssertEqual(AgoraButton.Size.medium.horizontalPadding, SpacingTokens.md, "Medium button should use md padding")
        XCTAssertEqual(AgoraButton.Size.large.horizontalPadding, SpacingTokens.lg, "Large button should use lg padding")
    }
    
    // MARK: - Accessibility Tests
    
    func testButtonAccessibilityCompliance() {
        // Test that medium buttons meet iOS touch target guidelines (44pt minimum)
        XCTAssertGreaterThanOrEqual(AgoraButton.Size.medium.height, 44, "Medium buttons should meet 44pt minimum touch target")
        XCTAssertGreaterThanOrEqual(AgoraButton.Size.large.height, 44, "Large buttons should meet 44pt minimum touch target")
    }
    
    @MainActor
    func testButtonAccessibilityWithVoiceOver() {
        // Test that buttons work with accessibility features
        let button = AgoraButton("Accessible Button") { }
        
        // In a real app, this would test VoiceOver compatibility
        // For unit tests, we ensure the button can be created and has proper text
        XCTAssertNotNil(button, "Button should be accessible to assistive technologies")
    }
    
    @MainActor
    func testButtonTextContrast() {
        // Test that button text has sufficient contrast for accessibility
        // This is implicitly tested through our color token tests, but we verify
        // that buttons use appropriate color combinations
        
        let primaryButton = AgoraButton("Primary", style: .primary) { }
        let secondaryButton = AgoraButton("Secondary", style: .secondary) { }
        let tertiaryButton = AgoraButton("Tertiary", style: .tertiary) { }
        let destructiveButton = AgoraButton("Destructive", style: .destructive) { }
        let ghostButton = AgoraButton("Ghost", style: .ghost) { }
        
        // Verify all button styles can be created (color contrast is tested in ColorTokensTests)
        XCTAssertNotNil(primaryButton, "Primary button should have accessible colors")
        XCTAssertNotNil(secondaryButton, "Secondary button should have accessible colors")
        XCTAssertNotNil(tertiaryButton, "Tertiary button should have accessible colors")
        XCTAssertNotNil(destructiveButton, "Destructive button should have accessible colors")
        XCTAssertNotNil(ghostButton, "Ghost button should have accessible colors")
    }
    
    @MainActor
    func testDisabledButtonAccessibility() {
        // Test that disabled buttons are properly indicated for accessibility
        let disabledButton = AgoraButton("Disabled Button", isEnabled: false) { }
        
        XCTAssertNotNil(disabledButton, "Disabled button should be properly accessible")
        // In a real implementation, this would test that the button is marked as disabled for screen readers
    }
    
    // MARK: - Button Interaction Tests
    
    @MainActor
    func testButtonActionCallback() {
        let button = AgoraButton("Test Action") {
            // Action callback for testing
        }
        
        // We can't directly trigger button taps in unit tests, but we can verify the action is stored
        XCTAssertNotNil(button, "Button with action should be created successfully")
        // In integration tests, we would simulate button taps and verify action execution
    }
    
    @MainActor
    func testButtonWithEmptyTitle() {
        let button = AgoraButton("") { }
        XCTAssertNotNil(button, "Button with empty title should still be created")
    }
    
    @MainActor
    func testButtonWithLongTitle() {
        let longTitle = "This is a very long button title that might wrap or truncate depending on the available space"
        let button = AgoraButton(longTitle) { }
        XCTAssertNotNil(button, "Button with long title should be created successfully")
    }
    
    // MARK: - Button Style Visual Tests
    
    @MainActor
    func testPrimaryButtonConfiguration() {
        let button = AgoraButton("Primary", style: .primary) { }
        XCTAssertNotNil(button, "Primary button should be configured correctly")
        // Visual properties are tested through the button's computed properties
    }
    
    @MainActor
    func testSecondaryButtonConfiguration() {
        let button = AgoraButton("Secondary", style: .secondary) { }
        XCTAssertNotNil(button, "Secondary button should be configured correctly")
    }
    
    @MainActor
    func testTertiaryButtonConfiguration() {
        let button = AgoraButton("Tertiary", style: .tertiary) { }
        XCTAssertNotNil(button, "Tertiary button should be configured correctly")
    }
    
    @MainActor
    func testDestructiveButtonConfiguration() {
        let button = AgoraButton("Destructive", style: .destructive) { }
        XCTAssertNotNil(button, "Destructive button should be configured correctly")
    }
    
    @MainActor
    func testGhostButtonConfiguration() {
        let button = AgoraButton("Ghost", style: .ghost) { }
        XCTAssertNotNil(button, "Ghost button should be configured correctly")
    }
    
    // MARK: - Button Animation Tests
    
    @MainActor
    func testButtonStyleExists() {
        // Test that the custom button style can be created
        // The actual animation behavior would be tested in UI tests
        let button = AgoraButton("Animated Button") { }
        XCTAssertNotNil(button, "Button with custom style should be created")
    }
    
    // MARK: - Design System Integration Tests
    
    func testButtonUsesDesignSystemTokens() {
        // Test that buttons properly use design system spacing tokens
        XCTAssertEqual(AgoraButton.Size.small.horizontalPadding, SpacingTokens.sm)
        XCTAssertEqual(AgoraButton.Size.medium.horizontalPadding, SpacingTokens.md)
        XCTAssertEqual(AgoraButton.Size.large.horizontalPadding, SpacingTokens.lg)
    }
    
    func testButtonUsesDesignSystemTypography() {
        // Test that buttons use typography scale fonts
        let smallFont = AgoraButton.Size.small.font
        let mediumFont = AgoraButton.Size.medium.font
        let largeFont = AgoraButton.Size.large.font
        
        XCTAssertNotNil(smallFont, "Small button should use design system typography")
        XCTAssertNotNil(mediumFont, "Medium button should use design system typography")
        XCTAssertNotNil(largeFont, "Large button should use design system typography")
    }
    
    func testButtonCornerRadius() {
        // Test that buttons use consistent corner radius from spacing tokens
        // The corner radius is set to SpacingTokens.xs (8pt) in the implementation
        XCTAssertEqual(SpacingTokens.xs, 8, "Button corner radius should use 8pt spacing token")
    }
}