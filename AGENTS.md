# AGENTS.md — BongoCat Menubar

## What this is

macOS menu bar app (no dock icon) that animates a cat typing along with your keystrokes. Pure Swift, no Xcode project, no package manager — compiled directly with `swiftc`, driven by a `Makefile`.

## Build and run

```bash
make build   # debug build -> .build/debug/BongoCat Menubar.app (ad-hoc signed)
make run     # build and launch
make icon    # regenerate Resources/AppIcon.icns from the cat SVG
make dmg     # universal (arm64+x86_64) release build + DMG in .build/release/
make clean   # remove .build/
make help    # list all targets
```

- Requires macOS 13+ frameworks (AppKit, ApplicationServices, CoreGraphics, ServiceManagement).
- Build output lives in `.build/<config>/` (gitignored). Generated `AppIcon.icns` is also gitignored.
- Version is stamped from the latest git tag (`v1.2.3` → `1.2.3`), falling back to `Info.plist`; build number is the commit count. The source `Info.plist` is never mutated — stamping happens on the bundled copy via PlistBuddy.

## Repository layout

```
Sources/                  5 Swift files (see below)
Resources/
  Icons/                  idle / typing_a / typing_b / typing_both SVGs
  *.lproj/                en + zh-Hans Localizable.strings
  AppIcon.icns            generated (gitignored, rebuilt by `make build` when missing)
Info.plist                LSUIElement app, bundle id com.zhiyozhao.bongocat-menubar
Makefile                  all build/package entry points
scripts/generate-icon.swift  renders AppIcon.icns (gradient squircle + cat, iconutil)
.github/workflows/release.yml
```

There are no tests, linter, formatter, or typecheck steps.

## Architecture

5 source files in `Sources/`:

| File | Role |
|---|---|
| `main.swift` | Entry point. Creates NSApplication with `.accessory` activation policy (menu-bar-only, no dock icon). |
| `AppDelegate.swift` | Wires everything together: status item, menu, permission handling, mode switching. |
| `KeyboardMonitor.swift` | CGEvent tap for global key-down/key-up/flags-changed. Requires Accessibility permission. Auto-re-enables on tap timeout. |
| `KeystrokeAnimator.swift` | Maps keycodes to animation frames. Two modes: **Normal** (alternating toggle) and **Follow Hands** (left/right hand tracking). |
| `IconManager.swift` | Loads SVG/PNG icons from app bundle. Falls back to SF Symbols (`cat`/`cat.fill`). |

Entry point flow: `main.swift` → `AppDelegate.applicationDidFinishLaunching` → sets up icon manager, animator, keyboard monitor, menu, and permission polling.

## Key domain details

- **Animation frames**: `idle`, `typing_a`, `typing_b`, `typing_both` — corresponding SVGs in `Resources/Icons/`.
- **Left/right hand split**: `KeystrokeAnimator.swift` defines which macOS keycodes belong to each hand. Modifiers (Shift, Ctrl, Opt, Cmd) are split left/right.
- **Follow Hands mode**: tracks independent left/right state → `typing_both` frame when both hands are down. Normal mode just alternates `typing_a`/`typing_b`.
- **Icon loading order**: `<name>.svg` → `<name>_color.png` → `<name>.png` → SF Symbol fallback. Files with `_color` in the name are not set as template images.

## Signing

Two modes, auto-selected by the Makefile:

- **Self-signed cert `BongoCat Menubar Development`** (preferred): created once per machine via `scripts/create-signing-identity.sh`. The designated requirement anchors on the certificate, so macOS TCC keeps the Accessibility grant across rebuilds and upgrades.
- **Ad-hoc (`-`)**: fallback when the cert is absent. The code hash changes every build, so Accessibility permission is re-requested after each update.

In CI, the release workflow imports the cert from secrets `SIGNING_CERT_P12` / `SIGNING_CERT_PASSWORD` when present, so release builds share the same stable identity. To set up: export the identity from Keychain Access (or `security export -t identities -f pkcs12`) as a .p12, then `gh secret set SIGNING_CERT_P12 < <(base64 -i cert.p12)` and `gh secret set SIGNING_CERT_PASSWORD`.

This is NOT Developer ID signing: Gatekeeper still warns for direct DMG downloads (the Homebrew cask strips quarantine via `xattr -cr` in postflight). To remove the warning entirely, use a paid Developer ID certificate + notarization.

## Permissions

The app needs **Accessibility** permission (System Settings → Privacy & Security → Accessibility) to use CGEvent taps. `AppDelegate` polls `AXIsProcessTrusted()` every 2 seconds and auto-starts monitoring once granted. Without permission, only the menu bar icon is shown. With a stable signing identity (see above), the grant persists across rebuilds and upgrades; with ad-hoc signing, run `tccutil reset Accessibility com.zhiyozhao.bongocat-menubar` to re-prompt.

## CI / Release

`.github/workflows/release.yml` triggers on `v*` tags:

1. `make dmg` (universal binary, ad-hoc signed, UDZO DMG via `hdiutil`)
2. Publish GitHub release with auto-generated notes (asset: `BongoCat-Menubar-v<version>.dmg`)

To release: push a tag like `git tag v1.0.0 && git push --tags`.

Homebrew distribution is **pull-based** and lives entirely in the `zhiyozhao/homebrew-tap` repo: its `sync-casks.yml` workflow polls this repo's latest published release on an hourly schedule, recomputes the DMG sha256, and bumps `Casks/bongocat-menubar.rb`. No token sharing between repos. The DMG asset name must stay `BongoCat-Menubar-v<version>.dmg` — the cask URL interpolates `#{version}` into that exact pattern.

## Gotchas

- The app bundle name has a **space**: `BongoCat Menubar.app`. Quoting matters in shell commands, and because GNU Make splits target names on whitespace, incremental builds are tracked via `.build/<config>/.build-stamp` instead of the binary path.
- `swiftc` only honors a single `-target` flag — universal binaries are built by compiling per-arch and combining with `lipo` (the Makefile handles this; set `ARCHS="arm64 x86_64"`).
- `make build` compiles all `Sources/*.swift` — adding a new file requires no manifest changes.
- CGEvent taps can be silently disabled by the system (timeout or permission revocation). `KeyboardMonitor` handles `.tapDisabledByTimeout` and `.tapDisabledByUserInput` by re-enabling.
- macOS renders SVGs in `NSImage` natively (used both at runtime for menu icons and by the icon generator script).
