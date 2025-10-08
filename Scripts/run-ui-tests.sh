#!/bin/bash

# UI Test Runner Script for Agora
# This script runs the UI tests for the main app flows

set -e

echo "🧪 Running Agora UI Tests..."

# Get available simulators
echo "📱 Available iOS Simulators:"
xcrun simctl list devices iOS | grep "iPhone"

# Use the first available iPhone 16 Pro simulator
SIMULATOR_ID=$(xcrun simctl list devices iOS | grep "iPhone 16 Pro" | head -1 | grep -o '[A-F0-9-]\{36\}')

if [ -z "$SIMULATOR_ID" ]; then
    echo "❌ No iPhone 16 Pro simulator found. Please create one in Xcode."
    exit 1
fi

echo "📱 Using simulator: $SIMULATOR_ID"

# Boot the simulator if it's not already running
echo "🚀 Booting simulator..."
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true

# Wait for simulator to be ready
echo "⏳ Waiting for simulator to be ready..."
sleep 5

# Run the UI tests
echo "🧪 Running UI Tests..."

# Test app launch
echo "Testing app launch..."
xcodebuild test \
    -project Agora.xcodeproj \
    -scheme Agora \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:AgoraUITests/AgoraUITestsLaunchTests/testLaunch \
    -quiet

# Test tab navigation
echo "Testing tab navigation..."
xcodebuild test \
    -project Agora.xcodeproj \
    -scheme Agora \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:AgoraUITests/TabNavigationUITests/testAllTabsExist \
    -quiet

# Test accessibility
echo "Testing accessibility..."
xcodebuild test \
    -project Agora.xcodeproj \
    -scheme Agora \
    -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
    -only-testing:AgoraUITests/AccessibilityUITests/testVoiceOverLabels \
    -quiet

echo "✅ All UI tests completed successfully!"
echo ""
echo "📋 Available test suites:"
echo "  - AgoraUITests: Main app flow tests"
echo "  - TabNavigationUITests: Tab navigation specific tests"
echo "  - AccessibilityUITests: VoiceOver and accessibility tests"
echo "  - AgoraUITestsLaunchTests: App launch and performance tests"
echo ""
echo "To run all tests:"
echo "  xcodebuild test -project Agora.xcodeproj -scheme Agora -destination 'platform=iOS Simulator,id=$SIMULATOR_ID'"