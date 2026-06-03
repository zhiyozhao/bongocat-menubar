#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/BongoCat-Menubar"
BUILD_DIR="$PROJECT_DIR/.build"
APP_NAME="BongoCat Menubar"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
BINARY_PATH="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "=== Building $APP_NAME ==="

if [ ! -d "$APP_BUNDLE" ]; then
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    cp "$PROJECT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
fi

# Copy icons
if [ -d "$PROJECT_DIR/Resources/Icons" ]; then
    cp "$PROJECT_DIR/Resources/Icons/"*.svg "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
    cp "$PROJECT_DIR/Resources/Icons/"*.png "$APP_BUNDLE/Contents/Resources/" 2>/dev/null || true
    echo "  Icons copied to bundle"
fi

echo "Compiling Swift sources..."
SOURCES=$(find "$PROJECT_DIR/Sources" -name "*.swift" | sort)

swiftc \
    -o "$BINARY_PATH" \
    -target "arm64-apple-macosx13.0" \
    -framework AppKit \
    -framework ApplicationServices \
    -framework CoreGraphics \
    $SOURCES

echo ""
echo "=== Build complete: $APP_BUNDLE ==="
echo ""
echo "To run: open \"$APP_BUNDLE\""
