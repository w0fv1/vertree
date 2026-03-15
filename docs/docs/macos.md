---
sidebar_position: 7
---

# macOS 说明

## 当前支持范围

Vertree 的 macOS 版本在 0.8.0 已经具备桌面可用性，当前覆盖的能力包括：

- 菜单栏 / 托盘图标
- 应用菜单中的常用操作
- Finder Services:
  - 备份文件
  - 快速备份
  - 监控文件
  - 查看版本树
- 开机自启
- 文件监控与自动备份
- 主题、语言、设置页

## 当前还没有的部分

- GitHub Actions 自动产出的 macOS 安装包
- 像 Windows 那样的系统级右键菜单注册页
- 更完整的 macOS 分发与签名说明

## 运行方式

```bash
flutter config --enable-macos-desktop
brew install cocoapods
flutter pub get
flutter run -d macos
```

## Finder Services 的行为

当你在 Finder 中对文件执行 Vertree 服务时，应用会被唤起并把动作转发到 Flutter 层。当前支持：

- `备份文件（Vertree）`
- `快速备份（Vertree）`
- `监控文件（Vertree）`
- `查看版本树（Vertree）`

如果应用已经在后台运行，这些动作会直接复用现有实例。

## 菜单栏与 Dock

- 应用支持隐藏到菜单栏后继续运行
- 从菜单栏恢复窗口时会主动刷新 Dock 图标和激活状态
- 设置页和常用动作可以从应用菜单直接进入

## 使用建议

- 首次运行后先确认 Services 是否已经出现在 Finder 中
- 如果项目目录在 iCloud Desktop/Documents 下，优先移走再构建
- 如果只想后台监控，可以开启启动进托盘 / 菜单栏的使用方式

## 发布状态

目前 macOS 更适合开发者或愿意自行构建的用户使用。Windows 仍然是当前发布流程里最完整的官方分发平台。
