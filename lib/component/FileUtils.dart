import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:vertree/main.dart';

class FileUtils {

  /// 获取当前应用程序的目录路径，并确保路径格式适合当前操作系统
  static String appDirPath() {
    final exePath = Platform.resolvedExecutable;
    final exeDir = File(exePath).parent.path;

    // 使用path库自动适配不同平台的路径分隔符
    return p.normalize(exeDir);
  }


  /// 处理路径，确保路径格式适合当前操作系统
  static String _normalizePath(String path) {
    return p.normalize(path); // 处理不规范的路径，适配当前系统
  }

  /// 打开文件夹
  static void openFolder(String folderPath) {
    try {
      String normalizedPath = _normalizePath(folderPath);

      if (!Directory(normalizedPath).existsSync()) {
        logger.error("文件夹不存在: $normalizedPath");
        return;
      }

      if (Platform.isWindows) {
        Process.run('explorer.exe', [normalizedPath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [normalizedPath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [normalizedPath]);
      }
    } catch (e) {
      logger.error("打开文件夹失败: $e");
    }
  }

  /// 打开文件
  static void openFile(String filePath) {
    try {
      String normalizedPath = _normalizePath(filePath);

      if (!File(normalizedPath).existsSync()) {
        logger.error("文件不存在: $normalizedPath");
        return;
      }

      if (Platform.isWindows) {
        Process.run('explorer.exe', [normalizedPath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [normalizedPath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [normalizedPath]);
      }
    } catch (e) {
      logger.error("打开文件失败: $e");
    }
  }
}
