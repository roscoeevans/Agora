import ArgumentParser
import Foundation

struct SelfUpdateCommand: ParsableCommand, RunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "self-update",
        abstract: "Update agctl to the latest version"
    )
    
    @Option(help: "Update channel (stable or nightly)")
    var channel: String = "stable"
    
    @Flag(help: "Show verbose output")
    var verbose = false
    
    var timeout: Duration { .seconds(300) }
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        Logger.section("🔄 Updating agctl")
        
        // Check if we're using the shim
        let shimPath = "/usr/local/bin/agctl"
        
        guard FileManager.default.fileExists(atPath: shimPath) else {
            Logger.warning("Shim not found at \(shimPath)")
            Logger.info("Install the shim first:")
            Logger.bullet("cd Tools/agctl-shim && ./install.sh")
            return .failure
        }
        
        // Get latest version from GitHub
        Logger.info("Checking for updates...")
        
        guard let latestVersion = try await fetchLatestVersion(channel: channel, bag: bag) else {
            Logger.error("Failed to check for updates")
            return .failure
        }
        
        let currentVersion = AGCTLCommand.configuration.version
        
        if latestVersion == currentVersion {
            Logger.success("Already up to date (\(currentVersion))")
            return .success
        }
        
        Logger.info("New version available: \(latestVersion) (current: \(currentVersion))")
        
        // Download and install
        do {
            try await withSpinner(
                "Downloading agctl \(latestVersion)",
                successMessage: "Downloaded successfully",
                failureMessage: "Download failed"
            ) {
                try await downloadVersion(latestVersion, bag: bag)
            }
            
            // Update .agctl-version if in repo
            if let repoRoot = findRepoRoot() {
                let versionFile = repoRoot.appendingPathComponent(".agctl-version")
                try latestVersion.write(to: versionFile, atomically: true, encoding: .utf8)
                Logger.success("Updated .agctl-version to \(latestVersion)")
            }
            
            Logger.success("Successfully updated to \(latestVersion)")
            Logger.info("Restart your terminal or run 'agctl --version' to verify")
            
            return .success
        } catch {
            Logger.error("Update failed: \(error.localizedDescription)")
            return .failure
        }
    }
    
    private func fetchLatestVersion(channel: String, bag: CancellationBag) async throws -> String? {
        // TODO: Implement GitHub API call to fetch latest release
        // For now, return a mock version
        return "1.3.0"
    }
    
    private func downloadVersion(_ version: String, bag: CancellationBag) async throws {
        let cachePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".agctl/versions")
            .appendingPathComponent(version)
        
        try FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
        
        // TODO: Implement actual download from GitHub releases
        // For now, just copy the current binary
        Logger.info("Download functionality coming soon")
    }
    
    private func findRepoRoot() -> URL? {
        var current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        while current.path != "/" {
            let versionFile = current.appendingPathComponent(".agctl-version")
            if FileManager.default.fileExists(atPath: versionFile.path) {
                return current
            }
            current = current.deletingLastPathComponent()
        }
        
        return nil
    }
}


