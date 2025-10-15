import ArgumentParser
import Foundation

struct ValidateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate project structure and dependencies",
        subcommands: [
            ModulesCommand.self,
            DependenciesCommand.self
        ]
    )
}

// MARK: - Module Validation

extension ValidateCommand {
    struct ModulesCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "modules",
            abstract: "Validate module structure and naming conventions"
        )
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose = false
        
        func run() throws {
            Logger.section("🔍 Validating Module Structure")
            
            let packages = try PackageResolver.allPackages()
            Logger.info("Found \(packages.count) packages")
            print("")
            
            var issues: [String] = []
            
            // Check each package
            for package in packages.sorted(by: { $0.displayName < $1.displayName }) {
                if verbose {
                    Logger.info("Checking \(package.displayName)...")
                }
                
                // Validate naming conventions
                issues += validateNaming(package)
                
                // Validate directory structure
                issues += validateStructure(package)
                
                // Validate dependencies
                issues += validateDependencyRules(package)
                
                // Validate test target exists
                issues += validateTests(package)
            }
            
            if issues.isEmpty {
                Logger.success("All modules are valid!")
            } else {
                print("")
                Logger.error("Found \(issues.count) issue(s):")
                for issue in issues {
                    Logger.bullet(issue)
                }
                throw ExitCode.failure
            }
        }
        
        private func validateNaming(_ package: Package) -> [String] {
            var issues: [String] = []
            
            // Features should end with "Feature"
            if package.type == .feature && !package.name.hasSuffix("Feature") {
                issues.append("\(package.displayName): Name should end with 'Feature' (got '\(package.name)')")
            }
            
            // Check for naming inconsistencies
            let expectedName = package.path.lastPathComponent
            if package.name != expectedName && !package.name.hasSuffix("Feature") {
                issues.append("\(package.displayName): Package name '\(package.name)' doesn't match directory '\(expectedName)'")
            }
            
            return issues
        }
        
        private func validateStructure(_ package: Package) -> [String] {
            var issues: [String] = []
            let fm = FileManager.default
            
            // Check for Sources directory
            let sourcesDir = package.path.appendingPathComponent("Sources")
            if !fm.fileExists(atPath: sourcesDir.path) {
                issues.append("\(package.displayName): Missing 'Sources' directory")
            }
            
            // Check for Package.swift
            let packageSwift = package.path.appendingPathComponent("Package.swift")
            if !fm.fileExists(atPath: packageSwift.path) {
                issues.append("\(package.displayName): Missing 'Package.swift'")
            }
            
            return issues
        }
        
        private func validateDependencyRules(_ package: Package) -> [String] {
            var issues: [String] = []
            
            switch package.type {
            case .feature:
                // Features should NOT depend on other Features
                for dep in package.dependencies {
                    if dep.hasSuffix("Feature") || isFeaturePackage(dep) {
                        issues.append("\(package.displayName): Feature should not depend on another Feature ('\(dep)')")
                    }
                }
                
            case .kit:
                // Kits should only depend on Shared or other Kits
                for dep in package.dependencies {
                    if dep.hasSuffix("Feature") || isFeaturePackage(dep) {
                        issues.append("\(package.displayName): Kit should not depend on Features ('\(dep)')")
                    }
                }
                
            case .shared:
                // Shared packages should not depend on Features or Kits
                for dep in package.dependencies {
                    if isLocalPackage(dep) {
                        issues.append("\(package.displayName): Shared package should not depend on local packages ('\(dep)')")
                    }
                }
                
            case .unknown:
                break
            }
            
            return issues
        }
        
        private func validateTests(_ package: Package) -> [String] {
            var issues: [String] = []
            
            let testsDir = package.path.appendingPathComponent("Tests")
            if !FileManager.default.fileExists(atPath: testsDir.path) {
                if verbose {
                    issues.append("\(package.displayName): No 'Tests' directory found (recommended)")
                }
            }
            
            return issues
        }
        
        private func isFeaturePackage(_ name: String) -> Bool {
            let featureNames = ["Auth", "Home", "HomeForYou", "HomeFollowing", "Compose", "PostDetail",
                              "Threading", "Profile", "Search", "Notifications", "DMs"]
            return featureNames.contains(name)
        }
        
        private func isLocalPackage(_ name: String) -> Bool {
            // Check if this is a known local package name
            let localPackages = ["DesignSystem", "Networking", "Persistence", "Media", "Analytics",
                               "Moderation", "Verification", "Recommender", "AppFoundation", "TestSupport"]
            return localPackages.contains(name) || name.hasSuffix("Feature")
        }
    }
}

// MARK: - Dependency Validation

extension ValidateCommand {
    struct DependenciesCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "dependencies",
            abstract: "Validate dependency graph and check for circular dependencies"
        )
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose = false
        
        func run() throws {
            Logger.section("🔍 Validating Dependencies")
            
            let packages = try PackageResolver.allPackages()
            Logger.info("Found \(packages.count) packages")
            print("")
            
            var issues: [String] = []
            
            // Check for circular dependencies
            if verbose {
                Logger.info("Checking for circular dependencies...")
            }
            
            for package in packages {
                if let cycle = findCircularDependency(from: package, in: packages) {
                    let cycleString = cycle.map { $0.displayName }.joined(separator: " → ")
                    issues.append("Circular dependency detected: \(cycleString)")
                }
            }
            
            // Check for missing dependencies
            if verbose {
                Logger.info("Checking for missing dependencies...")
            }
            
            for package in packages {
                for dep in package.dependencies {
                    let found = packages.contains { $0.displayName == dep || $0.name == dep }
                    if !found && isLocalPackage(dep) {
                        issues.append("\(package.displayName): Dependency '\(dep)' not found")
                    }
                }
            }
            
            // Check for invalid relative paths
            if verbose {
                Logger.info("Checking for invalid paths...")
            }
            
            for package in packages {
                let packageSwift = package.path.appendingPathComponent("Package.swift")
                if let content = try? String(contentsOf: packageSwift, encoding: .utf8) {
                    if content.contains(".package(path:") {
                        // Basic sanity check - just ensure relative paths start with ..
                        let pathPattern = #"\.package\(path:\s*"([^"]+)"\)"#
                        if let regex = try? NSRegularExpression(pattern: pathPattern) {
                            let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
                            
                            for match in matches {
                                if let range = Range(match.range(at: 1), in: content) {
                                    let path = String(content[range])
                                    if !path.hasPrefix("..") && !path.hasPrefix("/") {
                                        issues.append("\(package.displayName): Invalid relative path '\(path)' (should start with '..')")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if issues.isEmpty {
                Logger.success("All dependencies are valid!")
            } else {
                print("")
                Logger.error("Found \(issues.count) issue(s):")
                for issue in issues {
                    Logger.bullet(issue)
                }
                throw ExitCode.failure
            }
        }
        
        private func findCircularDependency(from package: Package, in packages: [Package], visited: Set<String> = [], path: [Package] = []) -> [Package]? {
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
        
        private func isLocalPackage(_ name: String) -> Bool {
            let localPackages = ["DesignSystem", "Networking", "Persistence", "Media", "Analytics",
                               "Moderation", "Verification", "Recommender", "AppFoundation", "TestSupport"]
            return localPackages.contains(name) || name.hasSuffix("Feature")
        }
    }
}

