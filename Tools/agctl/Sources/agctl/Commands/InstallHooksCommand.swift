import ArgumentParser
import Foundation

struct InstallHooksCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "install-hooks",
        abstract: "Install git hooks for automatic validation and code generation"
    )
    
    @Flag(name: .shortAndLong, help: "Force overwrite existing hooks")
    var force = false
    
    func run() throws {
        Logger.section("🪝 Installing Git Hooks")
        
        let root = FileSystem.findRoot()
        let hooksSource = root.appendingPathComponent(".githooks")
        let hooksTarget = root.appendingPathComponent(".git/hooks")
        
        let fm = FileManager.default
        
        // Ensure .git/hooks directory exists
        if !fm.fileExists(atPath: hooksTarget.path) {
            try fm.createDirectory(at: hooksTarget, withIntermediateDirectories: true)
        }
        
        // Create .githooks directory if it doesn't exist
        if !fm.fileExists(atPath: hooksSource.path) {
            try fm.createDirectory(at: hooksSource, withIntermediateDirectories: true)
            Logger.info("Created .githooks directory")
        }
        
        // Install hooks
        try installHook(name: "pre-commit", from: hooksSource, to: hooksTarget)
        try installHook(name: "post-merge", from: hooksSource, to: hooksTarget)
        
        Logger.success("Git hooks installed successfully!")
        print("")
        Logger.info("Installed hooks:")
        Logger.bullet("pre-commit - Validates modules before commit")
        Logger.bullet("post-merge - Regenerates OpenAPI client if spec changed")
    }
    
    private func installHook(name: String, from source: URL, to target: URL) throws {
        let sourceFile = source.appendingPathComponent(name)
        let targetFile = target.appendingPathComponent(name)
        
        let fm = FileManager.default
        
        // Create hook content if it doesn't exist
        if !fm.fileExists(atPath: sourceFile.path) {
            let content = hookContent(for: name)
            try FileSystem.writeFile(at: sourceFile, content: content)
            Logger.info("Created \(name) hook template")
        }
        
        // Copy to .git/hooks
        if fm.fileExists(atPath: targetFile.path) {
            if force {
                try fm.removeItem(at: targetFile)
                Logger.warning("Overwriting existing \(name) hook")
            } else {
                Logger.warning("\(name) hook already exists (use --force to overwrite)")
                return
            }
        }
        
        try fm.copyItem(at: sourceFile, to: targetFile)
        
        // Make executable
        let attributes = [FileAttributeKey.posixPermissions: 0o755]
        try fm.setAttributes(attributes, ofItemAtPath: targetFile.path)
        
        Logger.success("Installed \(name) hook")
    }
    
    private func hookContent(for name: String) -> String {
        switch name {
        case "pre-commit":
            return """
                #!/bin/bash
                # Pre-commit hook for Agora
                # Validates module structure before allowing commit
                
                set -e
                
                echo "🔍 Running pre-commit validation..."
                
                # Validate module structure
                if command -v agctl &> /dev/null; then
                    agctl validate modules || {
                        echo "❌ Module validation failed!"
                        echo "Fix the issues above or use 'git commit --no-verify' to skip validation"
                        exit 1
                    }
                else
                    echo "⚠️  agctl not found, skipping validation"
                    echo "Install with: cd Tools/agctl && swift build -c release"
                fi
                
                # Run SwiftLint if available
                if command -v swiftlint &> /dev/null; then
                    echo "🔍 Running SwiftLint..."
                    swiftlint lint --quiet || {
                        echo "⚠️  SwiftLint found issues (not blocking commit)"
                    }
                fi
                
                echo "✅ Pre-commit checks passed!"
                """
            
        case "post-merge":
            return """
                #!/bin/bash
                # Post-merge hook for Agora
                # Regenerates OpenAPI client if spec changed
                
                set -e
                
                # Check if OpenAPI spec changed
                if git diff HEAD@{1} --name-only 2>/dev/null | grep -q "OpenAPI/agora.yaml"; then
                    echo "📡 OpenAPI spec changed, regenerating client..."
                    
                    if command -v agctl &> /dev/null; then
                        agctl generate openapi || {
                            echo "⚠️  Failed to regenerate OpenAPI client"
                            echo "Run 'agctl generate openapi' manually"
                        }
                    else
                        echo "⚠️  agctl not found"
                        echo "Install with: cd Tools/agctl && swift build -c release"
                    fi
                fi
                
                # Check if Package.swift changed
                if git diff HEAD@{1} --name-only 2>/dev/null | grep -q "Package.swift"; then
                    echo "📦 Package.swift changed, you may need to rebuild"
                fi
                """
            
        default:
            return """
                #!/bin/bash
                # \(name) hook for Agora
                echo "Hook \(name) executed"
                """
        }
    }
}

