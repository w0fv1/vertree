---
sidebar_position: 1
---

# Vertree 开发入门

Vertree 是一个基于 Flutter 的桌面应用，目标是给“单文件持续演进”的工作流提供版本树、自动备份、平台原生入口和本机自动化接口。

## 技术栈

- Flutter Desktop
- Dart
- Windows / macOS / Linux 原生平台桥接
- Docusaurus 文档站

## 环境准备

### Flutter

请先安装 Flutter stable，并确认桌面支持已启用：

```bash
flutter doctor
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

### 平台依赖

- Windows：如需构建安装包，额外安装 Inno Setup
- macOS：安装 CocoaPods
- Linux：安装 GTK / 通知 / 托盘 / RPM 打包相关依赖
- 文档站：Node.js 18+

## 克隆项目

```bash
git clone https://github.com/w0fv1/vertree.git
cd vertree
flutter pub get
```

## 运行应用

### Windows

```bash
flutter run -d windows
```

如果你要验证注册表菜单、Win11 新菜单或开机自启，可能需要提升权限；普通 UI 和版本树/监控逻辑不要求始终以管理员身份运行。

### macOS

```bash
brew install cocoapods
flutter run -d macos
```

### Linux

```bash
flutter run -d linux
```

## 本地开发控制脚本

仓库自带 `dev_server.py`，它会托管一个 `flutter run` 子进程，并暴露 loopback-only 控制接口，方便本地代理或自动化工具迭代 UI：

```bash
python dev_server.py --bootstrap --device windows
```

默认控制器地址为 `http://127.0.0.1:32500`，支持：

- `GET /status`
- `GET /logs`
- `POST /start`
- `POST /reload`
- `POST /hot-restart`
- `POST /restart-process`
- `POST /stop`
- `POST /ensure-ready`

## 项目结构

```text
vertree/
├── lib/
│   ├── api/            # 本机 HTTP API 契约、文档与 server
│   ├── component/      # 配置、日志、命令处理、窗口控制、托盘等通用组件
│   ├── core/           # 版本树、监控、Result、TreeBuilder 等核心逻辑
│   ├── platform/       # Windows / macOS / Linux 平台集成与 bootstrap
│   ├── service/        # 面向 API 的业务服务
│   ├── view/           # 页面、模块与可视化组件
│   ├── app_runtime.dart
│   └── main.dart
├── windows/            # Windows 打包与上下文菜单相关脚本
├── macos/              # macOS 构建脚本与原生桥接
├── linux/              # Linux 发布与 RPM 打包脚本
├── docs/               # Docusaurus 文档站
└── .github/workflows/  # Release / Pages 工作流
```

## 关键模块

- `lib/main.dart`：按平台选择 bootstrap
- `lib/app_runtime.dart`：应用启动总控、页面切换、单实例、托盘、HTTP API、命令行分发
- `lib/component/app_cli.dart`：CLI 参数解析
- `lib/component/app_command_handler.dart`：把 CLI 请求分发到备份 / 监控 / 版本树动作
- `lib/core/FileVersionTree.dart`：版本号、文件元信息、文件节点与备份/分支逻辑
- `lib/core/MonitManager.dart`、`lib/core/Monitor.dart`：监控任务管理与自动备份
- `lib/api/LocalHttpApiServer.dart`、`lib/service/LocalHttpApiService.dart`：本机自动化接口
- `lib/platform/platform_integration.dart`：跨平台上下文菜单、开机自启、GNOME 检测、Win11 包身份等封装

## 构建发布工件

### Windows

```powershell
pwsh -File windows/build.ps1 -BuildMode Release
```

会生成：

- `windows/Vertree_Setup.exe`
- `windows/Vertree_Setup.zip`

### macOS

```bash
macos/build_macos_release.sh
```

会生成：

- `build/dist/vertree-macos-<version>.zip`
- `build/dist/vertree-macos-<version>.dmg`

### Linux

```bash
linux/build_linux_release.sh
linux/build_linux_rpm.sh
```

会生成：

- `build/dist/vertree-linux-x64-<version>.tar.gz`
- `build/dist/*.rpm`

## 文档站

文档站位于 `docs/`：

```bash
cd docs
npm install
npm start
npm run build
```

## 版本发布流程

1. 修改 `pubspec.yaml` 中的版本号
2. 同步更新应用内展示版本号（当前在 `lib/app_runtime.dart`）
3. 新建 `.github/release-<version>.md`
4. 更新 README、文档站和必要的站点首页内容
5. 构建并验证：
   - `flutter analyze`
   - `npm run build`（在 `docs/` 下）
6. 提交代码并创建 tag：`V<version>`

GitHub Actions 会在推送 tag 后自动构建三平台工件并创建 prerelease / release。
