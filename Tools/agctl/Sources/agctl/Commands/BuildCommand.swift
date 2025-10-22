import ArgumentParser
import Foundation

struct BuildCommand: ParsableCommand, RunnableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build one or all Swift packages"
    )
    
    @Argument(help: "The package to build (e.g., Auth, DesignSystem). If omitted, builds all packages.")
    var packageName: String?
    
    @Flag(name: .shortAndLong, help: "Show verbose build output")
    var verbose = false
    
    @Flag(name: .shortAndLong, help: "Build in release configuration")
    var release = false
    
    @Flag(help: "Enable performance profiling")
    var profile = false
    
    /// Timeout: 30 minutes for builds (some packages can take a while)
    var timeout: Duration { .seconds(1800) }
    
    func execute(bag: CancellationBag) async throws -> ExitCode {
        let startTime = Date()
        var success = false
        var errorType: String? = nil
        
        defer {
            let duration = Date().timeIntervalSince(startTime)
            let finalSuccess = success
            let finalErrorType = errorType
            Task {
                await Telemetry.shared.trackBuild(
                    packageName: packageName,
                    duration: duration,
                    success: finalSuccess,
                    errorType: finalErrorType
                )
            }
        }
        
        do {
            let result: ExitCode
            if profile {
                // Use performance profiling
                if let packageName = packageName {
                    result = try await PerformanceProfiler.shared.profileBuild(packageName: packageName) {
                        try await buildPackage(named: packageName, bag: bag)
                    }
                } else {
                    result = try await PerformanceProfiler.shared.profileBuild(packageName: nil) {
                        try await buildAllPackages(bag: bag)
                    }
                }
            } else {
                if let packageName = packageName {
                    result = try await buildPackage(named: packageName, bag: bag)
                } else {
                    result = try await buildAllPackages(bag: bag)
                }
            }
            
            success = result == .success
            return result
        } catch {
            errorType = String(describing: type(of: error))
            Task {
                await Telemetry.shared.trackError(
                    error.localizedDescription,
                    command: "build",
                    context: [
                        "package_name": packageName ?? "all_packages",
                        "verbose": verbose,
                        "release": release
                    ]
                )
            }
            throw error
        }
    }
    
    private func buildPackage(named name: String, bag: CancellationBag) async throws -> ExitCode {
        Logger.section("🔨 Building \(name)")
        
        guard let package = try PackageResolver.findPackage(named: name) else {
            Logger.error("Package '\(name)' not found")
            print("")
            print("Available packages:")
            let packages = try PackageResolver.allPackages()
            for pkg in packages.sorted(by: { $0.displayName < $1.displayName }) {
                print("  • \(pkg.displayName) (\(pkg.name))")
            }
            return .failure
        }
        
        // Quick dependency check before building
        let allPackages = try PackageResolver.allPackages()
        if let cycle = findCircularDependency(from: package, in: allPackages) {
            let cycleString = cycle.map { $0.displayName }.joined(separator: " → ")
            Logger.error("Cannot build: Circular dependency detected")
            Logger.bullet(cycleString)
            print("")
            Logger.info("Run 'agctl validate dependencies' for full analysis")
            return .failure
        }
        
        Logger.bullet("Package: \(package.displayName)")
        Logger.bullet("Path:    \(package.path.path)")
        Logger.bullet("Type:    \(package.type)")
        print("")
        
        let configuration = release ? "release" : "debug"
        let args = ["build", "-c", configuration]
        
        do {
            if verbose {
                // Live output mode
                let result = try await runProcessWithLiveOutput(
                    "/usr/bin/xcrun",
                    arguments: ["swift"] + args,
                    workingDirectory: package.path,
                    bag: bag
                )
                
                if result.isSuccess {
                    Logger.success("Build succeeded!")
                    return .success
                } else {
                    Logger.error("Build failed")
                    return .failure
                }
            } else {
                // Spinner mode
                let result = try await withSpinner(
                    "Building \(package.displayName)",
                    successMessage: "Build succeeded",
                    failureMessage: "Build failed"
                ) {
                    try await runSwift(
                        arguments: args,
                        workingDirectory: package.path,
                        bag: bag
                    )
                }
                
                if result.isSuccess {
                    return .success
                } else {
                    // Show actual build errors
                    print("")
                // Show AI-powered error suggestions
                let context = ErrorContext(
                    packageName: package.displayName,
                    buildType: .singlePackage,
                    hasRecentChanges: false,
                    command: "build"
                )
                
                let analysis = AIErrorAnalyzer.analyzeError(result.stderr + "\n" + result.stdout, context: context)
                
                if analysis.hasHighConfidence {
                    Logger.section("🤖 AI Error Analysis")
                    Logger.info("I found some issues and have suggestions:")
                    print("")
                    
                    for suggestion in analysis.suggestions.prefix(3) {
                        Logger.bullet(suggestion)
                    }
                    
                    if analysis.canAutoFix {
                        print("")
                        Logger.info("I can try to fix these automatically:")
                        for autoFix in analysis.autoFixes {
                            Logger.bullet(autoFix.description)
                        }
                        print("")
                        Logger.info("Run 'agctl auto-fix \(package.displayName)' to attempt automatic fixes")
                    }
                    print("")
                }
                
                if !result.stderr.isEmpty {
                    print(result.stderr)
                }
                if !result.stdout.isEmpty {
                    print(result.stdout)
                }
                return .failure
                }
            }
        } catch {
            Logger.error("Unexpected error: \(error.localizedDescription)")
            return .failure
        }
    }
    
    private func buildAllPackages(bag: CancellationBag) async throws -> ExitCode {
        Logger.section("🔨 Building All Packages")
        
        let packages = try PackageResolver.allPackages()
        
        // Check for circular dependencies before building anything
        Logger.info("Checking for circular dependencies...")
        for package in packages {
            if let cycle = findCircularDependency(from: package, in: packages) {
                let cycleString = cycle.map { $0.displayName }.joined(separator: " → ")
                print("")
                Logger.error("Cannot build: Circular dependency detected")
                Logger.bullet(cycleString)
                print("")
                Logger.info("Run 'agctl validate dependencies' for full analysis")
                return .failure
            }
        }
        Logger.success("No circular dependencies found")
        print("")
        
        let sorted = packages.sorted { pkg1, pkg2 in
            // Build order: Shared -> Kits -> Features
            if pkg1.type != pkg2.type {
                return sortOrder(for: pkg1.type) < sortOrder(for: pkg2.type)
            }
            return pkg1.displayName < pkg2.displayName
        }
        
        Logger.info("Found \(sorted.count) packages")
        print("")
        
        let configuration = release ? "release" : "debug"
        let args = ["build", "-c", configuration]
        
        if verbose {
            // Verbose mode: show each build with live output, fail fast
            for (index, package) in sorted.enumerated() {
                let progress = "[\(index + 1)/\(sorted.count)]"
                Logger.info("\(progress) Building \(package.displayName)...")
                
                let result = try await runProcessWithLiveOutput(
                    "/usr/bin/xcrun",
                    arguments: ["swift"] + args,
                    workingDirectory: package.path,
                    bag: bag
                )
                
                if result.isSuccess {
                    Logger.success("  ✓ \(package.displayName)")
                } else {
                    Logger.error("  ✗ \(package.displayName) failed")
                    print("")
                    Logger.error("Build failed. Stopping at first failure.")
                    Logger.info("Fix the error above and try again.")
                    return .failure
                }
            }
        } else {
            // Non-verbose mode: show progress bar, fail fast with error output
            let progressBar = AsyncProgressBar(total: sorted.count, message: "Building")
            
            for (index, package) in sorted.enumerated() {
                await progressBar.update(current: index, itemMessage: package.displayName)
                
                let result = try await runSwift(
                    arguments: args,
                    workingDirectory: package.path,
                    bag: bag
                )
                
                if !result.isSuccess {
                    // Stop progress bar and show the error
                    await progressBar.complete(finalMessage: "Build failed")
                    print("")
                    Logger.error("\(package.displayName) failed to build")
                    print("")
                    
                    // Show the actual error
                    if !result.stderr.isEmpty {
                        print(result.stderr)
                    }
                    if !result.stdout.isEmpty {
                        print(result.stdout)
                    }
                    
                    print("")
                    Logger.info("Fix the error above and run 'agctl build' again")
                    Logger.info("Or run 'agctl build \(package.displayName) --verbose' for detailed output")
                    return .failure
                }
            }
            
            await progressBar.complete(finalMessage: "Build complete")
        }
        
        print("")
        Logger.success("All packages built successfully!")
        return .success
    }
    
    private func sortOrder(for type: PackageType) -> Int {
        switch type {
        case .shared: return 0
        case .kit: return 1
        case .feature: return 2
        case .unknown: return 3
        }
    }
    
    // MARK: - Dependency Validation
    
    private func findCircularDependency(
        from package: Package,
        in packages: [Package],
        visited: Set<String> = [],
        path: [Package] = []
    ) -> [Package]? {
        // If we've seen this package before, we have a cycle
        if visited.contains(package.name) {
            if let startIndex = path.firstIndex(where: { $0.name == package.name }) {
                return Array(path[startIndex...]) + [package]
            }
            return nil
        }
        
        var newVisited = visited
        newVisited.insert(package.name)
        
        var newPath = path
        newPath.append(package)
        
        // Check each dependency
        for depName in package.dependencies {
            if let depPackage = packages.first(where: { $0.name == depName || $0.displayName == depName }) {
                if let cycle = findCircularDependency(from: depPackage, in: packages, visited: newVisited, path: newPath) {
                    return cycle
                }
            }
        }
        
        return nil
    }
}

