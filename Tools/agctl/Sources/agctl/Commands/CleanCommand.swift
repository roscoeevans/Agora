import ArgumentParser
import Foundation

struct CleanCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clean",
        abstract: "Clean Xcode build artifacts and cached data"
    )
    
    @Flag(name: .shortAndLong, help: "Show verbose output")
    var verbose = false
    
    @Flag(name: [.customLong("all")], help: "Clean everything including DerivedData and module cache")
    var cleanAll = false
    
    func run() throws {
        Logger.section("🧹 Cleaning Build Artifacts")
        
        var cleanedItems: [String] = []
        var failedItems: [String] = []
        
        // Always clean: Project build folder
        if cleanProjectBuildFolder() {
            cleanedItems.append("Project build folder")
        } else {
            failedItems.append("Project build folder")
        }
        
        // Always clean: Swift Package Manager caches
        if cleanSwiftPackageCache() {
            cleanedItems.append("Swift Package Manager cache")
        } else {
            failedItems.append("Swift Package Manager cache")
        }
        
        // Clean all: DerivedData
        if cleanAll {
            if cleanDerivedData() {
                cleanedItems.append("DerivedData")
            } else {
                failedItems.append("DerivedData")
            }
            
            // Clean all: Module cache
            if cleanModuleCache() {
                cleanedItems.append("Module cache")
            } else {
                failedItems.append("Module cache")
            }
        }
        
        // Summary
        print("")
        if !cleanedItems.isEmpty {
            Logger.success("Cleaned \(cleanedItems.count) item(s):")
            for item in cleanedItems {
                Logger.bullet(item)
            }
        }
        
        if !failedItems.isEmpty {
            print("")
            Logger.warning("Could not clean \(failedItems.count) item(s):")
            for item in failedItems {
                Logger.bullet(item)
            }
        }
        
        if !cleanAll && failedItems.isEmpty {
            print("")
            Logger.info("Tip: Use --all to also clean DerivedData and module cache")
        }
    }
    
    /// Clean the project's build folder
    private func cleanProjectBuildFolder() -> Bool {
        Logger.info("Cleaning project build folder...")
        
        do {
            let workspaceRoot = FileSystem.findRoot()
            let buildPath = workspaceRoot.appendingPathComponent("build").path
            
            if FileManager.default.fileExists(atPath: buildPath) {
                try FileManager.default.removeItem(atPath: buildPath)
                if verbose {
                    Logger.arrow("Removed: \(buildPath)")
                }
            } else if verbose {
                Logger.arrow("Not found: \(buildPath)")
            }
            return true
        } catch {
            if verbose {
                Logger.error("Error: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    /// Clean Swift Package Manager build artifacts
    private func cleanSwiftPackageCache() -> Bool {
        Logger.info("Cleaning Swift Package Manager cache...")
        
        var success = true
        
        do {
            let workspaceRoot = FileSystem.findRoot()
            
            // Clean main .build directory
            let mainBuildPath = workspaceRoot.appendingPathComponent(".build").path
            if FileManager.default.fileExists(atPath: mainBuildPath) {
                try FileManager.default.removeItem(atPath: mainBuildPath)
                if verbose {
                    Logger.arrow("Removed: \(mainBuildPath)")
                }
            }
            
            // Clean package-level .build directories
            let packages = try PackageResolver.allPackages()
            for package in packages {
                let packageBuildPath = package.path.path.appending("/.build")
                if FileManager.default.fileExists(atPath: packageBuildPath) {
                    try FileManager.default.removeItem(atPath: packageBuildPath)
                    if verbose {
                        Logger.arrow("Removed: \(packageBuildPath)")
                    }
                }
            }
            
            // Also clean agctl's own build directory
            let agctlBuildPath = workspaceRoot.appendingPathComponent("Tools/agctl/.build").path
            if FileManager.default.fileExists(atPath: agctlBuildPath) {
                try FileManager.default.removeItem(atPath: agctlBuildPath)
                if verbose {
                    Logger.arrow("Removed: \(agctlBuildPath)")
                }
            }
            
        } catch {
            if verbose {
                Logger.error("Error: \(error.localizedDescription)")
            }
            success = false
        }
        
        return success
    }
    
    /// Clean DerivedData
    private func cleanDerivedData() -> Bool {
        Logger.info("Cleaning DerivedData...")
        
        do {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
            let derivedDataPath = "\(homeDirectory)/Library/Developer/Xcode/DerivedData"
            
            if FileManager.default.fileExists(atPath: derivedDataPath) {
                // Get project-specific DerivedData folder
                let workspaceRoot = FileSystem.findRoot()
                let projectName = workspaceRoot.lastPathComponent
                
                // Try to find and remove project-specific DerivedData
                let contents = try FileManager.default.contentsOfDirectory(atPath: derivedDataPath)
                var removed = false
                
                for item in contents {
                    if item.hasPrefix(projectName) || item.contains("Agora") {
                        let itemPath = "\(derivedDataPath)/\(item)"
                        try FileManager.default.removeItem(atPath: itemPath)
                        if verbose {
                            Logger.arrow("Removed: \(itemPath)")
                        }
                        removed = true
                    }
                }
                
                if !removed && verbose {
                    Logger.arrow("No project-specific DerivedData found")
                }
            } else if verbose {
                Logger.arrow("DerivedData directory not found")
            }
            
            return true
        } catch {
            if verbose {
                Logger.error("Error: \(error.localizedDescription)")
            }
            return false
        }
    }
    
    /// Clean module cache
    private func cleanModuleCache() -> Bool {
        Logger.info("Cleaning module cache...")
        
        do {
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
            let moduleCachePath = "\(homeDirectory)/Library/Caches/org.swift.swiftpm"
            
            if FileManager.default.fileExists(atPath: moduleCachePath) {
                try FileManager.default.removeItem(atPath: moduleCachePath)
                if verbose {
                    Logger.arrow("Removed: \(moduleCachePath)")
                }
            } else if verbose {
                Logger.arrow("Module cache not found")
            }
            
            // Also clean Xcode's module cache
            let xcodeModuleCachePath = "\(homeDirectory)/Library/Developer/Xcode/DerivedData/ModuleCache.noindex"
            if FileManager.default.fileExists(atPath: xcodeModuleCachePath) {
                try FileManager.default.removeItem(atPath: xcodeModuleCachePath)
                if verbose {
                    Logger.arrow("Removed: \(xcodeModuleCachePath)")
                }
            } else if verbose {
                Logger.arrow("Xcode module cache not found")
            }
            
            return true
        } catch {
            if verbose {
                Logger.error("Error: \(error.localizedDescription)")
            }
            return false
        }
    }
}

