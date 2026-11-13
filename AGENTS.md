# AGENTS.md — BongoCat Menubar

macOS 菜单栏 Bongo Cat（无 Dock 图标），跟着键盘敲击做动画。纯 Swift + AppKit，SwiftPM 构建，无第三方依赖。用户文档见 `README.md`（产品视角，不写实现细节），开发文档见 `docs/DEVELOPMENT.md`，环境与重建见 `SETUP.md`。

## 命令

```bash
make check     # plutil/bash 语法检查 + swift build + swift test（CI 跑的就是它）
make run       # Scripts/build-app.sh 打包后前台运行，Ctrl-C 退出
make package   # .build/release/BongoCat Menubar.app + BongoCat-Menubar-v<version>.dmg
make icon      # 重新生成 Resources/AppIcon.icns（gitignored）
make demo      # 重新生成 docs/assets/ 的演示 PNG/GIF
```

工具链：Xcode 16+（Swift Testing 需要），本机验证 Xcode 26.3 / Swift 6.2。最低系统 macOS 13。

## 完成定义

`make check` 全绿；改了逻辑就加或改 `Tests/BongoCatCoreTests/` 的测试；用户可见变化用用户语言写进 `CHANGELOG.md` 的 Unreleased（纯工程改动只写“内部改进”，细节记到 `docs/DEVELOPMENT.md`）；已提交（Conventional Commits）。

## 结构约定

- `Sources/BongoCatCore/`：可测的纯逻辑（`KeyMap` 左右手键位、`modifierKeyIsDown`、`KeystrokeAnimator` 两种模式、`IconManager` 图标查找）。新逻辑优先放这里并写测试。
- `Sources/BongoCatMenubar/`：app 壳（`main.swift`、`AppDelegate` 菜单与权限、`KeyboardMonitor` CGEvent tap），依赖辅助功能权限，不做单元测试。
- 测试用 Swift Testing（`import Testing`）。`KeystrokeAnimator.now` 可注入时钟，`IconManager(bundle:)` 可注入资源 bundle；不要在测试里用固定 sleep。
- 资源不走 SwiftPM resources：`Scripts/build-app.sh` 把 `Resources/Icons/*`、`*.lproj`、`AppIcon.icns` 拷进 `Contents/Resources`，代码用 `Bundle.main` 读取。

## 不能改（连着线上 Homebrew 和用户已授予的权限）

- bundle id `com.zhiyozhao.bongocat-menubar`、app 名 `BongoCat Menubar.app`、可执行文件名 `BongoCat Menubar`。
- DMG 资产名 `BongoCat-Menubar-v<version>.dmg`：`zhiyozhao/homebrew-tap` 的 cask URL 按这个格式拼。
- 版本号来自 git tag（`v1.2.3` → `1.2.3`，回退 `Info.plist`），build 号是 commit 数；只改打包后的 Info.plist，源 `Info.plist` 不动。
- `v*` tag 触发 `.github/workflows/release.yml`；secrets 名 `SIGNING_P12_BASE64` / `SIGNING_P12_PASSWORD`。
- 签名身份 `DEV X`（统一自签名证书，管理在 `~/Codes/dev-x-signing`）。designated requirement 锚定证书，TCC 才能在升级后保留辅助功能授权。无证书时 build-app.sh 回退 ad-hoc。

## 边界

不 push、不打 tag、不改 GitHub 设置或 secrets、不碰 homebrew-tap 和 dev-x-signing、不打印 p12 密码；不装全局工具（brew、`-g`）。需要这些时上报。项目内装了新东西同步更新 SETUP.md。

## 发布

打 `v*` tag 并 push → release.yml：导入证书 → build-app.sh → 校验 `Authority=DEV X` → 启动冒烟 5 秒 → UDZO DMG → `gh release create`。tap 每小时轮询最新 release 并更新 cask（pull 模式，两仓库不共享 token）。`Scripts/package-dmg.sh` 与 release.yml 的 DMG 步骤格式相同，改一处要同步另一处。

## 已知坑

- app 名带空格：shell 里要加引号；Makefile 只用伪目标。
- universal 构建 `swift build -c release --arch arm64 --arch x86_64` 的产物在 `.build/apple/Products/Release/`。
- CGEvent tap 会被系统停用（超时或权限变化），`KeyboardMonitor` 收到 `.tapDisabledBy*` 时重新启用。
- 修饰键走 `flagsChanged`，左右同名键要看 device 位（见 `ModifierKeys.swift`）。Caps Lock 在左手键表里，但 `flagsChanged` 对它总判为松开，目前不触发动画。
- 跟随模式按实际按住的 keycode 集合跟踪每只手，某侧集合为空才收回该侧爪子。丢失的 keyUp 由 `isKeyDown`（app 里是 `CGEventSource.keyState`）兜底：每个事件和按住期间每 1 秒核对一次。
- ad-hoc 签名每次构建都会让辅助功能授权失效：`tccutil reset Accessibility com.zhiyozhao.bongocat-menubar` 后重新授权。
- 这不是 Developer ID 签名，DMG 直接下载会被 Gatekeeper 提示；cask 在 postflight 里 `xattr -cr`。
