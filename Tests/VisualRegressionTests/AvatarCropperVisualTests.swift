import XCTest
import SwiftUI
import CoreGraphics
@testable import DesignSystem
@testable import AppFoundation

/// Visual regression tests for the avatar cropper system
/// Validates UI appearance, layout, and visual consistency across different configurations
@available(iOS 16.0, macOS 13.0, *)
final class AvatarCropperVisualTests: XCTestCase {
    
    // MARK: - Test Data
    
    private var testImages: [String: CGImage] = [:]
    private var baselineConfigs: [String: AvatarCropperConfig] = [:]
    
    override func setUp() {
        super.setUp()
        setupTestImages()
        setupBaselineConfigs()
    }
    
    override func tearDown() {
        testImages.removeAll()
        baselineConfigs.removeAll()
        super.tearDown()
    }
    
    // MARK: - UI Component Visual Tests
    
    @MainActor
    func testAvatarCropperViewBaseline() {
        // Given: Standard avatar cropper configuration
        let config = baselineConfigs["standard"]!
        let testImage = testImages["square"]!
        
        // When: Rendering the avatar cropper view
        let cropperView = AvatarCropperView(
            sourceImage: testImage,
            config: config,
            onCancel: {},
            onConfirm: { _ in }
        )
        
        // Then: Capture and validate visual appearance
        let snapshot = captureSnapshot(of: cropperView, size: CGSize(width: 375, height: 812))
        XCTAssertNotNil(snapshot, "Should capture baseline snapshot")
        
        // Note: In a real implementation, this would compare against stored baseline images
        validateSnapshotBaseline(snapshot, identifier: "avatar_cropper_baseline")
    }
    
    @MainActor
    func testLiquidGlassChromeAppearance() {
        // Given: Configuration with Liquid Glass chrome enabled
        var config = baselineConfigs["standard"]!
        config.useLiquidGlassChrome = true
        
        let testImage = testImages["landscape"]!
        
        // When: Rendering with Liquid Glass chrome
        let cropperView = AvatarCropperView(
            sourceImage: testImage,
            config: config,
            onCancel: {},
            onConfirm: { _ in }
        )
        
        // Then: Validate chrome appearance
        let snapshot = captureSnapshot(of: cropperView, size: CGSize(width: 375, height: 812))
        validateSnapshotBaseline(snapshot, identifier: "liquid_glass_chrome")
        
        // Test without chrome for comparison
        config.useLiquidGlassChrome = false
        let cropperViewNoChrome = AvatarCropperView(
            sourceImage: testImage,
            config: config,
            onCancel: {},
            onConfirm: { _ in }
        )
        
        let snapshotNoChrome = captureSnapshot(of: cropperViewNoChrome, size: CGSize(width: 375, height: 812))
        validateSnapshotBaseline(snapshotNoChrome, identifier: "no_chrome")
        
        // Verify visual differences
        XCTAssertNotEqual(snapshot?.pngData(), snapshotNoChrome?.pngData(), 
                         "Chrome and no-chrome versions should look different")
    }
    
    @MainActor
    func testGridOverlayVisibility() {
        // Given: Configuration with grid overlay
        var configWithGrid = baselineConfigs["standard"]!
        configWithGrid.showGrid = true
        
        var configWithoutGrid = baselineConfigs["standard"]!
        configWithoutGrid.showGrid = false
        
        let testImage = testImages["portrait"]!
        
        // When: Rendering with and without grid
        let cropperWithGrid = AvatarCropperView(
            sourceImage: testImage,
            config: configWithGrid,
            onCancel: {},
            onConfirm: { _ in }
        )
        
        let cropperWithoutGrid = AvatarCropperView(
            sourceImage: testImage,
            config: configWithoutGrid,
            onCancel: {},
            onConfirm: { _ in }
        )
        
        // Then: Validate grid appearance
        let snapshotWithGrid = captureSnapshot(of: cropperWithGrid, size: CGSize(width: 375, height: 812))
        let snapshotWithoutGrid = captureSnapshot(of: cropperWithoutGrid, size: CGSize(width: 375, height: 812))
        
        validateSnapshotBaseline(snapshotWithGrid, identifier: "with_grid")
        validateSnapshotBaseline(snapshotWithoutGrid, identifier: "without_grid")
        
        // Verify visual differences
        XCTAssertNotEqual(snapshotWithGrid?.pngData(), snapshotWithoutGrid?.pngData(),
                         "Grid visibility should create visual difference")
    }
    
    // MARK: - Quality Warning Visual Tests
    
    @MainActor
    func testQualityWarningAppearance() {
        // Given: Different quality warnings
        let warnings: [QualityWarning] = [
            .lowPixelDensity(current: 0.8, minimum: 1.0),
            .qualityLimitedZoom(current: 1.0, minimum: 2.0),
            .cropAreaTooSmall(current: CGSize(width: 400, height: 400), minimum: CGSize(width: 640, height: 640)),
            .sourceImageTooSmall(current: 200, minimum: 320)
        ]
        
        for (index, warning) in warnings.enumerated() {
            // When: Rendering quality warning view
            let warningView = QualityWarningView(warning: warning) {
                // Dismiss action
            }
            
            // Then: Capture warning appearance
            let snapshot = captureSnapshot(of: warningView, size: CGSize(width: 350, height: 80))
            validateSnapshotBaseline(snapshot, identifier: "quality_warning_\(index)")
        }
    }
    
    @MainActor
    func testQualityMetricsDisplay() {
        // Given: Different quality metrics scenarios
        let metricsScenarios: [(QualityMetrics, String)] = [
            (createHighQualityMetrics(), "high_quality"),
            (createMediumQualityMetrics(), "medium_quality"),
            (createLowQualityMetrics(), "low_quality")
        ]
        
        for (metrics, identifier) in metricsScenarios {
            // When: Rendering quality metrics view
            let metricsView = QualityMetricsView(metrics: metrics)
            
            // Then: Capture metrics display
            let snapshot = captureSnapshot(of: metricsView, size: CGSize(width: 300, height: 150))
            validateSnapshotBaseline(snapshot, identifier: "quality_metrics_\(identifier)")
        }
    }
    
    // MARK: - Error Recovery Visual Tests
    
    @MainActor
    func testErrorRecoveryViewAppearance() {
        // Given: Error recovery manager with different errors
        let errorScenarios: [(CropValidationError, String)] = [
            (.imageTooSmall(size: CGSize(width: 200, height: 150), minimum: 320), "image_too_small"),
            (.cropProcessingFailed, "processing_failed"),
            (.uploadFailed(underlying: NSError(domain: "Test", code: -1)), "upload_failed"),
            (.memoryPressure, "memory_pressure")
        ]
        
        for (error, identifier) in errorScenarios {
            // When: Creating error recovery view
            let recoveryManager = CropErrorRecoveryManager()
            recoveryManager.handleError(error)
            
            let recoveryView = CropErrorRecoveryView(recoveryManager: recoveryManager) { _ in
                // Action handler
            }
            
            // Then: Capture error recovery appearance
            let snapshot = captureSnapshot(of: recoveryView, size: CGSize(width: 350, height: 400))
            validateSnapshotBaseline(snapshot, identifier: "error_recovery_\(identifier)")
        }
    }
    
    // MARK: - Different Image Aspect Ratios
    
    @MainActor
    func testDifferentAspectRatios() {
        // Given: Images with different aspect ratios
        let aspectRatioTests: [(String, String)] = [
            ("square", "1_1_aspect"),
            ("landscape", "16_9_aspect"),
            ("portrait", "9_16_aspect"),
            ("wide", "21_9_aspect"),
            ("tall", "9_21_aspect")
        ]
        
        let config = baselineConfigs["standard"]!
        
        for (imageKey, identifier) in aspectRatioTests {
            guard let testImage = testImages[imageKey] else { continue }
            
            // When: Rendering cropper with different aspect ratios
            let cropperView = AvatarCropperView(
                sourceImage: testImage,
                config: config,
                onCancel: {},
                onConfirm: { _ in }
            )
            
            // Then: Capture aspect ratio handling
            let snapshot = captureSnapshot(of: cropperView, size: CGSize(width: 375, height: 812))
            validateSnapshotBaseline(snapshot, identifier: "aspect_ratio_\(identifier)")
        }
    }
    
    // MARK: - Dark Mode Visual Tests
    
    @MainActor
    func testDarkModeAppearance() {
        // Given: Standard configuration in dark mode
        let config = baselineConfigs["standard"]!
        let testImage = testImages["square"]!
        
        // When: Rendering in dark mode
        let cropperView = AvatarCropperView(
            sourceImage: testImage,
            config: config,
            onCancel: {},
            onConfirm: { _ in }
        )
        .preferredColorScheme(.dark)
        
        // Then: Capture dark mode appearance
        let snapshot = captureSnapshot(of: cropperView, size: CGSize(width: 375, height: 812))
        validateSnapshotBaseline(snapshot, identifier: "dark_mode")
        
        // Compare with light mode
        let lightModeView = AvatarCropperView(
            sourceImage: testImage,
            config: config,
            onCancel: {},
            onConfirm: { _ in }
        )
        .preferredColorScheme(.light)
        
        let lightSnapshot = captureSnapshot(of: lightModeView, size: CGSize(width: 375, height: 812))
        validateSnapshotBaseline(lightSnapshot, identifier: "light_mode")
        
        // Verify visual differences
        XCTAssertNotEqual(snapshot?.pngData(), lightSnapshot?.pngData(),
                         "Dark and light modes should look different")
    }
    
    // MARK: - Device Size Variations
    
    @MainActor
    func testDifferentDeviceSizes() {
        // Given: Different device screen sizes
        let deviceSizes: [(CGSize, String)] = [
            (CGSize(width: 320, height: 568), "iphone_se"),      // iPhone SE
            (CGSize(width: 375, height: 667), "iphone_8"),       // iPhone 8
            (CGSize(width: 375, height: 812), "iphone_x"),       // iPhone X
            (CGSize(width: 414, height: 896), "iphone_11"),      // iPhone 11
            (CGSize(width: 428, height: 926), "iphone_14_pro"),  // iPhone 14 Pro
            (CGSize(width: 768, height: 1024), "ipad"),          // iPad
            (CGSize(width: 1024, height: 1366), "ipad_pro")      // iPad Pro
        ]
        
        let config = baselineConfigs["standard"]!
        let testImage = testImages["square"]!
        
        for (size, identifier) in deviceSizes {
            // When: Rendering on different device sizes
            let cropperView = AvatarCropperView(
                sourceImage: testImage,
                config: config,
                onCancel: {},
                onConfirm: { _ in }
            )
            
            // Then: Capture device-specific layout
            let snapshot = captureSnapshot(of: cropperView, size: size)
            validateSnapshotBaseline(snapshot, identifier: "device_\(identifier)")
        }
    }
    
    // MARK: - Configuration Variations
    
    @MainActor
    func testConfigurationVariations() {
        // Given: Different configuration presets
        let configTests: [(String, String)] = [
            ("standard", "standard_config"),
            ("highQuality", "high_quality_config"),
            ("compact", "compact_config")
        ]
        
        let testImage = testImages["landscape"]!
        
        for (configKey, identifier) in configTests {
            guard let config = baselineConfigs[configKey] else { continue }
            
            // When: Rendering with different configurations
            let cropperView = AvatarCropperView(
                sourceImage: testImage,
                config: config,
                onCancel: {},
                onConfirm: { _ in }
            )
            
            // Then: Capture configuration-specific appearance
            let snapshot = captureSnapshot(of: cropperView, size: CGSize(width: 375, height: 812))
            validateSnapshotBaseline(snapshot, identifier: "config_\(identifier)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupTestImages() {
        testImages["square"] = createTestImage(width: 800, height: 800, pattern: .solid)
        testImages["landscape"] = createTestImage(width: 1200, height: 800, pattern: .gradient)
        testImages["portrait"] = createTestImage(width: 600, height: 900, pattern: .checkerboard)
        testImages["wide"] = createTestImage(width: 1600, height: 600, pattern: .stripes)
        testImages["tall"] = createTestImage(width: 400, height: 1200, pattern: .circles)
    }
    
    private func setupBaselineConfigs() {
        // Standard configuration
        baselineConfigs["standard"] = AvatarCropperConfig()
        
        // High quality configuration
        var highQualityConfig = AvatarCropperConfig()
        highQualityConfig.qualityMultiplier = 2.0
        highQualityConfig.outputSize = 1024
        baselineConfigs["highQuality"] = highQualityConfig
        
        // Compact configuration
        var compactConfig = AvatarCropperConfig()
        compactConfig.maskDiameterFraction = 0.9
        compactConfig.showGrid = false
        compactConfig.useLiquidGlassChrome = false
        baselineConfigs["compact"] = compactConfig
    }
    
    private enum TestPattern {
        case solid, gradient, checkerboard, stripes, circles
    }
    
    private func createTestImage(width: Int, height: Int, pattern: TestPattern) -> CGImage {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        
        switch pattern {
        case .solid:
            context.setFillColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            
        case .gradient:
            let colors = [CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
                         CGColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)]
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil)!
            context.drawLinearGradient(gradient, 
                                     start: CGPoint(x: 0, y: 0), 
                                     end: CGPoint(x: width, y: height), 
                                     options: [])
            
        case .checkerboard:
            let squareSize = 50
            for y in stride(from: 0, to: height, by: squareSize) {
                for x in stride(from: 0, to: width, by: squareSize) {
                    let isEven = ((x / squareSize) + (y / squareSize)) % 2 == 0
                    context.setFillColor(red: isEven ? 1.0 : 0.0, green: isEven ? 1.0 : 0.0, blue: isEven ? 1.0 : 0.0, alpha: 1.0)
                    context.fill(CGRect(x: x, y: y, width: squareSize, height: squareSize))
                }
            }
            
        case .stripes:
            let stripeWidth = 20
            for x in stride(from: 0, to: width, by: stripeWidth * 2) {
                context.setFillColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
                context.fill(CGRect(x: x, y: 0, width: stripeWidth, height: height))
            }
            
        case .circles:
            context.setFillColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            
            context.setFillColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
            let circleSize = 60
            for y in stride(from: circleSize/2, to: height, by: circleSize) {
                for x in stride(from: circleSize/2, to: width, by: circleSize) {
                    context.fillEllipse(in: CGRect(x: x - circleSize/2, y: y - circleSize/2, 
                                                  width: circleSize, height: circleSize))
                }
            }
        }
        
        return context.makeImage()!
    }
    
    private func createHighQualityMetrics() -> QualityMetrics {
        var metrics = QualityMetrics()
        metrics.pixelDensity = 2.5
        metrics.zoomQuality = 2.0
        metrics.cropAreaRatio = 0.8
        metrics.aspectRatioDeviation = 0.0
        return metrics
    }
    
    private func createMediumQualityMetrics() -> QualityMetrics {
        var metrics = QualityMetrics()
        metrics.pixelDensity = 1.5
        metrics.zoomQuality = 1.2
        metrics.cropAreaRatio = 0.5
        metrics.aspectRatioDeviation = 0.05
        return metrics
    }
    
    private func createLowQualityMetrics() -> QualityMetrics {
        var metrics = QualityMetrics()
        metrics.pixelDensity = 0.8
        metrics.zoomQuality = 0.9
        metrics.cropAreaRatio = 0.3
        metrics.aspectRatioDeviation = 0.1
        return metrics
    }
    
    @MainActor
    private func captureSnapshot<V: View>(of view: V, size: CGSize) -> UIImage? {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        hostingController.view.layoutIfNeeded()
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            hostingController.view.layer.render(in: context.cgContext)
        }
    }
    
    private func validateSnapshotBaseline(_ snapshot: UIImage?, identifier: String) {
        guard let snapshot = snapshot else {
            XCTFail("Failed to capture snapshot for \(identifier)")
            return
        }
        
        // Note: In a real implementation, this would:
        // 1. Compare against stored baseline images
        // 2. Calculate pixel differences
        // 3. Report visual regressions
        // 4. Update baselines when approved
        
        // For now, we just verify the snapshot was captured
        XCTAssertNotNil(snapshot.pngData(), "Snapshot should have valid PNG data for \(identifier)")
        
        // Verify minimum image properties
        XCTAssertGreaterThan(snapshot.size.width, 0, "Snapshot width should be positive")
        XCTAssertGreaterThan(snapshot.size.height, 0, "Snapshot height should be positive")
        
        // Log snapshot info for debugging
        print("📸 Captured snapshot '\(identifier)': \(snapshot.size.width)×\(snapshot.size.height)")
    }
}

// MARK: - Visual Test Extensions

extension AvatarCropperConfig {
    /// Create a configuration optimized for visual testing
    static var visualTesting: AvatarCropperConfig {
        var config = AvatarCropperConfig()
        config.showGrid = true
        config.useLiquidGlassChrome = true
        return config
    }
}