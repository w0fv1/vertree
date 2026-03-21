# Vertree 0.10.0-alpha2

Vertree `0.10.0-alpha2` 是一次预发布版本，主要聚焦 macOS Finder 集成、文档站点域名修正，以及跨平台应用标识统一。

## 本次重点

- 新增 macOS Finder 扩展入口，右键可直接触发 Vertree 动作并回传到主应用
- 修正文档站点部署配置，站点域名统一到 `https://vertree.w0fv1.dev`
- 统一 Linux / Windows / macOS 里的应用标识与反向域名命名，收敛到 `dev.w0fv1.vertree`
- 更新 Pages 工作流，部署前自动构建 Docusaurus，减少旧产物导致的页面异常

## 说明

- 这是 `alpha` 预发布，不是正式稳定版
- GitHub Release 会以 `prerelease` 形式发布
- 若通过 tag 触发发布，请使用 `V0.10.0-alpha2` 或 `v0.10.0-alpha2`
