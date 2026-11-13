# BongoCat Menubar

[中文](README.md) | English

Bongo Cat for the macOS menu bar: it taps its paws while you type. No window, no Dock icon.

[![Release](https://img.shields.io/github/v/release/zhiyozhao/bongocat-menubar)](https://github.com/zhiyozhao/bongocat-menubar/releases/latest)
[![check](https://img.shields.io/github/actions/workflow/status/zhiyozhao/bongocat-menubar/check.yml?branch=master&label=check)](https://github.com/zhiyozhao/bongocat-menubar/actions/workflows/check.yml)
![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black)
![Universal](https://img.shields.io/badge/Apple%20Silicon%20%2B%20Intel-universal-black)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/assets/demo-dark.gif">
  <img alt="The menu bar cat taps along with key presses: F raises the left paw, J the right, both together tap both paws" src="docs/assets/demo-light.gif" width="640">
</picture>

(Rendered from the real icons in `Resources/Icons/`; the menu bar is magnified 2.5×.)

## Features

- The menu bar cat animates as you type and adapts to light and dark menu bars.
- Two modes: **Follow Mode** tracks your hands (left-side keys tap the left paw, right-side keys the right paw, both at once tap both); **Normal Mode** alternates paws on every key press.
- Modifier keys (Shift, Control, Option, Command) animate too, split by left and right side.
- Optional Launch at Login.
- English and Simplified Chinese UI, following the system language.
- Key events are read locally only to drive the animation. Nothing is recorded or uploaded (see [Privacy](#permissions-and-privacy)).

## Install

Requires macOS 13 or later. Universal binary for Apple Silicon and Intel.

### Homebrew (recommended)

```bash
brew install --cask zhiyozhao/tap/bongocat-menubar
```

Upgrade with `brew upgrade --cask bongocat-menubar`. The cask removes the download quarantine flag after install, so Gatekeeper does not block the first launch.

### DMG download

1. Download `BongoCat-Menubar-v<version>.dmg` from [Releases](https://github.com/zhiyozhao/bongocat-menubar/releases/latest).
2. Open the DMG and drag `BongoCat Menubar.app` into Applications.
3. On first launch macOS says it cannot verify the developer. The app is **self-signed** (certificate `DEV X`), not signed with an Apple Developer ID and not notarized. Either:
   - open it once, and after it is blocked go to System Settings → Privacy & Security and click "Open Anyway" near the bottom; or
   - run in Terminal:

     ```bash
     xattr -dr com.apple.quarantine "/Applications/BongoCat Menubar.app"
     ```

## Quick start

1. Open the app. The cat appears in the menu bar.
2. On first run it asks for **Accessibility** permission. Click "Open Settings" and enable BongoCat Menubar under System Settings → Privacy & Security → Accessibility.
3. No restart needed: the app checks every 2 seconds and starts reacting to keys as soon as permission is granted.
4. Click the cat in the menu bar to switch modes, toggle Launch at Login, or quit.

## Modes

| Mode | Behavior |
|---|---|
| Follow Mode (default) | Holding a left-side key raises the left paw, a right-side key the right paw, both sides together tap both paws. Releasing everything returns to idle. |
| Normal Mode | Every key press alternates the paws. After 0.5 s without typing the cat returns to idle. |

Hands are split by physical key position on a QWERTY keyboard:

- Left: Esc, F1–F5, `` ` `` and 1–5, Tab and Q–T, A–G, Left Shift and Z–B, Left Control / Option / Command.
- Right: F6–F12, 6–0, `-`, `=`, Delete, Y–P, `[`, `]`, `\`, H–L, `;`, `'`, Return, N–M, `,`, `.`, `/`, Right Shift, Space, Right Command / Option / Control, arrow keys.
- Not animated: Caps Lock, numeric keypad, fn, Forward Delete, Home / End / Page Up / Page Down, F13 and above.

The selected mode is remembered across launches.

## Permissions and privacy

**Why Accessibility permission**: the app needs to know when a key goes down or up, and which one, to move the matching paw. macOS only lets an app listen to global keyboard events through a CGEvent tap after it is granted Accessibility access.

**What the app actually does** (matches the source, see `Sources/BongoCatMenubar/KeyboardMonitor.swift`):

- It receives key-down, key-up and modifier-change events in listen-only (`listenOnly`) mode. It never blocks, changes or injects keystrokes.
- From each event it reads only the key code, plus the modifier state for modifier events, to decide which hand and whether the key went down or up. It does not read the characters you type.
- Key information stays in memory just long enough to pick an icon frame. Nothing is logged or written to disk.
- The app contains no networking code and uploads nothing.
- The only setting stored on disk is the current mode (`followHands` in `UserDefaults`). Launch at Login is registered through the system `SMAppService`.

Without permission the app shows only the menu bar icon, and the menu shows an "Accessibility" item as a reminder.

## Build from source

Requires Xcode 16 or later (verified locally with Xcode 26.3). No other dependencies.

```bash
git clone https://github.com/zhiyozhao/bongocat-menubar.git
cd bongocat-menubar
make check     # build + unit tests
make run       # build the release .app and run it in the foreground, Ctrl-C to quit
make package   # produces .build/release/BongoCat Menubar.app and BongoCat-Menubar-v<version>.dmg
```

Signing: if a certificate named `DEV X` is in your keychain it is used; otherwise the build falls back to ad-hoc signing. With ad-hoc signing, Accessibility permission has to be granted again after every rebuild.

## FAQ

**I granted permission but the cat does not move.**
In System Settings → Privacy & Security → Accessibility, turn BongoCat Menubar off and on again. If that fails, remove the entry with the `-` button and add it again. You can also reset the grant and reopen the app:

```bash
tccutil reset Accessibility com.zhiyozhao.bongocat-menubar
```

**The cat does not move while I type in a password field or some terminals.**
That is macOS Secure Input. In password fields, or terminals with "Secure Keyboard Entry" on, the system does not deliver key events to any third-party app. It recovers once you leave that field.

**Do I need to grant permission again after upgrading?**
Since v1.0.0 every release is signed with the same `DEV X` certificate, so the grant survives upgrades. Upgrading from an earlier version needs one more grant.

**I use a non-QWERTY layout (Dvorak, AZERTY, ...).**
Hands are split by physical key position, independent of the input source or layout, so the left half of the keyboard still drives the left paw.

**Why does the numeric keypad not animate?**
The keypad and keys like Home / End are not part of the left/right split, so by design they do not trigger the animation.

**How do I uninstall?**

```bash
brew uninstall --cask bongocat-menubar          # or just delete the app from Applications
tccutil reset Accessibility com.zhiyozhao.bongocat-menubar
defaults delete com.zhiyozhao.bongocat-menubar  # remove the saved mode setting
```

If you enabled Launch at Login, turn it off in the menu first.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
