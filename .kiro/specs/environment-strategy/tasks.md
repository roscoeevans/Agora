# Implementation Plan

- [x] 1. Set up build configuration foundation
  - Create Base.xcconfig with shared settings extracted from existing Debug/Release configs
  - Update existing Debug.xcconfig and Release.xcconfig to include Base.xcconfig
  - Create environment-specific xcconfig files (Debug-Development, Debug-Staging, Release-Staging, Release-Production)
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [x] 2. Implement environment detection and configuration system
  - [x] 2.1 Create Environment enum in AppFoundation module
    - Add Environment enum with development, staging, production cases
    - Implement static current property using compilation conditions
    - Add helper properties for environment-specific behavior
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 2.2 Create AppConfig structure for centralized configuration
    - Add AppConfig struct to AppFoundation module with all required properties
    - Implement plist loading logic with proper error handling
    - Add configuration validation methods
    - _Requirements: 3.1, 3.4, 3.5, 7.2_

  - [x] 2.3 Create configuration plist structure and examples
    - Create Resources/Configs directory structure
    - Create example plist files with consistent schema for all environments
    - Update .gitignore to exclude actual secrets files
    - _Requirements: 3.1, 3.2, 3.3_

- [x] 3. Implement service factory pattern for mock/production services
  - [x] 3.1 Define service protocols for external dependencies
    - Create AuthServiceProtocol for authentication operations
    - Create PhoneVerifierProtocol for phone verification
    - Create CaptchaServiceProtocol for captcha handling
    - _Requirements: 4.1, 4.6, 7.3_

  - [x] 3.2 Implement mock service implementations
    - Create MockAuthService with realistic test responses
    - Create MockPhoneVerifier with configurable verification flows
    - Create MockCaptchaService with test captcha tokens
    - _Requirements: 4.1, 4.4, 4.5_

  - [x] 3.3 Create ServiceFactory for environment-appropriate service selection
    - Implement DefaultServiceFactory with mock/production service selection
    - Add error handling and fallback logic for service creation
    - Integrate with AppConfig for mock service toggle
    - _Requirements: 4.2, 4.5, 4.6_

- [x] 4. Update existing networking infrastructure
  - [x] 4.1 Modify APIClient to use environment-specific configuration
    - Update APIClient initialization to use AppConfig.shared.apiBaseURL
    - Modify shared instance creation to use environment-specific settings
    - Ensure backward compatibility with existing usage
    - _Requirements: 1.4, 1.5, 7.2_

  - [x] 4.2 Update AuthTokenProvider integration
    - Modify existing AuthTokenProvider usage to work with ServiceFactory
    - Ensure mock and production auth services implement consistent interface
    - Update dependency injection patterns
    - _Requirements: 4.5, 4.6, 7.3_

- [x] 5. Create Xcode project configuration
  - [x] 5.1 Create Xcode schemes for each environment
    - Create "Agora Development" scheme using Debug-Development configuration
    - Create "Agora Staging" scheme using Debug-Staging configuration  
    - Create "Agora Production" scheme using Release-Production configuration
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 6.4_

  - [x] 5.2 Configure environment-specific app settings
    - Set up bundle identifiers for each environment (dev, staging, production)
    - Configure app display names with environment indicators
    - Set up compilation conditions for environment detection
    - _Requirements: 5.1, 5.2, 6.4_

- [ ] 6. Implement environment-specific UI components
  - [ ] 6.1 Create EnvironmentBadge component for development/staging builds
    - Add EnvironmentBadge SwiftUI view to DesignSystem module
    - Implement conditional display logic for non-production environments
    - Style badge with appropriate colors and positioning
    - _Requirements: 5.5_

  - [ ] 6.2 Create debug menu for mock service toggling
    - Add DebugMenu SwiftUI view with mock service toggles
    - Implement DebugSettings class for runtime mock service control
    - Add debug menu access from Profile or Settings screen
    - _Requirements: 4.3_

  - [ ] 6.3 Integrate environment badge into main navigation
    - Add EnvironmentBadge to main tab bar or navigation bar
    - Ensure badge only appears in development and staging builds
    - Position badge to not interfere with existing UI elements
    - _Requirements: 5.5_

- [ ] 7. Set up environment-specific entitlements and capabilities
  - [ ] 7.1 Create environment-specific entitlements files
    - Create separate entitlements files for each environment
    - Configure associated domains for environment-specific deep links
    - Set up push notification environment settings
    - _Requirements: 5.3, 5.4_

  - [ ] 7.2 Configure universal links for each environment
    - Set up associated domains for dev.agora.app, staging.agora.app, agora.app
    - Update URL handling to work with environment-specific domains
    - Test deep link functionality across environments
    - _Requirements: 5.3_

- [ ] 8. Add configuration validation and safety checks
  - [ ] 8.1 Implement startup configuration validation
    - Add AppConfig.validate() call during app initialization
    - Implement debug assertions for environment/bundle ID consistency
    - Add runtime checks for production safety
    - _Requirements: 2.5, 3.4_

  - [ ] 8.2 Add development-time safety assertions
    - Implement debug assertions to prevent production misconfiguration
    - Add bundle identifier validation for each environment
    - Create compile-time checks for environment consistency
    - _Requirements: 2.5, 6.6_

- [ ]* 9. Create comprehensive test suite for environment system
  - [ ]* 9.1 Write unit tests for Environment enum and AppConfig
    - Test environment detection logic with different compilation conditions
    - Test configuration loading with valid and invalid plist files
    - Test error handling for missing or malformed configuration
    - _Requirements: 3.4, 3.5_

  - [ ]* 9.2 Write tests for service factory and mock implementations
    - Test ServiceFactory service selection logic for each environment
    - Test mock service implementations with various scenarios
    - Test fallback behavior when service creation fails
    - _Requirements: 4.4, 4.5, 4.6_

  - [ ]* 9.3 Write integration tests for environment-specific behavior
    - Test APIClient initialization with different environment configurations
    - Test deep link handling across different environments
    - Test environment badge display logic
    - _Requirements: 1.4, 1.5, 5.3, 5.5_

- [ ] 10. Update project documentation and setup instructions
  - [ ] 10.1 Create environment setup documentation
    - Document the three-environment strategy and Supabase project setup
    - Create setup instructions for new developers
    - Document daily workflow for switching between environments
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [ ] 10.2 Update existing README and development guides
    - Update main README with environment strategy overview
    - Add troubleshooting guide for common environment issues
    - Document mock service usage and testing patterns
    - _Requirements: 4.3, 6.5_