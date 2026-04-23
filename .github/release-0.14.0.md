# Vertree 0.14.0

Vertree `0.14.0` 修复 Windows 11 新设备上的新右键菜单注册链路，并收紧局域网分享页自动探测失败后的重试和候选地址展示行为。

## 本次重点

- Windows 11 一级右键菜单注册改为优先使用 signed sparse MSIX + ExternalLocation，保留 loose manifest 作为本地开发兜底
- 安装器在原始登录用户上下文注册/清理 per-user sparse package，避免管理员 UAC token 写到错误账户
- 构建脚本支持通过 `VERTREE_MSIX_CERTIFICATE_PATH` / `VERTREE_MSIX_CERTIFICATE_PASSWORD` 生成并签名 Win11 sparse identity package
- 分享下载页的“重新探测”不再污染 URL hash，避免失败后反复触发探测循环
- 分享下载页现在会对候选 LAN IP 和 `ip:port` 组合去重并设置硬上限，避免失败时列表膨胀
- 官网公告、首页、简介和安装/开发文档同步更新到 `0.14.0`

## 发布说明

- 这是正式稳定版，不会以 `prerelease` 形式发布
- 若通过 tag 触发发布，请使用 `V0.14.0` 或 `v0.14.0`
