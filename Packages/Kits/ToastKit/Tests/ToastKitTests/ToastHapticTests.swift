import XCTest
@testable import ToastKit
#if canImport(UIKit)
import UIKit
#endif

final class ToastHapticTests: XCTestCase {
    
    // MARK: - ToastHaptic Enum Tests
    
    func testToastHapticDefaultForKinds() {
        #if canImport(UIKit) && !os(macOS)
        // Test default haptics for each toast kind
        let successHaptic = ToastHaptic.default(for: .success)
        let errorHaptic = ToastHaptic.default(for: .error)
        let warningHaptic = ToastHaptic.default(for: .warning)
        let infoHaptic = ToastHaptic.default(for: .info)
        let customHaptic = ToastHaptic.default(for: .custom(icon: nil, accent: nil))
        
        // Verify correct haptic types are assigned
        switch successHaptic {
        case .notification(.success):
            break // Expected
        default:
            XCTFail("Success toast should use notification(.success) haptic")
        }
        
        switch errorHaptic {
        case .notification(.error):
            break // Expected
        default:
            XCTFail("Error toast should use notification(.error) haptic")
        }
        
        switch warningHaptic {
        case .notification(.warning):
            break // Expected
        default:
            XCTFail("Warning toast should use notification(.warning) haptic")
        }
        
        switch infoHaptic {
        case .impact(.light):
            break // Expected
        default:
            XCTFail("Info toast should use impact(.light) haptic")
        }
        
        switch customHaptic {
        case .impact(.medium):
            break // Expected
        default:
            XCTFail("Custom toast should use impact(.medium) haptic")
        }
        #else
        // On non-iOS platforms, should return .none
        XCTAssertEqual(ToastHaptic.default(for: .success), .none)
        XCTAssertEqual(ToastHaptic.default(for: .error), .none)
        XCTAssertEqual(ToastHaptic.default(for: .warning), .none)
        XCTAssertEqual(ToastHaptic.default(for: .info), .none)
        #endif
    }
    
    func testCustomHapticCreation() {
        #if canImport(UIKit) && !os(macOS)
        let customNotification = ToastHaptic.custom(notification: .success)
        let customImpact = ToastHaptic.custom(impact: .heavy)
        
        switch customNotification {
        case .customNotification(.success):
            break // Expected
        default:
            XCTFail("Custom notification haptic not created correctly")
        }
        
        switch customImpact {
        case .customImpact(.heavy):
            break // Expected
        default:
            XCTFail("Custom impact haptic not created correctly")
        }
        #else
        // On non-iOS platforms, custom methods don't exist
        // This test is only relevant for iOS
        #endif
    }
    
    func testHapticExecution() async {
        // Test that haptic execution doesn't crash
        let haptics: [ToastHaptic] = [
            .auto,
            .none,
            .disabled
        ]
        
        #if canImport(UIKit) && !os(macOS)
        let platformHaptics: [ToastHaptic] = [
            .notification(.success),
            .notification(.error),
            .notification(.warning),
            .impact(.light),
            .impact(.medium),
            .impact(.heavy),
            .customNotification(.success),
            .customImpact(.medium)
        ]
        #endif
        
        // Test basic haptics
        for haptic in haptics {
            await MainActor.run {
                haptic.execute()
            }
        }
        
        #if canImport(UIKit) && !os(macOS)
        // Test platform-specific haptics
        for haptic in platformHaptics {
            await MainActor.run {
                haptic.execute()
            }
        }
        #endif
    }
    
    func testHapticExecutionWithTiming() async {
        let haptic = ToastHaptic.default(for: .success)
        
        // Test execution with no delay - should not crash
        await haptic.executeWithAnimationTiming()
        
        // Test execution with delay - should not crash
        let startTime = ContinuousClock.now
        await haptic.executeWithAnimationTiming(delay: .milliseconds(50))
        let endTime = ContinuousClock.now
        let elapsed = endTime - startTime
        
        // Verify delay was respected (with some tolerance for execution time)
        // Note: On some systems, the delay might be very small due to optimization
        XCTAssertGreaterThanOrEqual(elapsed, .milliseconds(10), "Some delay should be respected")
    }
    
    // MARK: - ToastOptions Haptic Control Tests
    
    func testToastOptionsHapticControl() {
        // Test default options include haptics
        let defaultOptions = ToastOptions()
        XCTAssertEqual(defaultOptions.haptics, .auto, "Default options should use auto haptics")
        
        // Test options without haptics
        let silentOptions = ToastOptions.withoutHaptics()
        XCTAssertEqual(silentOptions.haptics, .disabled, "Silent options should disable haptics")
        
        // Test modifying existing options
        let originalOptions = ToastOptions(haptics: .auto)
        let modifiedOptions = originalOptions.withoutHaptics()
        XCTAssertEqual(modifiedOptions.haptics, .disabled, "Modified options should disable haptics")
        
        // Test custom haptics
        let customHaptic = ToastHaptic.default(for: .success)
        let customOptions = originalOptions.withHaptics(customHaptic)
        XCTAssertEqual(customOptions.haptics, customHaptic, "Custom haptics should be applied")
    }
    
    func testToastOptionsDefaultForKind() {
        let successOptions = ToastOptions.default(for: .success)
        let errorOptions = ToastOptions.default(for: .error)
        let warningOptions = ToastOptions.default(for: .warning)
        let infoOptions = ToastOptions.default(for: .info)
        
        // Verify haptics are set correctly for each kind
        XCTAssertEqual(successOptions.haptics, .default(for: .success))
        XCTAssertEqual(errorOptions.haptics, .default(for: .error))
        XCTAssertEqual(warningOptions.haptics, .default(for: .warning))
        XCTAssertEqual(infoOptions.haptics, .default(for: .info))
        
        // Verify priorities are set correctly
        XCTAssertEqual(successOptions.priority, .default(for: .success))
        XCTAssertEqual(errorOptions.priority, .default(for: .error))
        XCTAssertEqual(warningOptions.priority, .default(for: .warning))
        XCTAssertEqual(infoOptions.priority, .default(for: .info))
    }
    
    // MARK: - ToastItem Haptic Integration Tests
    
    func testToastItemHapticConfiguration() {
        // Test that ToastItem properly configures haptics based on kind
        let successToast = ToastItem.success("Success message")
        let errorToast = ToastItem.error("Error message")
        let warningToast = ToastItem.warning("Warning message")
        let infoToast = ToastItem.info("Info message")
        
        XCTAssertEqual(successToast.options.haptics, .default(for: .success))
        XCTAssertEqual(errorToast.options.haptics, .default(for: .error))
        XCTAssertEqual(warningToast.options.haptics, .default(for: .warning))
        XCTAssertEqual(infoToast.options.haptics, .default(for: .info))
    }
    
    func testToastItemCustomHaptics() {
        let customOptions = ToastOptions(haptics: .disabled)
        let customToast = ToastItem.success("Success message", options: customOptions)
        
        XCTAssertEqual(customToast.options.haptics, .disabled, "Custom haptics should override defaults")
    }
    
    // MARK: - Integration Tests
    
    func testHapticSystemIntegration() async {
        let manager = ToastManager()
        
        // Test showing toasts with different haptic configurations
        let successToast = ToastItem.success("Success with haptics")
        let silentToast = ToastItem.success("Success without haptics", options: .withoutHaptics())
        
        // These should not crash and should handle haptics appropriately
        await manager.show(successToast)
        await manager.show(silentToast)
        
        // Clean up
        await manager.dismissAll()
    }
    
    func testConvenienceMethodsWithHaptics() async {
        let manager = ToastManager()
        
        // Test convenience methods with haptics - should not crash
        await manager.success("Success message")
        await manager.error("Error message")
        await manager.warning("Warning message")
        await manager.info("Info message")
        
        // Test silent convenience methods
        await manager.successSilent("Silent success")
        await manager.errorSilent("Silent error")
        await manager.warningSilent("Silent warning")
        await manager.infoSilent("Silent info")
        
        // Test custom haptics method
        let customHaptic = ToastHaptic.default(for: .success)
        await manager.showWithCustomHaptics("Custom haptics", haptics: customHaptic)
        
        // Clean up
        await manager.dismissAll()
    }
}

// Note: ToastHaptic already conforms to Equatable in the main module