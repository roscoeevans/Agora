import XCTest
@testable import agctl

final class ConfigTests: XCTestCase {
    func testDefaultConfiguration() {
        let config = AGCTLConfig()
        
        // Build defaults
        XCTAssertEqual(config.build.defaultConfiguration, .debug)
        XCTAssertEqual(config.build.parallelJobs, 4)
        XCTAssertFalse(config.build.verbose)
        
        // Validation defaults
        XCTAssertTrue(config.validation.strictNaming)
        XCTAssertFalse(config.validation.allowFeatureDeps)
        XCTAssertFalse(config.validation.enforceTests)
        
        // Generate defaults
        XCTAssertEqual(config.generate.openapi.specPath, "OpenAPI/agora.yaml")
        XCTAssertEqual(
            config.generate.openapi.outputPath,
            "Packages/Kits/Networking/Sources/Networking/Generated"
        )
        
        // Lint defaults
        XCTAssertFalse(config.lint.autoFix)
        XCTAssertFalse(config.lint.strict)
        XCTAssertNil(config.lint.configPath)
    }
    
    func testConfigCodable() throws {
        let config = AGCTLConfig()
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        // Decode
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AGCTLConfig.self, from: data)
        
        // Verify
        XCTAssertEqual(decoded.build.defaultConfiguration, config.build.defaultConfiguration)
        XCTAssertEqual(decoded.build.parallelJobs, config.build.parallelJobs)
        XCTAssertEqual(decoded.validation.strictNaming, config.validation.strictNaming)
    }
    
    func testGenerateExampleConfig() {
        let example = ConfigManager.generateExample()
        
        // Verify it contains expected sections
        XCTAssertTrue(example.contains("build:"))
        XCTAssertTrue(example.contains("validation:"))
        XCTAssertTrue(example.contains("generate:"))
        XCTAssertTrue(example.contains("lint:"))
        
        // Verify it contains expected keys
        XCTAssertTrue(example.contains("defaultConfiguration:"))
        XCTAssertTrue(example.contains("parallelJobs:"))
        XCTAssertTrue(example.contains("strictNaming:"))
        XCTAssertTrue(example.contains("autoFix:"))
    }
}

