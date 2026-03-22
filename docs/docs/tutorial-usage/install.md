---
sidebar_position: 1
---

# 安装

## Windows

Windows 仍然是当前最完整的桌面发布形态。

1. 打开 [GitHub Releases](https://github.com/w0fv1/vertree/releases)
2. 下载最新版本的 `vertree-windows-x64-<version>.zip`、`vertree-windows-x64-<version>-setup.exe`、`vertree-windows-x64-<version>.msi`、用于后续签名的 unsigned `vertree-windows-x64-<version>.msix`，或用于 Win11 菜单调试的 `vertree-windows-x64-<version>-win11-dev.zip`
3. 如果下载的是 `setup.exe` 或 `msi`，直接运行安装；如果下载的是 `zip`，解压后直接运行其中的 `vertree.exe`
4. 首次启动后完成初始化

初始化通常会完成这些动作：

- 注册右键菜单
- 写入开机自启
- 准备托盘运行环境

后续都可以在设置页里再开关。

![initial-setup-dialog](/img/tutorial/initial-setup-dialog.png)

## macOS

仓库已经包含 macOS 工程和自动构建脚本，GitHub Release 会产出：

- `vertree-macos-<version>.zip`
- `vertree-macos-<arch>-<version>.dmg`
- `vertree-macos-<arch>-<version>.zip`

### 前置条件

- Flutter 已启用 macOS 桌面支持
- 已安装 CocoaPods

```bash
flutter config --enable-macos-desktop
brew install cocoapods
```

### 本地运行

```bash
flutter pub get
flutter run -d macos
```

### 注意

- 如果项目在 iCloud 同步的 `Desktop` / `Documents` 目录下，可能出现签名失败，建议移到非 iCloud 目录。
- Finder Services、菜单栏和应用菜单需要在应用首次正常启动后才能完整接入。
- 当前发布工件还没有 Apple notarization。

## Linux

仓库已经包含 Linux 工程和自动构建脚本，GitHub Release 会产出：

- `vertree-linux-x64-<version>.tar.gz`
- `vertree-linux-x64-<version>.deb`
- `vertree-<version>-*.x86_64.rpm`

### 前置条件

- Flutter 已启用 Linux 桌面支持
- 系统具备 GTK / 通知 / 托盘相关依赖

```bash
flutter config --enable-linux-desktop
flutter pub get
flutter run -d linux
```

### 注意

- GNOME Files 右键菜单依赖 `nautilus-python`
- GNOME 托盘能力常常依赖 AppIndicator 扩展；若系统未启用，Vertree 会回退为正常窗口启动而不是托盘常驻

## 版本号与发布

- `pubspec.yaml` 中的 `version` 决定发布版本
- `.github/release-<version>.md` 决定 GitHub Release 说明
- GitHub Release workflow 要求 tag 与 `pubspec.yaml` 版本完全一致
- 例如发布 `0.11.0-alpha3` 时，应使用 tag `V0.11.0-alpha3`
