#!/bin/bash
# 构建 release 版 .app 并用 DEV X 签名（实际构建由 Makefile 完成：swiftc 直编）
# 用法: Scripts/build-app.sh
set -e
cd "$(dirname "$0")/.."

make build CONFIG=release ARCHS="arm64 x86_64"

echo "built .build/release/BongoCat Menubar.app"
