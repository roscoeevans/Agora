#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SPEC="$ROOT_DIR/OpenAPI/agora.yaml"
CONF="$ROOT_DIR/OpenAPI/openapi-config.yaml"
OUT="$ROOT_DIR/Packages/Kits/Networking/Sources/Networking/Generated"
LOCK="$ROOT_DIR/OpenAPI/VERSION.lock"

echo "🔧 OpenAPI Client Code Generation"
echo "=================================="
echo ""
echo "• Spec:   $SPEC"
echo "• Config: $CONF"
echo "• Output: $OUT"
echo ""

# Ensure output directory exists
rm -rf "$OUT"
mkdir -p "$OUT"

# Method 1: Try using swift-openapi-generator via Mint (recommended)
if command -v mint &> /dev/null; then
    echo "→ Using Mint to run swift-openapi-generator"
    mint run apple/swift-openapi-generator swift-openapi-generator generate \
        "$SPEC" \
        --config "$CONF" \
        --output-directory "$OUT" \
        && echo "main" > "$LOCK" \
        && echo "✅ Generation successful via Mint!" \
        && exit 0
fi

# Method 2: Try using homebrew-installed generator
if command -v swift-openapi-generator &> /dev/null; then
    echo "→ Using Homebrew swift-openapi-generator"
    VERSION=$(swift-openapi-generator --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    swift-openapi-generator generate \
        "$SPEC" \
        --config "$CONF" \
        --output-directory "$OUT" \
        && echo "$VERSION" > "$LOCK" \
        && echo "✅ Generation successful via Homebrew!" \
        && exit 0
fi

# Method 3: Try using SPM plugin (if in Xcode project context)
if [[ -f "$ROOT_DIR/Package.swift" ]]; then
    echo "→ Attempting to use SPM plugin"
    cd "$ROOT_DIR"
    
    # Create temporary package with plugin
    TEMP_PKG="$ROOT_DIR/.tools/openapi-temp"
    rm -rf "$TEMP_PKG"
    mkdir -p "$TEMP_PKG"
    
    cat > "$TEMP_PKG/Package.swift" <<'EOF'
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenAPIGenerator",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0")
    ]
)
EOF
    
    # Try to invoke plugin
    if swift package --package-path "$TEMP_PKG" plugin generate-code-from-openapi \
        --input "$SPEC" \
        --config "$CONF" \
        --output "$OUT" 2>/dev/null; then
        echo "1.0.0" > "$LOCK"
        rm -rf "$TEMP_PKG"
        echo "✅ Generation successful via SPM plugin!"
        exit 0
    fi
    
    rm -rf "$TEMP_PKG"
fi

# Method 4: Try Docker (fallback for CI environments)
if command -v docker &> /dev/null; then
    echo "→ Using Docker with Swift 6"
    docker run --rm \
        -v "$ROOT_DIR:/workspace" \
        -w /workspace \
        swift:6.0 \
        bash -c "swift package resolve && swift run openapi-generator generate \
            /workspace/OpenAPI/agora.yaml \
            --config /workspace/OpenAPI/openapi-config.yaml \
            --output-directory /workspace/Packages/Kits/Networking/Sources/Networking/Generated" \
        && echo "docker" > "$LOCK" \
        && echo "✅ Generation successful via Docker!" \
        && exit 0
fi

# If all methods fail, provide helpful instructions
echo ""
echo "❌ No OpenAPI generator found!"
echo ""
echo "Please install swift-openapi-generator using one of these methods:"
echo ""
echo "  1. Mint (recommended):"
echo "     brew install mint"
echo "     mint install apple/swift-openapi-generator"
echo ""
echo "  2. Homebrew:"
echo "     brew install swift-openapi-generator"
echo ""
echo "  3. Manual:"
echo "     git clone https://github.com/apple/swift-openapi-generator"
echo "     cd swift-openapi-generator"
echo "     make install"
echo ""
echo "After installation, run 'make api-gen' again."
echo ""

exit 1
