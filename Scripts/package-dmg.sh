#!/bin/bash
# 把已构建的 .app 打成 DMG（与 .github/workflows/release.yml 的 Package DMG 步骤同格式：
# UDZO + /Applications 软链，文件名 BongoCat-Menubar-v<version>.dmg）
# 用法: Scripts/package-dmg.sh        （先跑 Scripts/build-app.sh）
set -euo pipefail
cd "$(dirname "$0")/.."

DISPLAY_NAME="BongoCat Menubar"
APP_BUNDLE=".build/release/$DISPLAY_NAME.app"
[ -d "$APP_BUNDLE" ] || { echo "错误: 未找到 $APP_BUNDLE，先运行 Scripts/build-app.sh" >&2; exit 1; }

# 版本号取自已打包 .app（build-app.sh 已按 git tag 写入）
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_BUNDLE/Contents/Info.plist")"
DMG=".build/release/BongoCat-Menubar-v$VERSION.dmg"
STAGE=".build/dmg"

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"
cp -R "$APP_BUNDLE" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$DISPLAY_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGE"

echo "packaged $DMG"
