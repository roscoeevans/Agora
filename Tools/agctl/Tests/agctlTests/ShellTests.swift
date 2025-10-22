import XCTest
@testable import agctl

final class ShellTests: XCTestCase {
    func testRunSimpleCommand() throws {
        let output = try Shell.run("echo hello")
        XCTAssertEqual(output, "hello")
    }
    
    func testRunCommandWithWorkingDirectory() throws {
        let output = try Shell.run("pwd", at: "/tmp")
        XCTAssertTrue(output.contains("/tmp") || output.contains("/private/tmp"))
    }
    
    func testWhichFindsExistingBinary() {
        let swiftPath = Shell.which("swift")
        XCTAssertNotNil(swiftPath)
        XCTAssertTrue(swiftPath!.contains("swift"))
    }
    
    func testWhichReturnsNilForNonexistentBinary() {
        let result = Shell.which("nonexistent-binary-12345")
        XCTAssertNil(result)
    }
    
    func testCommandErrorThrown() {
        XCTAssertThrowsError(try Shell.run("false")) { error in
            guard let shellError = error as? Shell.CommandError else {
                XCTFail("Expected Shell.CommandError")
                return
            }
            XCTAssertEqual(shellError.exitCode, 1)
        }
    }
    
    func testCommandErrorDescription() {
        do {
            _ = try Shell.run("false")
            XCTFail("Expected command to throw")
        } catch let error as Shell.CommandError {
            let description = error.errorDescription ?? ""
            XCTAssertTrue(description.contains("exit code 1"))
            XCTAssertTrue(description.contains("false"))
        } catch {
            XCTFail("Expected Shell.CommandError")
        }
    }
}

