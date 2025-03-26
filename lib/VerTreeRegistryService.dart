import 'dart:io';
import 'package:vertree/I18nLang.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/main.dart';

import 'component/WindowsRegistryHelper.dart';
import 'package:path/path.dart' as path;

class VerTreeRegistryService {
  static const String appName = "VerTree"; // 应用名称

  static const String runRegistryPath = r'Software\Microsoft\Windows\CurrentVersion\Run';

  static String exePath = Platform.resolvedExecutable;

  static void reAddContextMenu() {
    if (checkBackupKeyExists()) {
      RegistryHelper.removeContextMenuOptionByKey(AppLocale.registry_backupKeyName);
      addVerTreeBackupContextMenu();
    }

    if (checkMonitorKeyExists()) {
      RegistryHelper.removeContextMenuOptionByKey(AppLocale.registry_monitorKeyName);
      addVerTreeMonitorContextMenu();
    }

    if (checkViewTreeKeyExists()) {
      RegistryHelper.removeContextMenuOptionByKey(AppLocale.registry_viewTreeKeyName);
      addVerTreeViewContextMenu();
    }

    if (checkExpressBackupKeyExists()) {
      RegistryHelper.removeContextMenuOptionByKey(AppLocale.registry_expressBackupKeyName);
      addVerTreeExpressBackupContextMenu();
    }
  }



  static bool addVerTreeBackupContextMenu() {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(FileUtils.appDirPath(), 'data', 'flutter_assets', 'assets', 'img', 'icon', 'save.ico');

    return RegistryHelper.addContextMenuOption(
      AppLocale.registry_backupKeyName,
      appLocale.getText(AppLocale.registry_backupKeyName),
      '"$exePath" --backup "%1"',
      iconPath: iconPath,
    );
  }

  static bool addVerTreeMonitorContextMenu() {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(FileUtils.appDirPath(), 'data', 'flutter_assets', 'assets', 'img', 'icon', 'monit.ico');

    return RegistryHelper.addContextMenuOption(
      AppLocale.registry_monitorKeyName,
      appLocale.getText(AppLocale.registry_monitorKeyName),
      '"$exePath" --monit "%1"',
      iconPath: iconPath,
    );
  }

  static bool addVerTreeViewContextMenu() {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(FileUtils.appDirPath(), 'data', 'flutter_assets', 'assets', 'img', 'logo', 'logo.ico');

    return RegistryHelper.addContextMenuOption(
      AppLocale.registry_viewTreeKeyName,
      appLocale.getText(AppLocale.registry_viewTreeKeyName),
      '"$exePath" --viewtree "%1"',
      iconPath: iconPath,
    );
  }

  static bool addVerTreeExpressBackupContextMenu() {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(
      FileUtils.appDirPath(),
      'data',
      'flutter_assets',
      'assets',
      'img',
      'icon',
      'express-save.ico',
    );

    return RegistryHelper.addContextMenuOption(
      AppLocale.registry_expressBackupKeyName,
      appLocale.getText(AppLocale.registry_expressBackupKeyName),
      '"$exePath" --express-backup "%1"',
      iconPath: iconPath,
    );
  }

  static bool removeVerTreeExpressBackupContextMenu() {
    return RegistryHelper.checkRegistryMenuExistsByKey(AppLocale.registry_expressBackupKeyName);
  }

  static bool removeVerTreeViewContextMenu() {
    return RegistryHelper.checkRegistryMenuExistsByKey(AppLocale.registry_viewTreeKeyName);
  }

  static bool removeVerTreeMonitorContextMenu() {
    return RegistryHelper.checkRegistryMenuExistsByKey(AppLocale.registry_monitorKeyName);
  }

  static bool removeVerTreeBackupContextMenu() {
    return RegistryHelper.checkRegistryMenuExistsByKey(AppLocale.registry_backupKeyName);
  }

  static bool checkBackupKeyExists() {
    return RegistryHelper.checkRegistryMenuExistsByKey(AppLocale.registry_backupKeyName);
  }

  static bool checkExpressBackupKeyExists() {
    return RegistryHelper.checkRegistryMenuExistsByKey(AppLocale.registry_expressBackupKeyName);
  }

  static bool checkMonitorKeyExists() {
    return RegistryHelper.checkRegistryMenuExistsByKey(AppLocale.registry_monitorKeyName);
  }

  static bool checkViewTreeKeyExists() {
    return RegistryHelper.checkRegistryMenuExistsByKey(AppLocale.registry_viewTreeKeyName);
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

  static const String backupMenuName = "备份文件 VerTree";
  static const String expressBackupMenuName = "快速备份文件 VerTree";
  static const String monitorMenuName = "监控文件变动 VerTree";
  static const String viewTreeMenuName = "查看文件版本树 VerTree"; // 新增菜单项名称
  static bool clearObsoleteRegistry() {
    bool success = true;

    if (checkContextMenuExists(backupMenuName)) {
      success &= RegistryHelper.removeContextMenuOptionByMenuName(backupMenuName);
    }

    if (checkContextMenuExists(monitorMenuName)) {
      success &= RegistryHelper.removeContextMenuOptionByMenuName(monitorMenuName);
    }

    if (checkContextMenuExists(viewTreeMenuName)) {
      success &= RegistryHelper.removeContextMenuOptionByMenuName(viewTreeMenuName);
    }

    if (checkContextMenuExists(expressBackupMenuName)) {
      success &= RegistryHelper.removeContextMenuOptionByMenuName(expressBackupMenuName);
    }

    return success;
  }

  /// 通用检查方法：根据菜单名称判断注册表项是否存在
  static bool checkContextMenuExists(String menuName) {
    return RegistryHelper.checkRegistryMenuExistsByMenuName(menuName);
  }
}
