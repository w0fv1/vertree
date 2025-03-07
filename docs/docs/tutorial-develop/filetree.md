---
sidebar_position: 2
---

# 🌳 Vertree版本树设计解析

在 Vertree 中，文件版本管理的核心围绕两个类实现：`FileVersion` 和 `FileNode`。

- `FileVersion` 负责版本号的构造与计算。
- `FileNode` 实现文件版本树的节点结构，负责文件版本关系管理。

---

## 一、FileVersion 类介绍

`FileVersion` 类表示一个文件的版本号，形如：

```
0.0 → 0.1 → 0.2
           └→ 0.2-0.0 → 0.2-0.1
```

### 🎯 版本号结构设计理念：

- **树状结构**：
    - 主干：`X.Y`（如 `0.0`、`0.1`）。
    - 分支：用`-`表示子分支，如 `0.1-0.0`。
    - 每个版本号的单元为 `(branch.version)`。

例如：
```
0.0 (主干版本)
├── 0.1 (主干版本递增)
└── 0.0-0.0 (从0.0分支出来的子版本)
```

---

### 📌 关键方法说明：

- **`nextVersion()`**：
    - 获取当前版本的下一个版本（同分支递增）。
    - 如：`0.0 → 0.1`, `0.1-0.0 → 0.1-0.1`

- **`branchVersion(int branchIndex)`**：
    - 创建一个新分支，新增版本为 `branchIndex.0`。
    - 如：从 `0.1` 创建新分支 `0.1-0.0`

- **`compareTo(FileVersion other)`**：
    - 逐段比较版本号大小，用于排序版本。

- **`isSameBranch(FileVersion other)`**：
    - 判断两个版本是否位于同一分支，仅考虑分支结构，不考虑版本号。

- **`isChild(FileVersion other)`**：
    - 判断一个版本是否为另一个版本的直接子版本。

- **`isDirectBranch(FileVersion other)`**：
    - 判断是否直接从当前版本创建的新分支。

- **`isIndirectBranch(FileVersion other)`**：
    - 判断是否从当前版本派生出的间接分支。

---

## 二、FileNode 类介绍

`FileNode` 类代表版本树中的一个节点（文件的特定版本）。

### 🌱 FileNode 结构与用途：

- 每个节点包含一个 `FileMeta`，描述文件元数据。
- 节点可拥有：
    - **子版本 (`child`)**：同一分支下的下一个版本。
    - **多个分支版本 (`branches`)**：从当前版本分裂出的新分支。

- 节点结构示意：

```
当前节点
├── child (下一版本)
└── branches
    ├── branch1
    └── branch2
```

---

### 📌 关键方法解析：

#### 🚩 版本树构建方法：

- **`addChild(FileNode node)`**：
    - 为当前版本节点添加一个子版本。

- **`addBranch(FileNode branch)`**：
    - 为当前版本节点创建新的分支节点。

- **`backup()`**：
    - 创建当前节点的下一个版本（子节点），复制文件并生成新版本号。

- **`branch()`**：
    - 创建从当前节点的新分支（分支节点），复制文件生成新分支版本号。

#### 🚩 节点插入与递归管理方法：

- **`push(FileNode node)`**：
    - 将给定节点递归地插入到版本树的正确位置。
    - 依次尝试判断节点是否为直接子节点、直接分支节点、间接子节点。

#### 🚩 版本树的可视化输出：

- **`toTreeString()`**：
    - 将版本树以直观的文本形式展示，便于调试和理解版本结构。

示例如：

```
Root[design.psd (version: 0.0)]
    Child[design.0.1.psd (version: 0.1)]
        Child[design.0.2.psd (version: 0.2)]
        Branch[design.0.1-0.0.psd (version: 0.1-0.0)]
```

---

## 🚧 文件元数据 (`FileMeta`) 类：

- 存储文件的基本属性，包括文件路径、大小、版本号、创建及修改时间等。
- 文件名解析规则明确，利于扩展。

---

## 🚀 快速参与开发的建议：

### 如何增加新功能：

- **版本树新功能**：
    - 在 `FileVersion` 中扩展新方法，完善版本规则；
    - 在 `FileNode` 中增加节点操作逻辑。

- **文件备份或监控功能**：
    - 在 `FileNode` 类的 `backup()` 与 `branch()` 中增加文件处理逻辑。

### 如何排查 Bug：

- 利用 `toTreeString()` 快速输出版本树状态，定位问题。
- 查看版本节点方法（`isChild`、`isDirectBranch` 等）逻辑是否符合预期。

---

## 🛠️ 总结（给开发者的话）：

Vertree 的版本树核心结构十分清晰：

- `FileVersion`：专注于版本号的创建与计算；
- `FileNode`：专注于文件的版本关系构建与管理。

开发时，只需明确版本的概念、分支的操作方式，即可快速上手并扩展新功能。

期待你的加入，让 Vertree 更加强大！🚀✨