#!/bin/bash
# 构建 release 版 .app 并用 DEV X 签名（SwiftPM 编译，universal binary）
# 用法: Scripts/build-app.sh
set -e
cd "$(dirname "$0")/.."

APP_NAME="BongoCat Menubar"
APP_BUNDLE=".build/release/$APP_NAME.app"
IDENTITY="DEV X"

# ---- 编译（universal: arm64 + x86_64） ----
swift build -c release --arch arm64 --arch x86_64

# 多架构产物路径（SwiftPM 多 arch 输出在 .build/apple/Products/Release/）
BIN=".build/apple/Products/Release/BongoCatMenubar"
[ -f "$BIN" ] || BIN=".build/release/BongoCatMenubar"

# ---- 版本号（与旧 Makefile 一致：git tag 优先，回退 Info.plist） ----
VERSION="$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//')"
[ -n "$VERSION" ] || VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info.plist)"
BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || echo 1)"

# ---- 图标（gitignored，缺失时现场生成，与旧 Makefile 行为一致） ----
[ -f Resources/AppIcon.icns ] || swift Scripts/generate-icon.swift

# ---- 组装 .app ----
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp Info.plist "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP_BUNDLE/Contents/Info.plist"
cp "$BIN" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp Resources/Icons/* "$APP_BUNDLE/Contents/Resources/"
for lproj in Resources/*.lproj; do cp -R "$lproj" "$APP_BUNDLE/Contents/Resources/"; done
cp Resources/AppIcon.icns "$APP_BUNDLE/Contents/Resources/"

# ---- 签名 ----
if security find-certificate -c "$IDENTITY" >/dev/null 2>&1; then
    codesign --force --deep --sign "$IDENTITY" "$APP_BUNDLE"
else
    echo "警告: 未找到签名身份 '$IDENTITY'，回退为 ad-hoc 签名"
    codesign --force --deep --sign - "$APP_BUNDLE"
fi
codesign -v "$APP_BUNDLE"

echo "built $APP_BUNDLE (v$VERSION+$BUILD_NUMBER, universal)"
