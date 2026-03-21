---
sidebar_position: 8
---

# Linux 说明

## 当前状态

Vertree 已经可以在 Linux 上进入 Flutter 桌面构建流程，但当前仍处于适配阶段，还没有正式发布的 Linux 安装包。

在 Fedora 43 上，本仓库已经实测通过了以下几步：

- Flutter 工程可生成 Linux 平台目录
- `flutter pub get` 可成功完成
- CMake / Ninja / GTK3 / 托盘 / 通知相关系统依赖可以被正确识别

当前还存在一个代码层面的兼容问题：

- `tray_manager` 的 Linux 插件在当前环境下会因为上游废弃 API 告警被当成错误处理，导致构建中断
- GNOME Files 右键菜单依赖 `nautilus-python`

这意味着 Linux 端现在的主要工作已经从“缺环境”进入“修兼容”阶段。

## 开发环境要求

### Flutter / Dart

- Flutter 3.41.5 或更新版本
- Dart 3.10.0 或更新版本

项目当前的 SDK 约束见 [pubspec.yaml](../../pubspec.yaml)：

```yaml
environment:
  sdk: '>=3.10.0 <4.0.0'
```

### Fedora 依赖

在 Fedora 43 上，当前确认需要安装这些系统包：

- `clang`
- `cmake`
- `ninja-build`
- `gtk3-devel`
- `libnotify-devel`
- `libayatana-appindicator-gtk3-devel`
- `python3-nautilus`

可选但推荐：

- `mesa-demos`
  用于提供 `eglinfo`，方便 `flutter doctor` 检查图形驱动信息

建议直接执行：

```bash
sudo dnf install clang cmake ninja-build gtk3-devel libnotify-devel libayatana-appindicator-gtk3-devel mesa-demos
```

如果你要在 GNOME Files 里启用 Vertree 的文件右键菜单，还需要：

```bash
sudo dnf install python3-nautilus
```

## 为什么需要这些依赖

- `clang`：Linux 桌面原生代码编译器
- `cmake`：Flutter Linux runner 和插件的构建系统
- `ninja-build`：CMake 默认使用的底层构建执行器
- `gtk3-devel`：Flutter Linux shell 依赖的 GTK3 开发头文件
- `libnotify-devel`：`local_notifier` 插件的 Linux 依赖
- `libayatana-appindicator-gtk3-devel`：`tray_manager` 插件的 Linux 托盘依赖
- `python3-nautilus`：GNOME Files 顶层右键菜单扩展依赖
- `mesa-demos`：补充 `eglinfo` 等诊断工具，不是应用启动硬依赖

## 启动步骤

如果本机还没有 Flutter，可先把 Flutter SDK 放到用户目录并加入 `PATH`。之后在项目根目录执行：

```bash
flutter config --enable-linux-desktop
flutter create --platforms=linux .
flutter pub get
flutter run -d linux
```

如果系统里设置了全局代理，而代理对 Flutter / pub / git 不稳定，建议在无代理环境下运行：

```bash
env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY -u all_proxy -u ALL_PROXY \
  flutter run -d linux
```

## 当前已确认的阻塞点

在 Fedora 43 上，补齐系统依赖后，当前实际遇到的下一个问题是：

- `tray_manager` Linux 插件中的 `app_indicator_new` 废弃告警被 `-Werror` 提升为构建错误

这不是缺系统包，而是插件代码本身需要进一步兼容处理。

## 对 RPM 打包的意义

如果后续要做 RPM 打包，至少需要把下面这些运行 / 构建前提整理清楚：

- 构建机需要具备 Flutter Linux toolchain
- SPEC 或打包说明里需要列出 GTK / libnotify / appindicator 相关依赖
- 托盘与通知能力需要在目标发行版上单独验证
- 插件层的废弃 API 问题需要先修掉，否则 RPM 构建同样会失败
