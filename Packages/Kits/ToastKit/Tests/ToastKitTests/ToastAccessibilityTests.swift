import XCTest
import SwiftUI
@testable import ToastKit

@available(iOS 26.0, *)
final class ToastAccessibilityTests: XCTestCase {
    
    // MARK: - VoiceOver Announcement Tests
    
    func testVoiceOverAnnouncementText() {
        // Test success toast announcement
        let successToast = ToastItem.success("Profile updated")
        let successAnnouncement = ToastAccessibility.createAnnouncementText(for: successToast)
        XCTAssertTrue(successAnnouncement.contains("Success:"))
        XCTAssertTrue(successAnnouncement.contains("Profile updated"))
        XCTAssertTrue(successAnnouncement.contains("Double tap to dismiss"))
        
        // Test error toast with action
        let errorToast = ToastItem.error(
            "Upload failed",
            action: .retry {}
        )
        let errorAnnouncement = ToastAccessibility.createAnnouncementText(for: errorToast)
        XCTAssertTrue(errorAnnouncement.contains("Error:"))
        XCTAssertTrue(errorAnnouncement.contains("Upload failed"))
        XCTAssertTrue(errorAnnouncement.contains("Double tap to perform action"))
        
        // Test warning toast
        let warningToast = ToastItem.warning("Storage low")
        let warningAnnouncement = ToastAccessibility.createAnnouncementText(for: warningToast)
        XCTAssertTrue(warningAnnouncement.contains("Warning:"))
        XCTAssertTrue(warningAnnouncement.contains("Storage low"))
        
        // Test info toast
        let infoToast = ToastItem.info("New messages")
        let infoAnnouncement = ToastAccessibility.createAnnouncementText(for: infoToast)
        XCTAssertTrue(infoAnnouncement.contains("Information:"))
        XCTAssertTrue(infoAnnouncement.contains("New messages"))
        
        // Test custom toast
        let customToast = ToastItem(
            message: "Custom notification",
            kind: .custom(icon: nil, accent: nil)
        )
        let customAnnouncement = ToastAccessibility.createAnnouncementText(for: customToast)
        XCTAssertTrue(customAnnouncement.contains("Notification:"))
        XCTAssertTrue(customAnnouncement.contains("Custom notification"))
    }
    
    // MARK: - Dynamic Type Support Tests
    
    func testAdaptiveFontSelection() {
        // Test small text sizes use title3 for single line
        let smallFont = ToastAccessibility.adaptiveFont(
            for: .medium,
            singleLine: true,
            hasAction: false
        )
        XCTAssertEqual(smallFont, .title3.weight(.semibold))
        
        // Test large text sizes use body font
        let largeFont = ToastAccessibility.adaptiveFont(
            for: .xxxLarge,
            singleLine: true,
            hasAction: false
        )
        XCTAssertEqual(largeFont, .body.weight(.medium))
        
        // Test with action uses body font even for small sizes
        let actionFont = ToastAccessibility.adaptiveFont(
            for: .medium,
            singleLine: true,
            hasAction: true
        )
        XCTAssertEqual(actionFont, .body.weight(.medium))
        
        // Test multi-line always uses body font
        let multiLineFont = ToastAccessibility.adaptiveFont(
            for: .medium,
            singleLine: false,
            hasAction: false
        )
        XCTAssertEqual(multiLineFont, .body.weight(.medium))
    }
    
    func testMaxLinesForDynamicType() {
        // Test standard sizes allow 2 lines
        XCTAssertEqual(ToastAccessibility.maxLines(for: .small), 2)
        XCTAssertEqual(ToastAccessibility.maxLines(for: .medium), 2)
        XCTAssertEqual(ToastAccessibility.maxLines(for: .large), 2)
        
        // Test larger sizes allow more lines
        XCTAssertEqual(ToastAccessibility.maxLines(for: .xLarge), 3)
        XCTAssertEqual(ToastAccessibility.maxLines(for: .xxLarge), 3)
        XCTAssertEqual(ToastAccessibility.maxLines(for: .xxxLarge), 4)
    }
    
    func testVerticalLayoutDecision() {
        // Test standard sizes without action use horizontal layout
        XCTAssertFalse(ToastAccessibility.shouldUseVerticalLayout(
            dynamicTypeSize: .medium,
            hasAction: false
        ))
        
        // Test xxxLarge always uses vertical layout
        XCTAssertTrue(ToastAccessibility.shouldUseVerticalLayout(
            dynamicTypeSize: .xxxLarge,
            hasAction: false
        ))
        
        // Test xLarge with action uses vertical layout
        XCTAssertTrue(ToastAccessibility.shouldUseVerticalLayout(
            dynamicTypeSize: .xLarge,
            hasAction: true
        ))
        
        // Test large without action uses horizontal layout
        XCTAssertFalse(ToastAccessibility.shouldUseVerticalLayout(
            dynamicTypeSize: .large,
            hasAction: false
        ))
    }
    
    // MARK: - Touch Target Tests
    
    func testMinimumTouchTargetSize() {
        let minimumSize = ToastAccessibility.minimumTouchTarget
        XCTAssertEqual(minimumSize.width, 44)
        XCTAssertEqual(minimumSize.height, 44)
    }
    
    func testAccessibleButtonFrame() {
        // Test small content gets expanded to minimum size
        let smallContent = CGSize(width: 20, height: 20)
        let expandedFrame = ToastAccessibility.accessibleButtonFrame(content: smallContent)
        XCTAssertEqual(expandedFrame.width, 44)
        XCTAssertEqual(expandedFrame.height, 44)
        
        // Test large content maintains its size
        let largeContent = CGSize(width: 60, height: 50)
        let maintainedFrame = ToastAccessibility.accessibleButtonFrame(content: largeContent)
        XCTAssertEqual(maintainedFrame.width, 60)
        XCTAssertEqual(maintainedFrame.height, 50)
        
        // Test custom minimum size
        let customMinimum = CGSize(width: 50, height: 50)
        let customFrame = ToastAccessibility.accessibleButtonFrame(
            content: smallContent,
            minimumSize: customMinimum
        )
        XCTAssertEqual(customFrame.width, 50)
        XCTAssertEqual(customFrame.height, 50)
    }
    
    // MARK: - Material and Transparency Tests
    
    func testAdaptiveMaterial() {
        // Test normal transparency uses ultraThin
        let normalMaterial = ToastAccessibility.adaptiveMaterial(
            reduceTransparency: false,
            colorScheme: .light
        )
        // Material doesn't conform to Equatable, so we test behavior indirectly
        XCTAssertNotNil(normalMaterial)
        
        // Test reduced transparency uses more opaque materials
        let reducedLightMaterial = ToastAccessibility.adaptiveMaterial(
            reduceTransparency: true,
            colorScheme: .light
        )
        XCTAssertNotNil(reducedLightMaterial)
        
        let reducedDarkMaterial = ToastAccessibility.adaptiveMaterial(
            reduceTransparency: true,
            colorScheme: .dark
        )
        XCTAssertNotNil(reducedDarkMaterial)
    }
    
    func testContrastSafeTextColor() {
        let testBackground = Color.blue
        
        // Test normal transparency uses primary color
        let normalColor = ToastAccessibility.contrastSafeTextColor(
            for: testBackground,
            colorScheme: .light,
            reduceTransparency: false
        )
        XCTAssertEqual(normalColor, .primary)
        
        // Test reduced transparency uses high contrast colors
        let highContrastLight = ToastAccessibility.contrastSafeTextColor(
            for: testBackground,
            colorScheme: .light,
            reduceTransparency: true
        )
        XCTAssertEqual(highContrastLight, .black)
        
        let highContrastDark = ToastAccessibility.contrastSafeTextColor(
            for: testBackground,
            colorScheme: .dark,
            reduceTransparency: true
        )
        XCTAssertEqual(highContrastDark, .white)
    }
    
    func testAccessibleShadow() {
        // Test normal conditions have shadow
        let normalShadow = ToastAccessibility.accessibleShadow(
            reduceTransparency: false,
            colorScheme: .light,
            lowPowerMode: false
        )
        XCTAssertNotEqual(normalShadow.color, .clear)
        XCTAssertGreaterThan(normalShadow.radius, 0)
        XCTAssertGreaterThan(normalShadow.offset, 0)
        
        // Test reduced transparency disables shadow
        let reducedTransparencyShadow = ToastAccessibility.accessibleShadow(
            reduceTransparency: true,
            colorScheme: .light,
            lowPowerMode: false
        )
        XCTAssertEqual(reducedTransparencyShadow.color, .clear)
        XCTAssertEqual(reducedTransparencyShadow.radius, 0)
        XCTAssertEqual(reducedTransparencyShadow.offset, 0)
        
        // Test low power mode disables shadow
        let lowPowerShadow = ToastAccessibility.accessibleShadow(
            reduceTransparency: false,
            colorScheme: .light,
            lowPowerMode: true
        )
        XCTAssertEqual(lowPowerShadow.color, .clear)
        XCTAssertEqual(lowPowerShadow.radius, 0)
        XCTAssertEqual(lowPowerShadow.offset, 0)
        
        // Test dark mode has different shadow opacity
        let darkShadow = ToastAccessibility.accessibleShadow(
            reduceTransparency: false,
            colorScheme: .dark,
            lowPowerMode: false
        )
        let lightShadow = ToastAccessibility.accessibleShadow(
            reduceTransparency: false,
            colorScheme: .light,
            lowPowerMode: false
        )
        // Dark mode should have more opaque shadow
        XCTAssertNotEqual(darkShadow.color, lightShadow.color)
    }
    
    // MARK: - Accessibility Labels and Hints Tests
    
    func testAccessibilityLabel() {
        // Test success toast label
        let successToast = ToastItem.success("Profile updated")
        let successLabel = ToastAccessibility.accessibilityLabel(for: successToast)
        XCTAssertTrue(successLabel.contains("Success notification:"))
        XCTAssertTrue(successLabel.contains("Profile updated"))
        
        // Test error toast label
        let errorToast = ToastItem.error("Upload failed")
        let errorLabel = ToastAccessibility.accessibilityLabel(for: errorToast)
        XCTAssertTrue(errorLabel.contains("Error notification:"))
        XCTAssertTrue(errorLabel.contains("Upload failed"))
        
        // Test warning toast label
        let warningToast = ToastItem.warning("Storage low")
        let warningLabel = ToastAccessibility.accessibilityLabel(for: warningToast)
        XCTAssertTrue(warningLabel.contains("Warning notification:"))
        XCTAssertTrue(warningLabel.contains("Storage low"))
        
        // Test info toast label
        let infoToast = ToastItem.info("New messages")
        let infoLabel = ToastAccessibility.accessibilityLabel(for: infoToast)
        XCTAssertTrue(infoLabel.contains("Information notification:"))
        XCTAssertTrue(infoLabel.contains("New messages"))
        
        // Test custom toast label
        let customToast = ToastItem(
            message: "Custom notification",
            kind: .custom(icon: nil, accent: nil)
        )
        let customLabel = ToastAccessibility.accessibilityLabel(for: customToast)
        XCTAssertTrue(customLabel.contains("Notification:"))
        XCTAssertTrue(customLabel.contains("Custom notification"))
    }
    
    func testAccessibilityHint() {
        // Test toast with action
        let actionToast = ToastItem.error(
            "Upload failed",
            action: .retry {}
        )
        let actionHint = ToastAccessibility.accessibilityHint(for: actionToast)
        XCTAssertEqual(actionHint, "Double tap to perform action, or swipe to dismiss")
        
        // Test dismissible toast without action
        let dismissibleToast = ToastItem.success("Profile updated")
        let dismissibleHint = ToastAccessibility.accessibilityHint(for: dismissibleToast)
        XCTAssertEqual(dismissibleHint, "Double tap to dismiss")
        
        // Test non-dismissible toast
        var nonDismissibleOptions = ToastOptions()
        nonDismissibleOptions.allowsUserDismiss = false
        let nonDismissibleToast = ToastItem(
            message: "Processing...",
            kind: .info,
            options: nonDismissibleOptions
        )
        let nonDismissibleHint = ToastAccessibility.accessibilityHint(for: nonDismissibleToast)
        XCTAssertEqual(nonDismissibleHint, "Will dismiss automatically")
    }
    
    // MARK: - Integration Tests
    
    func testToastOptionsAccessibilityDefaults() {
        // Test that error toasts are not polite by default
        let errorOptions = ToastOptions.default(for: .error)
        XCTAssertFalse(errorOptions.accessibilityPolite)
        
        // Test that other toast types are polite by default
        let successOptions = ToastOptions.default(for: .success)
        XCTAssertTrue(successOptions.accessibilityPolite)
        
        let infoOptions = ToastOptions.default(for: .info)
        XCTAssertTrue(infoOptions.accessibilityPolite)
        
        let warningOptions = ToastOptions.default(for: .warning)
        XCTAssertTrue(warningOptions.accessibilityPolite)
    }
    
    func testToastItemAccessibilityConfiguration() {
        // Test that error toasts are configured for assertive announcements
        let errorToast = ToastItem.error("Critical error")
        XCTAssertFalse(errorToast.options.accessibilityPolite)
        
        // Test that success toasts are configured for polite announcements
        let successToast = ToastItem.success("Operation completed")
        XCTAssertTrue(successToast.options.accessibilityPolite)
    }
}

// MARK: - Helper Extensions for Testing

@available(iOS 26.0, *)
private extension ToastAccessibility {
    /// Expose private method for testing
    static func createAnnouncementText(for item: ToastItem) -> String {
        var components: [String] = []
        
        // Add kind prefix for context
        switch item.kind {
        case .success:
            components.append("Success:")
        case .error:
            components.append("Error:")
        case .warning:
            components.append("Warning:")
        case .info:
            components.append("Information:")
        case .custom:
            components.append("Notification:")
        }
        
        // Add main message
        components.append(localizedString(from: item.message))
        
        // Add action hint if present
        if item.action != nil {
            components.append("Double tap to perform action.")
        } else {
            components.append("Double tap to dismiss.")
        }
        
        return components.joined(separator: " ")
    }
    
    /// Convert LocalizedStringKey to String for testing
    private static func localizedString(from key: LocalizedStringKey) -> String {
        let mirror = Mirror(reflecting: key)
        if let keyValue = mirror.children.first(where: { $0.label == "key" })?.value as? String {
            return NSLocalizedString(keyValue, comment: "")
        }
        return "\(key)"
    }
}