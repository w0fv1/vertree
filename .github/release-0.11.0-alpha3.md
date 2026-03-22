# Vertree 0.11.0-alpha3

Vertree `0.11.0-alpha3` 是一次预发布版本，重点放在 Windows 安装链路补强，尤其是 Windows 11 新右键菜单、菜单乱码修复，以及 MSI 安装包补齐。

## 本次重点

- Windows 发布链路补齐 `msi` 安装包，与现有 `setup.exe` / `zip` 一起产出
- Windows 发布文件名统一为 `vertree-windows-x64-<version>` 风格，与 Linux / macOS 保持一致
- 自动更新现在会识别预发布版本，并按当前平台优先选择合适的下载资产
- 修复 Windows 旧菜单中额外出现的错误 `Vertree` 子菜单问题
- 修复 Windows 上右键菜单中文 / 日文标题乱码问题，菜单扩展 DLL 统一按 UTF-8 编译
- 修复 Windows 11 新菜单开关未真正注册 sparse package 的问题，安装版现在会携带 `win11_packaging` 资源
- Win11 菜单开启时会清理旧的注册表式伪菜单，关闭时会正确卸载 sparse package 并同步清理旧注册
- 设置页中 Win11 菜单开关的启用 / 关闭逻辑已修正，避免“看起来关闭了但实际上仍保留注册”的状态错乱
- 同步 `pubspec.yaml`、应用内版本号与本次 release 到 `0.11.0-alpha3`

## 说明

- 这是 `alpha` 预发布，不是正式稳定版
- GitHub Release 会以 `prerelease` 形式发布
- 若通过 tag 触发发布，请使用 `V0.11.0-alpha3` 或 `v0.11.0-alpha3`
