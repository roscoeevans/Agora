import ArgumentParser
import Foundation

struct TestCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "test",
        abstract: "Test one or all Swift packages"
    )
    
    @Argument(help: "The package to test (e.g., AuthFeature, DesignSystem). If omitted, tests all packages.")
    var packageName: String?
    
    @Flag(name: .shortAndLong, help: "Show verbose test output")
    var verbose = false
    
    @Flag(name: .long, help: "Run tests in parallel")
    var parallel = false
    
    func run() throws {
        if let packageName = packageName {
            try testPackage(named: packageName)
        } else {
            try testAllPackages()
        }
    }
    
    private func testPackage(named name: String) throws {
        Logger.section("🧪 Testing \(name)")
        
        guard let package = try PackageResolver.findPackage(named: name) else {
            Logger.error("Package '\(name)' not found")
            print("")
            print("Available packages:")
            let packages = try PackageResolver.allPackages()
            for pkg in packages.sorted(by: { $0.displayName < $1.displayName }) {
                print("  • \(pkg.displayName) (\(pkg.name))")
            }
            throw ExitCode.failure
        }
        
        Logger.bullet("Package: \(package.displayName)")
        Logger.bullet("Path:    \(package.path.path)")
        print("")
        
        let parallelFlag = parallel ? "--parallel" : ""
        let command = "swift test \(parallelFlag)"
        
        do {
            if verbose {
                try Shell.runWithLiveOutput(command, at: package.path.path)
            } else {
                Logger.info("Running tests...")
                let output = try Shell.run(command, at: package.path.path)
                
                // Parse test results
                let results = parseTestResults(from: output)
                print("")
                Logger.success("Tests passed: \(results.passed)")
                if results.failed > 0 {
                    Logger.error("Tests failed: \(results.failed)")
                }
                if results.skipped > 0 {
                    Logger.warning("Tests skipped: \(results.skipped)")
                }
            }
            Logger.success("All tests passed!")
        } catch {
            Logger.error("Tests failed")
            throw ExitCode.failure
        }
    }
    
    private func testAllPackages() throws {
        Logger.section("🧪 Testing All Packages")
        
        let packages = try PackageResolver.allPackages()
        let sorted = packages.sorted { pkg1, pkg2 in
            // Test order: Shared -> Kits -> Features
            if pkg1.type != pkg2.type {
                return sortOrder(for: pkg1.type) < sortOrder(for: pkg2.type)
            }
            return pkg1.displayName < pkg2.displayName
        }
        
        Logger.info("Found \(sorted.count) packages")
        print("")
        
        var failed: [String] = []
        var totalPassed = 0
        var totalFailed = 0
        var totalSkipped = 0
        
        let parallelFlag = parallel ? "--parallel" : ""
        
        for (index, package) in sorted.enumerated() {
            let progress = "[\(index + 1)/\(sorted.count)]"
            Logger.info("\(progress) Testing \(package.displayName)...")
            
            let command = "swift test \(parallelFlag)"
            
            do {
                let output = try Shell.run(command, at: package.path.path)
                let results = parseTestResults(from: output)
                totalPassed += results.passed
                totalFailed += results.failed
                totalSkipped += results.skipped
                
                if results.failed == 0 {
                    Logger.success("  ✓ \(package.displayName) (\(results.passed) passed)")
                } else {
                    Logger.error("  ✗ \(package.displayName) (\(results.failed) failed)")
                    failed.append(package.displayName)
                }
            } catch {
                Logger.error("  ✗ \(package.displayName) (build/test error)")
                failed.append(package.displayName)
            }
        }
        
        print("")
        Logger.section("Test Summary")
        Logger.success("Passed:  \(totalPassed)")
        if totalFailed > 0 {
            Logger.error("Failed:  \(totalFailed)")
        }
        if totalSkipped > 0 {
            Logger.warning("Skipped: \(totalSkipped)")
        }
        
        if failed.isEmpty {
            Logger.success("All tests passed!")
        } else {
            print("")
            Logger.error("Failed packages:")
            for name in failed {
                Logger.bullet(name)
            }
            throw ExitCode.failure
        }
    }
    
    private func sortOrder(for type: PackageType) -> Int {
        switch type {
        case .shared: return 0
        case .kit: return 1
        case .feature: return 2
        case .unknown: return 3
        }
    }
    
    private func parseTestResults(from output: String) -> (passed: Int, failed: Int, skipped: Int) {
        var passed = 0
        var failed = 0
        let skipped = 0
        
        // Look for test summary patterns
        // Example: "Test Suite 'All tests' passed at ..."
        // Example: "Executed 42 tests, with 0 failures (0 unexpected) in 1.234 (1.345) seconds"
        
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("Executed") && line.contains("tests") {
                // Parse: "Executed X tests, with Y failures"
                let components = line.components(separatedBy: .whitespaces)
                if let executedIndex = components.firstIndex(of: "Executed"),
                   executedIndex + 1 < components.count,
                   let total = Int(components[executedIndex + 1]) {
                    
                    if let failuresIndex = components.firstIndex(where: { $0.contains("failure") }),
                       failuresIndex > 0,
                       let failures = Int(components[failuresIndex - 1]) {
                        failed = failures
                        passed = total - failures
                    } else {
                        passed = total
                    }
                }
            }
        }
        
        // If we couldn't parse, assume success if no "failed" in output
        if passed == 0 && !output.lowercased().contains("failed") {
            passed = 1 // At least some tests passed
        }
        
        return (passed, failed, skipped)
    }
}

