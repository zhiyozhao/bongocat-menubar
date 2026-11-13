# 更新记录 / Changelog

格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [1.0.3] - 2026-11-13

### 修复
- 同时按住左右两个 Shift（或其他成对的修饰键）再松开其中一个，对应的爪子不再一直抬着。
- 跟随模式下一只手按住几个键时，松开其中一个不再让爪子提前收回，这只手的键全部松开才收回。
- 在密码框等地方松开按键后，爪子不再一直按着，最多一秒就会抬起。
- 跟随模式下按着键切到普通模式再切回来，小猫不再错误地双爪按下；切换模式时小猫会趴回去。

### 其他
- 以 MIT 许可证开源。
- 内部改进。

## [1.0.2] - 2026-09-10

### 其他
- 内部改进，功能无变化。

## [1.0.1] - 2026-09-10

### 其他
- 内部改进，功能无变化。

## [1.0.0] - 2026-09-10

首个 1.0 版本，版本号从这里重新开始计。

### 变更
- 从这个版本起，升级后不用重新授予辅助功能权限。从更早的版本升级上来，需要再授权一次。

### 此前版本已具备的功能
- 菜单栏小猫随键盘敲击做动画：趴着、拍左爪、拍右爪、双爪齐拍。
- 跟随模式（默认）按左右手区分爪子；普通模式每次按键左右交替，停手半秒后趴回去。
- Shift、Control、Option、Command 也会让小猫动。
- 记住上次选择的模式；可设置开机启动。
- 简体中文和英文界面。
- 缺少辅助功能权限时弹窗引导，授权后自动开始工作。
- 黑白风格的 app 图标。
- 可用 Homebrew 或 DMG 安装。

[Unreleased]: https://github.com/zhiyozhao/bongocat-menubar/compare/v1.0.3...HEAD
[1.0.3]: https://github.com/zhiyozhao/bongocat-menubar/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/zhiyozhao/bongocat-menubar/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/zhiyozhao/bongocat-menubar/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/zhiyozhao/bongocat-menubar/releases/tag/v1.0.0
