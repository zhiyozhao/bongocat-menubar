# 开发文档

面向想从源码构建或参与开发的人。用户文档见 [README](../README.md)。环境要求和重建步骤见 [SETUP.md](../SETUP.md)，项目约定和发布流程见 [AGENTS.md](../AGENTS.md)。

## 从源码构建

需要 Xcode 16 或更新（单元测试用 Swift Testing），没有第三方依赖。本地在 Xcode 26.3 上验证过。

```bash
git clone https://github.com/zhiyozhao/bongocat-menubar.git
cd bongocat-menubar
make check     # plist/脚本语法检查 + swift build + swift test（CI 跑的就是它）
make run       # 打包 release 版 .app 并在前台运行，Ctrl-C 退出
make package   # 产出 .build/release/BongoCat Menubar.app 和 BongoCat-Menubar-v<版本>.dmg
make icon      # 重新生成 Resources/AppIcon.icns
make demo      # 重新生成 README 演示图（docs/assets/）
```

## 签名

钥匙串里有名为 `DEV X` 的代码签名证书时用它签名，否则回退为 ad-hoc 签名。正式发布都用 `DEV X`，designated requirement 锚定证书，所以升级后系统保留辅助功能授权。

ad-hoc 签名的 app 每次重新构建后授权都会失效，重置后再授权：

```bash
tccutil reset Accessibility com.zhiyozhao.bongocat-menubar
```

app 没有 Developer ID 签名和公证。DMG 直接下载会被 Gatekeeper 拦下；Homebrew cask 在 postflight 里执行 `xattr -cr` 去掉隔离标记。手动处理：

```bash
xattr -dr com.apple.quarantine "/Applications/BongoCat Menubar.app"
```

## 实现要点

键盘监听在 `Sources/BongoCatMenubar/KeyboardMonitor.swift`：

- 用 `CGEvent.tapCreate` 建 session 级 event tap，选项 `.listenOnly`，只订阅 `keyDown`、`keyUp`、`flagsChanged` 三类事件。不拦截、不修改、不注入事件。
- 每个事件只读 `keyboardEventKeycode`；`flagsChanged` 再读 `event.flags`，用 device 位区分左右同名修饰键（`Sources/BongoCatCore/ModifierKeys.swift`）。
- keycode 只在内存里交给 `KeystrokeAnimator` 切换图标帧，不写日志、不落盘。源码里没有任何网络调用。
- 系统停用 tap（`.tapDisabledByTimeout` / `.tapDisabledByUserInput`）时重新启用。

app 壳在 `Sources/BongoCatMenubar/AppDelegate.swift`：

- 启动时 `AXIsProcessTrusted()` 为假就弹引导窗，之后每 2 秒轮询一次，拿到权限就启动监听。
- 模式保存在 `UserDefaults` 的 `followHands`（默认 `true`，即跟随模式）。这是 app 唯一持久化的设置。
- 开机启动用 `SMAppService.mainApp` 注册。

动画逻辑在 `Sources/BongoCatCore/KeystrokeAnimator.swift`：

- 跟随模式按实际按住的 keycode 集合分别跟踪左右手，某侧集合为空才收回该侧爪子。丢失的 keyUp 由 `CGEventSource.keyState` 兜底：每个事件和按住期间每 1 秒核对一次。
- 普通模式每次按键左右帧交替，0.5 秒无输入回到 `idle`，最小刷新间隔 1/60 秒。
- 切换模式时清空状态并回到 `idle`。

图标：`Resources/Icons/` 里的 `idle`、`typing_a`（左爪）、`typing_b`（右爪）、`typing_both` 四帧 SVG，作为 template image 加载，菜单栏深浅色由系统着色。

## 左右手键位

按 QWERTY ANSI 键盘的物理位置（macOS 虚拟 keycode）划分，定义在 `Sources/BongoCatCore/KeyMap.swift`，与输入法和键盘布局无关。

- 左手：Esc、F1–F5、`` ` `` 和 1–5、Tab 和 Q–T、Caps Lock 和 A–G、左 Shift 和 Z–B、左 Control / Option / Command。
- 右手：F6–F12、6–0、`-`、`=`、Delete、Y–P、`[`、`]`、`\`、H–L、`;`、`'`、Return、N–M、`,`、`.`、`/`、右 Shift、空格、右 Command / Option / Control、方向键。
- 不触发动画：数字小键盘、fn、向前删除、Home / End / Page Up / Page Down、F13 以上。
- Caps Lock 虽然在左手表里，但 `flagsChanged` 对它总判为松开，目前不触发动画。

## 演示图

`Scripts/render-demo.swift`（`make demo`）用 `Resources/Icons/` 里的真实图标在模拟菜单栏上渲染，不截屏：

- `demo-*.gif`：跟随模式下打出 “bongo cat”。按键时间写在脚本的 `strokes` 里，小猫的帧按 app 同样的规则（某侧有键按住就拍下该侧爪子）从按键时间推出来，所以键盘高亮和爪子始终同步。菜单栏放大 3.5 倍。
- `demo-*.png`：四帧静态图，菜单栏放大 2.5 倍。
- 图里只出现按键字母，中英文 README 共用。

## 更新记录的写法

`CHANGELOG.md` 面向用户，只写用户能感知的变化；纯工程改动在对应版本里合并成一句“内部改进”。各版本的工程改动：

- 1.0.3：单元测试（Swift Testing），覆盖左右手键位、两种模式的帧切换、图标加载顺序；`make check / run / package` 统一入口；push / PR 上运行的 CI；README 演示图。
- 1.0.2：构建系统从 swiftc + Makefile 迁移到 SwiftPM，仍输出 universal 版本。
- 1.0.1：统一构建脚本 `Scripts/build-app.sh`，整理发布流程。
- 1.0.0：改用统一的自签名证书 `DEV X`，版本号从 1.0.0 重新开始。
