# Agora UI Tests

This directory contains comprehensive UI tests for the Agora iOS app, covering main app flows, tab navigation, and accessibility compliance.

## Test Structure

### AgoraUITests.swift
Main UI test suite covering:
- App launch verification
- Tab navigation functionality
- Screen transition stability
- Performance testing
- Error handling and stress testing

### TabNavigationUITests.swift
Dedicated tab navigation tests covering:
- Tab existence and proper labeling
- Tab selection behavior
- Content verification for each tab
- Navigation state preservation
- Multiple tab switching scenarios

### AccessibilityUITests.swift
Comprehensive accessibility tests covering:
- VoiceOver label verification
- Accessibility element identification
- Dynamic Type support
- Reduced Motion compatibility
- High contrast mode support

### AgoraUITestsLaunchTests.swift
App launch and performance tests covering:
- Successful app launch verification
- Launch performance measurement
- Launch stability across multiple attempts
- Different orientation launch testing

## Test Coverage

### Main App Flows ✅
- [x] App launches successfully on simulator
- [x] Tab bar displays with all expected tabs
- [x] Tab navigation works correctly
- [x] Screen transitions are stable
- [x] Rapid tab switching doesn't cause crashes

### Tab Navigation ✅
- [x] All tabs exist with correct labels
- [x] Tab selection works properly
- [x] Default tab (For You) is selected on launch
- [x] Tab state is preserved when switching
- [x] Multiple tab switches work correctly

### Accessibility Compliance ✅
- [x] VoiceOver labels are present and meaningful
- [x] All interactive elements are accessibility elements
- [x] Tab buttons have correct accessibility traits
- [x] Selected state is properly communicated
- [x] Interface remains usable with Dynamic Type
- [x] Reduced Motion preferences are respected
- [x] High contrast mode is supported

## Running Tests

### Using Xcode
1. Open `Agora.xcodeproj` in Xcode
2. Select a simulator (iPhone 16 Pro recommended)
3. Press `Cmd+U` to run all tests, or
4. Use the Test Navigator to run specific test suites

### Using Command Line
```bash
# Run all UI tests
xcodebuild test -project Agora.xcodeproj -scheme Agora -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Run specific test suite
xcodebuild test -project Agora.xcodeproj -scheme Agora -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:AgoraUITests

# Run using the provided script
./Scripts/run-ui-tests.sh
```

### Test Requirements
- iOS 26.0+ simulator
- Xcode 16.0+
- iPhone or iPad simulator (iPhone 16 Pro recommended)

## Test Implementation Details

### App Launch Tests
- Verify tab bar appears within 10 seconds
- Check all expected tabs are present
- Confirm For You tab is selected by default
- Take screenshots for visual verification

### Tab Navigation Tests
- Test each tab individually
- Verify tab selection state changes
- Ensure other tabs are deselected when one is selected
- Test rapid switching for stability

### Screen Transition Tests
- Navigate through all tabs sequentially
- Test rapid tab switching (stress test)
- Verify app remains responsive after transitions
- Check for memory leaks or crashes

### Accessibility Tests
- Verify VoiceOver labels exist and are descriptive
- Check accessibility traits are appropriate
- Test with different text sizes (Dynamic Type)
- Ensure high contrast compatibility
- Verify reduced motion support

### Performance Tests
- Measure app launch time
- Test tab switching performance
- Monitor memory usage during tests
- Verify smooth animations and transitions

## Test Data and Mocks

Since this is the scaffolding phase with placeholder implementations:
- Tests focus on UI structure and navigation
- No backend integration testing yet
- Mock data will be added as features are implemented
- Tests verify basic functionality without complex business logic

## Continuous Integration

These tests are designed to run in CI environments:
- Use headless simulators for faster execution
- Generate test reports and screenshots
- Fail fast on critical path issues
- Support parallel test execution

## Future Enhancements

As features are implemented, tests will be expanded to cover:
- User authentication flows
- Post creation and interaction
- Search functionality
- Notification handling
- Profile management
- Real-time updates
- Network error handling
- Offline behavior

## Troubleshooting

### Common Issues
1. **Simulator not found**: Ensure iPhone 16 Pro simulator is installed
2. **Build failures**: Check that all package dependencies are resolved
3. **Test timeouts**: Increase timeout values for slower CI environments
4. **Accessibility failures**: Verify VoiceOver is properly configured

### Debug Tips
- Use `app.debugDescription` to inspect UI hierarchy
- Add screenshots with `XCTAttachment` for visual debugging
- Use breakpoints in test methods for step-by-step debugging
- Check simulator logs for crash information

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

**Requirement 6.3**: Test accessibility compliance with VoiceOver
- ✅ VoiceOver label verification
- ✅ Accessibility element identification
- ✅ Proper accessibility traits
- ✅ Dynamic Type support

**Requirement 6.5**: Test basic screen transitions and app launch
- ✅ App launch verification
- ✅ Tab navigation testing
- ✅ Screen transition stability
- ✅ Performance measurement