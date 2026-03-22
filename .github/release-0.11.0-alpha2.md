# Vertree 0.11.0-alpha2

Vertree `0.11.0-alpha2` 是一次预发布版本，重点放在 Windows 发布链路、自动更新下载体验，以及 Windows 11 新右键菜单注册修复上。

## 本次重点

- Windows 发布产物命名统一为 `vertree-windows-x64-<version>` 风格，与 Linux / macOS 保持一致
- Windows 发布链路新增 `msi` 安装包，与现有 `setup.exe` / `zip` 一起产出
- 自动更新现在会识别预发布版本，并按当前平台优先选择合适的下载资产
- Windows 优先下载 `setup.exe`，macOS 优先 `dmg`，Linux 默认优先 `tar.gz`，RPM 系发行版优先 `rpm`
- 修复 Windows 11 新菜单在普通安装版下没有正确注册的问题，不再错误依赖 Sparse Package / MSIX 身份
- 安装初始化、设置页开关和卸载流程已同步覆盖 Win11 新菜单注册/清理
- 增加版本更新下载选择相关测试，并同步 `pubspec.yaml`、应用内版本号与本次 release 到 `0.11.0-alpha2`

## 说明

- 这是 `alpha` 预发布，不是正式稳定版
- GitHub Release 会以 `prerelease` 形式发布
- 若通过 tag 触发发布，请使用 `V0.11.0-alpha2` 或 `v0.11.0-alpha2`
