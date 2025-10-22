import ArgumentParser
import Foundation

struct CompletionsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "completions",
        abstract: "Generate shell completion scripts"
    )
    
    @Argument(help: "The shell to generate completions for (bash, zsh, fish)")
    var shell: Shell
    
    enum Shell: String, ExpressibleByArgument {
        case bash
        case zsh
        case fish
        
        var defaultValueDescription: String { rawValue }
    }
    
    func run() throws {
        let script = AGCTLCommand.completionScript(for: shell.shellType)
        print(script)
    }
}

extension CompletionsCommand.Shell {
    var shellType: CompletionShell {
        switch self {
        case .bash: return .bash
        case .zsh: return .zsh
        case .fish: return .fish
        }
    }
}

