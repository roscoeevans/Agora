#!/usr/bin/env swift
import Foundation

/// Lightweight bootstrap shim for agctl
/// This tiny launcher ensures you always run the right version:
/// 1. Local dev build (if in repo with changes)
/// 2. Pinned version (from .agctl-version)
/// 3. Latest installed version (fallback)

// MARK: - Configuration

struct ShimConfig {
    static let cachePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".agctl")
    
    static let versionsPath = cachePath.appendingPathComponent("versions")
    static let buildsPath = cachePath.appendingPathComponent("builds")
    
    static let githubRepo = "agora-labs/agora-ios"  // Update to actual repo
    static let githubReleaseURL = "https://api.github.com/repos/\(githubRepo)/releases"
}

// MARK: - Version Resolution

func resolveExecutable() -> String? {
    let currentDir = FileManager.default.currentDirectoryPath
    
    // 1. Check for local dev build (in Agora repo)
    if let devBuild = findLocalDevBuild(from: currentDir) {
        return devBuild
    }
    
    // 2. Check for version pin (.agctl-version)
    if let pinnedVersion = findPinnedVersion(from: currentDir),
       let versionedBuild = findOrDownloadVersion(pinnedVersion) {
        return versionedBuild
    }
    
    // 3. Fall back to latest installed version
    if let latestInstalled = findLatestInstalledVersion() {
        return latestInstalled
    }
    
    return nil
}

/// Find local dev build in Agora repository
func findLocalDevBuild(from directory: String) -> String? {
    var current = URL(fileURLWithPath: directory)
    
    // Walk up looking for Tools/agctl directory
    while current.path != "/" {
        let agctlPath = current.appendingPathComponent("Tools/agctl")
        let sourcesPath = agctlPath.appendingPathComponent("Sources")
        
        // Check if we're in the Agora repo
        if FileManager.default.fileExists(atPath: sourcesPath.path) {
            // Check if sources are newer than cached build
            let gitHash = getGitHash(at: current)
            let buildPath = ShimConfig.buildsPath
                .appendingPathComponent(gitHash)
                .appendingPathComponent("agctl")
            
            if shouldRebuild(sourcesPath: sourcesPath, buildPath: buildPath) {
                // Build it!
                if let built = buildLocalVersion(at: agctlPath, hash: gitHash) {
                    return built
                }
            } else if FileManager.default.fileExists(atPath: buildPath.path) {
                // Use cached build
                return buildPath.path
            }
        }
        
        current = current.deletingLastPathComponent()
    }
    
    return nil
}

/// Get current git hash for cache key
func getGitHash(at repoPath: URL) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
    process.arguments = ["-C", repoPath.path, "rev-parse", "--short", "HEAD"]
    process.currentDirectoryURL = repoPath
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()
    
    try? process.run()
    process.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let hash = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    
    return hash ?? "unknown"
}

/// Check if we should rebuild (sources newer than build)
func shouldRebuild(sourcesPath: URL, buildPath: URL) -> Bool {
    guard let buildModified = try? FileManager.default.attributesOfItem(atPath: buildPath.path)[.modificationDate] as? Date else {
        // Build doesn't exist
        return true
    }
    
    // Check if any source file is newer
    guard let enumerator = FileManager.default.enumerator(at: sourcesPath, includingPropertiesForKeys: [.contentModificationDateKey]) else {
        return false
    }
    
    for case let fileURL as URL in enumerator {
        if fileURL.pathExtension == "swift" {
            if let fileModified = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
               fileModified > buildModified {
                return true
            }
        }
    }
    
    return false
}

/// Build local version
func buildLocalVersion(at agctlPath: URL, hash: String) -> String? {
    fputs("🔨 Building agctl from local sources (\(hash))...\n", stderr)
    fflush(stderr)
    
    let buildDir = ShimConfig.buildsPath.appendingPathComponent(hash)
    try? FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["swift", "build", "-c", "release", "--product", "agctl"]
    process.currentDirectoryURL = agctlPath
    
    // Show build output for transparency
    process.standardOutput = FileHandle.standardOutput
    process.standardError = FileHandle.standardError
    
    do {
        try process.run()
    } catch {
        fputs("❌ Failed to start build: \(error)\n", stderr)
        return nil
    }
    
    process.waitUntilExit()
    
    guard process.terminationStatus == 0 else {
        fputs("❌ Build failed with exit code \(process.terminationStatus)\n", stderr)
        return nil
    }
    
    // Copy binary to cache
    let builtBinary = agctlPath.appendingPathComponent(".build/release/agctl")
    let cachedBinary = buildDir.appendingPathComponent("agctl")
    
    do {
        try? FileManager.default.removeItem(at: cachedBinary)
        try FileManager.default.copyItem(at: builtBinary, to: cachedBinary)
    } catch {
        fputs("⚠️ Warning: Failed to cache binary: \(error)\n", stderr)
        // Still return the built binary path
        return builtBinary.path
    }
    
    fputs("✅ Built successfully (cached for future runs)\n", stderr)
    fflush(stderr)
    return cachedBinary.path
}

/// Find pinned version from .agctl-version file
func findPinnedVersion(from directory: String) -> String? {
    var current = URL(fileURLWithPath: directory)
    
    while current.path != "/" {
        let versionFile = current.appendingPathComponent(".agctl-version")
        
        if let contents = try? String(contentsOf: versionFile, encoding: .utf8) {
            let version = contents.trimmingCharacters(in: .whitespacesAndNewlines)
            if !version.isEmpty {
                return version
            }
        }
        
        current = current.deletingLastPathComponent()
    }
    
    return nil
}

/// Find or download a specific version
func findOrDownloadVersion(_ version: String) -> String? {
    let versionPath = ShimConfig.versionsPath
        .appendingPathComponent(version)
        .appendingPathComponent("agctl")
    
    if FileManager.default.fileExists(atPath: versionPath.path) {
        return versionPath.path
    }
    
    // Download it
    fputs("📥 Downloading agctl \(version)...\n", stderr)
    
    // TODO: Implement download from GitHub releases
    // For now, return nil
    return nil
}

/// Find latest installed version
func findLatestInstalledVersion() -> String? {
    guard FileManager.default.fileExists(atPath: ShimConfig.versionsPath.path),
          let versions = try? FileManager.default.contentsOfDirectory(atPath: ShimConfig.versionsPath.path) else {
        return nil
    }
    
    // Sort versions and pick latest
    let sorted = versions.sorted().reversed()
    
    for version in sorted {
        let binary = ShimConfig.versionsPath
            .appendingPathComponent(version)
            .appendingPathComponent("agctl")
        
        if FileManager.default.fileExists(atPath: binary.path) {
            return binary.path
        }
    }
    
    return nil
}

// MARK: - Main

func main() {
    // Debug: Show we're running
    if ProcessInfo.processInfo.environment["AGCTL_DEBUG"] != nil {
        fputs("DEBUG: agctl shim starting...\n", stderr)
        fflush(stderr)
    }
    
    // Ensure cache directories exist
    try? FileManager.default.createDirectory(at: ShimConfig.cachePath, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(at: ShimConfig.versionsPath, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(at: ShimConfig.buildsPath, withIntermediateDirectories: true)
    
    // Resolve which binary to execute
    guard let executable = resolveExecutable() else {
        fputs("""
            ❌ No agctl installation found.
            
            To install:
            1. Clone the Agora repository
            2. cd Tools/agctl && ./install.sh
            
            Or download from: https://github.com/\(ShimConfig.githubRepo)/releases
            
            """, stderr)
        exit(1)
    }
    
    if ProcessInfo.processInfo.environment["AGCTL_DEBUG"] != nil {
        fputs("DEBUG: Resolved executable: \(executable)\n", stderr)
        fputs("DEBUG: Args: \(CommandLine.arguments)\n", stderr)
        fflush(stderr)
    }
    
    // Exec the real binary with same arguments
    let args = [executable] + Array(CommandLine.arguments.dropFirst())
    
    // Convert to C strings (use UnsafeMutablePointer for proper memory management)
    let cArgs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) } + [nil]
    defer {
        for arg in cArgs {
            free(arg)
        }
    }
    
    // Replace this process with the real agctl
    execv(executable, cArgs)
    
    // If execv returns, something went wrong
    fputs("❌ Failed to execute \(executable): \(String(cString: strerror(errno)))\n", stderr)
    exit(1)
}

main()

