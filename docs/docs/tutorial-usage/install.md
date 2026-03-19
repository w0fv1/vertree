---
sidebar_position: 1
---

# 安装

## Windows

0.8.1 的官方发布产物目前以 Windows 为主。

1. 打开 [GitHub Releases](https://github.com/w0fv1/vertree/releases)
2. 下载最新版本的 `Vertree_Setup.zip`
3. 解压得到 `Vertree_Setup.exe`
4. 运行安装程序并完成安装
5. 首次启动后完成初始化

初始化通常会完成这些动作：

- 注册右键菜单
- 写入开机自启
- 准备托盘运行环境

后续都可以在设置页里再开关。

## macOS

仓库已经包含 macOS 工程和平台接入，但当前 GitHub Action 还没有自动发布 macOS 安装包。使用方式以本地构建为主。

### 前置条件

- Flutter 已启用 macOS 桌面支持
- 已安装 CocoaPods

```bash
flutter config --enable-macos-desktop
brew install cocoapods
```

### 运行

```bash
flutter pub get
flutter run -d macos
```

### 注意

- 如果项目在 iCloud 同步的 `Desktop` / `Documents` 目录下，可能出现签名失败，建议移到非 iCloud 目录。
- Finder Services、菜单栏和应用菜单需要在应用首次正常启动后才能完整接入。

## 版本号与发布

- `pubspec.yaml` 中的 `version` 决定发布版本
- GitHub Windows Release workflow 要求 tag 与 `pubspec.yaml` 版本完全一致
- 例如发布 `0.8.1` 时，应使用 tag `V0.8.1`
