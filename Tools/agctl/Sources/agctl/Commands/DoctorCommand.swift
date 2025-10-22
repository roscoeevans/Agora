import ArgumentParser
import Foundation

struct DoctorCommand: ParsableCommand, RunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Check agctl installation health"
    )
    
    var timeout: Duration { .seconds(60) }
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        Logger.section("🏥 agctl Health Check")
        print("")
        
        var allGood = true
        
        // Check 1: Shim installation
        allGood = checkShim() && allGood
        
        // Check 2: Cache directories
        allGood = checkCacheDirectories() && allGood
        
        // Check 3: Git repository
        allGood = checkGitRepo() && allGood
        
        // Check 4: Swift toolchain
        allGood = await checkSwiftToolchain(bag: bag) && allGood
        
        // Check 5: Dependencies
        allGood = await checkDependencies(bag: bag) && allGood
        
        // Check 6: Codesign (if not in dev mode)
        allGood = checkCodesign() && allGood
        
        print("")
        
        if allGood {
            Logger.success("All checks passed! ✨")
            return .success
        } else {
            Logger.warning("Some checks failed. See above for details.")
            return .failure
        }
    }
    
    private func checkShim() -> Bool {
        Logger.info("Checking shim installation...")
        
        let shimPath = "/usr/local/bin/agctl"
        
        if FileManager.default.fileExists(atPath: shimPath) {
            Logger.success("  ✓ Shim found at \(shimPath)")
            return true
        } else {
            Logger.error("  ✗ Shim not found at \(shimPath)")
            Logger.info("    Install with: cd Tools/agctl-shim && ./install.sh")
            return false
        }
    }
    
    private func checkCacheDirectories() -> Bool {
        Logger.info("Checking cache directories...")
        
        let cachePath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".agctl")
        
        let dirs = [
            cachePath.appendingPathComponent("versions"),
            cachePath.appendingPathComponent("builds")
        ]
        
        var allExist = true
        
        for dir in dirs {
            if FileManager.default.fileExists(atPath: dir.path) {
                // Check if writable
                if FileManager.default.isWritableFile(atPath: dir.path) {
                    Logger.success("  ✓ \(dir.path) (writable)")
                } else {
                    Logger.error("  ✗ \(dir.path) (not writable)")
                    allExist = false
                }
            } else {
                Logger.warning("  ⚠ \(dir.path) (not found, will be created)")
            }
        }
        
        return allExist
    }
    
    private func checkGitRepo() -> Bool {
        Logger.info("Checking git repository...")
        
        let gitPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".git")
        
        if FileManager.default.fileExists(atPath: gitPath.path) {
            Logger.success("  ✓ In git repository")
            
            // Check if in Agora repo
            let agctlPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent("Tools/agctl")
            
            if FileManager.default.fileExists(atPath: agctlPath.path) {
                Logger.success("  ✓ In Agora repository (dev mode available)")
            } else {
                Logger.info("  ℹ Not in Agora repository")
            }
            
            return true
        } else {
            Logger.warning("  ⚠ Not in a git repository")
            return true  // Not a failure
        }
    }
    
    private func checkSwiftToolchain(bag: CancellationBag) async -> Bool {
        Logger.info("Checking Swift toolchain...")
        
        do {
            let result = try await runProcess(
                "/usr/bin/xcrun",
                arguments: ["swift", "--version"],
                bag: bag
            )
            
            if result.isSuccess {
                let version = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                    .components(separatedBy: "\n").first ?? "unknown"
                Logger.success("  ✓ Swift: \(version)")
                return true
            } else {
                Logger.error("  ✗ Swift not found")
                return false
            }
        } catch {
            Logger.error("  ✗ Failed to check Swift: \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkDependencies(bag: CancellationBag) async -> Bool {
        Logger.info("Checking dependencies...")
        
        let tools = [
            ("git", "/usr/bin/git"),
            ("xcrun", "/usr/bin/xcrun")
        ]
        
        var allFound = true
        
        for (name, path) in tools {
            if FileManager.default.fileExists(atPath: path) {
                Logger.success("  ✓ \(name) found")
            } else {
                Logger.error("  ✗ \(name) not found at \(path)")
                allFound = false
            }
        }
        
        // Check optional tools
        let optionalTools = [
            "swiftlint": "SwiftLint (for linting)",
            "swift-openapi-generator": "OpenAPI Generator (for code generation)"
        ]
        
        for (tool, description) in optionalTools {
            do {
                let result = try await runProcess(
                    "/usr/bin/which",
                    arguments: [tool],
                    bag: bag
                )
                
                if result.isSuccess {
                    Logger.success("  ✓ \(description)")
                } else {
                    Logger.warning("  ⚠ \(description) not found (optional)")
                }
            } catch {
                Logger.warning("  ⚠ \(description) not found (optional)")
            }
        }
        
        return allFound
    }
    
    private func checkCodesign() -> Bool {
        Logger.info("Checking code signing...")
        
        // Get current executable path
        guard let executablePath = Bundle.main.executablePath else {
            Logger.warning("  ⚠ Cannot determine executable path")
            return true  // Not a failure
        }
        
        // Check if signed
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        process.arguments = ["--verify", "--verbose", executablePath]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try? process.run()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            Logger.success("  ✓ Binary is properly signed")
            return true
        } else {
            Logger.warning("  ⚠ Binary is not signed (OK for development)")
            return true  // Not a failure for dev builds
        }
    }
}


