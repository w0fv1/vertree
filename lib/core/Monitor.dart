import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:vertree/core/MonitManager.dart';
import 'package:vertree/main.dart';

class Monitor {
  late String filePath;
  late String backupDirPath;
  late File file;
  late Directory backupDir;

  DateTime? _lastBackupTime;
  StreamSubscription<FileSystemEvent>? _subscription;

  Monitor(this.filePath) {
    file = File(filePath);
    if (!file.existsSync()) {
      print("File does not exist: $filePath");
      return;
    }

    final directory = file.parent;
    final fileName = p.basenameWithoutExtension(file.path);

    backupDir = Directory(p.join(directory.path, '${fileName}_bak'));
    backupDirPath = backupDir.path;

    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
  }

  Monitor.fromTask(FileMonitTask fileMonitTask) {
    filePath = fileMonitTask.filePath;
    file = File(filePath);
    if (!file.existsSync()) {
      logger.error("File does not exist: $filePath");
      return;
    }
    if (fileMonitTask.backupDirPath == null) {
      logger.error("Backup dir does not exist: $filePath");
      return;
    }

    backupDirPath = fileMonitTask.backupDirPath!;

    backupDir = Directory(backupDirPath);

    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
  }

  void start() {
    _subscription = file.parent.watch(events: FileSystemEvent.all).listen((event) {
      print("事件触发: ${event.type} -> ${event.path}");
      if (event.path == file.absolute.path) {
        _handleFileChange(file, backupDir);
      }
    });

    logger.info("Started monitoring: $filePath");
  }
  bool _isHandlingFileChange = false; // 添加一个布尔标志

  void _handleFileChange(File file, Directory backupDir) {
    if (_isHandlingFileChange) {
      logger.info("handleFileChange 调用被拒绝，因为之前的调用仍在运行");
      return;
    }
    _isHandlingFileChange = true;

    try {
      final now = DateTime.now();
      logger.info("handleFileChange ${file.path}");
      if (_lastBackupTime == null || now.difference(_lastBackupTime!).inMinutes >= configer.get("monitorRate", 1)) {
        logger.info("backupFile ${file.path}");

        _backupFile(file, backupDir);
        _lastBackupTime = now;
        _cleanupOldBackups(backupDir);
      } else {
        logger.info("_lastBackupTime ${_lastBackupTime?.toIso8601String()}");
      }
    } finally {
      _isHandlingFileChange = false; // 确保在任何情况下都重置标志
    }
  }

  void _cleanupOldBackups(Directory backupDir) {
    final maxBackups = configer.get("monitorMaxSize",9999 );
    final files = backupDir.listSync().whereType<File>().toList();
    if (files.length > maxBackups) {
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      final filesToDelete = files.take(files.length - maxBackups);
      for (final fileToDelete in filesToDelete) {
        try {
          fileToDelete.deleteSync();
          logger.info("Deleted old backup: ${fileToDelete.path}");
        } catch (e) {
          logger.error("Error deleting old backup: $e");
        }
      }
    }
  }

  void _backupFile(File file, Directory backupDir) {
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = p.join(backupDir.path, '${p.basename(file.path)}_$timestamp.bak${p.extension(file.path)}');
      logger.info("Backup to: $backupPath");
      file.copySync(backupPath);
      logger.info("Backup created: $backupPath");
    } catch (e) {
      logger.error("Error creating backup: $e");
    }
  }

  void stop() {
    _subscription?.cancel();
    logger.info("Stopped monitoring: $filePath");
  }
}
