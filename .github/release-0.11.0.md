# Vertree 0.11.0

Vertree `0.11.0` 是 `0.11.x` 阶段的首个正式版，重点是把局域网分享、本机自动化接口和三平台发布链路一起稳定下来。

## 本次重点

- 新增局域网文件分享能力，可为单个版本文件生成临时下载链接、二维码和自动选路桥接页
- 分享入口已接入版本树节点、监控页、托盘菜单，以及 Windows 右键菜单 / Win11 新菜单、macOS Finder Services、Linux GNOME Files 和应用菜单
- 本机 HTTP API 与 OpenAPI 文档进一步补齐，覆盖监控任务、备份、版本树、窗口控制、截图导出和分享校验等自动化场景
- 仓库自带 `dev_server.py`，可托管 `flutter run` 并提供 `reload`、`hot-restart`、`restart-process` 等本地开发控制端点
- Windows 发布链路已统一到 `setup.exe`、真正的便携 `zip`、`msi`、`symbols.zip` 和 `win11-dev.zip`
- Linux 发布链路已统一产出 `tar.gz`、`.deb`、`.rpm`，macOS 发布链路会产出带架构标识的 `zip`、`dmg` 和符号包
- 自动更新下载选择会按平台优先挑选合适工件，并忽略 `symbols`、`win11-dev`、`msix` 这类开发者产物
- 修复并稳定了 Windows 11 新右键菜单注册、退出时后台服务清理、开机自启进入托盘行为，以及分享成功后的窗口前置提醒

## 发布说明

- 这是正式稳定版，不会以 `prerelease` 形式发布
- 若通过 tag 触发发布，请使用 `V0.11.0` 或 `v0.11.0`
