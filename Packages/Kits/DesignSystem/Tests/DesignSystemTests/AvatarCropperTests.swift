import XCTest
import SwiftUI
import CoreGraphics
@testable import DesignSystem

@available(iOS 16.0, macOS 13.0, *)
final class AvatarCropperTests: XCTestCase {
    
    // MARK: - Test Data
    
    private var sampleImage: CGImage!
    private var config: AvatarCropperConfig!
    
    override func setUp() {
        super.setUp()
        sampleImage = createTestImage(width: 800, height: 600)
        config = AvatarCropperConfig.default
    }
    
    override func tearDown() {
        sampleImage = nil
        config = nil
        super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testAvatarCropperConfigDefaults() {
        let config = AvatarCropperConfig()
        
        XCTAssertEqual(config.outputSize, 512, "Default output size should be 512")
        XCTAssertEqual(config.qualityMultiplier, 1.25, accuracy: 0.01, "Default quality multiplier should be 1.25")
        XCTAssertEqual(config.maxZoomMultiplier, 4.0, accuracy: 0.01, "Default max zoom multiplier should be 4.0")
        XCTAssertEqual(config.maskDiameterFraction, 0.82, accuracy: 0.01, "Default mask diameter fraction should be 0.82")
        XCTAssertTrue(config.showGrid, "Grid should be shown by default")
        XCTAssertFalse(config.allowRotation, "Rotation should be disabled by default")
        XCTAssertTrue(config.useLiquidGlassChrome, "Liquid Glass chrome should be enabled by default")
        XCTAssertEqual(config.minPixelPerPoint, 1.0, accuracy: 0.01, "Default min pixel per point should be 1.0")
        XCTAssertEqual(config.encoding, .pngSRGB, "Default encoding should be PNG sRGB")
    }
    
    func testAvatarCropperConfigValidation() {
        var config = AvatarCropperConfig()
        
        // Test valid configuration
        XCTAssertTrue(config.isValid, "Default configuration should be valid")
        XCTAssertTrue(config.validate().isEmpty, "Default configuration should have no validation errors")
        
        // Test invalid output size
        config.outputSize = 32 // Too small
        XCTAssertFalse(config.isValid, "Configuration with too small output size should be invalid")
        XCTAssertFalse(config.validate().isEmpty, "Configuration with too small output size should have validation errors")
        
        config.outputSize = 8192 // Too large
        XCTAssertFalse(config.isValid, "Configuration with too large output size should be invalid")
        
        // Reset and test quality multiplier
        config = AvatarCropperConfig()
        config.qualityMultiplier = 0.5 // Too small
        XCTAssertFalse(config.isValid, "Configuration with too small quality multiplier should be invalid")
        
        config.qualityMultiplier = 5.0 // Too large
        XCTAssertFalse(config.isValid, "Configuration with too large quality multiplier should be invalid")
        
        // Reset and test mask diameter fraction
        config = AvatarCropperConfig()
        config.maskDiameterFraction = 0.1 // Too small
        XCTAssertFalse(config.isValid, "Configuration with too small mask diameter should be invalid")
        
        config.maskDiameterFraction = 1.5 // Too large
        XCTAssertFalse(config.isValid, "Configuration with too large mask diameter should be invalid")
    }
    
    func testAvatarCropperConfigMimeTypes() {
        var config = AvatarCropperConfig()
        
        config.encoding = .pngSRGB
        XCTAssertEqual(config.mimeType, "image/png", "PNG encoding should return correct MIME type")
        XCTAssertEqual(config.fileExtension, "png", "PNG encoding should return correct file extension")
        XCTAssertEqual(config.jpegQuality, 1.0, "PNG encoding should return quality 1.0")
        
        config.encoding = .jpegSRGB(quality: 0.8)
        XCTAssertEqual(config.mimeType, "image/jpeg", "JPEG encoding should return correct MIME type")
        XCTAssertEqual(config.fileExtension, "jpg", "JPEG encoding should return correct file extension")
        XCTAssertEqual(config.jpegQuality, 0.8, accuracy: 0.01, "JPEG encoding should return correct quality")
        
        // Test quality clamping
        config.encoding = .jpegSRGB(quality: 1.5) // Too high
        XCTAssertEqual(config.jpegQuality, 1.0, "JPEG quality should be clamped to 1.0")
        
        config.encoding = .jpegSRGB(quality: -0.5) // Too low
        XCTAssertEqual(config.jpegQuality, 0.0, "JPEG quality should be clamped to 0.0")
    }
    
    // MARK: - CropState Tests
    
    @MainActor
    func testCropStateInitialization() {
        let cropState = CropState()
        
        XCTAssertEqual(cropState.scale, 1.0, "Initial scale should be 1.0")
        XCTAssertEqual(cropState.translation, .zero, "Initial translation should be zero")
        XCTAssertFalse(cropState.isGestureActive, "Gesture should not be active initially")
        XCTAssertTrue(cropState.showGrid, "Grid should be shown initially")
        XCTAssertTrue(cropState.showInstructions, "Instructions should be shown initially")
        XCTAssertEqual(cropState.processingState, .idle, "Processing state should be idle initially")
        XCTAssertFalse(cropState.showQualityWarning, "Quality warning should not be shown initially")
    }
    
    @MainActor
    func testCropStateSetup() {
        let cropState = CropState()
        let maskDiameter: CGFloat = 300
        let screenScale: CGFloat = 3.0
        
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: maskDiameter,
            screenScale: screenScale,
            config: config
        )
        
        XCTAssertEqual(cropState.sourceSize, CGSize(width: 800, height: 600), "Source size should be set correctly")
        XCTAssertNotNil(cropState.constraints, "Constraints should be calculated")
        XCTAssertGreaterThan(cropState.scale, 1.0, "Initial scale should be slightly above minimum")
    }
    
    @MainActor
    func testCropStateGestureHandling() {
        let cropState = CropState()
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        // Test gesture begin
        cropState.gestureDidBegin()
        XCTAssertTrue(cropState.isGestureActive, "Gesture should be active after begin")
        XCTAssertFalse(cropState.showGrid, "Grid should be hidden during gesture")
        
        // Test gesture end
        cropState.gestureDidEnd()
        XCTAssertFalse(cropState.isGestureActive, "Gesture should not be active after end")
        XCTAssertTrue(cropState.showGrid, "Grid should be shown after gesture ends")
    }
    
    @MainActor
    func testCropStateScaleConstraints() {
        let cropState = CropState()
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        guard let constraints = cropState.constraints else {
            XCTFail("Constraints should be available")
            return
        }
        
        // Test scale clamping to minimum
        cropState.updateScale(constraints.minScale - 1.0)
        XCTAssertEqual(cropState.scale, constraints.minScale, accuracy: 0.01, "Scale should be clamped to minimum")
        
        // Test scale clamping to maximum
        cropState.updateScale(constraints.maxScale + 1.0)
        XCTAssertEqual(cropState.scale, constraints.maxScale, accuracy: 0.01, "Scale should be clamped to maximum")
        
        // Test valid scale
        let midScale = (constraints.minScale + constraints.maxScale) / 2
        cropState.updateScale(midScale)
        XCTAssertEqual(cropState.scale, midScale, accuracy: 0.01, "Valid scale should be set correctly")
    }
    
    @MainActor
    func testCropStateCropRectCalculation() {
        let cropState = CropState()
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        let cropRect = cropState.calculateCropRect()
        
        XCTAssertGreaterThan(cropRect.width, 0, "Crop rect width should be positive")
        XCTAssertGreaterThan(cropRect.height, 0, "Crop rect height should be positive")
        XCTAssertEqual(cropRect.width, cropRect.height, accuracy: 0.1, "Crop rect should be square")
        XCTAssertGreaterThanOrEqual(cropRect.origin.x, 0, "Crop rect should be within image bounds")
        XCTAssertGreaterThanOrEqual(cropRect.origin.y, 0, "Crop rect should be within image bounds")
        XCTAssertLessThanOrEqual(cropRect.maxX, 800, "Crop rect should be within image bounds")
        XCTAssertLessThanOrEqual(cropRect.maxY, 600, "Crop rect should be within image bounds")
    }
    
    // MARK: - AvatarCropperView Tests
    
    @MainActor
    func testAvatarCropperViewInitialization() {
        let view = AvatarCropperView(
            sourceImage: sampleImage,
            config: config,
            onCancel: {},
            onConfirm: { _ in }
        )
        
        XCTAssertNotNil(view, "AvatarCropperView should initialize successfully")
    }
    
    @MainActor
    func testAvatarCropperViewWithCustomConfig() {
        var customConfig = AvatarCropperConfig()
        customConfig.outputSize = 256
        customConfig.showGrid = false
        customConfig.useLiquidGlassChrome = false
        
        let view = AvatarCropperView(
            sourceImage: sampleImage,
            config: customConfig,
            onCancel: {},
            onConfirm: { _ in }
        )
        
        XCTAssertNotNil(view, "AvatarCropperView with custom config should initialize successfully")
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testAccessibilitySupportInitialization() {
        let cropState = CropState()
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        let accessibility = AccessibilitySupport(
            cropState: cropState,
            config: config,
            onScaleChange: { _ in },
            onReset: {}
        )
        
        XCTAssertNotNil(accessibility, "AccessibilitySupport should initialize successfully")
        XCTAssertFalse(accessibility.cropperAccessibilityLabel.isEmpty, "Accessibility label should not be empty")
        XCTAssertFalse(accessibility.cropperAccessibilityHint.isEmpty, "Accessibility hint should not be empty")
    }
    
    @MainActor
    func testAccessibilityLabelsAndHints() {
        let cropState = CropState()
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        let accessibility = AccessibilitySupport(
            cropState: cropState,
            config: config,
            onScaleChange: { _ in },
            onReset: {}
        )
        
        let label = accessibility.cropperAccessibilityLabel
        let hint = accessibility.cropperAccessibilityHint
        let value = accessibility.cropperAccessibilityValue
        
        XCTAssertTrue(label.contains("Avatar editor"), "Label should mention avatar editor")
        XCTAssertTrue(label.contains("Circular crop"), "Label should mention circular crop")
        XCTAssertTrue(hint.contains("Double-tap"), "Hint should mention double-tap")
        XCTAssertTrue(value.contains("Zoom"), "Value should contain zoom information")
    }
    
    @MainActor
    func testAccessibilityContrastAdjustment() {
        let cropState = CropState()
        let accessibility = AccessibilitySupport(
            cropState: cropState,
            config: config,
            onScaleChange: { _ in },
            onReset: {}
        )
        
        let colors = accessibility.contrastAdjustedColors
        XCTAssertNotNil(colors.background, "Background color should be provided")
        XCTAssertNotNil(colors.foreground, "Foreground color should be provided")
    }
    
    @MainActor
    func testAccessibilityReduceMotionSupport() {
        let cropState = CropState()
        let accessibility = AccessibilitySupport(
            cropState: cropState,
            config: config,
            onScaleChange: { _ in },
            onReset: {}
        )
        
        // Test animation handling for reduce motion
        let animation = Animation.easeInOut(duration: 0.3)
        let result = accessibility.animationForReducedMotion(animation, value: 1.0)
        
        // The result depends on system settings, but should not crash
        XCTAssertNotNil(result, "Animation for reduced motion should return a valid result")
    }
    
    // MARK: - Gesture Handler Tests
    
    @MainActor
    func testCropGestureHandlerInitialization() {
        let cropState = CropState()
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        let gestureHandler = CropGestureHandler(
            cropState: cropState,
            maskDiameter: 300,
            onBoundaryHit: {}
        )
        
        XCTAssertNotNil(gestureHandler, "CropGestureHandler should initialize successfully")
        XCTAssertNotNil(gestureHandler.createGestures(), "Gesture handler should create gestures")
    }
    
    @MainActor
    func testDoubleTapZoomCycling() {
        let cropState = CropState()
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        let gestureHandler = CropGestureHandler(
            cropState: cropState,
            maskDiameter: 300,
            onBoundaryHit: {}
        )
        
        let initialScale = cropState.scale
        let tapLocation = CGPoint(x: 150, y: 150)
        let viewSize = CGSize(width: 600, height: 600)
        
        // Simulate double tap
        gestureHandler.handleDoubleTap(at: tapLocation, in: viewSize)
        
        // Scale should change after double tap
        XCTAssertNotEqual(cropState.scale, initialScale, "Scale should change after double tap")
    }
    
    // MARK: - Integration Tests
    
    @MainActor
    func testFullCropperWorkflow() {
        let cropState = CropState()
        
        // Setup
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        // Verify initial state
        XCTAssertNotNil(cropState.constraints, "Constraints should be calculated")
        XCTAssertGreaterThan(cropState.scale, 1.0, "Initial scale should be above minimum")
        
        // Simulate gesture interaction
        cropState.gestureDidBegin()
        XCTAssertTrue(cropState.isGestureActive, "Gesture should be active")
        
        // Update scale and translation
        if let constraints = cropState.constraints {
            let newScale = (constraints.minScale + constraints.maxScale) / 2
            cropState.updateScale(newScale)
            XCTAssertEqual(cropState.scale, newScale, accuracy: 0.01, "Scale should be updated")
        }
        
        cropState.updateTranslation(CGSize(width: 10, height: 10))
        XCTAssertNotEqual(cropState.translation, .zero, "Translation should be updated")
        
        // End gesture
        cropState.gestureDidEnd()
        XCTAssertFalse(cropState.isGestureActive, "Gesture should not be active")
        
        // Calculate final crop rect
        let cropRect = cropState.calculateCropRect()
        XCTAssertGreaterThan(cropRect.width, 0, "Final crop rect should be valid")
        XCTAssertGreaterThan(cropRect.height, 0, "Final crop rect should be valid")
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testCropStatePerformance() {
        let cropState = CropState()
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        measure {
            // Simulate rapid gesture updates
            for i in 0..<100 {
                let scale = 1.0 + CGFloat(i) * 0.01
                cropState.updateScale(scale)
                
                let translation = CGSize(width: CGFloat(i), height: CGFloat(i))
                cropState.updateTranslation(translation)
                
                _ = cropState.calculateCropRect()
            }
        }
    }
    
    @MainActor
    func testAccessibilityPerformance() {
        let cropState = CropState()
        cropState.setup(
            sourceImage: sampleImage,
            maskDiameter: 300,
            screenScale: 3.0,
            config: config
        )
        
        let accessibility = AccessibilitySupport(
            cropState: cropState,
            config: config,
            onScaleChange: { _ in },
            onReset: {}
        )
        
        measure {
            // Test accessibility value calculation performance
            for _ in 0..<100 {
                _ = accessibility.cropperAccessibilityValue
                _ = accessibility.contrastAdjustedColors
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage(width: Int, height: Int) -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        
        // Fill with a gradient for testing
        context.setFillColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Add some geometric shapes for visual testing
        context.setFillColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.8)
        context.fillEllipse(in: CGRect(x: width/4, y: height/4, width: width/2, height: height/2))
        
        return context.makeImage()!
    }
}

// MARK: - Mock Classes for Testing

@available(iOS 16.0, macOS 13.0, *)
class MockCropState: CropState {
    var mockConstraints: CropConstraints?
    
    override var constraints: CropConstraints? {
        return mockConstraints
    }
    
    func setMockConstraints(_ constraints: CropConstraints) {
        mockConstraints = constraints
    }
}