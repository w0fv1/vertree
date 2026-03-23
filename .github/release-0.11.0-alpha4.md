# Vertree 0.11.0-alpha4

Vertree `0.11.0-alpha4` 是一次预发布版本，重点放在安装版 Windows 11 新右键菜单修复，以及 Linux 发布产物命名一致性整理。

## 本次重点

- 修复安装版 Windows 11 新菜单注册失败的问题：sparse package 现在会先复制到当前用户可写目录再执行注册，避免从 `Program Files` 直接注册时触发 `Add-AppxPackage` 的 `0x80070005` 拒绝访问
- 保留现有 Win11 菜单刷新流程，重新注册 sparse package 后仍会清理相关 `dllhost` 并刷新 Explorer，减少菜单状态不同步
- Linux RPM 发布产物命名已统一到与其他平台一致的 `vertree-linux-x64-<version>.rpm` 风格
- 同步 `pubspec.yaml`、应用内版本号、README 状态段与安装文档示例版本到 `0.11.0-alpha4`

## 说明

- 这是 `alpha` 预发布，不是正式稳定版
- GitHub Release 会以 `prerelease` 形式发布
- 若通过 tag 触发发布，请使用 `V0.11.0-alpha4` 或 `v0.11.0-alpha4`
