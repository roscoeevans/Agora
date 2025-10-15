import Foundation

enum PackageType {
    case feature
    case kit
    case shared
    case unknown
    
    init(path: URL) {
        let components = path.pathComponents
        if components.contains("Features") {
            self = .feature
        } else if components.contains("Kits") {
            self = .kit
        } else if components.contains("Shared") {
            self = .shared
        } else {
            self = .unknown
        }
    }
}

struct Package {
    let name: String
    let path: URL
    let type: PackageType
    let dependencies: [String]
    
    var displayName: String {
        path.lastPathComponent
    }
}

enum PackageResolver {
    enum Error: LocalizedError {
        case packageNotFound(String)
        case invalidPackageManifest(URL)
        
        var errorDescription: String? {
            switch self {
            case .packageNotFound(let name):
                return "Package '\(name)' not found"
            case .invalidPackageManifest(let url):
                return "Invalid Package.swift at \(url.path)"
            }
        }
    }
    
    /// Parse a Package.swift file
    static func parse(at url: URL) throws -> Package {
        let packageSwift = url.appendingPathComponent("Package.swift")
        
        guard FileManager.default.fileExists(atPath: packageSwift.path) else {
            throw Error.invalidPackageManifest(url)
        }
        
        let content = try String(contentsOf: packageSwift, encoding: .utf8)
        
        // Extract package name
        let name = extractPackageName(from: content) ?? url.lastPathComponent
        
        // Extract dependencies
        let dependencies = extractDependencies(from: content)
        
        return Package(
            name: name,
            path: url,
            type: PackageType(path: url),
            dependencies: dependencies
        )
    }
    
    /// Find all packages in the project
    static func allPackages() throws -> [Package] {
        let packageURLs = try FileSystem.findPackages()
        return try packageURLs.map { try parse(at: $0) }
    }
    
    /// Find a specific package by name or display name
    static func findPackage(named name: String) throws -> Package? {
        let packages = try allPackages()
        
        // Try exact name match first
        if let match = packages.first(where: { $0.name == name }) {
            return match
        }
        
        // Try display name match
        if let match = packages.first(where: { $0.displayName == name }) {
            return match
        }
        
        // Try case-insensitive match
        return packages.first { package in
            package.name.lowercased() == name.lowercased() ||
            package.displayName.lowercased() == name.lowercased()
        }
    }
    
    // MARK: - Private Helpers
    
    private static func extractPackageName(from content: String) -> String? {
        // Look for: name: "PackageName"
        let pattern = #"name:\s*"([^"]+)""#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(
                in: content,
                range: NSRange(content.startIndex..., in: content)
              ) else {
            return nil
        }
        
        if let range = Range(match.range(at: 1), in: content) {
            return String(content[range])
        }
        
        return nil
    }
    
    private static func extractDependencies(from content: String) -> [String] {
        var deps: [String] = []
        
        // Look for local package dependencies: .package(path: "...")
        let pathPattern = #"\.package\(path:\s*"([^"]+)"\)"#
        if let regex = try? NSRegularExpression(pattern: pathPattern) {
            let matches = regex.matches(
                in: content,
                range: NSRange(content.startIndex..., in: content)
            )
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: content) {
                    let path = String(content[range])
                    // Extract package name from path
                    let components = path.components(separatedBy: "/")
                    if let name = components.last {
                        deps.append(name)
                    }
                }
            }
        }
        
        return deps
    }
}

