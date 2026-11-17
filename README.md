# BongoCat Menubar

中文 | [English](README.en.md) · [官网](https://zhiyozhao.github.io/bongocat-menubar/) · **[安装](#安装)**

Mac 菜单栏里的一只猫。你打字，它拍爪子：左手拍左爪，右手拍右爪。

[![最新版本](https://img.shields.io/github/v/release/zhiyozhao/bongocat-menubar?label=%E6%9C%80%E6%96%B0%E7%89%88%E6%9C%AC)](https://github.com/zhiyozhao/bongocat-menubar/releases/latest)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/demo-dark.gif">
  <img alt="打字 bongo cat 时，菜单栏里的小猫跟着拍爪子：左手的键拍左爪，右手的键拍右爪，两边同时按下双爪一起拍" src="docs/assets/demo-light.gif" width="720">
</picture>

## 安装

需要 macOS 13 或更新，Apple 芯片和 Intel 芯片都支持。

```bash
brew install --cask zhiyozhao/tap/bongocat-menubar
```

也可以到 [Releases](https://github.com/zhiyozhao/bongocat-menubar/releases/latest) 下载 DMG，把 app 拖进“应用程序”。DMG 装的 app 第一次打开会提示“无法验证开发者”，因为它没有经过 Apple 公证：到“系统设置 → 隐私与安全性”，在页面底部点“仍要打开”。用 Homebrew 装不会有这个提示。

**授权“辅助功能”**：第一次打开会弹窗，点“打开设置”；系统接着再弹一个窗口，点“打开系统设置”；然后在“辅助功能”列表里打开 BongoCat Menubar 的开关。两秒内小猫就开始动，不用重启 app。点了“稍后”的话，之后点菜单栏里的小猫，选“辅助功能”。

macOS 只让拿到这项权限的 app 知道你按了哪个键。BongoCat Menubar 只用它看按键，不读你打出的文字，也不会拦截或替你按键。

## 和别的 Bongo Cat 有什么不同

- 只待在菜单栏，不开窗口，不进 Dock，不挡屏幕。
- 分左右手：左手的键拍左爪，右手的键拍右爪，两边一起按就双爪齐拍。不想分左右，点菜单栏里的小猫，在菜单里选“普通模式”，每按一下左右爪轮流拍。
- 不联网，不记录按键。
- 免费开源。

刻意不做：桌面宠物、积分、帽子、皮肤。

## 常见问题

**小猫不动？**
在密码框里打字时不动是正常的，macOS 不会把这些按键告诉任何 app。数字小键盘、Caps Lock、fn、Home、End、Page Up、Page Down、向前删除和 F13 以上的键不会触发拍爪。点开小猫的菜单，如果有“辅助功能”这一项，说明还没授权，点它去打开开关；已经授权还不动，就到“系统设置 → 隐私与安全性 → 辅助功能”里把开关关掉再打开。

**菜单栏里找不到小猫？**
带刘海的 MacBook 上，菜单栏图标太多时，放不下的会被藏到刘海后面。退出几个菜单栏 app 就能看到它。

**怎么升级？**
`brew upgrade --cask bongocat-menubar`。升级时小猫会被退出，装好后从“应用程序”里再打开它。用 DMG 的话，先在小猫的菜单里选“退出”，再用新版覆盖。升级后不用重新授权。

**怎么卸载？**
开过“开机启动”的话，先在小猫的菜单里关掉。然后 `brew uninstall --cask bongocat-menubar`，或者把 app 拖到废纸篓。

## 许可证

[MIT](LICENSE) · [更新记录](CHANGELOG.md) · [开发文档](docs/DEVELOPMENT.md)
