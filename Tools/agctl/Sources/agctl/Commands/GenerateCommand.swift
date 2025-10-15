import ArgumentParser
import Foundation

struct GenerateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate code and resources",
        subcommands: [
            OpenAPICommand.self,
            MocksCommand.self
        ]
    )
}

// MARK: - OpenAPI Generation

extension GenerateCommand {
    struct OpenAPICommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "openapi",
            abstract: "Generate OpenAPI client code from spec"
        )
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose = false
        
        func run() throws {
            let root = FileSystem.findRoot()
            let spec = root.appendingPathComponent("OpenAPI/agora.yaml")
            let config = root.appendingPathComponent("OpenAPI/openapi-config.yaml")
            let output = root.appendingPathComponent("Packages/Kits/Networking/Sources/Networking/Generated")
            let lock = root.appendingPathComponent("OpenAPI/VERSION.lock")
            
            Logger.section("🔧 OpenAPI Client Code Generation")
            Logger.bullet("Spec:   \(spec.path)")
            Logger.bullet("Config: \(config.path)")
            Logger.bullet("Output: \(output.path)")
            print("")
            
            // Ensure spec exists
            guard FileManager.default.fileExists(atPath: spec.path) else {
                Logger.error("OpenAPI spec not found at \(spec.path)")
                throw ExitCode.failure
            }
            
            // Clean and recreate output directory
            try FileSystem.clean(directory: output)
            
            // Try different generation methods
            if let version = try tryMint(spec: spec, config: config, output: output, verbose: verbose) {
                try FileSystem.writeFile(at: lock, content: version)
                Logger.success("Generation successful via Mint!")
                return
            }
            
            if let version = try tryHomebrew(spec: spec, config: config, output: output, verbose: verbose) {
                try FileSystem.writeFile(at: lock, content: version)
                Logger.success("Generation successful via Homebrew!")
                return
            }
            
            if let version = try trySPMPlugin(spec: spec, config: config, output: output, root: root, verbose: verbose) {
                try FileSystem.writeFile(at: lock, content: version)
                Logger.success("Generation successful via SPM plugin!")
                return
            }
            
            if let version = try tryDocker(spec: spec, config: config, output: output, root: root, verbose: verbose) {
                try FileSystem.writeFile(at: lock, content: version)
                Logger.success("Generation successful via Docker!")
                return
            }
            
            // All methods failed
            Logger.error("No OpenAPI generator found!")
            print("")
            print("Please install swift-openapi-generator using one of these methods:")
            print("")
            print("  1. Mint (recommended):")
            print("     brew install mint")
            print("     mint install apple/swift-openapi-generator")
            print("")
            print("  2. Homebrew:")
            print("     brew install swift-openapi-generator")
            print("")
            print("After installation, run 'agctl generate openapi' again.")
            print("")
            
            throw ExitCode.failure
        }
        
        // MARK: - Generation Methods
        
        private func tryMint(spec: URL, config: URL, output: URL, verbose: Bool) throws -> String? {
            guard Shell.which("mint") != nil else {
                return nil
            }
            
            Logger.arrow("Using Mint to run swift-openapi-generator")
            
            let command = """
                mint run apple/swift-openapi-generator swift-openapi-generator generate \
                    "\(spec.path)" \
                    --config "\(config.path)" \
                    --output-directory "\(output.path)"
                """
            
            do {
                if verbose {
                    try Shell.runWithLiveOutput(command)
                } else {
                    try Shell.run(command)
                }
                return "mint"
            } catch {
                if verbose {
                    Logger.warning("Mint method failed: \(error)")
                }
                return nil
            }
        }
        
        private func tryHomebrew(spec: URL, config: URL, output: URL, verbose: Bool) throws -> String? {
            guard let binaryPath = Shell.which("swift-openapi-generator") else {
                return nil
            }
            
            Logger.arrow("Using Homebrew swift-openapi-generator")
            
            // Get version
            let versionOutput = try? Shell.run("\(binaryPath) --version")
            let version = extractVersion(from: versionOutput ?? "") ?? "unknown"
            
            let command = """
                swift-openapi-generator generate \
                    "\(spec.path)" \
                    --config "\(config.path)" \
                    --output-directory "\(output.path)"
                """
            
            do {
                if verbose {
                    try Shell.runWithLiveOutput(command)
                } else {
                    try Shell.run(command)
                }
                return version
            } catch {
                if verbose {
                    Logger.warning("Homebrew method failed: \(error)")
                }
                return nil
            }
        }
        
        private func trySPMPlugin(spec: URL, config: URL, output: URL, root: URL, verbose: Bool) throws -> String? {
            Logger.arrow("Attempting to use SPM plugin")
            
            // Create temporary package
            let tempPkg = root.appendingPathComponent(".tools/openapi-temp")
            try? FileManager.default.removeItem(at: tempPkg)
            try FileManager.default.createDirectory(at: tempPkg, withIntermediateDirectories: true)
            
            let packageSwift = """
                // swift-tools-version: 5.9
                import PackageDescription
                
                let package = Package(
                    name: "OpenAPIGenerator",
                    platforms: [.macOS(.v13)],
                    dependencies: [
                        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0")
                    ]
                )
                """
            
            try FileSystem.writeFile(at: tempPkg.appendingPathComponent("Package.swift"), content: packageSwift)
            
            let command = """
                swift package --package-path "\(tempPkg.path)" plugin generate-code-from-openapi \
                    --input "\(spec.path)" \
                    --config "\(config.path)" \
                    --output "\(output.path)"
                """
            
            do {
                if verbose {
                    try Shell.runWithLiveOutput(command)
                } else {
                    try Shell.run(command, captureStderr: true)
                }
                try? FileManager.default.removeItem(at: tempPkg)
                return "1.0.0"
            } catch {
                try? FileManager.default.removeItem(at: tempPkg)
                if verbose {
                    Logger.warning("SPM plugin method failed: \(error)")
                }
                return nil
            }
        }
        
        private func tryDocker(spec: URL, config: URL, output: URL, root: URL, verbose: Bool) throws -> String? {
            guard Shell.which("docker") != nil else {
                return nil
            }
            
            Logger.arrow("Using Docker with Swift 6")
            
            let command = """
                docker run --rm \
                    -v "\(root.path):/workspace" \
                    -w /workspace \
                    swift:6.0 \
                    bash -c "swift package resolve && swift run openapi-generator generate \
                        /workspace/OpenAPI/agora.yaml \
                        --config /workspace/OpenAPI/openapi-config.yaml \
                        --output-directory /workspace/Packages/Kits/Networking/Sources/Networking/Generated"
                """
            
            do {
                if verbose {
                    try Shell.runWithLiveOutput(command)
                } else {
                    try Shell.run(command)
                }
                return "docker"
            } catch {
                if verbose {
                    Logger.warning("Docker method failed: \(error)")
                }
                return nil
            }
        }
        
        private func extractVersion(from output: String) -> String? {
            let pattern = #"[0-9]+\.[0-9]+\.[0-9]+"#
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)),
                  let range = Range(match.range, in: output) else {
                return nil
            }
            return String(output[range])
        }
    }
}

// MARK: - Mock Generation

extension GenerateCommand {
    struct MocksCommand: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "mocks",
            abstract: "Generate mock data for SwiftUI previews"
        )
        
        func run() throws {
            Logger.section("🎭 Mock Data Generation")
            
            let root = FileSystem.findRoot()
            let outputDir = root.appendingPathComponent("Packages/Shared/TestSupport/Sources/TestSupport/Mocks/Generated")
            
            try FileSystem.clean(directory: outputDir)
            
            // Generate mock profiles
            let mockProfilesCode = generateMockProfiles()
            try FileSystem.writeFile(
                at: outputDir.appendingPathComponent("MockProfiles.swift"),
                content: mockProfilesCode
            )
            
            // Generate mock posts
            let mockPostsCode = generateMockPosts()
            try FileSystem.writeFile(
                at: outputDir.appendingPathComponent("MockPosts.swift"),
                content: mockPostsCode
            )
            
            Logger.success("Mock data generated successfully!")
            Logger.bullet("MockProfiles.swift")
            Logger.bullet("MockPosts.swift")
        }
        
        private func generateMockProfiles() -> String {
            """
            // Generated by agctl - DO NOT EDIT
            import Foundation
            
            public enum MockProfiles {
                public static let alice = Profile(
                    id: UUID(),
                    handle: "alice",
                    displayName: "Alice",
                    bio: "iOS developer and coffee enthusiast ☕️",
                    avatarURL: nil,
                    followerCount: 342,
                    followingCount: 189,
                    postCount: 127
                )
                
                public static let bob = Profile(
                    id: UUID(),
                    handle: "bob",
                    displayName: "Bob",
                    bio: "Building cool stuff with Swift",
                    avatarURL: nil,
                    followerCount: 1024,
                    followingCount: 512,
                    postCount: 256
                )
                
                public static let charlie = Profile(
                    id: UUID(),
                    handle: "charlie",
                    displayName: "Charlie",
                    bio: "Designer & developer",
                    avatarURL: nil,
                    followerCount: 89,
                    followingCount: 234,
                    postCount: 56
                )
                
                public static let all = [alice, bob, charlie]
            }
            """
        }
        
        private func generateMockPosts() -> String {
            """
            // Generated by agctl - DO NOT EDIT
            import Foundation
            
            public enum MockPosts {
                public static let shortText = Post(
                    id: UUID(),
                    authorID: MockProfiles.alice.id,
                    content: "Just shipped a new feature! 🚀",
                    mediaURLs: [],
                    createdAt: Date(),
                    likeCount: 42,
                    replyCount: 5,
                    repostCount: 8
                )
                
                public static let longText = Post(
                    id: UUID(),
                    authorID: MockProfiles.bob.id,
                    content: \"\"\"
                        Today I learned something interesting about Swift concurrency. 
                        When you use async/await, the compiler actually transforms your 
                        code into a state machine. This is why you can't capture inout 
                        parameters across suspension points!
                        \"\"\",
                    mediaURLs: [],
                    createdAt: Date().addingTimeInterval(-3600),
                    likeCount: 156,
                    replyCount: 23,
                    repostCount: 34
                )
                
                public static let withLink = Post(
                    id: UUID(),
                    authorID: MockProfiles.charlie.id,
                    content: "Check out this awesome article: https://example.com/swift-tips",
                    mediaURLs: [],
                    createdAt: Date().addingTimeInterval(-7200),
                    likeCount: 89,
                    replyCount: 12,
                    repostCount: 15
                )
                
                public static let all = [shortText, longText, withLink]
            }
            """
        }
    }
}

