
# Vertree - 单文件版本管理系统

针对单文件的版本管理系统，让每一次迭代都有备无患！

vertree不仅仅是一个工具，它是一种对创作过程的尊重。我们相信，每一个创作者都应该专注于自己的作品，而不是被版本管理的复杂性所困扰。vertree的出现，是为了让创作变得更加自由和高效。

通过vertree，我们希望改变的不仅仅是文件管理的方式，更是创作者的工作习惯。每一次的修改，都会成为创作历程中清晰的印记。每一次的回溯，都可以找到灵感的来源。

vertree的使命，是让每一个创作者都能轻松管理自己的文件版本，让创作的每一步都变得清晰、有序。

vertree：让每一次修改都有迹可循，让每一次迭代都有备无患！

## 功能亮点

- **文件版本管理**：对单个文件进行版本控制，轻松追溯文件变更历史。
- **文件监控**：实时监控文件变化，自动备份。
- **右键菜单集成**：将常用操作集成到系统右键菜单，方便快捷。
- **托盘管理**：通过系统托盘进行应用控制和操作。
- **跨平台支持**：兼容Windows、未来将支持macOS和Linux系统。

## 快速开始

首先你会需要flutter，请参考[Flutter Get started](https://docs.flutter.dev/get-started/install)


### 克隆仓库

```bash
git clone https://github.com/your-username/vertree.git
```

### 安装依赖


```bash
cd vertree
flutter pub get
```

### 运行项目

```bash
 flutter run -d windows
```

## 项目结构

```plaintext
vertree/
├── lib/
│   ├── component/      # 组件模块
│   ├── core/           # 核心逻辑模块
│   ├── view/           # 视图模块
│   └── main.dart       # 应用入口
├── assets/             # 资源文件
├── pubspec.yaml        # 项目配置
└── README.md           # 项目说明
```

## 依赖说明

该项目基于以下开源库：

| 依赖项                | 描述                             |
|-----------------------|----------------------------------|
| flutter               | Flutter SDK                     |
| bitsdojo_window       | 窗口管理                         |
| flutter_background_service | 后台服务                       |
| intl                  | 国际化支持                       |
| tray_manager          | 系统托盘管理                     |
| win32_registry        | Windows注册表操作                |
| window_manager        | 窗口管理                         |
| superuser             | 管理员权限                       |
| ffi                   | 外部函数接口                     |
| win32                 | Windows API封装                 |
| windows_single_instance | 单实例控制                 |
| path_provider         | 路径管理                         |
| loading_indicator     | 加载指示器                       |
| local_notifier        | 本地通知                         |
| file_picker           | 文件选择器                       |

## 已知缺陷

1. 管理员的权限管理不够精细，某些不需要管理员权限的情况会要求管理器权限打开。
2. 文本版本树的线的绘制有问题，需要移动一下才能正常显示。

## 未来规划

1. 增加Linux/Macos的系统支持。
2. 增加国际化语言支持。
3. 优化细节：1.优化管理员权限控制。

## 贡献指南

欢迎参与项目贡献！请按照以下步骤进行：

1. Fork本仓库。
2. 新增功能或修复问题。
3. 提交Pull Request。

## 许可协议

本项目采用MIT许可证，详情见[LICENSE](LICENSE)文件。

## 联系

如有问题或建议，请发布issue。