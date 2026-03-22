---
sidebar_position: 2
---

# Vertree 版本树设计解析

Vertree 的版本树核心围绕四个对象展开：

- `FileVersion`：版本号解析、比较、分支计算
- `FileMeta`：文件名、标签、扩展名、版本与文件属性
- `FileNode`：树节点、备份与分支行为
- `buildTree()`：从同目录文件集合构建版本树

## 文件名规则

Vertree 当前支持的版本化文件名格式为：

```text
<name>[#label].<version>.<ext>
```

例如：

- `story.0.0.txt`
- `story#baseline.0.1.txt`
- `story#optionA.0.1-1.0.txt`

其中：

- `name`：逻辑文件名
- `label`：可选备注
- `version`：树状版本号
- `ext`：原始扩展名

## FileVersion

`FileVersion` 内部把版本号拆成多个 `Segment(branch, version)`。

例子：

```text
0.0
0.1
0.1-1.0
0.1-1.1
```

核心规则：

- 同一分支上的下一个版本：`nextVersion()`
- 从当前版本派生一个新分支：`branchVersion(branchIndex)`
- 比较两个版本大小：`compareTo`
- 判断是否为直接子版本：`isChild`
- 判断是否为直接分支：`isDirectBranch`

## FileMeta

`FileMeta` 负责把文件路径拆成这些信息：

- `fullName`
- `name`
- `label`
- `version`
- `extension`
- `fullPath`
- `fileSize`
- `creationTime`
- `lastModifiedTime`

它还提供：

- `isSupportedTreeFilePath()`：判断文件名是否符合版本树命名规则
- `renameFile()`：在保留版本信息的前提下重命名标签

## FileNode

`FileNode` 代表一个具体版本的文件节点。

结构上它可能拥有：

- 一个 `child`：同分支的下一个版本
- 多个 `branches`：从当前节点分出的分支

关键方法：

- `safeBackup([label])`
- `backup([label])`
- `branch([label])`
- `push(FileNode node)`
- `toTreeString()`

### safeBackup 的行为

`safeBackup()` 会先尝试走主线下一个版本：

- 如果下一个版本号没有冲突，就创建正常备份
- 如果版本号已经被占用，就自动创建一个新分支

这让 UI 和 CLI 在“只想留一个新版本”时不需要手动决定到底该生成 child 还是 branch。

## buildTree()

`buildTree(String selectedFileNodePath)` 的流程是：

1. 检查目标文件是否存在
2. 检查文件名是否符合版本树规则
3. 扫描同目录下所有同名同扩展名、且可解析版本号的文件
4. 选取最小版本作为根节点
5. 按版本号排序后逐个 `push` 到树中

它不依赖数据库，完全基于当前文件系统状态重建树结构。

## 当前实现特点

- 版本树是“文件系统真相”的直接投影
- 标签直接体现在文件名里，不需要额外索引服务
- 备份与分支都通过复制文件完成
- 根节点、主线和分支的关系可以在没有应用进程时依然被人工理解
