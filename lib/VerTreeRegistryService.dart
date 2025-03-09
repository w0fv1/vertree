import 'dart:io';
import 'package:vertree/component/FileUtils.dart';

import 'component/WindowsRegistryHelper.dart';
import 'package:path/path.dart' as path;

class VerTreeRegistryService {
  static const String backupMenuName = "备份文件 VerTree";
  static const String monitorMenuName = "监控文件变动 VerTree";
  static const String viewTreeMenuName = "查看文件版本树 VerTree"; // 新增菜单项名称
  static const String appName = "VerTree"; // 应用名称

  static const String runRegistryPath = r'Software\Microsoft\Windows\CurrentVersion\Run';

  static String exePath = Platform.resolvedExecutable;

  // 右键菜单项检查
  static bool checkBackupKeyExists() {
    return RegistryHelper.checkRegistryMenuExists(backupMenuName);
  }

  static bool checkMonitorKeyExists() {
    return RegistryHelper.checkRegistryMenuExists(monitorMenuName);
  }

  static bool checkViewTreeKeyExists() {
    return RegistryHelper.checkRegistryMenuExists(viewTreeMenuName);
  }

  static bool addVerTreeBackupContextMenu() {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(FileUtils.appDirPath(), 'data', 'flutter_assets', 'assets', 'img', 'icon', 'save.ico');

    return RegistryHelper.addContextMenuOption(backupMenuName, '"$exePath" --backup %1', iconPath: iconPath);
  }

  static bool addVerTreeMonitorContextMenu() {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(FileUtils.appDirPath(), 'data', 'flutter_assets', 'assets', 'img', 'icon', 'monit.ico');

    return RegistryHelper.addContextMenuOption(monitorMenuName, '"$exePath" --monit %1', iconPath: iconPath);
  }

  static bool addVerTreeViewContextMenu() {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(FileUtils.appDirPath(), 'data', 'flutter_assets', 'assets', 'img', 'logo', 'logo.ico');

    return RegistryHelper.addContextMenuOption(viewTreeMenuName, '"$exePath" --viewtree %1', iconPath: iconPath);
  }

  // 移除右键菜单项
  static bool removeVerTreeBackupContextMenu() {
    return RegistryHelper.removeContextMenuOption(backupMenuName);
  }

  static bool removeVerTreeMonitorContextMenu() {
    return RegistryHelper.removeContextMenuOption(monitorMenuName);
  }

  static bool removeVerTreeViewContextMenu() {
    return RegistryHelper.removeContextMenuOption(viewTreeMenuName);
  }

  // 开机自启相关
  static bool enableAutoStart() {
    return RegistryHelper.enableAutoStart(runRegistryPath, appName, exePath);
  }

  static bool disableAutoStart() {
    return RegistryHelper.disableAutoStart(runRegistryPath, appName);
  }

  static bool isAutoStartEnabled() {
    return RegistryHelper.isAutoStartEnabled(runRegistryPath, appName);
  }
}
