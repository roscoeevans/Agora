import XCTest
import SwiftUI
@testable import ToastKit

@available(iOS 26.0, *)
final class ToastViewTests: XCTestCase {
    
    @MainActor
    func testToastViewCreation() {
        // Test that ToastView can be created with basic parameters
        let item = ToastItem.success("Test message")
        let view = ToastView(item: item, onDismiss: {})
        
        XCTAssertNotNil(view)
    }
    
    @MainActor
    func testToastViewWithAction() {
        // Test that ToastView can be created with an action
        let item = ToastItem.error("Error message", action: .retry {})
        let view = ToastView(item: item, onDismiss: {}, onAction: {})
        
        XCTAssertNotNil(view)
    }
    
    @MainActor
    func testToastOverlayViewCreation() {
        // Test that ToastOverlayView can be created
        let item = ToastItem.info("Info message")
        let view = ToastOverlayView(
            item: item,
            isPresented: true,
            onDismiss: {}
        )
        
        XCTAssertNotNil(view)
    }
    
    func testToastKindIcons() {
        // Test that all toast kinds have appropriate icons
        XCTAssertNotNil(ToastKind.success.defaultIcon)
        XCTAssertNotNil(ToastKind.error.defaultIcon)
        XCTAssertNotNil(ToastKind.info.defaultIcon)
        XCTAssertNotNil(ToastKind.warning.defaultIcon)
    }
    
    func testToastKindColors() {
        // Test that all toast kinds have appropriate colors
        XCTAssertEqual(ToastKind.success.defaultAccentColor, .green)
        XCTAssertEqual(ToastKind.error.defaultAccentColor, .red)
        XCTAssertEqual(ToastKind.info.defaultAccentColor, .blue)
        XCTAssertEqual(ToastKind.warning.defaultAccentColor, .orange)
    }
    
    func testCustomToastKind() {
        // Test custom toast kind with icon and color
        let customIcon = Image(systemName: "star.fill")
        let customColor = Color.purple
        let customKind = ToastKind.custom(icon: customIcon, accent: customColor)
        
        XCTAssertNotNil(customKind.defaultIcon)
        XCTAssertEqual(customKind.defaultAccentColor, customColor)
    }
}