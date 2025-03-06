import 'dart:io';
import 'component/WindowsRegistryHelper.dart';

class VerTreeRegistryService {
  static const String backupMenuName = "VerTree Backup";
  static const String monitorMenuName = "VerTree Monitor";
  static const String viewTreeMenuName = "View VerTree"; // 新增菜单项名称

  static String exePath = Platform.resolvedExecutable;

  static bool checkBackupKeyExists() {
    return RegistryHelper.checkRegistryMenuExists(backupMenuName);
  }

  static bool checkMonitorKeyExists() {
    return RegistryHelper.checkRegistryMenuExists(monitorMenuName);
  }

  static bool checkViewTreeKeyExists() {
    return RegistryHelper.checkRegistryMenuExists(viewTreeMenuName); // 新增检查方法
  }

  static bool addVerTreeBackupContextMenu() {
    return RegistryHelper.addContextMenuOption(
      backupMenuName,
      '$exePath --backup %1',
      iconPath: "assets/img/logo/logo.ico",
    );
  }

  static bool addVerTreeMonitorContextMenu() {
    return RegistryHelper.addContextMenuOption(
      monitorMenuName,
      '$exePath --monitor %1',
      iconPath: "assets/img/logo/logo.ico",
    );
  }

  static bool addVerTreeViewContextMenu() { // 新增方法
    return RegistryHelper.addContextMenuOption(
      viewTreeMenuName,
      '$exePath --viewtree %1',
      iconPath: "assets/img/logo/logo.ico",
    );
  }

  static bool removeVerTreeBackupContextMenu() {
    return RegistryHelper.removeContextMenuOption(backupMenuName);
  }

  static bool removeVerTreeMonitorContextMenu() {
    return RegistryHelper.removeContextMenuOption(monitorMenuName);
  }

  static bool removeVerTreeViewContextMenu() { // 新增方法
    return RegistryHelper.removeContextMenuOption(viewTreeMenuName);
  }
}
