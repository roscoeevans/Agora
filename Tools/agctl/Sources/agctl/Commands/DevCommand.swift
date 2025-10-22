import ArgumentParser
import Foundation

struct DevCommand: ParsableCommand, RunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "dev",
        abstract: "Run agctl in development mode with auto-reload"
    )
    
    @Argument(help: "Command to run when files change")
    var command: [String] = []
    
    @Option(help: "Watch directory (defaults to Tools/agctl)")
    var watch: String?
    
    var timeout: Duration { .seconds(86400) } // 24 hours - dev can run long
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        Logger.section("🔥 Development Mode")
        
        // Find agctl directory
        guard let agctlPath = findAgctlDirectory() else {
            Logger.error("Not in Agora repository")
            Logger.info("Run this command from within the Agora repository")
            return .failure
        }
        
        let watchPath = watch.map { URL(fileURLWithPath: $0) } ?? agctlPath
        
        Logger.info("Watching: \(watchPath.path)")
        Logger.info("Command: \(command.joined(separator: " "))")
        print("")
        Logger.info("Press Ctrl-C to stop")
        print("")
        
        // Track last build time
        var lastBuildTime = Date.distantPast
        let debounceInterval: TimeInterval = 2.0
        
        // Initial build
        guard await buildAgctl(at: agctlPath, bag: bag) else {
            return .failure
        }
        
        // Run initial command if provided
        if !command.isEmpty {
            _ = await runCommand(command, at: agctlPath, bag: bag)
        }
        
        // Watch for changes
        while !Task.isCancelled {
            if hasChanges(at: watchPath, since: lastBuildTime) {
                let now = Date()
                
                // Debounce rapid changes
                if now.timeIntervalSince(lastBuildTime) > debounceInterval {
                    Logger.info("🔄 Changes detected, rebuilding...")
                    print("")
                    
                    lastBuildTime = now
                    
                    guard await buildAgctl(at: agctlPath, bag: bag) else {
                        Logger.error("Build failed, waiting for fixes...")
                        print("")
                        try? await Task.sleep(for: .seconds(2))
                        continue
                    }
                    
                    // Re-run command if provided
                    if !command.isEmpty {
                        Logger.info("Re-running command...")
                        print("")
                        _ = await runCommand(command, at: agctlPath, bag: bag)
                        print("")
                    }
                    
                    Logger.success("Ready for changes")
                    print("")
                }
            }
            
            try? await Task.sleep(for: .seconds(1))
        }
        
        return .success
    }
    
    private func findAgctlDirectory() -> URL? {
        var current = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
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
    
    private func hasChanges(at path: URL, since date: Date) -> Bool {
        guard let enumerator = FileManager.default.enumerator(
            at: path,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else {
            return false
        }
        
        for case let fileURL as URL in enumerator {
            if fileURL.pathExtension == "swift" {
                if let modified = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
                   modified > date {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func buildAgctl(at agctlPath: URL, bag: CancellationBag) async -> Bool {
        do {
            try await withSpinner(
                "Building agctl",
                successMessage: "Build succeeded",
                failureMessage: "Build failed"
            ) {
                let result = try await runProcess(
                    "/usr/bin/xcrun",
                    arguments: ["swift", "build", "-c", "release", "--product", "agctl"],
                    workingDirectory: agctlPath,
                    bag: bag
                )
                
                guard result.isSuccess else {
                    if !result.stderr.isEmpty {
                        print(result.stderr)
                    }
                    throw ProcessError(
                        executable: "swift",
                        arguments: ["build"],
                        result: result
                    )
                }
            }
            return true
        } catch {
            Logger.error("Build failed: \(error.localizedDescription)")
            return false
        }
    }
    
    private func runCommand(_ cmd: [String], at agctlPath: URL, bag: CancellationBag) async -> Bool {
        guard !cmd.isEmpty else { return true }
        
        let executable = cmd[0]
        let args = Array(cmd.dropFirst())
        
        do {
            let result = try await runProcessWithLiveOutput(
                executable,
                arguments: args,
                workingDirectory: agctlPath,
                bag: bag
            )
            return result.isSuccess
        } catch {
            Logger.error("Command failed: \(error.localizedDescription)")
            return false
        }
    }
}


