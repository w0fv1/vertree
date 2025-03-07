import 'dart:io';
import 'component/WindowsRegistryHelper.dart';

class VerTreeRegistryService {
  static const String backupMenuName = "VerTree Backup";
  static const String monitorMenuName = "VerTree Monitor";
  static const String viewTreeMenuName = "View VerTree"; // 新增菜单项名称
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

  // 添加右键菜单项
  static bool addVerTreeBackupContextMenu() {
    return RegistryHelper.addContextMenuOption(
      backupMenuName,
      '"$exePath" --backup %1',
      iconPath: "assets/img/logo/logo.ico",
    );
  }

  static bool addVerTreeMonitorContextMenu() {
    return RegistryHelper.addContextMenuOption(
      monitorMenuName,
      '"$exePath" --monitor %1',
      iconPath: "assets/img/logo/logo.ico",
    );
  }

  static bool addVerTreeViewContextMenu() {
    return RegistryHelper.addContextMenuOption(
      viewTreeMenuName,
      '"$exePath" --viewtree %1',
      iconPath: "assets/img/logo/logo.ico",
    );
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
