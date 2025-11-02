import XCTest
@testable import ToastKit

final class ToastKitTests: XCTestCase {
    
    func testToastIDUniqueness() {
        let id1 = ToastID()
        let id2 = ToastID()
        
        XCTAssertNotEqual(id1, id2)
        XCTAssertNotEqual(id1.hashValue, id2.hashValue)
    }
    
    func testToastKindDefaults() {
        XCTAssertNotNil(ToastKind.success.defaultIcon)
        XCTAssertNotNil(ToastKind.error.defaultIcon)
        XCTAssertNotNil(ToastKind.info.defaultIcon)
        XCTAssertNotNil(ToastKind.warning.defaultIcon)
        
        XCTAssertEqual(ToastKind.success.analyticsValue, "success")
        XCTAssertEqual(ToastKind.error.analyticsValue, "error")
    }
    
    func testToastPriorityComparison() {
        XCTAssertTrue(ToastPriority.critical > ToastPriority.elevated)
        XCTAssertTrue(ToastPriority.elevated > ToastPriority.normal)
        XCTAssertTrue(ToastPriority.critical.canInterrupt(.normal))
        XCTAssertFalse(ToastPriority.normal.canInterrupt(.critical))
    }
    
    func testToastItemCreation() {
        let item = ToastItem.success("Test message")
        
        XCTAssertEqual(item.kind.analyticsValue, "success")
        XCTAssertEqual(item.options.priority, .normal)
    }
    
    func testToastCoalescing() {
        var item1 = ToastItem(
            message: "Original",
            kind: .info,
            options: ToastOptions(dedupeKey: "test-key")
        )
        
        let item2 = ToastItem(
            message: "Updated",
            kind: .success,
            options: ToastOptions(dedupeKey: "test-key")
        )
        
        XCTAssertTrue(item1.canCoalesce(with: item2))
        
        let originalId = item1.id
        item1.update(from: item2)
        
        // ID should remain the same, but content should update
        XCTAssertEqual(item1.id, originalId)
        XCTAssertEqual(item1.kind.analyticsValue, "success")
    }
    
    func testToastPolicy() {
        let policy = ToastPolicy.default
        
        XCTAssertEqual(policy.minimumInterval, .milliseconds(800))
        XCTAssertEqual(policy.maxQueueSize, 10)
        XCTAssertTrue(policy.respectLowPowerMode)
    }
    
    func testNoOpProvider() async {
        let provider = NoOpToastProvider()
        
        // Should not crash or throw
        await provider.show(ToastItem.info("Test"))
        await provider.dismissAll()
    }
}