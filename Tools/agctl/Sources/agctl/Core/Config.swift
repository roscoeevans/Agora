import Foundation

/// Configuration loaded from .agctl.yml
struct AGCTLConfig: Codable {
    var build: BuildConfig
    var validation: ValidationConfig
    var generate: GenerateConfig
    var lint: LintConfig
    
    struct BuildConfig: Codable {
        var defaultConfiguration: BuildConfiguration
        var parallelJobs: Int
        var verbose: Bool
        
        enum BuildConfiguration: String, Codable {
            case debug
            case release
        }
        
        init() {
            self.defaultConfiguration = .debug
            self.parallelJobs = 4
            self.verbose = false
        }
    }
    
    struct ValidationConfig: Codable {
        var strictNaming: Bool
        var allowFeatureDeps: Bool
        var enforceTests: Bool
        
        init() {
            self.strictNaming = true
            self.allowFeatureDeps = false
            self.enforceTests = false
        }
    }
    
    struct GenerateConfig: Codable {
        var openapi: OpenAPIConfig
        
        struct OpenAPIConfig: Codable {
            var specPath: String
            var outputPath: String
            
            init() {
                self.specPath = "OpenAPI/agora.yaml"
                self.outputPath = "Packages/Kits/Networking/Sources/Networking/Generated"
            }
        }
        
        init() {
            self.openapi = OpenAPIConfig()
        }
    }
    
    struct LintConfig: Codable {
        var autoFix: Bool
        var strict: Bool
        var configPath: String?
        
        init() {
            self.autoFix = false
            self.strict = false
            self.configPath = nil
        }
    }
    
    init() {
        self.build = BuildConfig()
        self.validation = ValidationConfig()
        self.generate = GenerateConfig()
        self.lint = LintConfig()
    }
}

/// Manages loading and accessing configuration
enum ConfigManager {
    /// Load configuration from .agctl.yml or use defaults
    static func load(from directory: String = FileManager.default.currentDirectoryPath) -> AGCTLConfig {
        let configPath = "\(directory)/.agctl.yml"
        
        // Check if config file exists
        guard FileManager.default.fileExists(atPath: configPath),
              let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)) else {
            return AGCTLConfig()
        }
        
        // Try to parse YAML (we'll use a simple parser for now)
        do {
            return try parseYAML(data)
        } catch {
            Logger.warning("Failed to parse .agctl.yml, using defaults: \(error.localizedDescription)")
            return AGCTLConfig()
        }
    }
    
    /// Generate example configuration file
    static func generateExample() -> String {
        return """
        # agctl configuration file
        # Place this file at the root of your project as .agctl.yml
        
        build:
          # Default build configuration (debug or release)
          defaultConfiguration: debug
          
          # Number of parallel build jobs
          parallelJobs: 4
          
          # Show verbose output by default
          verbose: false
        
        validation:
          # Enforce strict naming conventions (Features must end with "Feature")
          strictNaming: true
          
          # Allow Features to depend on other Features
          allowFeatureDeps: false
          
          # Require all packages to have test directories
          enforceTests: false
        
        generate:
          openapi:
            # Path to OpenAPI specification
            specPath: OpenAPI/agora.yaml
            
            # Output path for generated code
            outputPath: Packages/Kits/Networking/Sources/Networking/Generated
        
        lint:
          # Automatically fix lint issues when possible
          autoFix: false
          
          # Use strict mode (treat warnings as errors)
          strict: false
          
          # Path to custom SwiftLint configuration (optional)
          # configPath: .swiftlint.yml
        """
    }
    
    /// Parse YAML data into config (simple parser)
    private static func parseYAML(_ data: Data) throws -> AGCTLConfig {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ConfigError.invalidFormat
        }
        
        var config = AGCTLConfig()
        
        // Simple YAML parser for our specific structure
        let lines = content.components(separatedBy: .newlines)
        var currentSection: String?
        var currentSubsection: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Parse sections
            if !line.hasPrefix(" ") && line.hasSuffix(":") {
                currentSection = trimmed.dropLast().lowercased()
                currentSubsection = nil
                continue
            }
            
            // Parse subsections (2 spaces)
            if line.hasPrefix("  ") && !line.hasPrefix("    ") && line.hasSuffix(":") {
                currentSubsection = trimmed.dropLast().lowercased()
                continue
            }
            
            // Parse key-value pairs
            let components = trimmed.components(separatedBy: ": ")
            guard components.count == 2 else { continue }
            
            let key = components[0].trimmingCharacters(in: .whitespaces)
            let value = components[1].trimmingCharacters(in: .whitespaces)
            
            // Apply values based on section
            switch (currentSection, currentSubsection) {
            case ("build", nil):
                parseBuildConfig(key: key, value: value, config: &config)
            case ("validation", nil):
                parseValidationConfig(key: key, value: value, config: &config)
            case ("generate", "openapi"):
                parseOpenAPIConfig(key: key, value: value, config: &config)
            case ("lint", nil):
                parseLintConfig(key: key, value: value, config: &config)
            default:
                break
            }
        }
        
        return config
    }
    
    private static func parseBuildConfig(key: String, value: String, config: inout AGCTLConfig) {
        switch key.lowercased() {
        case "defaultconfiguration":
            if let buildConfig = AGCTLConfig.BuildConfig.BuildConfiguration(rawValue: value) {
                config.build.defaultConfiguration = buildConfig
            }
        case "paralleljobs":
            if let jobs = Int(value) {
                config.build.parallelJobs = jobs
            }
        case "verbose":
            config.build.verbose = value.lowercased() == "true"
        default:
            break
        }
    }
    
    private static func parseValidationConfig(key: String, value: String, config: inout AGCTLConfig) {
        switch key.lowercased() {
        case "strictnaming":
            config.validation.strictNaming = value.lowercased() == "true"
        case "allowfeaturedeps":
            config.validation.allowFeatureDeps = value.lowercased() == "true"
        case "enforcetests":
            config.validation.enforceTests = value.lowercased() == "true"
        default:
            break
        }
    }
    
    private static func parseOpenAPIConfig(key: String, value: String, config: inout AGCTLConfig) {
        switch key.lowercased() {
        case "specpath":
            config.generate.openapi.specPath = value
        case "outputpath":
            config.generate.openapi.outputPath = value
        default:
            break
        }
    }
    
    private static func parseLintConfig(key: String, value: String, config: inout AGCTLConfig) {
        switch key.lowercased() {
        case "autofix":
            config.lint.autoFix = value.lowercased() == "true"
        case "strict":
            config.lint.strict = value.lowercased() == "true"
        case "configpath":
            config.lint.configPath = value
        default:
            break
        }
    }
}

enum ConfigError: LocalizedError {
    case invalidFormat
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid configuration file format"
        case .fileNotFound:
            return "Configuration file not found"
        }
    }
}

