import XCTest
import CoreGraphics
@testable import Media

final class MediaTests: XCTestCase {
    
    func testMediaModuleExists() {
        let media = Media.shared
        XCTAssertNotNil(media)
    }
    
    func testMediaProcessorInitialization() {
        let processor = MediaProcessor.shared
        XCTAssertNotNil(processor)
    }
    
    func testUploadManagerInitialization() {
        let uploadManager = UploadManager.shared
        XCTAssertNotNil(uploadManager)
    }
    
    func testSelectedMediaCreation() {
        // Create a mock PhotosPickerItem (this would need proper mocking in real tests)
        // For now, just test the MediaType enum
        let mediaType = MediaType.image
        XCTAssertEqual(mediaType, .image)
    }
    
    func testMediaProcessingConfig() {
        let config = MediaProcessingConfig.default
        
        XCTAssertEqual(config.maxImageSize, CGSize(width: 1920, height: 1920))
        XCTAssertEqual(config.imageCompressionQuality, 0.8)
        XCTAssertEqual(config.maxVideoSize, CGSize(width: 1920, height: 1080))
    }
    
    func testUploadConfig() {
        let config = UploadConfig.default
        
        XCTAssertEqual(config.maxFileSize, 100 * 1024 * 1024) // 100MB
        XCTAssertTrue(config.allowedMimeTypes.contains("image/jpeg"))
        XCTAssertTrue(config.allowedMimeTypes.contains("video/mp4"))
        XCTAssertEqual(config.chunkSize, 1024 * 1024) // 1MB
    }
    
    func testUploadProgress() {
        let progress = UploadProgress(bytesUploaded: 50, totalBytes: 100)
        
        XCTAssertEqual(progress.bytesUploaded, 50)
        XCTAssertEqual(progress.totalBytes, 100)
        XCTAssertEqual(progress.percentage, 0.5)
    }
    
    func testUploadProgressZeroTotal() {
        let progress = UploadProgress(bytesUploaded: 0, totalBytes: 0)
        
        XCTAssertEqual(progress.percentage, 0.0)
    }
    
    func testProcessedMediaCreation() {
        let testData = Data("test".utf8)
        let processedMedia = ProcessedMedia(
            processedData: testData,
            type: .image,
            size: CGSize(width: 100, height: 100)
        )
        
        XCTAssertEqual(processedMedia.processedData, testData)
        XCTAssertEqual(processedMedia.type, .image)
        XCTAssertEqual(processedMedia.size, CGSize(width: 100, height: 100))
    }
    
    func testUploadResult() {
        let testURL = URL(string: "https://example.com/media.jpg")!
        let result = UploadResult(
            mediaId: "test-id",
            url: testURL,
            size: 1024,
            type: .image
        )
        
        XCTAssertEqual(result.mediaId, "test-id")
        XCTAssertEqual(result.url, testURL)
        XCTAssertEqual(result.size, 1024)
        XCTAssertEqual(result.type, .image)
    }
    
    // MARK: - CropGeometry Tests
    
    func testZoomRangeNoBlankSpaceInvariant() {
        // Test the fundamental invariant: no blank space should ever appear in the crop area
        let testCases: [(width: CGFloat, height: CGFloat, maskDiameter: CGFloat)] = [
            (1000, 1500, 300), // Portrait
            (1500, 1000, 300), // Landscape  
            (1000, 1000, 300), // Square
            (500, 2000, 200),  // Very tall
            (2000, 500, 200),  // Very wide
            (320, 320, 250),   // Minimum size
        ]
        
        let screenScale: CGFloat = 3.0
        let outputSize = 512
        let qualityMultiplier: CGFloat = 1.25
        let maxZoomMultiplier: CGFloat = 4.0
        
        for testCase in testCases {
            let sourceSize = CGSize(width: testCase.width, height: testCase.height)
            let result = CropGeometry.zoomRange(
                maskDiameterPoints: testCase.maskDiameter,
                screenScale: screenScale,
                sourceSize: sourceSize,
                outputSize: outputSize,
                qualityMultiplier: qualityMultiplier,
                maxZoomMultiplier: maxZoomMultiplier
            )
            
            // Invariant: min scale should ensure no blank space
            let expectedMinScale = max(
                testCase.maskDiameter / (testCase.width / screenScale),
                testCase.maskDiameter / (testCase.height / screenScale)
            )
            
            XCTAssertEqual(result.min, expectedMinScale, accuracy: 0.001,
                          "Min scale should prevent blank space for \(testCase)")
            
            // Invariant: max scale should be >= min scale
            XCTAssertGreaterThanOrEqual(result.max, result.min,
                                       "Max scale must be >= min scale for \(testCase)")
            
            // Invariant: quality validation
            let visibleSide = (testCase.maskDiameter * screenScale) / result.max
            let requiredSide = CGFloat(outputSize) * qualityMultiplier
            XCTAssertGreaterThanOrEqual(visibleSide, requiredSide - 1.0, // Allow 1px tolerance
                                       "Quality constraint violated for \(testCase)")
        }
    }
    
    func testPanClampingInvariant() {
        // Test that pan clamping always keeps the mask filled with image content
        let sourceSize = CGSize(width: 1000, height: 1500)
        let maskDiameter: CGFloat = 300
        let screenScale: CGFloat = 3.0
        let scale: CGFloat = 2.0
        
        let extremeTranslations: [CGSize] = [
            CGSize(width: 1000, height: 1000),   // Way too far
            CGSize(width: -1000, height: -1000), // Way too far negative
            CGSize(width: 500, height: -500),    // Mixed extreme
            CGSize(width: 0, height: 0),         // Center
            CGSize(width: 50, height: 75),       // Reasonable
        ]
        
        for translation in extremeTranslations {
            let clamped = CropGeometry.clampedTranslation(
                scale: scale,
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: sourceSize,
                proposedTranslation: translation
            )
            
            // Calculate expected bounds
            let dispW = (sourceSize.width / screenScale) * scale
            let dispH = (sourceSize.height / screenScale) * scale
            let maxX = max(0, (dispW - maskDiameter) / 2)
            let maxY = max(0, (dispH - maskDiameter) / 2)
            
            // Invariant: clamped translation should be within bounds
            XCTAssertLessThanOrEqual(abs(clamped.width), maxX + 0.001,
                                    "Clamped X translation exceeds bounds")
            XCTAssertLessThanOrEqual(abs(clamped.height), maxY + 0.001,
                                    "Clamped Y translation exceeds bounds")
        }
    }
    
    func testCropRectAccuracyRoundTrip() {
        // Test crop rect calculation accuracy with round-trip validation
        let sourceSize = CGSize(width: 2000, height: 1500)
        let maskDiameter: CGFloat = 400
        let screenScale: CGFloat = 3.0
        let scale: CGFloat = 1.5
        let translation = CGSize(width: 50, height: -30)
        
        let cropRect = CropGeometry.cropRectInImagePixels(
            scale: scale,
            translation: translation,
            maskDiameterPoints: maskDiameter,
            screenScale: screenScale,
            sourceSize: sourceSize
        )
        
        // Invariant: crop rect should be within source bounds
        XCTAssertGreaterThanOrEqual(cropRect.minX, 0, "Crop rect X should be >= 0")
        XCTAssertGreaterThanOrEqual(cropRect.minY, 0, "Crop rect Y should be >= 0")
        XCTAssertLessThanOrEqual(cropRect.maxX, sourceSize.width, "Crop rect maxX should be <= source width")
        XCTAssertLessThanOrEqual(cropRect.maxY, sourceSize.height, "Crop rect maxY should be <= source height")
        
        // Invariant: crop rect should be square
        XCTAssertEqual(cropRect.width, cropRect.height, accuracy: 1.0, "Crop rect should be square")
        
        // Invariant: crop rect size should match expected calculation
        let expectedSide = (maskDiameter * screenScale) / scale
        XCTAssertEqual(cropRect.width, expectedSide, accuracy: 1.0, "Crop rect size should match calculation")
    }
    
    func testExtremeAspectRatios() {
        // Test edge cases with extreme aspect ratios
        let extremeCases: [(width: CGFloat, height: CGFloat, description: String)] = [
            (4000, 500, "Very wide panorama"),
            (500, 4000, "Very tall portrait"),
            (320, 320, "Minimum square"),
            (8000, 1000, "Ultra-wide"),
            (1000, 8000, "Ultra-tall")
        ]
        
        let maskDiameter: CGFloat = 300
        let screenScale: CGFloat = 3.0
        let outputSize = 512
        let qualityMultiplier: CGFloat = 1.25
        let maxZoomMultiplier: CGFloat = 4.0
        
        for testCase in extremeCases {
            let sourceSize = CGSize(width: testCase.width, height: testCase.height)
            
            let zoomRange = CropGeometry.zoomRange(
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: sourceSize,
                outputSize: outputSize,
                qualityMultiplier: qualityMultiplier,
                maxZoomMultiplier: maxZoomMultiplier
            )
            
            // Test at minimum zoom (should always work)
            let minTranslation = CropGeometry.clampedTranslation(
                scale: zoomRange.min,
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: sourceSize,
                proposedTranslation: CGSize.zero
            )
            
            let minCropRect = CropGeometry.cropRectInImagePixels(
                scale: zoomRange.min,
                translation: minTranslation,
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: sourceSize
            )
            
            // Invariant: minimum zoom should always produce valid crop
            XCTAssertTrue(minCropRect.width > 0 && minCropRect.height > 0,
                         "Min zoom should produce valid crop for \(testCase.description)")
            
            // Test at maximum zoom
            let maxTranslation = CropGeometry.clampedTranslation(
                scale: zoomRange.max,
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: sourceSize,
                proposedTranslation: CGSize.zero
            )
            
            let maxCropRect = CropGeometry.cropRectInImagePixels(
                scale: zoomRange.max,
                translation: maxTranslation,
                maskDiameterPoints: maskDiameter,
                screenScale: screenScale,
                sourceSize: sourceSize
            )
            
            // Invariant: maximum zoom should produce valid crop
            XCTAssertTrue(maxCropRect.width > 0 && maxCropRect.height > 0,
                         "Max zoom should produce valid crop for \(testCase.description)")
        }
    }
    
    func testQualityValidation() {
        // Test quality validation functions
        let outputSize = 512
        let qualityMultiplier: CGFloat = 1.25
        let requiredPixels = CGFloat(outputSize) * qualityMultiplier // 640
        
        // Test cases around the quality threshold
        XCTAssertTrue(CropGeometry.validateCropQuality(
            cropSidePixels: 640,
            outputSize: outputSize,
            qualityMultiplier: qualityMultiplier
        ), "Exact quality threshold should pass")
        
        XCTAssertTrue(CropGeometry.validateCropQuality(
            cropSidePixels: 700,
            outputSize: outputSize,
            qualityMultiplier: qualityMultiplier
        ), "Above quality threshold should pass")
        
        XCTAssertFalse(CropGeometry.validateCropQuality(
            cropSidePixels: 600,
            outputSize: outputSize,
            qualityMultiplier: qualityMultiplier
        ), "Below quality threshold should fail")
    }
    
    func testPixelDensityValidation() {
        // Test minimum pixel density validation
        let screenScale: CGFloat = 3.0
        
        // Good pixel density (crisp)
        let goodMinScale: CGFloat = 2.0 // σ/s = 3.0/2.0 = 1.5 px/pt
        XCTAssertTrue(CropGeometry.validateMinimumPixelDensity(
            minScale: goodMinScale,
            screenScale: screenScale
        ), "Good pixel density should pass")
        
        // Borderline pixel density
        let borderlineMinScale: CGFloat = 3.0 // σ/s = 3.0/3.0 = 1.0 px/pt
        XCTAssertTrue(CropGeometry.validateMinimumPixelDensity(
            minScale: borderlineMinScale,
            screenScale: screenScale
        ), "Borderline pixel density should pass")
        
        // Poor pixel density (soft)
        let poorMinScale: CGFloat = 4.0 // σ/s = 3.0/4.0 = 0.75 px/pt
        XCTAssertFalse(CropGeometry.validateMinimumPixelDensity(
            minScale: poorMinScale,
            screenScale: screenScale
        ), "Poor pixel density should fail")
    }
    
    func testVisibleCropSideCalculation() {
        // Test utility function for visible crop side calculation
        let maskDiameter: CGFloat = 300
        let screenScale: CGFloat = 3.0
        let scale: CGFloat = 1.5
        
        let visibleSide = CropGeometry.visibleCropSideInPixels(
            scale: scale,
            maskDiameterPoints: maskDiameter,
            screenScale: screenScale
        )
        
        let expectedSide = (maskDiameter * screenScale) / scale // (300 * 3) / 1.5 = 600
        XCTAssertEqual(visibleSide, expectedSide, accuracy: 0.001,
                      "Visible crop side calculation should be accurate")
    }
    
    // MARK: - ImageCropRenderer Tests
    
    func testCropValidationErrorDescriptions() {
        // Test error descriptions for user-facing messages
        let tooSmallError = CropValidationError.imageTooSmall(
            size: CGSize(width: 200, height: 150),
            minimum: 320
        )
        XCTAssertEqual(tooSmallError.errorDescription, "This photo is too small for a profile picture.")
        
        let decodingError = CropValidationError.imageDecodingFailed
        XCTAssertEqual(decodingError.errorDescription, "Unable to process this image. Please try a different photo.")
        
        let processingError = CropValidationError.cropProcessingFailed
        XCTAssertEqual(processingError.errorDescription, "Failed to crop image. Please try again.")
        
        let memoryError = CropValidationError.memoryPressure
        XCTAssertEqual(memoryError.errorDescription, "Using an optimized preview to finish the crop.")
    }
    
    func testImageCropRendererInitialization() {
        // Test that renderer can be initialized
        let renderer = ImageCropRenderer()
        XCTAssertNotNil(renderer, "ImageCropRenderer should initialize successfully")
    }
}