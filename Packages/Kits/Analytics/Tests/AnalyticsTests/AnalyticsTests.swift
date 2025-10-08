import XCTest
@testable import Analytics

final class AnalyticsTests: XCTestCase {
    
    func testAnalyticsModuleExists() {
        let analytics = Analytics.shared
        XCTAssertNotNil(analytics)
    }
    
    func testAnalyticsManagerInitialization() {
        let manager = AnalyticsManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testEventTrackerInitialization() {
        let tracker = EventTracker.shared
        XCTAssertNotNil(tracker)
    }
    
    func testCrashReporterInitialization() {
        let crashReporter = CrashReporter.shared
        XCTAssertNotNil(crashReporter)
    }
    
    func testAnalyticsEventProperties() {
        let event = AnalyticsEvent.postCreated(characterCount: 100, hasMedia: true)
        
        XCTAssertEqual(event.name, "post_created")
        
        let properties = event.properties
        XCTAssertEqual(properties["character_count"] as? Int, 100)
        XCTAssertEqual(properties["has_media"] as? Bool, true)
    }
    
    func testUserSignInEvent() {
        let event = AnalyticsEvent.userSignedIn(method: "apple")
        
        XCTAssertEqual(event.name, "user_signed_in")
        XCTAssertEqual(event.properties["method"] as? String, "apple")
    }
    
    func testPostViewedEvent() {
        let event = AnalyticsEvent.postViewed(postId: "123", dwellTime: 5.5)
        
        XCTAssertEqual(event.name, "post_viewed")
        XCTAssertEqual(event.properties["post_id"] as? String, "123")
        XCTAssertEqual(event.properties["dwell_time"] as? TimeInterval, 5.5)
    }
    
    func testMediaProcessedEvent() {
        let event = AnalyticsEvent.mediaProcessed(type: "image", originalSize: 1000, compressedSize: 500)
        
        XCTAssertEqual(event.name, "media_processed")
        XCTAssertEqual(event.properties["type"] as? String, "image")
        XCTAssertEqual(event.properties["original_size"] as? Int64, 1000)
        XCTAssertEqual(event.properties["compressed_size"] as? Int64, 500)
        XCTAssertEqual(event.properties["compression_ratio"] as? Double, 0.5)
    }
    
    func testLogLevels() {
        XCTAssertEqual(LogLevel.debug.rawValue, "debug")
        XCTAssertEqual(LogLevel.info.rawValue, "info")
        XCTAssertEqual(LogLevel.warning.rawValue, "warning")
        XCTAssertEqual(LogLevel.error.rawValue, "error")
        XCTAssertEqual(LogLevel.fatal.rawValue, "fatal")
    }
}