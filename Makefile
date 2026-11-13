# 统一入口（见 AGENTS.md）。.app 名字带空格，所以这里只用伪目标，不用文件目标。
APP := .build/release/BongoCat Menubar.app

.PHONY: check build test lint run package icon demo clean

## check: 静态检查 + 构建 + 单元测试（CI 跑的就是它）
check: lint build test

lint:
	plutil -lint Info.plist
	bash -n Scripts/build-app.sh
	bash -n Scripts/package-dmg.sh

build:
	swift build

test:
	swift test

## run: 打包 release .app 并在前台运行（Ctrl-C 退出，日志直接输出到终端）
run:
	Scripts/build-app.sh
	"$(APP)/Contents/MacOS/BongoCat Menubar"

## package: universal .app（DEV X 签名，无证书时 ad-hoc）+ DMG，产物在 .build/release/
package:
	Scripts/build-app.sh
	Scripts/package-dmg.sh

## icon: 重新生成 Resources/AppIcon.icns
icon:
	swift Scripts/generate-icon.swift

## demo: 重新生成 README 演示图和 GIF（docs/assets/）
demo:
	swift Scripts/render-demo.swift

clean:
	swift package clean
	rm -rf "$(APP)" .build/release/BongoCat-Menubar-v*.dmg
