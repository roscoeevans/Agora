#!/bin/bash
# ci-postbuild.sh
# Post-build script for CI/CD

set -e

echo "🏗️ Running Agora CI postbuild script..."

# Run tests
echo "🧪 Running tests..."
xcodebuild test \
    -workspace Agora.xcworkspace \
    -scheme Agora \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -quiet

# Generate test coverage report
echo "📊 Generating test coverage..."
xcodebuild test \
    -workspace Agora.xcworkspace \
    -scheme Agora \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -enableCodeCoverage YES \
    -derivedDataPath DerivedData

# Archive for distribution
echo "📦 Creating archive..."
xcodebuild archive \
    -workspace Agora.xcworkspace \
    -scheme Agora \
    -destination 'generic/platform=iOS' \
    -archivePath Agora.xcarchive

echo "✅ CI postbuild complete!"
