import Foundation
import ArgumentParser

/// AI-powered error analysis and suggestion system
/// Uses pattern matching and heuristics to provide intelligent error recovery suggestions
struct AIErrorAnalyzer {
    
    // MARK: - Error Patterns
    
    private static let errorPatterns: [ErrorPattern] = [
        // Build errors
        ErrorPattern(
            pattern: #"error: circular dependency detected"#,
            category: .dependency,
            suggestions: [
                "Run 'agctl validate dependencies' to see the full dependency graph",
                "Check for Feature → Feature dependencies (not allowed)",
                "Consider moving shared code to a Kit or Shared package"
            ],
            autoFix: .validateDependencies
        ),
        
        ErrorPattern(
            pattern: #"error: no such module"#,
            category: .import,
            suggestions: [
                "Check if the module is properly declared in Package.swift",
                "Ensure the module is built before this one",
                "Run 'agctl build' to build all dependencies first"
            ],
            autoFix: .buildDependencies
        ),
        
        ErrorPattern(
            pattern: #"error: cannot find type"#,
            category: .type,
            suggestions: [
                "Check if the type is properly imported",
                "Verify the type exists in the target module",
                "Ensure the module dependency is correctly declared"
            ],
            autoFix: .checkImports
        ),
        
        ErrorPattern(
            pattern: #"error: use of unresolved identifier"#,
            category: .identifier,
            suggestions: [
                "Check spelling and case sensitivity",
                "Verify the identifier is in scope",
                "Check if it's properly imported from another module"
            ],
            autoFix: .checkImports
        ),
        
        ErrorPattern(
            pattern: #"error: 'async' call in a function that does not support concurrency"#,
            category: .concurrency,
            suggestions: [
                "Add 'async' to the function signature",
                "Use 'await' for the async call",
                "Consider using Task {} for non-async contexts"
            ],
            autoFix: .fixConcurrency
        ),
        
        ErrorPattern(
            pattern: #"error: 'Sendable' requirement"#,
            category: .concurrency,
            suggestions: [
                "Make the type conform to Sendable",
                "Use @unchecked Sendable for performance-critical types",
                "Wrap in a Sendable container if needed"
            ],
            autoFix: .fixSendable
        ),
        
        ErrorPattern(
            pattern: #"error: value of type.*has no member"#,
            category: .api,
            suggestions: [
                "Check the correct API usage",
                "Verify the type has the expected methods",
                "Check if you need to import a specific module"
            ],
            autoFix: .checkImports
        ),
        
        ErrorPattern(
            pattern: #"error: cannot convert value of type"#,
            category: .type,
            suggestions: [
                "Check type compatibility",
                "Use explicit casting if appropriate",
                "Verify the expected parameter types"
            ],
            autoFix: .checkTypes
        ),
        
        // Test errors
        ErrorPattern(
            pattern: #"error: test.*failed"#,
            category: .test,
            suggestions: [
                "Check test setup and teardown",
                "Verify mock data and expectations",
                "Run 'agctl test --verbose' for detailed output"
            ],
            autoFix: .runVerboseTests
        ),
        
        // Lint errors
        ErrorPattern(
            pattern: #"warning:.*should be"#,
            category: .lint,
            suggestions: [
                "Run 'agctl lint --fix' to auto-fix many issues",
                "Check SwiftLint configuration",
                "Review the specific rule violation"
            ],
            autoFix: .runLintFix
        )
    ]
    
    // MARK: - Analysis
    
    /// Analyze error output and return intelligent suggestions
    static func analyzeError(_ errorOutput: String, context: ErrorContext) -> ErrorAnalysis {
        var matchedPatterns: [MatchedPattern] = []
        var suggestions: [String] = []
        var autoFixes: [AutoFix] = []
        
        // Analyze each line of error output
        let lines = errorOutput.components(separatedBy: .newlines)
        
        for line in lines {
            for pattern in errorPatterns {
                if let match = pattern.matches(line) {
                    matchedPatterns.append(match)
                    suggestions.append(contentsOf: pattern.suggestions)
                    if let autoFix = pattern.autoFix {
                        autoFixes.append(autoFix)
                    }
                }
            }
        }
        
        // Deduplicate suggestions and auto-fixes
        let uniqueSuggestions = Array(Set(suggestions))
        let uniqueAutoFixes = Array(Set(autoFixes))
        
        // Generate contextual suggestions based on the error context
        let contextualSuggestions = generateContextualSuggestions(
            matchedPatterns: matchedPatterns,
            context: context
        )
        
        return ErrorAnalysis(
            matchedPatterns: matchedPatterns,
            suggestions: uniqueSuggestions + contextualSuggestions,
            autoFixes: uniqueAutoFixes,
            confidence: calculateConfidence(matchedPatterns: matchedPatterns),
            context: context
        )
    }
    
    // MARK: - Contextual Suggestions
    
    private static func generateContextualSuggestions(
        matchedPatterns: [MatchedPattern],
        context: ErrorContext
    ) -> [String] {
        var suggestions: [String] = []
        
        // Package-specific suggestions
        if let packageName = context.packageName {
            suggestions.append("Focus on package '\(packageName)' - run 'agctl build \(packageName) --verbose' for details")
        }
        
        // Build type suggestions
        switch context.buildType {
        case .singlePackage:
            suggestions.append("Try building all packages first: 'agctl build'")
        case .allPackages:
            suggestions.append("Try building individual packages to isolate the issue")
        }
        
        // Recent changes suggestions
        if context.hasRecentChanges {
            suggestions.append("Recent changes detected - consider reverting recent commits to isolate the issue")
        }
        
        // Dependency-related suggestions
        if matchedPatterns.contains(where: { $0.pattern.category == .dependency }) {
            suggestions.append("Run 'agctl validate modules' to check module structure")
            suggestions.append("Check Package.swift files for correct dependency declarations")
        }
        
        return suggestions
    }
    
    private static func calculateConfidence(matchedPatterns: [MatchedPattern]) -> Double {
        guard !matchedPatterns.isEmpty else { return 0.0 }
        
        let totalScore = matchedPatterns.reduce(0.0) { $0 + $1.confidence }
        return min(totalScore / Double(matchedPatterns.count), 1.0)
    }
}

// MARK: - Supporting Types

struct ErrorPattern {
    let pattern: String
    let category: ErrorCategory
    let suggestions: [String]
    let autoFix: AutoFix?
    
    func matches(_ line: String) -> MatchedPattern? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: line.utf16.count)
            
            if regex.firstMatch(in: line, options: [], range: range) != nil {
                return MatchedPattern(
                    pattern: self,
                    matchedLine: line,
                    confidence: 0.8 // Base confidence
                )
            }
        } catch {
            // Invalid regex, skip
        }
        
        return nil
    }
}

struct MatchedPattern {
    let pattern: ErrorPattern
    let matchedLine: String
    let confidence: Double
}

struct ErrorAnalysis {
    let matchedPatterns: [MatchedPattern]
    let suggestions: [String]
    let autoFixes: [AutoFix]
    let confidence: Double
    let context: ErrorContext
    
    var hasHighConfidence: Bool {
        confidence > 0.7
    }
    
    var canAutoFix: Bool {
        !autoFixes.isEmpty
    }
}

struct ErrorContext {
    let packageName: String?
    let buildType: BuildType
    let hasRecentChanges: Bool
    let command: String
    
    enum BuildType {
        case singlePackage
        case allPackages
    }
}

enum ErrorCategory {
    case dependency
    case `import`
    case type
    case identifier
    case concurrency
    case api
    case test
    case lint
    case unknown
}

enum AutoFix: String, CaseIterable {
    case validateDependencies = "agctl validate dependencies"
    case buildDependencies = "agctl build"
    case checkImports = "agctl build --verbose"
    case checkTypes = "agctl build --verbose --check-types"
    case fixConcurrency = "agctl build --verbose --fix-concurrency"
    case fixSendable = "agctl build --verbose --fix-sendable"
    case runVerboseTests = "agctl test --verbose"
    case runLintFix = "agctl lint --fix"
    
    var description: String {
        switch self {
        case .validateDependencies:
            return "Validate dependency structure"
        case .buildDependencies:
            return "Build all dependencies"
        case .checkImports:
            return "Check import statements"
        case .checkTypes:
            return "Check type compatibility"
        case .fixConcurrency:
            return "Fix concurrency issues"
        case .fixSendable:
            return "Fix Sendable requirements"
        case .runVerboseTests:
            return "Run tests with verbose output"
        case .runLintFix:
            return "Auto-fix linting issues"
        }
    }
}
