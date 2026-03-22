---
sidebar_position: 3
---

# Vertree 文件监控设计解析

Vertree 的监控能力由三个核心对象组成：

- `Monitor`：负责单个文件的文件系统监听与自动备份
- `MonitManager`：负责保存、恢复和切换多个监控任务
- `FileMonitTask`：监控任务的数据模型

## Monitor 的工作方式

`Monitor` 会监听目标文件所在目录的文件系统事件，并只在事件路径命中目标文件时继续处理。

核心行为：

- 使用 `file.parent.watch(events: FileSystemEvent.all)` 建立监听
- 记录运行时状态：
  - `startedAt`
  - `lastObservedEventAt`
  - `lastBackupTime`
  - `lastBackupPath`
  - `lastError`
  - `observedEventCount`
  - `createdBackupCount`
- 通过 `_isHandlingFileChange` 防止重入

## 自动备份策略

备份目录规则：

- 与源文件同目录
- 目录名为 `<basename>_bak`

备份文件名规则：

- `<原文件名>_<ISO时间戳>.bak<原扩展名>`

例如：

```text
story.0.1.txt_2026-03-22T11-35-10.123.bak.txt
```

## 频率控制与清理

监控不会对每一次保存都立即无限制落盘，而是受配置控制：

- `monitorRate`：最小备份间隔，默认 `5` 分钟
- `monitorMaxSize`：每个监控任务最多保留的备份数量，默认 `50`

当备份数量超过上限时，`Monitor` 会按最后修改时间从旧到新删除多余备份。

## MonitManager 的职责

`MonitManager` 是运行时监控任务的持有者。

它负责：

- 从 `config.json` 读取 `monitFiles`
- 在启动时恢复 `isRunning == true` 的任务
- 添加新任务
- 删除任务
- 切换任务运行状态
- 统一保存任务列表

关键方法：

- `addFileMonitTask(String path)`
- `removeFileMonitTask(String path)`
- `toggleFileMonitTaskStatus(FileMonitTask task)`
- `startAll()`

## FileMonitTask 的职责

`FileMonitTask` 用来描述一个持久化的监控任务，核心字段包括：

- `filePath`
- `backupDirPath`
- `isRunning`
- `fileExists`
- `monitor`

它同时提供：

- `toJson()`：持久化到配置
- `fromJson()`：从配置恢复

## 与本机 HTTP API 的关系

本机 HTTP API 会直接复用这些运行时对象：

- `GET /api/v1/monitor-tasks`
- `POST /api/v1/monitor-tasks`
- `PATCH /api/v1/monitor-tasks/{id}`
- `DELETE /api/v1/monitor-tasks/{id}`
- `GET /api/v1/monitor-tasks/{id}/backups`
- `POST /api/v1/monitor-tasks/{id}/verification-writes`

这意味着监控模块不仅服务 UI，也服务本地自动化和测试验证。

## 当前实现特点

- 备份逻辑简单直接，以文件复制为核心
- 配置恢复优先保证“可继续工作”，而不是引入复杂调度器
- 运行时元数据比较完整，便于设置页和 API 直接观测任务状态
- 目前以单文件监听为单位，不是目录级批处理系统
