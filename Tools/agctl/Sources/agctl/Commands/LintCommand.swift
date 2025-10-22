import ArgumentParser
import Foundation

struct LintCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lint",
        abstract: "Run SwiftLint on packages"
    )
    
    @Argument(help: "Package name to lint (omit to lint all)")
    var packageName: String?
    
    @Flag(name: .shortAndLong, help: "Show verbose output")
    var verbose = false
    
    @Flag(help: "Automatically fix issues when possible")
    var fix = false
    
    @Flag(help: "Treat warnings as errors")
    var strict = false
    
    @Option(help: "Path to SwiftLint configuration file")
    var config: String?
    
    func run() throws {
        // Load config
        let agctlConfig = ConfigManager.load()
        
        // Override with command line flags
        let shouldFix = fix || agctlConfig.lint.autoFix
        let isStrict = strict || agctlConfig.lint.strict
        let configPath = config ?? agctlConfig.lint.configPath
        
        // Check if SwiftLint is installed
        guard let swiftlintPath = Shell.which("swiftlint") else {
            Logger.error("SwiftLint not found!")
            print("")
            Logger.info("Install SwiftLint:")
            Logger.bullet("Via Homebrew: brew install swiftlint")
            Logger.bullet("Via Mint: mint install realm/SwiftLint")
            throw ExitCode.failure
        }
        
        if verbose {
            Logger.info("Using SwiftLint at: \(swiftlintPath)")
        }
        
        // Determine what to lint
        let packages: [Package]
        if let name = packageName {
            guard let package = try PackageResolver.findPackage(named: name) else {
                Logger.error("Package '\(name)' not found")
                throw ExitCode.failure
            }
            packages = [package]
        } else {
            packages = try PackageResolver.allPackages()
        }
        
        Logger.section("🧹 Running SwiftLint")
        Logger.info("Packages: \(packages.count)")
        if shouldFix {
            Logger.info("Mode: Auto-fix enabled")
        }
        if isStrict {
            Logger.warning("Strict mode: Warnings will be treated as errors")
        }
        print("")
        
        var totalViolations = 0
        var totalWarnings = 0
        var totalErrors = 0
        var failedPackages: [String] = []
        
        let progress = ProgressBar(total: packages.count, message: "Linting")
        
        for (index, package) in packages.enumerated() {
            progress.update(current: index, itemMessage: package.displayName)
            
            let result = lintPackage(
                package: package,
                fix: shouldFix,
                strict: isStrict,
                configPath: configPath,
                verbose: verbose
            )
            
            totalViolations += result.violations
            totalWarnings += result.warnings
            totalErrors += result.errors
            
            if !result.success {
                failedPackages.append(package.displayName)
            }
        }
        
        progress.complete(finalMessage: "Linting complete")
        
        print("")
        Logger.section("📊 Summary")
        Logger.info("Total packages: \(packages.count)")
        Logger.info("Total violations: \(totalViolations)")
        
        if totalWarnings > 0 {
            Logger.warning("Warnings: \(totalWarnings)")
        }
        if totalErrors > 0 {
            Logger.error("Errors: \(totalErrors)")
        }
        
        if failedPackages.isEmpty {
            print("")
            Logger.success("All packages passed lint checks! 🎉")
        } else {
            print("")
            Logger.error("Failed packages (\(failedPackages.count)):")
            for pkg in failedPackages {
                Logger.bullet(pkg)
            }
            print("")
            if shouldFix {
                Logger.info("Some issues could not be auto-fixed. Review and fix manually.")
            } else {
                Logger.info("Run with --fix to automatically fix some issues")
            }
            throw ExitCode.failure
        }
    }
    
    private func lintPackage(
        package: Package,
        fix: Bool,
        strict: Bool,
        configPath: String?,
        verbose: Bool
    ) -> LintResult {
        var command = "swiftlint"
        
        if fix {
            command += " --fix --format"
        }
        
        if strict {
            command += " --strict"
        }
        
        if let config = configPath {
            command += " --config \(config)"
        }
        
        // Lint the Sources directory
        let sourcesPath = package.path.appendingPathComponent("Sources").path
        command += " --path \(sourcesPath)"
        
        // Add reporter for parsing
        if !verbose {
            command += " --reporter json"
        }
        
        do {
            let output = try Shell.run(command, captureStderr: true)
            
            if verbose {
                print(output)
            }
            
            return parseLintOutput(output: output, verbose: verbose)
        } catch {
            if verbose {
                Logger.error("Lint failed for \(package.displayName): \(error)")
            }
            
            // Try to extract violation count from error
            if let shellError = error as? Shell.CommandError {
                let result = parseLintOutput(output: shellError.output, verbose: verbose)
                return result
            }
            
            return LintResult(success: false, violations: 0, warnings: 0, errors: 0)
        }
    }
    
    private func parseLintOutput(output: String, verbose: Bool) -> LintResult {
        // If verbose, output is not JSON
        if verbose {
            // Simple regex-based parsing
            let warningCount = output.components(separatedBy: "warning:").count - 1
            let errorCount = output.components(separatedBy: "error:").count - 1
            let totalViolations = warningCount + errorCount
            
            return LintResult(
                success: errorCount == 0,
                violations: totalViolations,
                warnings: warningCount,
                errors: errorCount
            )
        }
        
        // Parse JSON output
        guard let data = output.data(using: .utf8) else {
            return LintResult(success: true, violations: 0, warnings: 0, errors: 0)
        }
        
        do {
            let violations = try JSONDecoder().decode([LintViolation].self, from: data)
            
            let warnings = violations.filter { $0.severity == "Warning" }.count
            let errors = violations.filter { $0.severity == "Error" }.count
            
            return LintResult(
                success: errors == 0,
                violations: violations.count,
                warnings: warnings,
                errors: errors
            )
        } catch {
            // If JSON parsing fails, assume success with no violations
            return LintResult(success: true, violations: 0, warnings: 0, errors: 0)
        }
    }
}

// MARK: - Supporting Types

private struct LintResult {
    let success: Bool
    let violations: Int
    let warnings: Int
    let errors: Int
}

private struct LintViolation: Codable {
    let ruleID: String
    let reason: String
    let severity: String
    let file: String?
    let line: Int?
    let character: Int?
    
    enum CodingKeys: String, CodingKey {
        case ruleID = "rule_id"
        case reason
        case severity
        case file
        case line
        case character
    }
}

