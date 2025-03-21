---
sidebar_position: 5
---

# 🖌️ VerTree 设计理念

VerTree 从诞生之初就坚持以用户为中心的设计理念，我们希望版本管理工具能够贴合实际使用场景，而非仅服务于技术人员。以下是我们在设计过程中所坚持的核心思想：

---

## 1️⃣ 为什么不采用类似 Git 的文件数据库？

尽管 Git 是当前主流的版本管理工具，但它的设计核心是基于 **行文本差异（diff）** 的管理模式。这种模式在以下场景会遇到明显的不足：

- **复杂二进制工程文件管理困难**  
  如 Photoshop 的 PSD 文件、各类设计文件、Office 文档等，这些文件都属于复杂的二进制文件。Git 对这些文件的差异识别效果极差，几乎只能整体存储每个版本，无法利用 Git 本身优势，反而增加了管理成本。

- **对非技术人员不够友好**  
  Git 的 `commit`、`push`、`merge` 等概念，对于非开发人员而言过于复杂，学习成本较高。

因此，我们放弃了 Git 式文件数据库，转而采用了 **以文件复制为核心的版本管理模式**，简单直观，更贴合实际创作者的使用场景。

---

## 2️⃣ 为什么采用命名方式来控制版本？

我们在设计 VerTree 时，坚持了**“无侵入式”设计**。这意味着软件不会更改或影响用户原有的文件使用习惯。

文件命名是一种极为轻量化的元数据记录方式，有以下明显优势：

- **直观透明**：  
  用户只需通过文件名即可清晰了解版本的历史，无需特殊工具解析。
- **最小化侵入**：  
  用户随时可以脱离 VerTree 软件，独立管理和打开备份文件，避免了软件失效或迁移后文件无法使用的问题。

---

## 3️⃣ 为什么强调“无侵入”与“无感”使用？

版本管理工具的核心目的应是简化用户工作，而非增加使用负担：

- **降低用户学习成本**：  
  创作者的精力应聚焦于创作本身，而不是花费大量时间去学习版本管理工具复杂的概念和操作。

- **避免心智负担**：  
  用户使用 Git 等专业工具时，往往需要考虑版本冲突、分支管理、远程同步等问题。我们希望 VerTree 能够自动处理这些问题，让用户在**“无感知”**的状态下自动实现版本控制。

---

## 4️⃣ 为什么选择树状结构管理版本？

在真实的创作场景中，版本迭代和分支是普遍存在的现象：

- 客户反馈、创意探索、方案对比都可能导致版本的回退和分叉；
- 单一的线性版本历史（如简单的 v1、v2、v3）无法准确表达版本之间的分支关系；
- 树状结构直观展现了版本之间的历史关系，能帮助用户清晰了解创作过程，快速回溯和切换不同版本。

因此，我们选择树状结构来呈现版本历史，更贴近真实的创作与管理场景。

---

## 5️⃣ 为什么强调随时可脱离软件使用、不依赖工具？

我们认为，用户的创作和数据安全不应完全依赖于工具本身：

- 如果软件强制用户按照某个特定流程或强绑定模式使用，容易造成软件和数据的耦合，一旦软件出现问题，用户的工作流将完全受阻；
- 我们强调每个备份文件都是独立存在的，用户可随时 **脱离 VerTree 软件** 独立访问备份文件，进一步降低了用户的风险；
- 用户对工具的依赖度越低，心理负担和心智成本也会越低，这将极大地提升用户的信任感和使用意愿。

---

## 6️⃣为什么单纯使用复制来控制版本，而不引入二进制补丁算法？这样不是节约很多硬盘空间吗?

这个工具的目的是优化/增强现有流程，而不是延申出更复杂的版本管理来。也就是说，在之前 -- 你会创建复制两个版本，在使用工具之后，你也不会创建复制出更多个版本。

即使你觉着版本管理非常重要，这个工具很方便，因此创建了更多版本，也不会多出很多来。

对于版本控制的功能来说，以复制文件为核心的版本控制，理应不会比原来的工作流程浪费更多的空间，至少不会因此让硬盘顶不住。

所以，唯一需要担心的是监控，对于监控，占据的硬盘空间会很快的膨胀。

但对于监控来说，我们有别的方法解决这个问题 -- 比如删除掉老旧的监控备份，或者增加监控备份间隙。

总结，Vertree在这个阶段就引入“二进制diff 补丁”算法，是非常得不偿失的。我们有更简单方便好用的办法。

---
## 🌟 总结（给所有创作者的话）：

VerTree 追求的是**“让创作者专注于创作”**，而非被工具所限制或束缚。  
我们始终相信，优秀的工具应是直观的、透明的、无感的，并且随时可替代的。

我们的目标始终是帮助每位用户轻松管理创作过程，让每一次修改都有迹可循，让创作过程更加清晰、高效。

---

🌳 **VerTree，让创作更简单、更自由。**