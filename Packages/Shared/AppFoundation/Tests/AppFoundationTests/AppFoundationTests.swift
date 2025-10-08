import XCTest
@testable import AppFoundation

final class AppFoundationTests: XCTestCase {
    
    func testLoggerCreation() {
        let logger = Logger(category: "Test")
        // Logger should be created without issues
        logger.info("Test log message")
    }
    
    func testValidationHelpers() {
        // Test email validation
        XCTAssertTrue(ValidationHelpers.isValidEmail("test@example.com"))
        XCTAssertFalse(ValidationHelpers.isValidEmail("invalid-email"))
        
        // Test handle validation
        XCTAssertTrue(ValidationHelpers.isValidHandle("valid_handle123"))
        XCTAssertFalse(ValidationHelpers.isValidHandle("ab")) // too short
        XCTAssertFalse(ValidationHelpers.isValidHandle("invalid handle")) // contains space
        
        // Test post text validation
        let validResult = ValidationHelpers.isValidPostText("This is a valid post")
        XCTAssertTrue(validResult.isValid)
        
        let emptyResult = ValidationHelpers.isValidPostText("")
        XCTAssertFalse(emptyResult.isValid)
        XCTAssertNotNil(emptyResult.errorMessage)
    }
    
    func testDateExtensions() {
        let now = Date()
        XCTAssertTrue(now.isToday)
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        XCTAssertTrue(yesterday.isYesterday)
        
        let lastWeek = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        XCTAssertTrue(lastWeek.isWithinLastWeek)
    }
}