import XCTest
@testable import Moderation

final class ModerationTests: XCTestCase {
    
    func testModerationModuleExists() {
        let moderation = Moderation.shared
        XCTAssertNotNil(moderation)
    }
    
    func testReportComposerInitialization() {
        let composer = ReportComposer()
        XCTAssertNotNil(composer)
        XCTAssertNil(composer.selectedReportType)
        XCTAssertEqual(composer.reportDescription, "")
        XCTAssertFalse(composer.isSubmitting)
    }
    
    func testContentFilterInitialization() {
        let filter = ContentFilter.shared
        XCTAssertNotNil(filter)
    }
    
    func testSafetyManagerInitialization() {
        let safetyManager = SafetyManager.shared
        XCTAssertNotNil(safetyManager)
    }
    
    func testReportTypeDisplayNames() {
        XCTAssertEqual(ReportType.spam.displayName, "Spam")
        XCTAssertEqual(ReportType.harassment.displayName, "Harassment")
        XCTAssertEqual(ReportType.hateSpeech.displayName, "Hate Speech")
        XCTAssertEqual(ReportType.violence.displayName, "Violence")
        XCTAssertEqual(ReportType.sexualContent.displayName, "Sexual Content")
        XCTAssertEqual(ReportType.misinformation.displayName, "Misinformation")
        XCTAssertEqual(ReportType.copyright.displayName, "Copyright Violation")
        XCTAssertEqual(ReportType.other.displayName, "Other")
    }
    
    func testContentReportCreation() {
        let report = ContentReport(
            contentId: "post123",
            contentType: .post,
            reportType: .spam,
            description: "This is spam content",
            reporterId: "user456"
        )
        
        XCTAssertEqual(report.contentId, "post123")
        XCTAssertEqual(report.contentType, .post)
        XCTAssertEqual(report.reportType, .spam)
        XCTAssertEqual(report.description, "This is spam content")
        XCTAssertEqual(report.reporterId, "user456")
        XCTAssertNotNil(report.id)
        XCTAssertNotNil(report.createdAt)
    }
    
    func testReportValidation() {
        let composer = ReportComposer()
        
        // Invalid - no report type selected
        XCTAssertFalse(composer.validateReport())
        
        // Invalid - report type selected but no description
        composer.selectedReportType = .spam
        XCTAssertFalse(composer.validateReport())
        
        // Valid - both report type and description provided
        composer.reportDescription = "This is spam"
        XCTAssertTrue(composer.validateReport())
        
        // Invalid - empty description (whitespace only)
        composer.reportDescription = "   "
        XCTAssertFalse(composer.validateReport())
    }
    
    func testFilterConfigCreation() {
        let config = FilterConfig(
            mutedKeywords: ["spam", "bot"],
            mutedUsers: ["user123"],
            hideReplies: true,
            hideReposts: false,
            caseSensitive: true
        )
        
        XCTAssertEqual(config.mutedKeywords, ["spam", "bot"])
        XCTAssertEqual(config.mutedUsers, ["user123"])
        XCTAssertTrue(config.hideReplies)
        XCTAssertFalse(config.hideReposts)
        XCTAssertTrue(config.caseSensitive)
    }
    
    func testContentFilterMuteKeyword() {
        let filter = ContentFilter.shared
        
        // Add keyword
        filter.muteKeyword("test")
        let config = filter.getConfig()
        XCTAssertTrue(config.mutedKeywords.contains("test"))
        
        // Remove keyword
        filter.unmuteKeyword("test")
        let updatedConfig = filter.getConfig()
        XCTAssertFalse(updatedConfig.mutedKeywords.contains("test"))
    }
    
    func testContentFilterMuteUser() {
        let filter = ContentFilter.shared
        
        // Add user
        filter.muteUser("user123")
        let config = filter.getConfig()
        XCTAssertTrue(config.mutedUsers.contains("user123"))
        
        // Remove user
        filter.unmuteUser("user123")
        let updatedConfig = filter.getConfig()
        XCTAssertFalse(updatedConfig.mutedUsers.contains("user123"))
    }
    
    func testSafetyManagerContentValidation() async {
        let safetyManager = SafetyManager.shared
        
        // Valid content
        let validResult = await safetyManager.validateContent("This is a normal post")
        if case .valid = validResult {
            // Test passes
        } else {
            XCTFail("Expected valid result")
        }
        
        // Empty content
        let emptyResult = await safetyManager.validateContent("")
        if case .invalid(let reason) = emptyResult {
            if case .emptyContent = reason {
                // Test passes
            } else {
                XCTFail("Expected empty content error")
            }
        } else {
            XCTFail("Expected invalid result for empty content")
        }
        
        // Too long content
        let longContent = String(repeating: "a", count: 300)
        let longResult = await safetyManager.validateContent(longContent)
        if case .invalid(let reason) = longResult {
            if case .tooLong = reason {
                // Test passes
            } else {
                XCTFail("Expected too long error")
            }
        } else {
            XCTFail("Expected invalid result for long content")
        }
    }
}

// Mock content for testing
struct MockContent: FilterableContent {
    let id: String
    let authorId: String
    let text: String
    let isReply: Bool
    let isRepost: Bool
    let isSensitive: Bool
    let isReported: Bool
}