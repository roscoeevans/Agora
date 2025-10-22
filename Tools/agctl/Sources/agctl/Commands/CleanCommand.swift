import ArgumentParser
import Foundation

struct CleanCommand: ParsableCommand, RunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clean",
        abstract: "Clean build artifacts and cached data",
        subcommands: [
            AllCommand.self,
            XcodeCommand.self,
            SPMCommand.self,
            AgctlCommand.self
        ],
        defaultSubcommand: AllCommand.self
    )
    
    var timeout: Duration { .seconds(300) } // 5 minutes
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        // If called without subcommand, show help
        throw CleanError.help
    }
}

enum CleanError: LocalizedError {
    case help
    
    var errorDescription: String? {
        """
        Usage: agctl clean <target>
        
        Targets:
          all     Clean everything (SPM, Xcode, module cache)
          xcode   Clean Xcode DerivedData
          spm     Clean Swift Package Manager builds
          agctl   Clean agctl's own build cache
        
        Flags:
          --dry-run    Preview what would be deleted without deleting
          --verbose    Show detailed output
        """
    }
}

// MARK: - All Command

extension CleanCommand {
    struct AllCommand: ParsableCommand, RunnableCommand {
        static let configuration = CommandConfiguration(
            commandName: "all",
            abstract: "Clean everything (SPM, Xcode, caches)"
        )
        
        @Flag(name: .long, help: "Preview without deleting")
        var dryRun = false
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose = false
        
        var timeout: Duration { .seconds(300) }
        
        func execute(bag: CancellationBag) async throws -> ExitCode {
            Logger.section("🧹 Clean All")
            
            var totalSize: Int64 = 0
            var totalReclaimed: Int64 = 0
            
            // Calculate total size first
            if !dryRun {
                Logger.info("Calculating size...")
                totalSize = await calculateTotalSize()
                print("")
            }
            
            if dryRun {
                Logger.warning("DRY RUN - Nothing will be deleted")
                print("")
            }
            
            // Clean each target
            let targets: [(String, () async -> (Bool, Int64))] = [
                ("Swift Package Manager", { await cleanSPM(dryRun: dryRun, verbose: verbose, bag: bag) }),
                ("Xcode DerivedData", { await cleanXcode(dryRun: dryRun, verbose: verbose) }),
                ("Module cache", { await cleanModuleCache(dryRun: dryRun, verbose: verbose) }),
                ("agctl cache", { await cleanAgctlCache(dryRun: dryRun, verbose: verbose) })
            ]
            
            for (name, cleanFunc) in targets {
                let (success, size) = await cleanFunc()
                if success {
                    totalReclaimed += size
                    if !dryRun {
                        Logger.success("\(name): \(formatBytes(size))")
                    }
                }
            }
            
            print("")
            if dryRun {
                Logger.info("Would reclaim: \(formatBytes(totalSize))")
            } else {
                Logger.success("Total reclaimed: \(formatBytes(totalReclaimed))")
                
                // Check if agctl needs rebuilding
                if await needsRebuild() {
                    print("")
                    Logger.info("Rebuilding agctl...")
                    await rebuildAgctl(bag: bag)
                }
            }
            
            return .success
        }
    }
}

// MARK: - Xcode Command

extension CleanCommand {
    struct XcodeCommand: ParsableCommand, RunnableCommand {
        static let configuration = CommandConfiguration(
            commandName: "xcode",
            abstract: "Clean Xcode DerivedData"
        )
        
        @Flag(name: .long, help: "Preview without deleting")
        var dryRun = false
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose = false
        
        var timeout: Duration { .seconds(120) }
        
        func execute(bag: CancellationBag) async throws -> ExitCode {
            Logger.section("🧹 Clean Xcode DerivedData")
            
            if dryRun {
                Logger.warning("DRY RUN - Nothing will be deleted")
            }
            print("")
            
            let (success, size) = await cleanXcode(dryRun: dryRun, verbose: verbose)
            
            print("")
            if success {
                if dryRun {
                    Logger.info("Would reclaim: \(formatBytes(size))")
                } else {
                    Logger.success("Reclaimed: \(formatBytes(size))")
                }
                return .success
            } else {
                Logger.error("Clean failed")
                return .failure
            }
        }
    }
}

// MARK: - SPM Command

extension CleanCommand {
    struct SPMCommand: ParsableCommand, RunnableCommand {
        static let configuration = CommandConfiguration(
            commandName: "spm",
            abstract: "Clean Swift Package Manager builds"
        )
        
        @Flag(name: .long, help: "Preview without deleting")
        var dryRun = false
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose = false
        
        var timeout: Duration { .seconds(120) }
        
        func execute(bag: CancellationBag) async throws -> ExitCode {
            Logger.section("🧹 Clean Swift Package Manager")
            
            if dryRun {
                Logger.warning("DRY RUN - Nothing will be deleted")
            }
            print("")
            
            let (success, size) = await cleanSPM(dryRun: dryRun, verbose: verbose, bag: bag)
            
            print("")
            if success {
                if dryRun {
                    Logger.info("Would reclaim: \(formatBytes(size))")
                } else {
                    Logger.success("Reclaimed: \(formatBytes(size))")
                    
                    // Check if agctl needs rebuilding
                    if await needsRebuild() {
                        print("")
                        Logger.info("Rebuilding agctl...")
                        await rebuildAgctl(bag: bag)
                    }
                }
                return .success
            } else {
                Logger.error("Clean failed")
                return .failure
            }
        }
    }
}

// MARK: - Agctl Command

extension CleanCommand {
    struct AgctlCommand: ParsableCommand, RunnableCommand {
        static let configuration = CommandConfiguration(
            commandName: "agctl",
            abstract: "Clean agctl's own build cache"
        )
        
        @Flag(name: .long, help: "Preview without deleting")
        var dryRun = false
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose = false
        
        var timeout: Duration { .seconds(60) }
        
        func execute(bag: CancellationBag) async throws -> ExitCode {
            Logger.section("🧹 Clean agctl Cache")
            
            if dryRun {
                Logger.warning("DRY RUN - Nothing will be deleted")
            }
            print("")
            
            let (success, size) = await cleanAgctlCache(dryRun: dryRun, verbose: verbose)
            
            print("")
            if success {
                if dryRun {
                    Logger.info("Would reclaim: \(formatBytes(size))")
                } else {
                    Logger.success("Reclaimed: \(formatBytes(size))")
                    
                    // Rebuild agctl
                    print("")
                    Logger.info("Rebuilding agctl...")
                    await rebuildAgctl(bag: bag)
                }
                return .success
            } else {
                Logger.error("Clean failed")
                return .failure
            }
        }
    }
}

// MARK: - Clean Functions

private func cleanSPM(dryRun: Bool, verbose: Bool, bag: CancellationBag) async -> (Bool, Int64) {
    var totalSize: Int64 = 0
    
    do {
        let workspaceRoot = FileSystem.findRoot()
        
        let paths = [
            workspaceRoot.appendingPathComponent(".build"),
            workspaceRoot.appendingPathComponent("build"),
            workspaceRoot.appendingPathComponent("Tools/agctl/.build")
        ]
        
        // Also get all package .build directories
        let packages = try PackageResolver.allPackages()
        let packagePaths = packages.map { $0.path.appendingPathComponent(".build") }
        
        let allPaths = paths + packagePaths
        
        for path in allPaths {
            if FileManager.default.fileExists(atPath: path.path) {
                let size = directorySize(path.path)
                totalSize += size
                
                if verbose {
                    Logger.bullet("\(path.lastPathComponent): \(formatBytes(size))")
                }
                
                if !dryRun {
                    try FileManager.default.removeItem(at: path)
                }
            }
        }
        
        return (true, totalSize)
    } catch {
        if verbose {
            Logger.error("Error: \(error.localizedDescription)")
        }
        return (false, totalSize)
    }
}

private func cleanXcode(dryRun: Bool, verbose: Bool) async -> (Bool, Int64) {
    var totalSize: Int64 = 0
    
    do {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let derivedDataPath = homeDirectory.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        
        guard FileManager.default.fileExists(atPath: derivedDataPath.path) else {
            if verbose {
                Logger.bullet("DerivedData not found")
            }
            return (true, 0)
        }
        
        // Find Agora-specific folders
        let contents = try FileManager.default.contentsOfDirectory(atPath: derivedDataPath.path)
        
        for item in contents where item.contains("Agora") {
            let itemPath = derivedDataPath.appendingPathComponent(item)
            let size = directorySize(itemPath.path)
            totalSize += size
            
            if verbose {
                Logger.bullet("\(item): \(formatBytes(size))")
            }
            
            if !dryRun {
                try FileManager.default.removeItem(at: itemPath)
            }
        }
        
        return (true, totalSize)
    } catch {
        if verbose {
            Logger.error("Error: \(error.localizedDescription)")
        }
        return (false, totalSize)
    }
}

private func cleanModuleCache(dryRun: Bool, verbose: Bool) async -> (Bool, Int64) {
    var totalSize: Int64 = 0
    
    do {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        
        let paths = [
            homeDirectory.appendingPathComponent("Library/Caches/org.swift.swiftpm"),
            homeDirectory.appendingPathComponent("Library/Developer/Xcode/DerivedData/ModuleCache.noindex")
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path.path) {
                let size = directorySize(path.path)
                totalSize += size
                
                if verbose {
                    Logger.bullet("\(path.lastPathComponent): \(formatBytes(size))")
                }
                
                if !dryRun {
                    try FileManager.default.removeItem(at: path)
                }
            }
        }
        
        return (true, totalSize)
    } catch {
        if verbose {
            Logger.error("Error: \(error.localizedDescription)")
        }
        return (false, totalSize)
    }
}

private func cleanAgctlCache(dryRun: Bool, verbose: Bool) async -> (Bool, Int64) {
    var totalSize: Int64 = 0
    
    do {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let agctlCache = homeDirectory.appendingPathComponent(".agctl/builds")
        
        if FileManager.default.fileExists(atPath: agctlCache.path) {
            let size = directorySize(agctlCache.path)
            totalSize += size
            
            if verbose {
                Logger.bullet("agctl builds cache: \(formatBytes(size))")
            }
            
            if !dryRun {
                try FileManager.default.removeItem(at: agctlCache)
            }
        }
        
        return (true, totalSize)
    } catch {
        if verbose {
            Logger.error("Error: \(error.localizedDescription)")
        }
        return (false, totalSize)
    }
}

// MARK: - Rebuild Logic

private func needsRebuild() async -> Bool {
    // Check if the symlink is broken or agctl binary doesn't exist
    let agctlPath = "/usr/local/bin/agctl"
    
    guard FileManager.default.fileExists(atPath: agctlPath) else {
        return true
    }
    
    // Check if it's a symlink and if the target exists
    guard let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: agctlPath) else {
        return false
    }
    
    return !FileManager.default.fileExists(atPath: destination)
}

private func rebuildAgctl(bag: CancellationBag) async {
    do {
        let workspaceRoot = FileSystem.findRoot()
        let agctlPath = workspaceRoot.appendingPathComponent("Tools/agctl")
        
        let result = try await runProcess(
            "/usr/bin/xcrun",
            arguments: ["swift", "build", "-c", "release", "--product", "agctl"],
            workingDirectory: agctlPath,
            bag: bag
        )
        
        if result.isSuccess {
            Logger.success("agctl rebuilt successfully")
        } else {
            Logger.error("Failed to rebuild agctl")
            if !result.stderr.isEmpty {
                print(result.stderr)
            }
        }
    } catch {
        Logger.error("Failed to rebuild: \(error.localizedDescription)")
    }
}

// MARK: - Size Calculation

private func calculateTotalSize() async -> Int64 {
    var total: Int64 = 0
    
    do {
        let workspaceRoot = FileSystem.findRoot()
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        
        // SPM builds
        let spmPaths = [
            workspaceRoot.appendingPathComponent(".build"),
            workspaceRoot.appendingPathComponent("build"),
            workspaceRoot.appendingPathComponent("Tools/agctl/.build")
        ]
        
        for path in spmPaths {
            if FileManager.default.fileExists(atPath: path.path) {
                total += directorySize(path.path)
            }
        }
        
        // Package builds
        if let packages = try? PackageResolver.allPackages() {
            for package in packages {
                let buildPath = package.path.appendingPathComponent(".build")
                if FileManager.default.fileExists(atPath: buildPath.path) {
                    total += directorySize(buildPath.path)
                }
            }
        }
        
        // Xcode DerivedData
        let derivedDataPath = homeDirectory.appendingPathComponent("Library/Developer/Xcode/DerivedData")
        if FileManager.default.fileExists(atPath: derivedDataPath.path) {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: derivedDataPath.path) {
                for item in contents where item.contains("Agora") {
                    let itemPath = derivedDataPath.appendingPathComponent(item)
                    total += directorySize(itemPath.path)
                }
            }
        }
        
        // Module caches
        let cachePaths = [
            homeDirectory.appendingPathComponent("Library/Caches/org.swift.swiftpm"),
            homeDirectory.appendingPathComponent("Library/Developer/Xcode/DerivedData/ModuleCache.noindex")
        ]
        
        for path in cachePaths {
            if FileManager.default.fileExists(atPath: path.path) {
                total += directorySize(path.path)
            }
        }
        
    } catch {
        // Ignore errors in size calculation
    }
    
    return total
}

private func directorySize(_ path: String) -> Int64 {
    guard let enumerator = FileManager.default.enumerator(atPath: path) else {
        return 0
    }
    
    var totalSize: Int64 = 0
    
    for case let file as String in enumerator {
        let fullPath = (path as NSString).appendingPathComponent(file)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fullPath),
           let size = attributes[.size] as? Int64 {
            totalSize += size
        }
    }
    
    return totalSize
}

private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    formatter.allowedUnits = [.useGB, .useMB, .useKB]
    return formatter.string(fromByteCount: bytes)
}
