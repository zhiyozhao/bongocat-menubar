# SETUP — BongoCat Menubar

## 需要的环境

| 项目 | 要求 | 本机验证版本（2026-11-13） |
|---|---|---|
| macOS | 13+ 可运行；开发建议 14+ | macOS 15.6.1 |
| Xcode | 16+（`swift test` 用 Swift Testing） | Xcode 26.3，Swift 6.2.4 |
| 签名证书 | 可选：钥匙串里名为 `DEV X` 的代码签名证书 | 已安装 |

没有任何第三方依赖（没有 `Package.resolved`），不需要 brew、npm 或 Python。

签名证书由 `~/Codes/dev-x-signing` 统一管理，本项目不保存证书或密码。没有证书时构建自动回退 ad-hoc 签名，功能一样，只是每次重建后要重新授予辅助功能权限。

## 构建和检查

```bash
make check     # 语法检查 + 构建 + 单元测试，退出码 0 才算过
make run       # 打包 release .app 并前台运行（Ctrl-C 退出）
make package   # .app + DMG，产物在 .build/release/
codesign -dvv ".build/release/BongoCat Menubar.app"   # 看签名：Authority=DEV X 或 Signature=adhoc
```

- 产物全部在 `.build/`（gitignored）。`Resources/AppIcon.icns` 也是生成物，缺失时 build-app.sh 会现场生成。
- 没有后台进程、端口或模拟器。`make run` 起的 app 会在菜单栏多出一只猫，Ctrl-C 即退出；如果已经装了正式版，两只猫会同时出现，不影响。
- 运行时需要辅助功能权限才会响应按键；`make check` 不需要任何权限。

## CI

- `.github/workflows/check.yml`：分支 push 和 PR 时在 `macos-15` 上跑 `make check`。
- `.github/workflows/release.yml`：`v*` tag 触发发布（详见 AGENTS.md）。需要仓库 secrets `SIGNING_P12_BASE64` 和 `SIGNING_P12_PASSWORD`。

## 坏了怎么重建

```bash
make clean                 # swift package clean + 删 .app 和 DMG
rm -rf .build              # 还不行就整个删掉 SwiftPM 缓存
make icon                  # 重新生成 AppIcon.icns
make check && make package
```

- `swift build` 报找不到 `Testing` 模块：`xcode-select -p` 应指向 `/Applications/Xcode.app/Contents/Developer`，只装 Command Line Tools 时可能缺 Swift Testing。
- 签名变成 ad-hoc：`security find-certificate -c "DEV X"` 查不到证书。证书从 `~/Codes/dev-x-signing` 导入（由用户操作）。
- 授权后小猫不动：`tccutil reset Accessibility com.zhiyozhao.bongocat-menubar`，重新打开 app 授权。

## 本项目装过的东西

无。
