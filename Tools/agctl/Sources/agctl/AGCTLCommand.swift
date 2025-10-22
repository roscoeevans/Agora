import ArgumentParser
import Foundation

@main
struct AGCTLCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agctl",
        abstract: "Agora development command-line tool",
        discussion: """
            A unified interface for building, testing, validating, and generating code
            for the Agora iOS project.
            """,
        version: "1.4.0",
        subcommands: [
            GenerateCommand.self,
            BuildCommand.self,
            TestCommand.self,
            ValidateCommand.self,
            LintCommand.self,
            CleanCommand.self,
            ConfigCommand.self,
            CompletionsCommand.self,
            InstallHooksCommand.self,
            SelfUpdateCommand.self,
            UpdateCommand.self,
            DoctorCommand.self,
            DevCommand.self,
            // New 2025 features
            AutoFixCommand.self,
            ProfileCommand.self,
            TelemetryCommand.self,
            PluginCommand.self
        ],
        defaultSubcommand: nil
    )
    
    /// Main entrypoint with full reliability guards
    static func main() async {
        do {
            var command = try parseAsRoot()
            
            // If this is a RunnableCommand, use guarded execution
            if let runnable = command as? RunnableCommand {
                let code = await runnable.runWithGuards()
                Foundation.exit(code.rawValue)
            } else {
                // Legacy synchronous command
                try command.run()
                Foundation.exit(EXIT_SUCCESS)
            }
        } catch {
            // Let ArgumentParser format and exit (handles --help, --version, validation)
            Self.exit(withError: error)
        }
    }
}

