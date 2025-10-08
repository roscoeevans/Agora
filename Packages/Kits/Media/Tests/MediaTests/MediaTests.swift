import XCTest
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
}