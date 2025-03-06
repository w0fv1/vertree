import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

enum LogLevel { debug, info, error }

class AppLogger {
  late File _logFile;
  LogLevel _currentLevel;

  AppLogger(this._currentLevel);

  Future<void> init() async {
    final directory = await getApplicationSupportDirectory();
    final logDir = Directory('${directory.path}/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());
    _logFile = File('${logDir.path}/log_$timestamp.txt');

    // 延迟10秒后执行日志清理任务
    Future.delayed(Duration(seconds: 10), _cleanOldLogs);
  }

  void log(String message, {LogLevel level = LogLevel.info}) {
    if (level.index < _currentLevel.index) return;
    String logMessage = "[${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}] [${level.name.toUpperCase()}] $message";
    print(logMessage);
    _logFile.writeAsStringSync('$logMessage\n', mode: FileMode.append);
  }

  void debug(String message) => log(message, level: LogLevel.debug);
  void info(String message) => log(message, level: LogLevel.info);
  void error(String message) => log(message, level: LogLevel.error);

  Future<void> _cleanOldLogs() async {
    final directory = await getApplicationSupportDirectory();
    final logDir = Directory('${directory.path}/logs');
    if (!await logDir.exists()) return;

    final now = DateTime.now();
    final files = logDir.listSync();
    for (var file in files) {
      if (file is File) {
        final stat = await file.stat();
        final diff = now.difference(stat.modified);
        if (diff.inDays > 30) {
          await file.delete();
        }
      }
    }
  }
}
