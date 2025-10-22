import XCTest
@testable import Analytics

final class AnalyticsTests: XCTestCase {
    
    func testAnalyticsModuleExists() {
        let analytics = Analytics.shared
        XCTAssertNotNil(analytics)
    }
    
    func testEventTrackerInitialization() {
        let fakeClient = AnalyticsClientFake()
        let tracker = EventTracker(analyticsClient: fakeClient)
        XCTAssertNotNil(tracker)
    }
    
    @MainActor
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
    
    // MARK: - Skeleton Analytics Tests
    
    @MainActor
    func testSkeletonAnalyticsInitialization() {
        let fakeClient = AnalyticsClientFake()
        let skeletonAnalytics = SkeletonAnalytics(analyticsClient: fakeClient)
        XCTAssertNotNil(skeletonAnalytics)
    }
    
    func testFirstContentfulRowEvent() {
        let event = AnalyticsEvent.firstContentfulRow(feedType: "recommended", rowIndex: 0, elapsedTimeMs: 250)
        
        XCTAssertEqual(event.name, "first_contentful_row")
        XCTAssertEqual(event.properties["feed_type"] as? String, "recommended")
        XCTAssertEqual(event.properties["row_index"] as? Int, 0)
        XCTAssertEqual(event.properties["elapsed_time_ms"] as? Int, 250)
    }
    
    func testTimeToInteractiveEvent() {
        let event = AnalyticsEvent.timeToInteractive(feedType: "following", totalRows: 5, elapsedTimeMs: 800)
        
        XCTAssertEqual(event.name, "time_to_interactive")
        XCTAssertEqual(event.properties["feed_type"] as? String, "following")
        XCTAssertEqual(event.properties["total_rows"] as? Int, 5)
        XCTAssertEqual(event.properties["elapsed_time_ms"] as? Int, 800)
    }
    
    func testSkeletonErrorEvent() {
        let event = AnalyticsEvent.skeletonError(feedType: "profile", error: "Network timeout", context: "initial_load", retryCount: 1)
        
        XCTAssertEqual(event.name, "skeleton_error")
        XCTAssertEqual(event.properties["feed_type"] as? String, "profile")
        XCTAssertEqual(event.properties["error"] as? String, "Network timeout")
        XCTAssertEqual(event.properties["context"] as? String, "initial_load")
        XCTAssertEqual(event.properties["retry_count"] as? Int, 1)
    }
    
    func testSkeletonFPSDropEvent() {
        let event = AnalyticsEvent.skeletonFPSDrop(currentFPS: 45.2, threshold: 55.0)
        
        XCTAssertEqual(event.name, "skeleton_fps_drop")
        XCTAssertEqual(event.properties["current_fps"] as? Double, 45.2)
        XCTAssertEqual(event.properties["threshold"] as? Double, 55.0)
    }
    
    func testSkeletonMemoryThresholdEvent() {
        let event = AnalyticsEvent.skeletonMemoryThreshold(memoryUsageMB: 120, thresholdMB: 100)
        
        XCTAssertEqual(event.name, "skeleton_memory_threshold")
        XCTAssertEqual(event.properties["memory_usage_mb"] as? Int64, 120)
        XCTAssertEqual(event.properties["threshold_mb"] as? Int, 100)
    }
    
    @MainActor
    func testSkeletonAnalyticsTracking() async {
        let fakeClient = AnalyticsClientFake()
        let skeletonAnalytics = SkeletonAnalytics(analyticsClient: fakeClient)
        
        // Start timing
        skeletonAnalytics.startLoadingTimer(feedType: "recommended")
        
        // Track first contentful row
        await skeletonAnalytics.trackFirstContentfulRow(feedType: "recommended", rowIndex: 0)
        
        // Track time to interactive
        await skeletonAnalytics.trackTimeToInteractive(feedType: "recommended", totalRows: 5)
        
        // Verify events were tracked
        let trackCalls = await fakeClient.trackCalls()
        XCTAssertEqual(trackCalls.count, 2)
        
        let firstContentfulCall = trackCalls.first { $0.event == "first_contentful_row" }
        XCTAssertNotNil(firstContentfulCall)
        XCTAssertEqual(firstContentfulCall?.properties["feed_type"], "recommended")
        XCTAssertEqual(firstContentfulCall?.properties["row_index"], "0")
        
        let timeToInteractiveCall = trackCalls.first { $0.event == "time_to_interactive" }
        XCTAssertNotNil(timeToInteractiveCall)
        XCTAssertEqual(timeToInteractiveCall?.properties["feed_type"], "recommended")
        XCTAssertEqual(timeToInteractiveCall?.properties["total_rows"], "5")
    }
    
    @MainActor
    func testSkeletonErrorTracking() async {
        let fakeClient = AnalyticsClientFake()
        let skeletonAnalytics = SkeletonAnalytics(analyticsClient: fakeClient)
        
        let testError = NSError(domain: "TestDomain", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        
        await skeletonAnalytics.trackSkeletonError(
            feedType: "recommended",
            error: testError,
            context: "pagination",
            retryCount: 2
        )
        
        let trackCalls = await fakeClient.trackCalls()
        XCTAssertEqual(trackCalls.count, 1)
        
        let errorCall = trackCalls.first
        XCTAssertEqual(errorCall?.event, "skeleton_error")
        XCTAssertEqual(errorCall?.properties["feed_type"], "recommended")
        XCTAssertEqual(errorCall?.properties["error_description"], "Not found")
        XCTAssertEqual(errorCall?.properties["error_domain"], "TestDomain")
        XCTAssertEqual(errorCall?.properties["error_code"], "404")
        XCTAssertEqual(errorCall?.properties["context"], "pagination")
        XCTAssertEqual(errorCall?.properties["retry_count"], "2")
    }
}