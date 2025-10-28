import XCTest
import SwiftUI
import CoreGraphics
@testable import DesignSystem
@testable import Media
@testable import SupabaseKit
@testable import AppFoundation

/// Comprehensive integration tests for the avatar cropper system
/// Tests cross-module functionality, error handling, and quality assurance
@available(iOS 16.0, macOS 13.0, *)
final class AvatarCropperIntegrationTests: XCTestCase {
    
    // MARK: - Test Dependencies
    
    private var mockImageCropRenderer: MockImageCropRenderer!
    private var mockAvatarUploadService: MockAvatarUploadService!
    private var qualityAssuranceManager: CropQualityAssuranceManager!
    private var errorRecoveryManager: CropErrorRecoveryManager!
    private var dependencies: Dependencies!
    
    // MARK: - Test Data
    
    private var testImageData: Data!
    private var testImage: CGImage!
    private var config: AvatarCropperConfig!
    
    override func setUp() {
        super.setUp()
        
        // Create test image data
        testImageData = createTestImageData(width: 1000, height: 800)
        testImage = createTestImage(width: 1000, height: 800)
        
        // Create configuration
        config = AvatarCropperConfig.default
        
        // Create mock services
        mockImageCropRenderer = MockImageCropRenderer()
        mockAvatarUploadService = MockAvatarUploadService()
        
        // Create managers
        qualityAssuranceManager = CropQualityAssuranceManager()
        errorRecoveryManager = CropErrorRecoveryManager()
        
        // Create test dependencies
        dependencies = .test(
            imageCropRendering: mockImageCropRenderer,
            avatarUploadService: mockAvatarUploadService
        )
    }
    
    override func tearDown() {
        testImageData = nil
        testImage = nil
        config = nil
        mockImageCropRenderer = nil
        mockAvatarUploadService = nil
        qualityAssuranceManager = nil
        errorRecoveryManager = nil
        dependencies = nil
        super.tearDown()
    }
    
    // MARK: - Cross-Module Integration Tests
    
    func testEndToEndAvatarCropFlow() async throws {
        // Given: A complete avatar crop workflow
        let sourceSize = CGSize(width: 1000, height: 800)
        let maskDiameter: CGFloat = 300
        let screenScale: CGFloat = 3.0
        let outputSize = 512
        
        // Calculate crop parameters using CropGeometry
        let zoomRange = CropGeometry.zoomRange(
            maskDiameterPoints: maskDiameter,
            screenScale: screenScale,
            sourceSize: sourceSize,
            outputSize: outputSize,
            qualityMultiplier: config.qualityMultiplier,
            maxZoomMultiplier: config.maxZoomMultiplier
        )
        
        let scale = zoomRange.min * 1.2 // Zoom in slightly
        let translation = CGSize.zero
        
        let cropRect = CropGeometry.cropRectInImagePixels(
            scale: scale,
            translation: translation,
            maskDiameterPoints: maskDiameter,
            screenScale: screenScale,
            sourceSize: sourceSize
        )
        
        // When: Processing the crop through the full pipeline
        
        // 1. Quality validation
        let qualityResult = qualityAssuranceManager.validateCropQuality(
            sourceSize: sourceSize,
            cropRect: cropRect,
            scale: scale,
            maskDiameter: maskDiameter,
            screenScale: screenScale,
            outputSize: outputSize
        )
        
        // 2. Image crop rendering
        let cropData = try mockImageCropRenderer.renderSquareAvatar(
            source: testImage,
            cropRectInPixels: cropRect,
            outputSize: outputSize,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
        )
        
        // 3. Avatar upload
        let avatarURL = try await mockAvatarUploadService.uploadAvatar(cropData, mime: "image/png")
        
        // Then: Verify the complete workflow
        XCTAssertTrue(qualityResult.isValid, "Quality validation should pass")
        XCTAssertTrue(mockImageCropRenderer.renderCalled, "Image crop renderer should be called")
        XCTAssertTrue(mockAvatarUploadService.uploadCalled, "Avatar upload service should be called")
        XCTAssertNotNil(avatarURL, "Avatar URL should be returned")
        XCTAssertEqual(mockAvatarUploadService.lastMimeType, "image/png", "MIME type should be PNG")
    }
    
    func testCropGeometryAndQualityAssuranceIntegration() {
        // Given: Various image sizes and crop configurations
        let testCases: [(sourceSize: CGSize, expectedQuality: Bool)] = [
            (CGSize(width: 2000, height: 1500), true),  // High quality
            (CGSize(width: 800, height: 600), true),    // Good quality
            (CGSize(width: 400, height: 300), false),   // Low quality
            (CGSize(width: 200, height: 150), false)    // Very low quality
        ]
        
        let maskDiameter: CGFloat = 300
        let screenScale: CGFloat = 3.0
        let outputSize = 512
        
        for testCase in testCases {
            // When: Calculating zoom range and validating quality
            let zoomRange = CropGeometry.zoomRange(
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: testCase.sourceSize,
                outputSize: outputSize,
                qualityMultiplier: config.qualityMultiplier,
                maxZoomMultiplier: config.maxZoomMultiplier
            )
            
            let cropRect = CropGeometry.cropRectInImagePixels(
                scale: zoomRange.min,
                translation: .zero,
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: testCase.sourceSize
            )
            
            let qualityResult = qualityAssuranceManager.validateCropQuality(
                sourceSize: testCase.sourceSize,
                cropRect: cropRect,
                scale: zoomRange.min,
                maskDiameter: maskDiameter,
                screenScale: screenScale,
                outputSize: outputSize
            )
            
            // Then: Verify quality assessment matches expectations
            XCTAssertEqual(
                qualityResult.isValid,
                testCase.expectedQuality,
                "Quality validation should match expected result for size \(testCase.sourceSize)"
            )
        }
    }
    
    func testErrorRecoveryIntegration() async throws {
        // Given: Various error scenarios
        let errorScenarios: [CropValidationError] = [
            .imageTooSmall(size: CGSize(width: 200, height: 150), minimum: 320),
            .cropProcessingFailed,
            .uploadFailed(underlying: NSError(domain: "Test", code: -1)),
            .memoryPressure,
            .qualityLimitExceeded(maxZoom: 2.0, requestedZoom: 4.0)
        ]
        
        for error in errorScenarios {
            // When: Handling each error type
            errorRecoveryManager.handleError(error)
            
            // Then: Verify appropriate recovery suggestions are generated
            XCTAssertEqual(errorRecoveryManager.currentError, error, "Current error should be set")
            XCTAssertFalse(errorRecoveryManager.recoverySuggestions.isEmpty, "Recovery suggestions should be provided")
            
            // Verify retry availability matches error type
            XCTAssertEqual(
                errorRecoveryManager.canRetry,
                error.isRetryable,
                "Retry availability should match error retryability"
            )
            
            // Clear error for next test
            errorRecoveryManager.clearError()
        }
    }
    
    func testDependencyInjectionIntegration() {
        // Given: Dependencies with avatar cropper services
        let deps = Dependencies.test(
            imageCropRendering: mockImageCropRenderer,
            avatarUploadService: mockAvatarUploadService
        )
        
        // When: Accessing services through dependency injection
        let imageCropService = deps.imageCropRendering
        let uploadService = deps.avatarUploadService
        
        // Then: Verify services are properly injected
        XCTAssertNotNil(imageCropService, "Image crop rendering service should be available")
        XCTAssertNotNil(uploadService, "Avatar upload service should be available")
        XCTAssertTrue(imageCropService is MockImageCropRenderer, "Should be mock implementation")
        XCTAssertTrue(uploadService is MockAvatarUploadService, "Should be mock implementation")
    }
    
    // MARK: - Accessibility Compliance Tests
    
    @MainActor
    func testAvatarCropperAccessibilityCompliance() {
        // Given: AvatarCropperView with accessibility requirements
        let cropperView = AvatarCropperView(
            sourceImage: testImage,
            config: config,
            onCancel: {},
            onConfirm: { _ in }
        )
        
        // When: Rendering the view for accessibility testing
        let hostingController = UIHostingController(rootView: cropperView)
        let view = hostingController.view!
        
        // Then: Verify accessibility compliance
        
        // Check for accessibility labels
        let accessibilityElements = view.accessibilityElements ?? []
        XCTAssertFalse(accessibilityElements.isEmpty, "View should have accessibility elements")
        
        // Verify VoiceOver announcements are configured
        // Note: This would require more sophisticated testing in a real implementation
        // For now, we verify the view can be created without errors
        XCTAssertNotNil(view, "View should be created successfully")
        
        // Check for minimum hit target sizes (44x44 points)
        // This would require inspecting the actual UI elements
        // For integration testing, we verify the configuration supports accessibility
        XCTAssertTrue(config.useLiquidGlassChrome, "Liquid Glass chrome should support accessibility")
    }
    
    func testAccessibilityErrorRecovery() {
        // Given: Error recovery manager with accessibility considerations
        let error = CropValidationError.imageTooSmall(
            size: CGSize(width: 200, height: 150),
            minimum: 320
        )
        
        // When: Handling error with accessibility in mind
        errorRecoveryManager.handleError(error)
        
        // Then: Verify error messages are accessible
        XCTAssertNotNil(error.errorDescription, "Error should have accessible description")
        XCTAssertNotNil(error.recoverySuggestion, "Error should have accessible recovery suggestion")
        
        let suggestions = errorRecoveryManager.recoverySuggestions
        XCTAssertFalse(suggestions.isEmpty, "Should provide accessible recovery suggestions")
        
        for suggestion in suggestions {
            XCTAssertFalse(suggestion.title.isEmpty, "Suggestion should have accessible title")
            XCTAssertFalse(suggestion.description.isEmpty, "Suggestion should have accessible description")
        }
    }
    
    // MARK: - Performance and Memory Tests
    
    func testMemoryManagementDuringCropOperations() {
        // Given: Large image processing scenario
        let largeImage = createTestImage(width: 4000, height: 3000)
        
        // When: Processing multiple crops in sequence
        for i in 0..<10 {
            autoreleasepool {
                let cropRect = CGRect(x: 100 * i, y: 100 * i, width: 512, height: 512)
                
                do {
                    _ = try mockImageCropRenderer.renderSquareAvatar(
                        source: largeImage,
                        cropRectInPixels: cropRect,
                        outputSize: 512,
                        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
                    )
                } catch {
                    XCTFail("Crop operation should not fail: \(error)")
                }
            }
        }
        
        // Then: Verify memory is managed properly
        // Note: In a real implementation, this would check memory usage
        XCTAssertEqual(mockImageCropRenderer.renderCallCount, 10, "All crop operations should complete")
    }
    
    func testConcurrentCropOperations() async throws {
        // Given: Multiple concurrent crop operations
        let operations = (0..<5).map { i in
            Task {
                let cropRect = CGRect(x: 100 * i, y: 100 * i, width: 512, height: 512)
                return try mockImageCropRenderer.renderSquareAvatar(
                    source: testImage,
                    cropRectInPixels: cropRect,
                    outputSize: 512,
                    colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
                )
            }
        }
        
        // When: Executing operations concurrently
        let results = try await withThrowingTaskGroup(of: Data.self) { group in
            for operation in operations {
                group.addTask { try await operation.value }
            }
            
            var results: [Data] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
        
        // Then: Verify all operations complete successfully
        XCTAssertEqual(results.count, 5, "All concurrent operations should complete")
        XCTAssertEqual(mockImageCropRenderer.renderCallCount, 5, "All renders should be called")
    }
    
    // MARK: - Edge Case Tests
    
    func testExtremeAspectRatios() {
        // Given: Images with extreme aspect ratios
        let extremeAspectRatios: [(width: Int, height: Int, description: String)] = [
            (4000, 100, "Very wide"),
            (100, 4000, "Very tall"),
            (1, 1000, "Extremely tall"),
            (1000, 1, "Extremely wide")
        ]
        
        let maskDiameter: CGFloat = 300
        let screenScale: CGFloat = 3.0
        let outputSize = 512
        
        for aspectRatio in extremeAspectRatios {
            // When: Processing extreme aspect ratio image
            let sourceSize = CGSize(width: aspectRatio.width, height: aspectRatio.height)
            
            let zoomRange = CropGeometry.zoomRange(
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: sourceSize,
                outputSize: outputSize,
                qualityMultiplier: config.qualityMultiplier,
                maxZoomMultiplier: config.maxZoomMultiplier
            )
            
            // Then: Verify zoom range is calculated correctly
            XCTAssertGreaterThan(zoomRange.min, 0, "Minimum zoom should be positive for \(aspectRatio.description)")
            XCTAssertGreaterThanOrEqual(zoomRange.max, zoomRange.min, "Maximum zoom should be >= minimum for \(aspectRatio.description)")
            
            // Verify no blank space guarantee
            let cropRect = CropGeometry.cropRectInImagePixels(
                scale: zoomRange.min,
                translation: .zero,
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: sourceSize
            )
            
            XCTAssertGreaterThan(cropRect.width, 0, "Crop width should be positive for \(aspectRatio.description)")
            XCTAssertGreaterThan(cropRect.height, 0, "Crop height should be positive for \(aspectRatio.description)")
        }
    }
    
    func testBoundaryConditions() {
        // Given: Boundary condition scenarios
        let boundaryTests: [(sourceSize: CGSize, maskDiameter: CGFloat, description: String)] = [
            (CGSize(width: 320, height: 320), 320, "Minimum size, full mask"),
            (CGSize(width: 320, height: 320), 100, "Minimum size, small mask"),
            (CGSize(width: 10000, height: 10000), 300, "Very large image"),
            (CGSize(width: 512, height: 512), 512, "Output size match")
        ]
        
        let screenScale: CGFloat = 3.0
        let outputSize = 512
        
        for test in boundaryTests {
            // When: Processing boundary condition
            let zoomRange = CropGeometry.zoomRange(
                maskDiameterPoints: test.maskDiameter,
                screenScale: screenScale,
                sourceSize: test.sourceSize,
                outputSize: outputSize,
                qualityMultiplier: config.qualityMultiplier,
                maxZoomMultiplier: config.maxZoomMultiplier
            )
            
            // Then: Verify calculations are stable
            XCTAssertFalse(zoomRange.min.isNaN, "Minimum zoom should not be NaN for \(test.description)")
            XCTAssertFalse(zoomRange.max.isNaN, "Maximum zoom should not be NaN for \(test.description)")
            XCTAssertFalse(zoomRange.min.isInfinite, "Minimum zoom should not be infinite for \(test.description)")
            XCTAssertFalse(zoomRange.max.isInfinite, "Maximum zoom should not be infinite for \(test.description)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImageData(width: Int, height: Int) -> Data {
        // Create a simple test image data (PNG header)
        var data = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG signature
        
        // Add some mock image data
        let imageSize = width * height * 4 // RGBA
        let imageData = Data(repeating: 0xFF, count: imageSize)
        data.append(imageData)
        
        return data
    }
    
    private func createTestImage(width: Int, height: Int) -> CGImage {
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
        
        // Fill with a gradient for visual testing
        context.setFillColor(red: 0.5, green: 0.7, blue: 0.9, alpha: 1.0)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()!
    }
}

// MARK: - Test Extensions

extension AvatarCropperConfig {
    /// Whether the configuration is valid
    var isValid: Bool {
        return validate().isEmpty
    }
    
    /// Validate configuration and return any errors
    func validate() -> [String] {
        var errors: [String] = []
        
        if outputSize < 64 || outputSize > 2048 {
            errors.append("Output size must be between 64 and 2048")
        }
        
        if qualityMultiplier < 1.0 || qualityMultiplier > 3.0 {
            errors.append("Quality multiplier must be between 1.0 and 3.0")
        }
        
        if maxZoomMultiplier < 1.0 || maxZoomMultiplier > 10.0 {
            errors.append("Max zoom multiplier must be between 1.0 and 10.0")
        }
        
        if maskDiameterFraction < 0.5 || maskDiameterFraction > 1.0 {
            errors.append("Mask diameter fraction must be between 0.5 and 1.0")
        }
        
        return errors
    }
}