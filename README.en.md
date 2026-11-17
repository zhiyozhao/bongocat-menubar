<p align="right"><a href="README.md">中文</a> | English</p>

<p align="center"><img src="docs/assets/icon.png" width="128" height="128" alt=""></p>

<h1 align="center">BongoCat Menubar</h1>

<p align="center">
  <a href="https://github.com/zhiyozhao/bongocat-menubar/releases/latest"><img alt="Latest release" src="https://img.shields.io/github/v/release/zhiyozhao/bongocat-menubar?label=latest"></a>
  <img alt="macOS 13+" src="https://img.shields.io/badge/macOS-13%2B-black">
  <a href="https://zhiyozhao.github.io/bongocat-menubar/en/"><img alt="Website" src="https://img.shields.io/badge/website-zhiyozhao.github.io-black"></a>
</p>

<p align="center">A cat in your Mac menu bar. You type, it taps its paws: left hand, left paw; right hand, right paw.</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/demo-dark.gif">
    <img alt="While typing bongo cat, the menu bar cat taps along: left-hand keys tap the left paw, right-hand keys the right paw, both at once tap both paws" src="docs/assets/demo-light.gif" width="720">
  </picture>
</p>

## Install

### Step 1: Install the app (either way)

- **Homebrew**

  ```bash
  brew install --cask zhiyozhao/tap/bongocat-menubar
  ```

- **Manually**: download the DMG from [Releases](https://github.com/zhiyozhao/bongocat-menubar/releases/latest) and drag the app into Applications. If the first launch says the developer cannot be verified, go to System Settings → Privacy & Security and click "Open Anyway" at the bottom.

### Step 2: Grant Accessibility permission

Open the app, click "Open Settings" in the prompt, then "Open System Settings", and turn on BongoCat Menubar.

## FAQ

**The cat doesn't move.**\
Open the cat's menu. If it shows an "Accessibility" item, permission isn't granted yet: click it and turn the switch on. If permission is granted, turn the switch off and on again in Settings. The cat stays still while you type a password; that's normal.

**I can't find the cat in the menu bar.**\
When the menu bar is full, the notch hides the cat. Quit a few menu bar apps and it will show up.

**Does it record what I type?**\
No. It has no network access and saves no keystrokes.

**How do I upgrade?**\
`brew upgrade --cask bongocat-menubar`, then open the app again. No need to grant permission again.

**How do I uninstall?**\
`brew uninstall --cask bongocat-menubar`, or drag the app to the Trash.

---

[MIT license](LICENSE) · [Changelog](CHANGELOG.md) · [Development notes (Chinese)](docs/DEVELOPMENT.md)
