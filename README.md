# BongoCat Menubar

中文 | [English](README.en.md)

一只住在 Mac 菜单栏里的 Bongo Cat。你打字，它就跟着拍爪子。

[![最新版本](https://img.shields.io/github/v/release/zhiyozhao/bongocat-menubar?label=%E6%9C%80%E6%96%B0%E7%89%88%E6%9C%AC)](https://github.com/zhiyozhao/bongocat-menubar/releases/latest)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/demo-dark.gif">
  <img alt="打字 bongo cat 时，菜单栏里的小猫跟着拍爪子：左手的键拍左爪，右手的键拍右爪，两边同时按下双爪一起拍" src="docs/assets/demo-light.gif" width="720">
</picture>

```bash
brew install --cask zhiyozhao/tap/bongocat-menubar
```

不用 Homebrew 的话，到 [Releases](https://github.com/zhiyozhao/bongocat-menubar/releases/latest) 下载 DMG，把 app 拖进“应用程序”。

## 亮点

- 左手打字拍左爪，右手打字拍右爪，两手一起按就双爪齐拍。
- 只占菜单栏一个图标的位置，没有窗口，也不出现在 Dock 里。
- Shift、Control、Option、Command 也算数，并且分左右。
- 浅色、深色菜单栏都看得清。
- 可以设成开机自动出现。
- 中文、英文界面，跟随系统语言。
- 支持 macOS 13 及以上，Apple 芯片和 Intel 芯片的 Mac 都能用。

## 首次使用

1. 打开 BongoCat Menubar，菜单栏里会出现小猫。
2. 它会弹窗请求“辅助功能”权限。点“打开设置”，在“系统设置 → 隐私与安全性 → 辅助功能”里打开 BongoCat Menubar 的开关。
3. 不用重启 app，两秒内小猫就会开始跟着你打字。

**为什么要这个权限？** 小猫要知道你什么时候按下、松开了哪个键，才能拍对爪子。macOS 规定，任何 app 想在你使用别的 app 时感知按键，都必须先得到你在“辅助功能”里的授权。

**安全在哪？** 这个权限只用来“听”。BongoCat Menubar 不会拦下、修改或替你按任何键，也不会去操作别的 app。你随时可以在同一个设置页面里关掉这个开关，关掉后它就再也收不到按键了。

点一下菜单栏里的小猫，可以切换模式、开关开机启动、退出。

## 两种模式

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/demo-dark.png">
  <img alt="小猫的四个动作：不打字时趴着；按 F 拍左爪；按 J 拍右爪；F 和 J 一起按，双爪齐拍" src="docs/assets/demo-light.png" width="720">
</picture>

- **跟随模式**（默认）：键盘左半边的键拍左爪，右半边的键（含空格键和方向键）拍右爪。按住不放，爪子就一直按着，松开才抬起。
- **普通模式**：不分左右，每按一下键，左右爪轮流拍一次。停手半秒后小猫趴回去。

app 会记住你选的模式。

## 隐私

- 只看是哪个键被按下或松开，不读取你打出的文字。
- 按键信息只用来切换小猫的动作，用完就丢，不写进日志，也不存成文件。
- app 里没有任何联网功能，不上传任何数据。
- 唯一保存在你电脑上的，是你选的模式。

## 常见问题

**打开 DMG 里的 app 时，提示“无法验证开发者”？**
这个 app 没有经过 Apple 公证，所以第一次打开会被拦下。到“系统设置 → 隐私与安全性”，在页面下方点“仍要打开”即可，之后不会再问。用 Homebrew 安装不会遇到这个提示。

**已经授权了，小猫还是不动？**
在“系统设置 → 隐私与安全性 → 辅助功能”里，把 BongoCat Menubar 的开关关掉再打开。还不行，就用列表下方的“−”删掉它，重新打开 app 再授权一次。

**在密码框里打字时小猫不动？**
这是 macOS 的保护：输入密码时（以及打开了“安全键盘输入”的终端里），系统不会把按键告诉任何第三方 app。离开这个输入框就恢复。

**升级后要重新授权吗？**
从 1.0.0 起，升级后授权会保留。从更早的版本升上来，需要再授权一次。

**我用的不是 QWERTY 布局，左右手还准吗？**
准。左右手按键盘上的物理位置划分，和你用什么输入法、什么键盘布局无关。

**为什么有些键按了没反应？**
数字小键盘、Caps Lock、fn、Home、End、Page Up、Page Down、向前删除和 F13 以上的键不会让小猫动。

**怎么卸载？**
先在小猫的菜单里关掉“开机启动”（如果开过），然后执行 `brew uninstall --cask bongocat-menubar`，或者直接把 app 从“应用程序”拖到废纸篓。想把授权记录也清掉，就到“辅助功能”列表里用“−”删除它。

## 许可证

[MIT](LICENSE)

---

[更新记录](CHANGELOG.md) · [开发文档](docs/DEVELOPMENT.md)
