import Foundation

/// File system operations
enum FileSystem {
    /// Find the project root directory (contains Package.swift)
    static func findRoot() -> URL {
        var currentPath = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        
        // Walk up until we find Package.swift
        while currentPath.path != "/" {
            let packagePath = currentPath.appendingPathComponent("Package.swift")
            if FileManager.default.fileExists(atPath: packagePath.path) {
                return currentPath
            }
            currentPath = currentPath.deletingLastPathComponent()
        }
        
        // Fallback to current directory
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    }
    
    /// Find all package directories in the Packages folder
    static func findPackages() throws -> [URL] {
        let root = findRoot()
        let packagesDir = root.appendingPathComponent("Packages")
        
        guard FileManager.default.fileExists(atPath: packagesDir.path) else {
            return []
        }
        
        var packages: [URL] = []
        
        // Search in Features, Kits, and Shared directories
        let searchDirs = ["Features", "Kits", "Shared"]
        
        for dir in searchDirs {
            let searchPath = packagesDir.appendingPathComponent(dir)
            guard FileManager.default.fileExists(atPath: searchPath.path) else {
                continue
            }
            
            let contents = try FileManager.default.contentsOfDirectory(
                at: searchPath,
                includingPropertiesForKeys: [.isDirectoryKey]
            )
            
            for item in contents {
                let packageSwift = item.appendingPathComponent("Package.swift")
                if FileManager.default.fileExists(atPath: packageSwift.path) {
                    packages.append(item)
                }
            }
        }
        
        return packages
    }
    
    /// Clean a directory by removing and recreating it
    static func clean(directory: URL) throws {
        let fm = FileManager.default
        
        if fm.fileExists(atPath: directory.path) {
            try fm.removeItem(at: directory)
        }
        
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    
    /// Write string content to a file
    static func writeFile(at url: URL, content: String) throws {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Read string content from a file
    static func readFile(at url: URL) throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }
}

