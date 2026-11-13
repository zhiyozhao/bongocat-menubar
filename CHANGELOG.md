# 更新记录 / Changelog

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 修复
- 同时按住左右两侧的同一个修饰键（例如左右 Shift）时，松开其中一个后对应的爪子不再一直抬着。
- 跟随模式下按着键切换到普通模式再切回来，小猫不再错误地显示双爪；切换模式时小猫回到待机。

### 其他
- 新增单元测试（Swift Testing），覆盖左右手键位、两种模式的帧切换、图标加载顺序。
- 新增 `make check / run / package` 统一入口和在 push / PR 上运行的 CI。
- 新增中英文 README、演示图和 GIF、SETUP.md。

## [1.0.2] - 2026-09-10

### 其他
- 构建系统从 swiftc + Makefile 迁移到 SwiftPM，仍输出 Apple Silicon + Intel 通用版本，对用户无功能变化。

## [1.0.1] - 2026-09-10

### 其他
- 构建与发布流程整理（统一构建脚本 `Scripts/build-app.sh`），对用户无功能变化。

## [1.0.0] - 2026-09-10

首个 1.0 版本，版本号从这里重新开始计。

### 变更
- 改用统一的自签名证书 `DEV X` 签名。从这个版本起，升级后辅助功能授权会保留；从更早版本升级需要再授权一次。

### 此前版本已具备的功能
- 菜单栏小猫随键盘敲击做动画，四帧图标：待机、左爪、右爪、双爪。
- 跟随模式（默认）按左右手区分爪子；普通模式每次按键左右交替，0.5 秒无输入回到待机。
- 修饰键（Shift、Control、Option、Command）也会触发动画。
- 记住上次选择的模式；可设置开机启动。
- 简体中文和英文界面。
- 缺少辅助功能权限时弹出引导，授权后自动开始工作。
- 纯黑白风格的 app 图标。
- 通过 Homebrew tap `zhiyozhao/tap` 和 GitHub Releases 的 DMG 分发。

[Unreleased]: https://github.com/zhiyozhao/bongocat-menubar/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/zhiyozhao/bongocat-menubar/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/zhiyozhao/bongocat-menubar/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/zhiyozhao/bongocat-menubar/releases/tag/v1.0.0
