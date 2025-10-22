import ArgumentParser
import Foundation

struct UpdateCommand: ParsableCommand, RunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Update agctl to the latest version",
        discussion: """
            Rebuilds agctl with the latest source code changes.
            
            This command is useful when you've made changes to agctl's source code
            and want to ensure you're running the latest version.
            
            The command will:
            1. Navigate to the agctl source directory
            2. Clean any existing build artifacts
            3. Rebuild agctl in release mode
            4. Verify the build was successful
            """
    )
    
    @Flag(name: .shortAndLong, help: "Show verbose output during build")
    var verbose = false
    
    @Flag(name: .shortAndLong, help: "Clean build artifacts before rebuilding")
    var clean = false
    
    var timeout: Duration { .seconds(300) } // 5 minutes
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        Logger.section("🔄 Updating agctl")
        print("")
        
        // Find agctl directory
        guard let agctlPath = findAgctlDirectory() else {
            Logger.error("Not in Agora repository")
            Logger.info("Run this command from within the Agora repository")
            return .failure
        }
        
        Logger.info("Found agctl source at: \(agctlPath.path)")
        
        // Clean if requested
        if clean {
            Logger.info("Cleaning build artifacts...")
            let cleanResult = try await runProcess(
                "/usr/bin/xcrun",
                arguments: ["swift", "package", "clean"],
                workingDirectory: agctlPath,
                bag: bag
            )
            
            if !cleanResult.isSuccess {
                Logger.warning("Clean failed, but continuing with build...")
            }
        }
        
        // Build agctl
        Logger.info("Building agctl...")
        let buildResult = try await runProcess(
            "/usr/bin/xcrun",
            arguments: ["swift", "build", "-c", "release", "--product", "agctl"],
            workingDirectory: agctlPath,
            bag: bag
        )
        
        if buildResult.isSuccess {
            Logger.success("agctl updated successfully!")
            
            // Show version info
            let versionResult = try await runProcess(
                agctlPath.appendingPathComponent(".build/release/agctl").path,
                arguments: ["--version"],
                bag: bag
            )
            
            if versionResult.isSuccess {
                Logger.info("Version: \(versionResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
            
            print("")
            Logger.info("You can now use the updated agctl commands")
            return .success
        } else {
            Logger.error("Build failed!")
            if !buildResult.stderr.isEmpty {
                Logger.error("Error output:")
                print(buildResult.stderr)
            }
            return .failure
        }
    }
    
    /// Find the agctl source directory
    private func findAgctlDirectory() -> URL? {
        var current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        // Walk up looking for Tools/agctl directory
        while current.path != "/" {
            let agctlPath = current.appendingPathComponent("Tools/agctl")
            let sourcesPath = agctlPath.appendingPathComponent("Sources")
            
            if FileManager.default.fileExists(atPath: sourcesPath.path) {
                return agctlPath
            }
            
            current = current.deletingLastPathComponent()
        }
        
        return nil
    }
}
