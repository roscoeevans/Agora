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
        version: "1.0.0",
        subcommands: [
            GenerateCommand.self,
            BuildCommand.self,
            TestCommand.self,
            ValidateCommand.self,
            InstallHooksCommand.self
        ],
        defaultSubcommand: nil
    )
}

