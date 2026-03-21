# Vertree 0.10.0-alpha1

Vertree `0.10.0-alpha1` 是一次预发布版本，用来提前验证新的桌面集成、国际化补全，以及 Linux 发布链路。

## 本次重点

- 补齐一批桌面端 UI 文案的 i18n，包括设置页、托盘菜单、监控状态提示与初始化引导
- 完善 Linux 发布产物，GitHub Actions 现在同时产出 Linux 压缩包与 RPM
- 调整 RPM 打包逻辑，支持 `0.10.0-alpha1` 这类预发布版本号
- 同步更新设置页中的 GNOME / Windows 11 集成提示，减少平台相关配置的理解成本

## 说明

- 这是 `alpha` 预发布，不是正式稳定版
- GitHub Release 会以 `prerelease` 形式发布
- 若通过 tag 触发发布，请使用 `V0.10.0-alpha1` 或 `v0.10.0-alpha1`
