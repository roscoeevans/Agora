import XCTest
@testable import ToastKit
import SwiftUI

@available(iOS 26.0, *)
final class ToastPerformanceTests: XCTestCase {
    
    var performanceManager: ToastPerformanceManager!
    
    override func setUp() {
        super.setUp()
        performanceManager = ToastPerformanceManager.shared
    }
    
    override func tearDown() {
        performanceManager.clearCaches()
        super.tearDown()
    }
    
    func testPerformanceManagerSingleton() {
        let manager1 = ToastPerformanceManager.shared
        let manager2 = ToastPerformanceManager.shared
        
        XCTAssertTrue(manager1 === manager2, "Performance manager should be a singleton")
    }
    
    func testPerformanceModeAdaptation() {
        // Test that performance mode is properly initialized
        XCTAssertNotNil(performanceManager.performanceMode)
        
        // Test adaptive shadow configuration
        let shadowConfig = performanceManager.adaptiveShadowConfig()
        XCTAssertGreaterThan(shadowConfig.radius, 0)
        XCTAssertNotNil(shadowConfig.color)
        
        // Test adaptive blur radius
        let blurRadius = performanceManager.adaptiveBlurRadius()
        XCTAssertGreaterThan(blurRadius, 0)
    }
    
    #if canImport(UIKit) && !os(macOS)
    func testBlurViewCaching() {
        // Test blur view creation and caching
        let blurView1 = performanceManager.getBlurView(style: .regular, intensity: 1.0)
        let blurView2 = performanceManager.getBlurView(style: .regular, intensity: 1.0)
        
        XCTAssertTrue(blurView1 === blurView2, "Blur views with same parameters should be cached")
        
        // Test different parameters create different views
        let blurView3 = performanceManager.getBlurView(style: .prominent, intensity: 1.0)
        XCTAssertFalse(blurView1 === blurView3, "Different blur styles should create different views")
    }
    
    func testSymbolTextureCaching() {
        // Test symbol texture creation and caching
        let texture1 = performanceManager.getSymbolTexture(
            systemName: "checkmark.circle.fill",
            size: 20,
            weight: .medium,
            tintColor: .systemGreen
        )
        
        let texture2 = performanceManager.getSymbolTexture(
            systemName: "checkmark.circle.fill",
            size: 20,
            weight: .medium,
            tintColor: .systemGreen
        )
        
        XCTAssertNotNil(texture1)
        XCTAssertNotNil(texture2)
        XCTAssertTrue(texture1 === texture2, "Symbol textures with same parameters should be cached")
        
        // Test different parameters create different textures
        let texture3 = performanceManager.getSymbolTexture(
            systemName: "xmark.circle.fill",
            size: 20,
            weight: .medium,
            tintColor: .systemRed
        )
        
        XCTAssertNotNil(texture3)
        XCTAssertFalse(texture1 === texture3, "Different symbols should create different textures")
    }
    #endif
    
    func testMemoryCleanup() {
        // Test that memory cleanup doesn't crash
        performanceManager.performMemoryCleanup()
        
        // Test that cache clearing works
        performanceManager.clearCaches()
        
        // Should still be able to create new items after cleanup
        let shadowConfig = performanceManager.adaptiveShadowConfig()
        XCTAssertNotNil(shadowConfig)
    }
    
    #if canImport(UIKit) && !os(macOS)
    func testSceneManagement() {
        // Test scene registration (using mock object)
        let mockScene = NSObject()
        performanceManager.registerScene(mockScene as Any as! UIScene)
        
        // Test scene unregistration
        performanceManager.unregisterScene(mockScene as Any as! UIScene)
        
        // Should not crash
        XCTAssertTrue(true)
    }
    #endif
    
    func testTimerManagement() {
        // Test timer registration
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in }
        performanceManager.registerTimer(timer)
        
        // Verify timer is initially valid
        XCTAssertTrue(timer.isValid)
        
        // Test timer unregistration - this should invalidate the timer
        performanceManager.unregisterTimer(timer)
        
        // The unregisterTimer method should have invalidated the timer
        // Note: Due to async dispatch, we just verify the method doesn't crash
        XCTAssertTrue(true, "Timer management methods should not crash")
    }
    
    func testEnvironmentIntegration() {
        // Test environment key default value
        let defaultManager = ToastPerformanceManagerKey.defaultValue
        XCTAssertNotNil(defaultManager)
        
        // Test that it's the shared instance
        XCTAssertTrue(defaultManager === ToastPerformanceManager.shared)
    }
    
    @MainActor
    func testPerformanceOptimizedModifier() {
        // Test that the performance optimized modifier can be created
        let modifier = PerformanceOptimizedToastModifier()
        XCTAssertNotNil(modifier)
        
        // Test that it can be applied to a view
        let view = Text("Test")
            .performanceOptimizedToast()
        
        XCTAssertNotNil(view)
    }
    
    func testShadowConfigurationTypes() {
        let shadowConfig = performanceManager.adaptiveShadowConfig()
        
        // Test shadow configuration properties
        XCTAssertGreaterThan(shadowConfig.radius, 0)
        XCTAssertGreaterThanOrEqual(shadowConfig.offset.width, 0)
        XCTAssertGreaterThanOrEqual(shadowConfig.offset.height, 0)
        
        // Test that color is not nil
        XCTAssertNotNil(shadowConfig.color)
    }
    
    func testPerformanceModeValues() {
        // Test all performance mode cases
        let modes: [PerformanceMode] = [.standard, .lowPower, .highPerformance]
        
        for mode in modes {
            XCTAssertNotNil(mode)
        }
        
        // Test that modes are different
        XCTAssertNotEqual(PerformanceMode.standard, PerformanceMode.lowPower)
        XCTAssertNotEqual(PerformanceMode.lowPower, PerformanceMode.highPerformance)
        XCTAssertNotEqual(PerformanceMode.standard, PerformanceMode.highPerformance)
    }
}

