import XCTest
@testable import agctl

final class ProgressTests: XCTestCase {
    func testProgressIndicator() {
        let indicator = ProgressIndicator(message: "Testing")
        
        // Start and stop quickly
        indicator.start()
        Thread.sleep(forTimeInterval: 0.5)
        indicator.stop(success: true, finalMessage: "Test complete")
        
        // Test passes if no crash
        XCTAssertTrue(true)
    }
    
    func testProgressBar() {
        let bar = ProgressBar(total: 10, message: "Processing")
        
        for i in 0..<10 {
            bar.update(current: i, itemMessage: "Item \(i)")
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        bar.complete(finalMessage: "Done")
        
        // Test passes if no crash
        XCTAssertTrue(true)
    }
    
    func testProgressBarIncrement() {
        let bar = ProgressBar(total: 5, message: "Incrementing")
        
        for i in 0..<5 {
            bar.increment(itemMessage: "Step \(i)")
        }
        
        bar.complete()
        
        XCTAssertTrue(true)
    }
    
    func testWithProgress() throws {
        let result = try withProgress(
            "Testing operation",
            successMessage: "Success",
            failureMessage: "Failed"
        ) {
            Thread.sleep(forTimeInterval: 0.2)
            return 42
        }
        
        XCTAssertEqual(result, 42)
    }
    
    func testWithProgressThrows() {
        enum TestError: Error {
            case test
        }
        
        XCTAssertThrowsError(
            try withProgress(
                "Testing error",
                successMessage: "Success",
                failureMessage: "Failed"
            ) {
                throw TestError.test
            }
        )
    }
    
    func testTimeEstimator() {
        let estimator = TimeEstimator(totalItems: 100)
        
        // Can't estimate at start
        XCTAssertNil(estimator.estimatedTimeRemaining(completed: 0))
        
        // Sleep briefly and simulate progress
        Thread.sleep(forTimeInterval: 0.1)
        
        // Should have estimate after some work
        let remaining = estimator.estimatedTimeRemaining(completed: 10)
        XCTAssertNotNil(remaining)
        
        // Format test
        let formatted = estimator.formatTimeRemaining(completed: 10)
        XCTAssertNotNil(formatted)
        XCTAssertTrue(formatted!.contains("remaining"))
    }
}

