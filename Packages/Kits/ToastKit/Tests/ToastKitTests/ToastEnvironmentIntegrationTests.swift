import XCTest
import SwiftUI
@testable import ToastKit

final class ToastEnvironmentIntegrationTests: XCTestCase {
    
    func testToastEnvironmentKeyDefaultValue() {
        let defaultProvider = ToastEnvironmentKey.defaultValue
        XCTAssertTrue(defaultProvider is NoOpToastProvider)
    }
    
    func testToastPolicyKeyDefaultValue() {
        let defaultPolicy = ToastPolicyKey.defaultValue
        XCTAssertEqual(defaultPolicy.minimumInterval, .milliseconds(800))
        XCTAssertEqual(defaultPolicy.maxQueueSize, 10)
    }
    
    func testNoOpToastProvider() async {
        let provider = NoOpToastProvider()
        
        // These should not crash and should complete quickly
        await provider.show(ToastItem.success("Test"))
        await provider.show("Test", kind: .info, options: .init(), action: nil)
        await provider.dismiss(id: ToastID())
        await provider.dismissAll()
        
        // Test convenience methods
        await provider.success("Success")
        await provider.error("Error")
        await provider.info("Info")
        await provider.warning("Warning")
    }
    
    func testToastServiceFactory() {
        let manager = ToastServiceFactory.createToastManager()
        XCTAssertNotNil(manager)
        
        let system = ToastServiceFactory.createToastSystem()
        XCTAssertNotNil(system.manager)
        XCTAssertNotNil(system.sceneManager)
        XCTAssertNotNil(system.policy)
    }
    
    @MainActor
    func testToastServiceSingleton() {
        let service = ToastService.shared
        XCTAssertNotNil(service.manager)
        XCTAssertNotNil(service.sceneManager)
        XCTAssertNotNil(service.policy)
        
        // Test that it's actually a singleton
        let service2 = ToastService.shared
        XCTAssertTrue(service === service2)
    }
    
    func testEnvironmentIntegration() {
        // Test that environment values can be created without crashing
        var environment = EnvironmentValues()
        
        // Test default values
        XCTAssertTrue(environment.toasts is NoOpToastProvider)
        XCTAssertEqual(environment.toastPolicy.maxQueueSize, 10)
        
        // Test setting custom values
        let customManager = ToastServiceFactory.createToastManager()
        let customPolicy = ToastPolicy.conservative
        
        environment.toasts = customManager
        environment.toastPolicy = customPolicy
        
        XCTAssertTrue(environment.toasts is ToastManager)
        XCTAssertEqual(environment.toastPolicy.maxQueueSize, 5) // Conservative policy has maxQueueSize of 5
    }
}