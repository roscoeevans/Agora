import Foundation
import ArgumentParser

/// Plugin system for extending agctl functionality
/// Allows teams to add custom commands and functionality
@MainActor
class PluginSystem: @unchecked Sendable {
    static let shared = PluginSystem()
    
    private var plugins: [String: AGCTLPlugin] = [:]
    private let pluginDirectory: URL
    
    private init() {
        pluginDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".agctl/plugins")
        
        // Ensure plugin directory exists
        try? FileManager.default.createDirectory(at: pluginDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Plugin Management
    
    /// Load all installed plugins
    func loadPlugins() async throws {
        guard FileManager.default.fileExists(atPath: pluginDirectory.path) else { return }
        
        let contents = try FileManager.default.contentsOfDirectory(atPath: pluginDirectory.path)
        
        for item in contents {
            let pluginPath = pluginDirectory.appendingPathComponent(item)
            
            if item.hasSuffix(".agctl-plugin") {
                try await loadPlugin(from: pluginPath)
            }
        }
    }
    
    /// Load a specific plugin
    private func loadPlugin(from path: URL) async throws {
        // For now, plugins are Swift packages
        // In the future, this could support different plugin formats
        
        let manifestPath = path.appendingPathComponent("Package.swift")
        guard FileManager.default.fileExists(atPath: manifestPath.path) else {
            Logger.warning("No Package.swift found in plugin at \(path.path)")
            return
        }
        
        // Build the plugin
        let result = try await runProcess(
            "/usr/bin/xcrun",
            arguments: ["swift", "build", "-c", "release"],
            workingDirectory: path,
            bag: CancellationBag()
        )
        
        guard result.isSuccess else {
            Logger.error("Failed to build plugin at \(path.path)")
            return
        }
        
        // Load plugin metadata
        let metadata = try await loadPluginMetadata(from: path)
        let plugin = AGCTLPluginImpl(
            name: metadata.name,
            version: metadata.version,
            commands: [], // Will be discovered at runtime
            path: path
        )
        
        plugins[metadata.name] = plugin
        Logger.success("Loaded plugin: \(metadata.name) v\(metadata.version)")
    }
    
    /// Load plugin metadata
    private func loadPluginMetadata(from path: URL) async throws -> PluginMetadata {
        let metadataPath = path.appendingPathComponent("agctl-plugin.json")
        
        if FileManager.default.fileExists(atPath: metadataPath.path) {
            let data = try Data(contentsOf: metadataPath)
            return try JSONDecoder().decode(PluginMetadata.self, from: data)
        } else {
            // Fallback to Package.swift parsing
            return try await parsePackageManifest(from: path)
        }
    }
    
    /// Parse Package.swift for plugin metadata
    private func parsePackageManifest(from path: URL) async throws -> PluginMetadata {
        let manifestPath = path.appendingPathComponent("Package.swift")
        let content = try String(contentsOf: manifestPath, encoding: .utf8)
        
        // Simple parsing - in production, use a proper Swift parser
        let name = extractPackageName(from: content)
        let version = "1.0.0" // Default version
        
        return PluginMetadata(
            name: name,
            version: version,
            commands: [] // Will be discovered at runtime
        )
    }
    
    private func extractPackageName(from content: String) -> String {
        // Simple regex to extract package name
        let pattern = #"name:\s*"([^"]+)""#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: content, range: NSRange(location: 0, length: content.utf16.count)) {
            let range = match.range(at: 1)
            if let swiftRange = Range(range, in: content) {
                return String(content[swiftRange])
            }
        }
        return "unknown-plugin"
    }
    
    // MARK: - Plugin Commands
    
    /// Get all plugin commands
    func getAllCommands() -> [ParsableCommand.Type] {
        return plugins.values.flatMap { $0.commands }
    }
    
    /// Get commands for a specific plugin
    func getCommands(for pluginName: String) -> [ParsableCommand.Type] {
        return plugins[pluginName]?.commands ?? []
    }
    
    /// Execute a plugin command
    func executeCommand(_ command: String, arguments: [String]) async throws -> ExitCode {
        // Find the plugin that owns this command
        for plugin in plugins.values {
            if plugin.commands.contains(where: { $0.configuration.commandName == command }) {
                return try await plugin.execute(command: command, arguments: arguments)
            }
        }
        
        throw PluginError.commandNotFound(command)
    }
    
    // MARK: - Plugin Installation
    
    /// Install a plugin from a URL
    func installPlugin(from url: URL, name: String? = nil) async throws {
        Logger.info("Installing plugin from \(url.path)")
        
        let pluginName = name ?? url.lastPathComponent
        let pluginPath = pluginDirectory.appendingPathComponent("\(pluginName).agctl-plugin")
        
        // Clone/copy the plugin
        if url.isFileURL {
            try FileManager.default.copyItem(at: url, to: pluginPath)
        } else {
            // Git clone
            let result = try await runProcess(
                "/usr/bin/git",
                arguments: ["clone", url.absoluteString, pluginPath.path],
                bag: CancellationBag()
            )
            
            guard result.isSuccess else {
                throw PluginError.installationFailed("Git clone failed")
            }
        }
        
        // Load the newly installed plugin
        try await loadPlugin(from: pluginPath)
        
        Logger.success("Plugin '\(pluginName)' installed successfully")
    }
    
    /// Uninstall a plugin
    func uninstallPlugin(_ name: String) throws {
        guard let plugin = plugins[name] else {
            throw PluginError.pluginNotFound(name)
        }
        
        try FileManager.default.removeItem(at: plugin.path)
        plugins.removeValue(forKey: name)
        
        Logger.success("Plugin '\(name)' uninstalled")
    }
    
    /// List installed plugins
    func listPlugins() -> [PluginInfo] {
        return plugins.values.map { plugin in
            PluginInfo(
                name: plugin.name,
                version: plugin.version,
                commands: plugin.commands.map { $0.configuration.commandName ?? "unknown" }
            )
        }
    }
}

// MARK: - Plugin Protocol

protocol AGCTLPlugin: Sendable {
    var name: String { get }
    var version: String { get }
    var commands: [ParsableCommand.Type] { get }
    var path: URL { get }
    
    func execute(command: String, arguments: [String]) async throws -> ExitCode
}

// MARK: - Plugin Implementation

class AGCTLPluginImpl: @unchecked Sendable, AGCTLPlugin {
    let name: String
    let version: String
    let commands: [ParsableCommand.Type]
    let path: URL
    
    init(name: String, version: String, commands: [ParsableCommand.Type], path: URL) {
        self.name = name
        self.version = version
        self.commands = commands
        self.path = path
    }
    
    func execute(command: String, arguments: [String]) async throws -> ExitCode {
        // Execute the plugin command
        // This would involve loading the plugin's executable and running it
        // For now, return a placeholder
        Logger.info("Executing plugin command: \(command) with args: \(arguments.joined(separator: " "))")
        return .success
    }
}

// MARK: - Supporting Types

struct PluginMetadata: Codable {
    let name: String
    let version: String
    let commands: [String]
}

struct PluginInfo {
    let name: String
    let version: String
    let commands: [String]
}

enum PluginError: LocalizedError {
    case commandNotFound(String)
    case pluginNotFound(String)
    case installationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .commandNotFound(let command):
            return "Plugin command '\(command)' not found"
        case .pluginNotFound(let plugin):
            return "Plugin '\(plugin)' not found"
        case .installationFailed(let reason):
            return "Plugin installation failed: \(reason)"
        }
    }
}

// MARK: - Plugin Commands

struct PluginCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "plugin",
        abstract: "Manage agctl plugins"
    )
    
    @Argument(help: "Plugin action (install, uninstall, list)")
    var action: String
    
    @Argument(help: "Plugin name or URL")
    var target: String?
    
    func run() async throws {
        switch action {
        case "install":
            guard let target = target else {
                throw ValidationError("Plugin URL or name required")
            }
            
            let url = URL(string: target) ?? URL(fileURLWithPath: target)
            try await PluginSystem.shared.installPlugin(from: url)
            
        case "uninstall":
            guard let target = target else {
                throw ValidationError("Plugin name required")
            }
            try await PluginSystem.shared.uninstallPlugin(target)
            
        case "list":
            let plugins = await PluginSystem.shared.listPlugins()
            
            if plugins.isEmpty {
                Logger.info("No plugins installed")
            } else {
                Logger.section("Installed Plugins")
                for plugin in plugins {
                    Logger.info("• \(plugin.name) v\(plugin.version)")
                    for command in plugin.commands {
                        Logger.bullet("  - \(command)")
                    }
                }
            }
            
        default:
            throw ValidationError("Unknown action: \(action)")
        }
    }
}
