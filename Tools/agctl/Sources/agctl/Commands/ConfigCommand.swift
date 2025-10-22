import ArgumentParser
import Foundation

struct ConfigCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Manage agctl configuration",
        subcommands: [
            InitCommand.self,
            ShowCommand.self
        ]
    )
}

// MARK: - Init Config

extension ConfigCommand {
    struct InitCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "init",
            abstract: "Create a default .agctl.yml configuration file"
        )
        
        @Flag(name: .shortAndLong, help: "Overwrite existing configuration")
        var force = false
        
        func run() throws {
            let configPath = ".agctl.yml"
            
            // Check if file already exists
            if FileManager.default.fileExists(atPath: configPath) && !force {
                Logger.error("Configuration file already exists: \(configPath)")
                Logger.info("Use --force to overwrite")
                throw ExitCode.failure
            }
            
            let exampleConfig = ConfigManager.generateExample()
            
            try exampleConfig.write(toFile: configPath, atomically: true, encoding: .utf8)
            
            Logger.success("Created configuration file: \(configPath)")
            print("")
            Logger.info("Edit this file to customize agctl behavior for your project")
            Logger.info("Run 'agctl config show' to view current configuration")
        }
    }
}

// MARK: - Show Config

extension ConfigCommand {
    struct ShowCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "show",
            abstract: "Show current configuration"
        )
        
        func run() throws {
            let config = ConfigManager.load()
            
            Logger.section("⚙️  agctl Configuration")
            
            print("Build:")
            Logger.bullet("Default configuration: \(config.build.defaultConfiguration.rawValue)")
            Logger.bullet("Parallel jobs: \(config.build.parallelJobs)")
            Logger.bullet("Verbose: \(config.build.verbose)")
            
            print("")
            print("Validation:")
            Logger.bullet("Strict naming: \(config.validation.strictNaming)")
            Logger.bullet("Allow feature deps: \(config.validation.allowFeatureDeps)")
            Logger.bullet("Enforce tests: \(config.validation.enforceTests)")
            
            print("")
            print("Generate:")
            Logger.bullet("OpenAPI spec: \(config.generate.openapi.specPath)")
            Logger.bullet("OpenAPI output: \(config.generate.openapi.outputPath)")
            
            print("")
            print("Lint:")
            Logger.bullet("Auto-fix: \(config.lint.autoFix)")
            Logger.bullet("Strict: \(config.lint.strict)")
            if let configPath = config.lint.configPath {
                Logger.bullet("Config path: \(configPath)")
            }
            
            print("")
            
            // Check if .agctl.yml exists
            if FileManager.default.fileExists(atPath: ".agctl.yml") {
                Logger.info("Using configuration from: .agctl.yml")
            } else {
                Logger.info("Using default configuration (no .agctl.yml found)")
                Logger.info("Run 'agctl config init' to create a configuration file")
            }
        }
    }
}

