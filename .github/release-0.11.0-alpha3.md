# Vertree 0.11.0-alpha3

Vertree `0.11.0-alpha3` 是一次预发布版本，重点放在发布链路补强，尤其是 Windows 11 新右键菜单、Windows / Linux / macOS 开发者产物补齐，以及 MSI / DEB / 符号包支持。

## 本次重点

- Windows 发布链路补齐 `msi` 安装包，`zip` 现在是真正的便携版，并新增 unsigned `msix`、`symbols.zip` 与 `win11-dev.zip`
- Windows 发布文件名统一为 `vertree-windows-x64-<version>` 风格，与 Linux / macOS 保持一致
- Linux 发布链路新增 `.deb` 安装包，便于 Debian / Ubuntu 系发行版直接安装
- macOS 发布产物增加架构标识，并新增 `symbols.zip`
- GitHub Release 现在会附带统一的 `SHA256SUMS.txt` 校验文件
- 自动更新现在会识别预发布版本，并按当前平台优先选择合适的下载资产，同时忽略 `symbols` 等开发者工件
- 修复 Windows 旧菜单中额外出现的错误 `Vertree` 子菜单问题
- 修复 Windows 上右键菜单中文 / 日文标题乱码问题，菜单扩展 DLL 统一按 UTF-8 编译
- 修复 Windows 11 新菜单开关未真正注册 sparse package 的问题，安装版现在会携带 `win11_packaging` 资源
- Win11 菜单开启时会清理旧的注册表式伪菜单，关闭时会正确卸载 sparse package 并同步清理旧注册
- 设置页中 Win11 菜单开关的启用 / 关闭逻辑已修正，避免“看起来关闭了但实际上仍保留注册”的状态错乱
- GitHub Actions workflow 已切换到 Node 24 兼容模式，去除相关 deprecation 警告
- 同步 `pubspec.yaml`、应用内版本号与本次 release 到 `0.11.0-alpha3`

## 说明

- 这是 `alpha` 预发布，不是正式稳定版
- GitHub Release 会以 `prerelease` 形式发布
- 若通过 tag 触发发布，请使用 `V0.11.0-alpha3` 或 `v0.11.0-alpha3`
