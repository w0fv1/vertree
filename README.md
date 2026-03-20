# Vertree

Vertree 是一个面向单文件的可视化版本管理工具，适合设计稿、文档、脚本、配置文件这类不适合直接放进 Git 工作流的内容。它用树状结构组织版本，用监控机制做自动备份，尽量不改变你原本的使用习惯。

## 0.9.0 现状

- 支持 Windows 桌面使用，提供安装包、托盘、右键菜单、监控页、版本树、设置页。
- 支持 macOS 桌面运行，提供菜单栏/托盘、Finder Services、设置页快捷操作、开机自启。
- GitHub Actions 当前只自动构建 Windows 发布产物；macOS 仍以本地构建为主。
- 新增本机 HTTP API，可用于本地自动化测试、监控任务检查、版本树与备份验证。

## 核心能力

- 树状版本管理：主线版本、分支版本、备注标签都能直接体现在文件名和界面里。
- 自动监控备份：监控文件变化，按配置频率自动写入 `*_bak` 目录。
- 快速入口：Windows 右键菜单、macOS Finder Services、托盘菜单、应用菜单都可以直接触发操作。
- 设置集中管理：语言、主题、监控频率、最大备份数、上下文菜单、自启动都可以在设置页调整。
- 本机自动化接口：提供 loopback-only HTTP API 与 OpenAPI 文档，便于 AI 和脚本验证功能。
- 单实例与启动优化：避免重复打开，改善启动显示和托盘恢复体验。

## 使用方式

### Windows

1. 到 [GitHub Releases](https://github.com/w0fv1/vertree/releases) 下载最新的 `Vertree_Setup.zip`
2. 解压并运行 `Vertree_Setup.exe`
3. 首次启动完成初始化
4. 通过文件右键菜单或托盘开始使用

### macOS

当前仓库已包含 macOS 工程，但 CI 还没有自动产出 macOS 安装包。可用方式是本地构建运行：

```bash
flutter config --enable-macos-desktop
flutter pub get
flutter run -d macos
```

已支持的 macOS 入口：

- Finder Services: 备份、快速备份、监控、查看版本树
- 应用菜单: 设置、备份、快速备份、监控、查看版本树
- 菜单栏图标: 打开设置、执行常用操作

## 开发运行

### Windows

```bash
flutter config --enable-windows-desktop
flutter pub get
flutter run -d windows
```

### macOS

```bash
flutter config --enable-macos-desktop
brew install cocoapods
flutter pub get
flutter run -d macos
```

如果项目位于 iCloud 同步的 `Desktop` 或 `Documents` 下，macOS 可能在签名阶段失败，建议移到非 iCloud 目录。

## 配置文件

配置保存在应用支持目录下的 `config.json` 中。常用字段包括：

- `locale`: 语言
- `themeMode`: `system` / `light` / `dark`
- `monitorRate`: 监控备份最小间隔（分钟）
- `monitorMaxSize`: 单任务最多保留的备份数量
- `monitFiles`: 监控任务列表
- `launch2Tray`: 启动后是否进入托盘
- `isSetupDone`: 是否完成首次初始化
- `win11MenuEnabled`: 是否启用 Windows 11 新菜单集成

建议通过设置页修改，而不是手动编辑。

## 文档

- 用户文档: [docs/](https://w0fv1.github.io/vertree/)
- 本地文档开发: [docs/README.md](docs/README.md)

## 已知限制

- Windows 11 新菜单依赖 Sparse Package / MSIX 身份，没有打包身份时只能使用旧版右键菜单。
- macOS 目前没有官方自动构建的发布包，主要通过本地构建使用。
- 版本树画线仍有继续优化空间，复杂树下的布局和交互还会继续调整。

## 后续方向

- Linux 支持
- 更稳定的版本树布局与画布体验
- 更细的权限控制与平台集成
- 文件差异展示与搜索能力

## 许可

MIT. See [LICENSE](LICENSE).
