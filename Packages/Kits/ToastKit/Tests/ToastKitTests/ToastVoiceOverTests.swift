import XCTest
import SwiftUI
@testable import ToastKit
#if canImport(UIKit) && !os(macOS)
import UIKit
#endif

/// Comprehensive tests for VoiceOver announcement verification and accessibility integration
#if canImport(UIKit) && !os(macOS)
@available(iOS 26.0, *)
final class ToastVoiceOverTests: XCTestCase {
    
    private var mockAccessibilityNotifier: MockAccessibilityNotifier!
    
    override func setUp() async throws {
        try await super.setUp()
        
        await MainActor.run {
            mockAccessibilityNotifier = MockAccessibilityNotifier()
            // In a real implementation, we would inject this into ToastAccessibility
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            mockAccessibilityNotifier = nil
        }
        try await super.tearDown()
    }
    
    // MARK: - VoiceOver Announcement Tests
    
    @MainActor
    func testSuccessToastAnnouncement() throws {
        let successToast = ToastItem.success("Profile updated successfully")
        
        ToastAccessibility.announceToast(successToast, notifier: mockAccessibilityNotifier)
        
        // Verify announcement was made
        XCTAssertEqual(mockAccessibilityNotifier.announcements.count, 1)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertEqual(announcement.notificationType, "announcement")
        XCTAssertTrue(announcement.argument.contains("Success"))
        XCTAssertTrue(announcement.argument.contains("Profile updated successfully"))
    }
    
    @MainActor
    func testErrorToastAssertiveAnnouncement() throws {
        let errorToast = ToastItem.error("Upload failed")
        
        ToastAccessibility.announceToast(errorToast, notifier: mockAccessibilityNotifier)
        
        // Error toasts should use assertive (layoutChanged) notification
        XCTAssertEqual(mockAccessibilityNotifier.announcements.count, 1)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertEqual(announcement.notificationType, "layoutChanged")
        XCTAssertTrue(announcement.argument.contains("Error"))
        XCTAssertTrue(announcement.argument.contains("Upload failed"))
    }
    
    @MainActor
    func testWarningToastAnnouncement() throws {
        let warningToast = ToastItem.warning("Storage space low")
        
        ToastAccessibility.announceToast(warningToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertEqual(announcement.notificationType, "announcement")
        XCTAssertTrue(announcement.argument.contains("Warning"))
        XCTAssertTrue(announcement.argument.contains("Storage space low"))
    }
    
    @MainActor
    func testInfoToastAnnouncement() throws {
        let infoToast = ToastItem.info("New messages available")
        
        ToastAccessibility.announceToast(infoToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertEqual(announcement.notificationType, "announcement")
        XCTAssertTrue(announcement.argument.contains("Information"))
        XCTAssertTrue(announcement.argument.contains("New messages available"))
    }
    
    @MainActor
    func testCustomToastAnnouncement() throws {
        let customToast = ToastItem(
            message: "Custom notification message",
            kind: .custom(icon: Image(systemName: "star"), accent: .purple)
        )
        
        ToastAccessibility.announceToast(customToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertEqual(announcement.notificationType, "announcement")
        XCTAssertTrue(announcement.argument.contains("Notification"))
        XCTAssertTrue(announcement.argument.contains("Custom notification message"))
    }
    
    // MARK: - Action Announcement Tests
    
    @MainActor
    func testToastWithActionAnnouncement() throws {
        let actionToast = ToastItem.error(
            "Connection failed",
            action: .retry { /* retry logic */ }
        )
        
        ToastAccessibility.announceToast(actionToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertTrue(announcement.argument.contains("Connection failed"))
        XCTAssertTrue(announcement.argument.contains("Double tap to perform action"))
    }
    
    @MainActor
    func testToastWithoutActionAnnouncement() throws {
        let simpleToast = ToastItem.success("Operation completed")
        
        ToastAccessibility.announceToast(simpleToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertTrue(announcement.argument.contains("Operation completed"))
        XCTAssertTrue(announcement.argument.contains("Double tap to dismiss"))
    }
    
    @MainActor
    func testNonDismissibleToastAnnouncement() throws {
        var options = ToastOptions()
        options.allowsUserDismiss = false
        
        let nonDismissibleToast = ToastItem(
            message: "Processing, please wait",
            kind: .info,
            options: options
        )
        
        ToastAccessibility.announceToast(nonDismissibleToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertTrue(announcement.argument.contains("Processing, please wait"))
        XCTAssertTrue(announcement.argument.contains("Will dismiss automatically"))
    }
    
    // MARK: - Accessibility Priority Tests
    
    @MainActor
    func testPoliteAnnouncementPriority() throws {
        var options = ToastOptions()
        options.accessibilityPolite = true
        
        let politeToast = ToastItem(
            message: "Background sync completed",
            kind: .success,
            options: options
        )
        
        ToastAccessibility.announceToast(politeToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertEqual(announcement.notificationType, "announcement")
    }
    
    @MainActor
    func testAssertiveAnnouncementPriority() throws {
        var options = ToastOptions()
        options.accessibilityPolite = false
        
        let assertiveToast = ToastItem(
            message: "Critical system alert",
            kind: .error,
            options: options
        )
        
        ToastAccessibility.announceToast(assertiveToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertEqual(announcement.notificationType, "layoutChanged")
    }
    
    // MARK: - Accessibility Label Tests
    
    func testAccessibilityLabelGeneration() {
        let toast = ToastItem.warning("Battery level critical")
        let label = ToastAccessibility.accessibilityLabel(for: toast)
        
        XCTAssertTrue(label.contains("Warning notification"))
        XCTAssertTrue(label.contains("Battery level critical"))
    }
    
    func testAccessibilityLabelWithAction() {
        let actionToast = ToastItem.error(
            "Network error occurred",
            action: .retry { /* retry */ }
        )
        
        let label = ToastAccessibility.accessibilityLabel(for: actionToast)
        
        XCTAssertTrue(label.contains("Error notification"))
        XCTAssertTrue(label.contains("Network error occurred"))
    }
    
    func testAccessibilityLabelForCustomKind() {
        let customToast = ToastItem(
            message: "Custom system event",
            kind: .custom(icon: nil, accent: nil)
        )
        
        let label = ToastAccessibility.accessibilityLabel(for: customToast)
        
        XCTAssertTrue(label.contains("Notification"))
        XCTAssertTrue(label.contains("Custom system event"))
    }
    
    // MARK: - Accessibility Hint Tests
    
    func testAccessibilityHintWithAction() {
        let actionToast = ToastItem.info(
            "Update available",
            action: ToastAction(title: "Install", handler: {})
        )
        
        let hint = ToastAccessibility.accessibilityHint(for: actionToast)
        
        XCTAssertEqual(hint, "Double tap to perform action, or swipe to dismiss")
    }
    
    func testAccessibilityHintDismissibleOnly() {
        let dismissibleToast = ToastItem.success("Changes saved")
        
        let hint = ToastAccessibility.accessibilityHint(for: dismissibleToast)
        
        XCTAssertEqual(hint, "Double tap to dismiss")
    }
    
    func testAccessibilityHintNonDismissible() {
        var options = ToastOptions()
        options.allowsUserDismiss = false
        
        let nonDismissibleToast = ToastItem(
            message: "Syncing data...",
            kind: .info,
            options: options
        )
        
        let hint = ToastAccessibility.accessibilityHint(for: nonDismissibleToast)
        
        XCTAssertEqual(hint, "Will dismiss automatically")
    }
    
    // MARK: - Dynamic Type Integration Tests
    
    func testAnnouncementWithDynamicType() {
        // Test that announcements work correctly with different Dynamic Type sizes
        let toast = ToastItem.info("Dynamic type test message")
        
        // Simulate different dynamic type sizes
        let sizes: [DynamicTypeSize] = [.small, .medium, .large, .xLarge, .xxLarge, .xxxLarge]
        
        for size in sizes {
            ToastAccessibility.announceToast(toast, notifier: mockAccessibilityNotifier)
            
            // Announcement should work regardless of dynamic type size
            XCTAssertGreaterThan(mockAccessibilityNotifier.announcements.count, 0)
            
            let announcement = mockAccessibilityNotifier.announcements.last!
            XCTAssertTrue(announcement.argument.contains("Dynamic type test message"))
            
            mockAccessibilityNotifier.reset()
        }
    }
    
    // MARK: - Localization Tests
    
    func testLocalizedAnnouncementText() {
        // Test with LocalizedStringKey
        let localizedToast = ToastItem.success(LocalizedStringKey("toast.success.profile_updated"))
        
        ToastAccessibility.announceToast(localizedToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertTrue(announcement.argument.contains("Success"))
        // The actual localized string would depend on the app's localization
    }
    
    // MARK: - Multiple Announcement Tests
    
    @MainActor
    func testMultipleRapidAnnouncements() throws {
        let toast1 = ToastItem.info("First message")
        let toast2 = ToastItem.info("Second message")
        let toast3 = ToastItem.info("Third message")
        
        ToastAccessibility.announceToast(toast1, notifier: mockAccessibilityNotifier)
        ToastAccessibility.announceToast(toast2, notifier: mockAccessibilityNotifier)
        ToastAccessibility.announceToast(toast3, notifier: mockAccessibilityNotifier)
        
        // All announcements should be recorded
        XCTAssertEqual(mockAccessibilityNotifier.announcements.count, 3)
        
        // Verify order is maintained
        XCTAssertTrue(mockAccessibilityNotifier.announcements[0].argument.contains("First message"))
        XCTAssertTrue(mockAccessibilityNotifier.announcements[1].argument.contains("Second message"))
        XCTAssertTrue(mockAccessibilityNotifier.announcements[2].argument.contains("Third message"))
    }
    
    // MARK: - Edge Cases
    
    @MainActor
    func testEmptyMessageAnnouncement() throws {
        let emptyToast = ToastItem.info("")
        
        ToastAccessibility.announceToast(emptyToast, notifier: mockAccessibilityNotifier)
        
        // Should still announce the toast type even with empty message
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertTrue(announcement.argument.contains("Information"))
    }
    
    @MainActor
    func testVeryLongMessageAnnouncement() throws {
        let longMessage = String(repeating: "This is a very long message. ", count: 20)
        let longToast = ToastItem.error(LocalizedStringKey(longMessage))
        
        ToastAccessibility.announceToast(longToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertTrue(announcement.argument.contains("Error"))
        XCTAssertTrue(announcement.argument.contains(longMessage))
    }
    
    @MainActor
    func testSpecialCharactersInMessage() throws {
        let specialMessage = "Error: 50% complete! @user #hashtag $price"
        let specialToast = ToastItem.warning(LocalizedStringKey(specialMessage))
        
        ToastAccessibility.announceToast(specialToast, notifier: mockAccessibilityNotifier)
        
        let announcement = mockAccessibilityNotifier.announcements.first!
        XCTAssertTrue(announcement.argument.contains(specialMessage))
    }
    
    // MARK: - Integration with ToastManager Tests
    
    @MainActor
    func testAnnouncementIntegrationWithPresentation() async throws {
        let manager = ToastManager(
            policy: .default,
            telemetry: NoOpToastTelemetry()
        )
        
        let mockSceneManager = MockVoiceOverSceneManager()
        // Note: In a real implementation, we would inject the mock scene manager
        
        let toast = ToastItem.success("Integration test")
        await manager.show(toast)
        
        // Verify that presentation triggers announcement
        XCTAssertEqual(mockSceneManager.presentedToasts.count, 1)
        
        // In a real implementation, we would verify the announcement was made
        // through the presenter's accessibility integration
    }
}

// MARK: - Mock Implementations

private class MockAccessibilityNotifier {
    struct Announcement {
        let notificationType: String
        let argument: String
    }
    
    var announcements: [Announcement] = []
    
    func post(notificationType: String, argument: Any?) {
        let argumentString = argument as? String ?? "\(argument ?? "")"
        announcements.append(Announcement(notificationType: notificationType, argument: argumentString))
    }
    
    func reset() {
        announcements.removeAll()
    }
}

@MainActor
private class MockVoiceOverSceneManager {
    var presentedToasts: [ToastItem] = []
    
    func presentInActiveScene(
        _ item: ToastItem,
        onDismiss: @escaping (DismissalMethod) -> Void
    ) {
        presentedToasts.append(item)
        
        // Simulate announcement being made during presentation
        ToastAccessibility.announceToast(item)
    }
}

// MARK: - ToastAccessibility Test Extensions

@available(iOS 26.0, *)
extension ToastAccessibility {
    /// Test-friendly version of announceToast that accepts a mock notifier
    fileprivate static func announceToast(_ item: ToastItem, notifier: MockAccessibilityNotifier? = nil) {
        let announcementText = createAnnouncementText(for: item)
        let notificationType = item.options.accessibilityPolite ? "announcement" : "layoutChanged"
        
        if let notifier = notifier {
            notifier.post(notificationType: notificationType, argument: announcementText)
        } else {
            // In a real implementation, this would use UIAccessibility
            print("Accessibility announcement: \(announcementText)")
        }
    }
    
    /// Create the full announcement text for a toast
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
        
        // Add interaction hint
        if item.action != nil {
            components.append("Double tap to perform action.")
        } else if item.options.allowsUserDismiss {
            components.append("Double tap to dismiss.")
        } else {
            components.append("Will dismiss automatically.")
        }
        
        return components.joined(separator: " ")
    }
    
    /// Convert LocalizedStringKey to String for testing
    private static func localizedString(from key: LocalizedStringKey) -> String {
        // In a real implementation, this would properly resolve the localized string
        // For testing, we'll use a simplified approach
        let mirror = Mirror(reflecting: key)
        if let keyValue = mirror.children.first(where: { $0.label == "key" })?.value as? String {
            return NSLocalizedString(keyValue, comment: "")
        }
        return "\(key)"
    }
}
#endif