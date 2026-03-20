# Vertree Docs

Vertree 的文档站使用 Docusaurus 构建，源码在 `docs/docs`，静态产物输出到 `docs/build`。

## 环境

- Node.js 18+
- npm

## 安装依赖

```bash
npm install
```

## 本地预览

```bash
npm start
```

## 构建静态站点

```bash
npm run build
```

## 这次需要重点维护的文档

- `docs/docs/intro.md`
- `docs/docs/tutorial-usage/install.md`
- `docs/docs/tutorial-usage/usage.md`
- `docs/docs/macos.md`
- `docs/docs/linux.md`

如果发布内容有变更，优先先改这几处，再重新构建 `docs/build`。
