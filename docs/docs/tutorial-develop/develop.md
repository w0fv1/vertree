---
sidebar_position: 1
---

# 🚀 VerTree 开发入门

**VerTree** 是一款专注于 **单文件版本管理** 的工具，帮助用户轻松管理文件的历史版本。它采用 **Flutter** 开发，支持跨平台运行，并结合 **Windows API** 进行系统级集成。

---

## 🛠️ **环境准备**

### ✅ 1. 安装 Flutter

VerTree 使用**Flutter**进行开发，首先需要安装 Flutter SDK。请参考官方指南：
👉 [Flutter 安装指南](https://docs.flutter.dev/get-started/install)

**推荐版本**：请确保使用最新的稳定版 Flutter SDK 以获得最佳兼容性。

### ⚙️ 2. 配置 Flutter 开发环境

在终端运行以下命令，确保 Flutter 安装正确：

```bash
flutter doctor
```

如果遇到缺少依赖的提示，请按指引安装所需组件，如 **Android Studio、VS Code 插件** 或 **Windows 相关依赖** 。

---

## 📥 **克隆项目**

```bash
git clone https://github.com/your-username/vertree.git
cd vertree
```

---

## 📦 **安装依赖**

在项目根目录下运行：

```bash
flutter pub get
```

这将下载所有必须的依赖库。

---

## 🚀 **运行 VerTree**

### 🖥️ **Windows**

由于 VerTree 目前优先支持 Windows，目前某些功能依赖管理员权限，请以管理员身份运行：

```bash
flutter run -d windows
```

**如果遇到管理员权限问题**，可以以**管理员身份**运行终端或使用：

```bash
flutter run --release
```

### 🍎🐧 **macOS / Linux**

目前 **VerTree** 主要支持 **Windows**，未来版本将逐步扩展到 **macOS 和 Linux**，敬请期待！

---

## 📁 **项目结构**

```plaintext
vertree/
├── lib/
│   ├── component/      # 组件模块（如日志管理、配置管理等）
│   ├── core/           # 核心逻辑（版本管理、文件监控）
│   ├── view/           # 视图层，包含 UI 组件和页面
│   └── main.dart       # 应用入口
├── assets/             # 资源文件（图标、UI 组件）
├── pubspec.yaml        # 依赖管理文件
└── README.md           # 项目说明文档
```

---

## 📌 **关键模块介绍**

| 模块 | 说明 |
|------|------|
| **`lib/core/FileVersionTree.dart`** | 版本树核心逻辑，管理文件的版本分支 |
| **`lib/core/Monitor.dart`** | 文件监控模块，负责自动备份 |
| **`lib/component/Notifier.dart`** | 负责系统通知，如备份成功提示 |
| **`lib/component/WindowsRegistryHelper.dart`** | Windows 注册表管理，处理右键菜单等功能 |
| **`lib/view/VersionTreePage.dart`** | 版本管理 UI 展示页面 |
| **`lib/main.dart`** | 应用主入口 |

---

## 📦 **打包发布**

### 1️⃣ **编译 Windows 程序**

在项目根目录执行以下命令编译 Windows 应用程序：

```bash
flutter build windows
```

生成的可执行文件位于：

```plaintext
build/windows/runner/Release/
```

你可以直接运行 `vertree.exe` 文件，也可以进一步制作安装包。

### 2️⃣ **使用 Inno Setup 制作安装包**

项目提供了便捷的 Inno Setup 打包脚本，位于 `windows` 目录中：

- 确保已安装 [Inno Setup](https://jrsoftware.org/isdl.php)；
- 推荐使用默认安装路径：`C:\Program Files (x86)\Inno Setup 6\`

进入项目的 `windows` 目录：

```bash
cd windows
```

运行脚本进行打包：

```powershell
.\build.ps1
```

此操作会自动生成安装程序 (`Vertree_Setup.exe`) 并压缩成 `Vertree_Setup.zip`。

生成的文件位于 `windows` 目录中：

- `Vertree_Setup.exe`（安装程序）
- `Vertree_Setup.zip`（压缩后的安装包）

---

## 🌟 **未来规划**

1. **支持 macOS & Linux**：扩展跨平台兼容性。
2. **国际化支持 (i18n)**：实现多语言版本，让全球用户都能轻松使用。
3. **优化权限管理**：提升管理员权限控制的体验。

---

## 🙌 **贡献指南**

欢迎对 VerTree 进行贡献！

**如何参与？**

1. **Fork 仓库** 并克隆到本地；
2. **新增功能或修复问题**；
3. 提交 **Pull Request**。

---

## 📬 **联系**

如有任何问题或建议，请提交 [GitHub Issue](https://github.com/your-username/vertree)。我们会尽快回复！🚀

---

希望这份开发入门引导能帮助你快速上手！💡 欢迎提出优化建议！😃