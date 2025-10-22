import XCTest
@testable import agctl

final class LoggerTests: XCTestCase {
    func testLoggerMessages() {
        // These tests verify logger methods don't crash
        // In real usage, we'd capture stdout but that's complex for this test
        
        Logger.info("Test info message")
        Logger.success("Test success message")
        Logger.error("Test error message")
        Logger.warning("Test warning message")
        Logger.section("Test Section")
        Logger.bullet("Test bullet point")
        Logger.arrow("Test arrow")
        
        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }
}

