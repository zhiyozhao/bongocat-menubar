# BongoCat Menubar

[中文](README.md) | English · [Website](https://zhiyozhao.github.io/bongocat-menubar/en/)

A cat in your Mac menu bar. You type, it taps its paws: left hand, left paw; right hand, right paw.

[![Latest release](https://img.shields.io/github/v/release/zhiyozhao/bongocat-menubar?label=latest)](https://github.com/zhiyozhao/bongocat-menubar/releases/latest)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/demo-dark.gif">
  <img alt="While typing bongo cat, the menu bar cat taps along: left-hand keys tap the left paw, right-hand keys the right paw, both at once tap both paws" src="docs/assets/demo-light.gif" width="720">
</picture>

## Install

Requires macOS 13 or later, on Apple silicon or Intel.

```bash
brew install --cask zhiyozhao/tap/bongocat-menubar
```

Or download the DMG from [Releases](https://github.com/zhiyozhao/bongocat-menubar/releases/latest) and drag the app into Applications. The first time you open an app from the DMG, macOS says it cannot verify the developer, because the app is not notarized by Apple. Go to System Settings → Privacy & Security and click "Open Anyway" at the bottom. Installing with Homebrew skips this prompt.

**Grant Accessibility permission**: on first launch a prompt appears. Click "Open Settings" and turn on BongoCat Menubar in the list. The cat starts moving right away, no restart needed.

macOS only tells apps with this permission which keys you press. BongoCat Menubar uses it only to see key presses. It never reads the text you type, and never blocks or types keys for you.

## How it differs from other Bongo Cats

- Lives only in the menu bar. No window, nothing in the Dock, nothing covering your screen.
- Knows your hands: left-hand keys tap the left paw, right-hand keys the right paw, both at once tap both. If you'd rather not split hands, click the cat and switch to Normal Mode, where every key press alternates the paws.
- No network access, no keystroke logging.
- Free and open source.

Deliberately left out: desktop pets, points, hats, skins. It is just a cat that keeps you company while you type.

## FAQ

**The cat doesn't move.**
It is normal for the cat to stay still while you type a password: macOS does not share those key presses with any app. The numeric keypad, Caps Lock and fn never move it. Otherwise, go to System Settings → Privacy & Security → Accessibility and turn BongoCat Menubar off and on again.

**I can't find the cat in the menu bar.**
On MacBooks with a notch, menu bar icons that don't fit are hidden behind the notch. Quit a few menu bar apps and it will show up.

**How do I upgrade?**
`brew upgrade --cask bongocat-menubar`, or download the new DMG and replace the app. You don't need to grant permission again.

**How do I uninstall?**
If you turned on Launch at Login, turn it off in the cat's menu first. Then run `brew uninstall --cask bongocat-menubar`, or drag the app to the Trash.

## License

[MIT](LICENSE) · [Changelog](CHANGELOG.md) · [Development notes (Chinese)](docs/DEVELOPMENT.md)
