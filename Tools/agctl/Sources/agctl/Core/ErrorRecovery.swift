import Foundation
import ArgumentParser

/// Enhanced error recovery system with auto-fix capabilities
/// Automatically detects and fixes common issues
@MainActor
class ErrorRecovery: @unchecked Sendable {
    static let shared = ErrorRecovery()
    
    private init() {}
    
    // MARK: - Auto-Fix System
    
    /// Attempt to auto-fix common build errors
    func attemptAutoFix(for error: String, context: ErrorContext) async throws -> AutoFixResult {
        let analysis = AIErrorAnalyzer.analyzeError(error, context: context)
        
        guard analysis.canAutoFix else {
            return AutoFixResult(
                success: false,
                message: "No auto-fix available for this error",
                suggestions: analysis.suggestions
            )
        }
        
        Logger.section("🔧 Attempting Auto-Fix")
        
        var fixesApplied: [String] = []
        var failures: [String] = []
        
        for autoFix in analysis.autoFixes {
            do {
                let result = try await applyAutoFix(autoFix, context: context)
                if result.success {
                    fixesApplied.append(result.message)
                } else {
                    failures.append("\(autoFix.description): \(result.message)")
                }
            } catch {
                failures.append("\(autoFix.description): \(error.localizedDescription)")
            }
        }
        
        if !fixesApplied.isEmpty {
            Logger.success("Applied fixes:")
            for fix in fixesApplied {
                Logger.bullet(fix)
            }
        }
        
        if !failures.isEmpty {
            Logger.warning("Some fixes failed:")
            for failure in failures {
                Logger.bullet(failure)
            }
        }
        
        return AutoFixResult(
            success: !fixesApplied.isEmpty,
            message: "Applied \(fixesApplied.count) fixes",
            suggestions: analysis.suggestions,
            fixesApplied: fixesApplied,
            failures: failures
        )
    }
    
    // MARK: - Auto-Fix Implementations
    
    private func applyAutoFix(_ autoFix: AutoFix, context: ErrorContext) async throws -> AutoFixResult {
        switch autoFix {
        case .validateDependencies:
            return try await validateDependencies()
        case .buildDependencies:
            return try await buildDependencies()
        case .checkImports:
            return try await checkImports(context: context)
        case .checkTypes:
            return try await checkTypes(context: context)
        case .fixConcurrency:
            return try await fixConcurrency(context: context)
        case .fixSendable:
            return try await fixSendable(context: context)
        case .runVerboseTests:
            return try await runVerboseTests(context: context)
        case .runLintFix:
            return try await runLintFix(context: context)
        }
    }
    
    private func validateDependencies() async throws -> AutoFixResult {
        Logger.info("Validating dependencies...")
        
        let result = try await runProcess(
            "/usr/bin/xcrun",
            arguments: ["swift", "package", "resolve"],
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            bag: CancellationBag()
        )
        
        if result.isSuccess {
            return AutoFixResult(
                success: true,
                message: "Dependencies validated successfully"
            )
        } else {
            return AutoFixResult(
                success: false,
                message: "Dependency validation failed: \(result.stderr)"
            )
        }
    }
    
    private func buildDependencies() async throws -> AutoFixResult {
        Logger.info("Building dependencies...")
        
        let result = try await runProcess(
            "/usr/bin/xcrun",
            arguments: ["swift", "build", "--build-tests"],
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            bag: CancellationBag()
        )
        
        if result.isSuccess {
            return AutoFixResult(
                success: true,
                message: "Dependencies built successfully"
            )
        } else {
            return AutoFixResult(
                success: false,
                message: "Dependency build failed: \(result.stderr)"
            )
        }
    }
    
    private func checkImports(context: ErrorContext) async throws -> AutoFixResult {
        Logger.info("Checking imports...")
        
        guard let packageName = context.packageName else {
            return AutoFixResult(
                success: false,
                message: "No package specified for import checking"
            )
        }
        
        // Find the package directory
        guard let package = try PackageResolver.findPackage(named: packageName) else {
            return AutoFixResult(
                success: false,
                message: "Package '\(packageName)' not found"
            )
        }
        
        // Check for common import issues
        let sourceFiles = try findSourceFiles(in: package.path)
        var fixesApplied: [String] = []
        
        for file in sourceFiles {
            let content = try String(contentsOf: file, encoding: .utf8)
            let fixedContent = try fixImportIssues(in: content)
            
            if content != fixedContent {
                try fixedContent.write(to: file, atomically: true, encoding: .utf8)
                fixesApplied.append("Fixed imports in \(file.lastPathComponent)")
            }
        }
        
        if fixesApplied.isEmpty {
            return AutoFixResult(
                success: true,
                message: "No import issues found"
            )
        } else {
            return AutoFixResult(
                success: true,
                message: "Fixed \(fixesApplied.count) import issues",
                fixesApplied: fixesApplied
            )
        }
    }
    
    private func checkTypes(context: ErrorContext) async throws -> AutoFixResult {
        Logger.info("Checking type compatibility...")
        
        // This would involve more sophisticated type analysis
        // For now, just run a build with verbose output
        let result = try await runProcess(
            "/usr/bin/xcrun",
            arguments: ["swift", "build", "--verbose"],
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            bag: CancellationBag()
        )
        
        return AutoFixResult(
            success: result.isSuccess,
            message: result.isSuccess ? "Type check passed" : "Type check failed: \(result.stderr)"
        )
    }
    
    private func fixConcurrency(context: ErrorContext) async throws -> AutoFixResult {
        Logger.info("Fixing concurrency issues...")
        
        guard let packageName = context.packageName else {
            return AutoFixResult(
                success: false,
                message: "No package specified for concurrency fixes"
            )
        }
        
        guard let package = try PackageResolver.findPackage(named: packageName) else {
            return AutoFixResult(
                success: false,
                message: "Package '\(packageName)' not found"
            )
        }
        
        let sourceFiles = try findSourceFiles(in: package.path)
        var fixesApplied: [String] = []
        
        for file in sourceFiles {
            let content = try String(contentsOf: file, encoding: .utf8)
            let fixedContent = try fixConcurrencyIssues(in: content)
            
            if content != fixedContent {
                try fixedContent.write(to: file, atomically: true, encoding: .utf8)
                fixesApplied.append("Fixed concurrency issues in \(file.lastPathComponent)")
            }
        }
        
        if fixesApplied.isEmpty {
            return AutoFixResult(
                success: true,
                message: "No concurrency issues found"
            )
        } else {
            return AutoFixResult(
                success: true,
                message: "Fixed \(fixesApplied.count) concurrency issues",
                fixesApplied: fixesApplied
            )
        }
    }
    
    private func fixSendable(context: ErrorContext) async throws -> AutoFixResult {
        Logger.info("Fixing Sendable requirements...")
        
        guard let packageName = context.packageName else {
            return AutoFixResult(
                success: false,
                message: "No package specified for Sendable fixes"
            )
        }
        
        guard let package = try PackageResolver.findPackage(named: packageName) else {
            return AutoFixResult(
                success: false,
                message: "Package '\(packageName)' not found"
            )
        }
        
        let sourceFiles = try findSourceFiles(in: package.path)
        var fixesApplied: [String] = []
        
        for file in sourceFiles {
            let content = try String(contentsOf: file, encoding: .utf8)
            let fixedContent = try fixSendableIssues(in: content)
            
            if content != fixedContent {
                try fixedContent.write(to: file, atomically: true, encoding: .utf8)
                fixesApplied.append("Fixed Sendable issues in \(file.lastPathComponent)")
            }
        }
        
        if fixesApplied.isEmpty {
            return AutoFixResult(
                success: true,
                message: "No Sendable issues found"
            )
        } else {
            return AutoFixResult(
                success: true,
                message: "Fixed \(fixesApplied.count) Sendable issues",
                fixesApplied: fixesApplied
            )
        }
    }
    
    private func runVerboseTests(context: ErrorContext) async throws -> AutoFixResult {
        Logger.info("Running tests with verbose output...")
        
        let result = try await runProcess(
            "/usr/bin/xcrun",
            arguments: ["swift", "test", "--verbose"],
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            bag: CancellationBag()
        )
        
        return AutoFixResult(
            success: result.isSuccess,
            message: result.isSuccess ? "Tests passed" : "Tests failed: \(result.stderr)"
        )
    }
    
    private func runLintFix(context: ErrorContext) async throws -> AutoFixResult {
        Logger.info("Running SwiftLint with auto-fix...")
        
        let result = try await runProcess(
            "/usr/bin/swiftlint",
            arguments: ["--fix"],
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            bag: CancellationBag()
        )
        
        return AutoFixResult(
            success: result.isSuccess,
            message: result.isSuccess ? "Lint fixes applied" : "Lint fix failed: \(result.stderr)"
        )
    }
    
    // MARK: - Code Fixing Helpers
    
    private func fixImportIssues(in content: String) throws -> String {
        var lines = content.components(separatedBy: .newlines)
        var modified = false
        
        for (_, line) in lines.enumerated() {
            // Fix common import issues
            if line.contains("import Foundation") && !line.contains("import Foundation") {
                // Already has Foundation import
                continue
            }
            
            // Add missing Foundation import for common types
            if line.contains("Date(") || line.contains("URL(") || line.contains("FileManager") {
                if !lines.contains(where: { $0.contains("import Foundation") }) {
                    lines.insert("import Foundation", at: 0)
                    modified = true
                }
            }
        }
        
        return modified ? lines.joined(separator: "\n") : content
    }
    
    private func fixConcurrencyIssues(in content: String) throws -> String {
        var lines = content.components(separatedBy: .newlines)
        var modified = false
        
        for (index, line) in lines.enumerated() {
            // Fix async call in non-async function
            if line.contains("await ") && !lines[index-1].contains("async") {
                // Find the function declaration
                for i in (0..<index).reversed() {
                    if lines[i].contains("func ") {
                        if !lines[i].contains("async") {
                            lines[i] = lines[i].replacingOccurrences(of: "func ", with: "func async ")
                            modified = true
                        }
                        break
                    }
                }
            }
        }
        
        return modified ? lines.joined(separator: "\n") : content
    }
    
    private func fixSendableIssues(in content: String) throws -> String {
        var lines = content.components(separatedBy: .newlines)
        var modified = false
        
        for (index, line) in lines.enumerated() {
            // Add @unchecked Sendable for classes that need it
            if line.contains("class ") && line.contains(":") && !line.contains("Sendable") {
                if line.contains("ObservableObject") || line.contains("NSObject") {
                    lines[index] = line.replacingOccurrences(of: "class ", with: "class ")
                    // Add @unchecked Sendable conformance
                    _ = line.components(separatedBy: " ")[1].components(separatedBy: ":")[0]
                    lines[index] = lines[index] + ", @unchecked Sendable"
                    modified = true
                }
            }
        }
        
        return modified ? lines.joined(separator: "\n") : content
    }
    
    private func findSourceFiles(in directory: URL) throws -> [URL] {
        var sourceFiles: [URL] = []
        
        let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension == "swift" {
                sourceFiles.append(fileURL)
            }
        }
        
        return sourceFiles
    }
}

// MARK: - Supporting Types

struct AutoFixResult {
    let success: Bool
    let message: String
    let suggestions: [String]
    let fixesApplied: [String]
    let failures: [String]
    
    init(success: Bool, message: String, suggestions: [String] = [], fixesApplied: [String] = [], failures: [String] = []) {
        self.success = success
        self.message = message
        self.suggestions = suggestions
        self.fixesApplied = fixesApplied
        self.failures = failures
    }
}

// MARK: - Auto-Fix Command

struct AutoFixCommand: ParsableCommand, RunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auto-fix",
        abstract: "Automatically fix common build and code issues"
    )
    
    @Argument(help: "Package name to fix (optional)")
    var packageName: String?
    
    @Flag(help: "Show verbose output")
    var verbose = false
    
    var timeout: Duration { .seconds(300) }
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        Logger.section("🔧 Auto-Fix")
        
        // First, try to build to see what errors we have
        Logger.info("Building to identify issues...")
        
        let buildResult = try await runProcess(
            "/usr/bin/xcrun",
            arguments: ["swift", "build"],
            workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
            bag: bag
        )
        
        if buildResult.isSuccess {
            Logger.success("No issues found - build is already successful!")
            return .success
        }
        
        // Analyze the error and attempt fixes
        let context = ErrorContext(
            packageName: packageName,
            buildType: packageName != nil ? .singlePackage : .allPackages,
            hasRecentChanges: false,
            command: "build"
        )
        
        let errorOutput = buildResult.stderr + "\n" + buildResult.stdout
        let fixResult = try await ErrorRecovery.shared.attemptAutoFix(for: errorOutput, context: context)
        
        if fixResult.success {
            Logger.success("Auto-fix completed: \(fixResult.message)")
            
            if !fixResult.fixesApplied.isEmpty {
                Logger.info("Fixes applied:")
                for fix in fixResult.fixesApplied {
                    Logger.bullet(fix)
                }
            }
            
            // Try building again to verify fixes
            Logger.info("Verifying fixes...")
            let verifyResult = try await runProcess(
                "/usr/bin/xcrun",
                arguments: ["swift", "build"],
                workingDirectory: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
                bag: bag
            )
            
            if verifyResult.isSuccess {
                Logger.success("✅ Build successful after auto-fix!")
                return .success
            } else {
                Logger.warning("Build still failing after auto-fix")
                Logger.info("Remaining issues:")
                print(verifyResult.stderr)
                return .failure
            }
        } else {
            Logger.warning("Auto-fix failed: \(fixResult.message)")
            
            if !fixResult.suggestions.isEmpty {
                Logger.info("Manual suggestions:")
                for suggestion in fixResult.suggestions {
                    Logger.bullet(suggestion)
                }
            }
            
            return .failure
        }
    }
}
