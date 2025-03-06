import 'dart:async';
import 'dart:io';
import 'package:vertree/component/Configer.dart';
import 'package:vertree/core/Monitor.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/main.dart';
import 'package:path/path.dart' as p;

class MonitService {

  /// 由 MonitService 持有的任务列表
  List<FileMonitTask> monitFileTasks = [];

  /// 返回正在运行的监控任务数量
  int get runningTaskCount {
    return monitFileTasks.where((task) => task.isRunning).length;
  }

  MonitService() {
    // 从 configer 中获取存储的任务信息（JSON），再转换为对象列表
    final filesJson = configer.get<List<dynamic>>("monitFiles", <dynamic>[]);
    monitFileTasks = filesJson.map((e) => FileMonitTask.fromJson(e)).toList();

    // 如果 task.isRunning == true，则创建对应的 monitor 实例并启动监控
    for (var task in monitFileTasks) {
      if (task.isRunning) {
        _startMonitor(task);
      }
    }

  }

  /// 将当前任务列表保存到 configer
  Future<void> _saveMonitFiles() async {
    configer.set("monitFiles", monitFileTasks.map((t) => t.toJson()).toList());
  }

  /// 返回当前正在运行的监控数量
  int get runningMonitorCount {
    return monitFileTasks.where((t) => t.monitor != null).length;
  }

  /// 启动所有已标记为运行的监视任务
  Future<void> startAll() async {

    for (var task in monitFileTasks) {
      if (task.isRunning && task.monitor == null) {
        _startMonitor(task);
      }
    }
  }

  /// 添加文件监视任务
  Future<Result<FileMonitTask, String>> addFileMonitTask(String path) async {

    // 检查任务是否已存在
    if (monitFileTasks.any((task) => task.filePath == path)) {
      logger.info("Task already exists for: $path");
      return Result.eMsg("Task already exists for: $path");
    }
    // 创建新任务
    final newTask = FileMonitTask(filePath: path, isRunning: true);

    // 启动监视
    _startMonitor(newTask);

    // 加入列表并保存配置
    monitFileTasks.add(newTask);
    await _saveMonitFiles();

    return Result.ok(newTask);
  }

  /// 移除文件监视任务
  Future<void> removeFileMonitTask(String path) async {

    final index = monitFileTasks.indexWhere((t) => t.filePath == path);
    if (index == -1) {
      print("Task not found for: $path");
      return;
    }

    // 停止监视
    final task = monitFileTasks[index];
    _pauseMonitor(task);

    // 从列表中移除并保存
    monitFileTasks.removeAt(index);
    await _saveMonitFiles();
  }

  /// 切换文件监视任务的运行状态
  Future<FileMonitTask> toggleFileMonitTaskStatus(FileMonitTask task) async {

    final index = monitFileTasks.indexWhere((t) => t.filePath == task.filePath);
    if (index == -1) {
      print("Task not found for: ${task.filePath}");
      return task;
    }

    // 切换状态
    task.isRunning = !task.isRunning;
    if (task.isRunning) {
      _startMonitor(task);
    } else {
      _pauseMonitor(task);
    }

    monitFileTasks[index] = task;
    await _saveMonitFiles();

    return task;
  }

  /// 启动监视
  void _startMonitor(FileMonitTask task) {
    task.monitor ??= Monitor.fromTask(task);
    task.monitor?.start();
    task.isRunning = true;
  }

  /// 停止监视
  void _pauseMonitor(FileMonitTask task) {
    task.monitor?.stop();
    task.monitor = null;
    task.isRunning = false;
  }
}


class FileMonitTask {
  String filePath;
  late String backupDirPath;
  bool isRunning; // 是否正在运行
  late File file;
  Monitor? monitor;

  FileMonitTask({required this.filePath, this.isRunning = false}) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print("File does not exist: $filePath");
      return;
    }

    final directory = file.parent;
    final fileName = p.basenameWithoutExtension(file.path);

    final backupDir = Directory(p.join(directory.path, '${fileName}_bak'));
    backupDirPath = backupDir.path;
  }

  // 将对象转换为 Map（用于 JSON 序列化）
  Map<String, dynamic> toJson() => {"filePath": filePath, "backupDirPath": backupDirPath, "isRunning": isRunning};

  // 从 Map（JSON 反序列化）创建对象
  factory FileMonitTask.fromJson(Map<String, dynamic> json) {
    return FileMonitTask(filePath: json["filePath"], isRunning: json["isRunning"] ?? false);
  }

  @override
  String toString() => 'FileMonitTask(filePath: $filePath, backupDirPath: $backupDirPath, isRunning: $isRunning)';
}
