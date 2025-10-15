import ArgumentParser
import Foundation

struct BuildCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        abstract: "Build one or all Swift packages"
    )
    
    @Argument(help: "The package to build (e.g., AuthFeature, DesignSystem). If omitted, builds all packages.")
    var packageName: String?
    
    @Flag(name: .shortAndLong, help: "Show verbose build output")
    var verbose = false
    
    @Flag(name: .shortAndLong, help: "Build in release configuration")
    var release = false
    
    func run() throws {
        if let packageName = packageName {
            try buildPackage(named: packageName)
        } else {
            try buildAllPackages()
        }
    }
    
    private func buildPackage(named name: String) throws {
        Logger.section("🔨 Building \(name)")
        
        guard let package = try PackageResolver.findPackage(named: name) else {
            Logger.error("Package '\(name)' not found")
            print("")
            print("Available packages:")
            let packages = try PackageResolver.allPackages()
            for pkg in packages.sorted(by: { $0.displayName < $1.displayName }) {
                print("  • \(pkg.displayName) (\(pkg.name))")
            }
            throw ExitCode.failure
        }
        
        Logger.bullet("Package: \(package.displayName)")
        Logger.bullet("Path:    \(package.path.path)")
        Logger.bullet("Type:    \(package.type)")
        print("")
        
        let configuration = release ? "release" : "debug"
        let command = "swift build -c \(configuration)"
        
        do {
            if verbose {
                try Shell.runWithLiveOutput(command, at: package.path.path)
            } else {
                Logger.info("Building...")
                let output = try Shell.run(command, at: package.path.path)
                if verbose {
                    print(output)
                }
            }
            Logger.success("Build succeeded!")
        } catch {
            Logger.error("Build failed")
            throw ExitCode.failure
        }
    }
    
    private func buildAllPackages() throws {
        Logger.section("🔨 Building All Packages")
        
        let packages = try PackageResolver.allPackages()
        let sorted = packages.sorted { pkg1, pkg2 in
            // Build order: Shared -> Kits -> Features
            if pkg1.type != pkg2.type {
                return sortOrder(for: pkg1.type) < sortOrder(for: pkg2.type)
            }
            return pkg1.displayName < pkg2.displayName
        }
        
        Logger.info("Found \(sorted.count) packages")
        print("")
        
        var failed: [String] = []
        let configuration = release ? "release" : "debug"
        
        for (index, package) in sorted.enumerated() {
            let progress = "[\(index + 1)/\(sorted.count)]"
            Logger.info("\(progress) Building \(package.displayName)...")
            
            let command = "swift build -c \(configuration)"
            
            do {
                if verbose {
                    try Shell.runWithLiveOutput(command, at: package.path.path)
                } else {
                    _ = try Shell.run(command, at: package.path.path)
                }
                Logger.success("  ✓ \(package.displayName)")
            } catch {
                Logger.error("  ✗ \(package.displayName)")
                failed.append(package.displayName)
            }
        }
        
        print("")
        
        if failed.isEmpty {
            Logger.success("All packages built successfully!")
        } else {
            Logger.error("Failed to build \(failed.count) package(s):")
            for name in failed {
                Logger.bullet(name)
            }
            throw ExitCode.failure
        }
    }
    
    private func sortOrder(for type: PackageType) -> Int {
        switch type {
        case .shared: return 0
        case .kit: return 1
        case .feature: return 2
        case .unknown: return 3
        }
    }
}

