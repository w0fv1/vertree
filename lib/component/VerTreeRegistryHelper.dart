import 'dart:io';
import 'package:vertree/component/ElevatedTask.dart';
import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/main.dart';

import '../utils/WindowsRegistryUtil.dart';
import 'package:path/path.dart' as path;

class VerTreeRegistryService {
  static const String registry_backupKeyName = "RegistryVerTreeBackup";
  static const String registry_expressBackupKeyName =
      "RegistryVerTreeExpressBackup";
  static const String registry_monitorKeyName = "RegistryVerTreeMonitor";
  static const String registry_viewTreeKeyName = "RegistryVerTreeViewTree";

  static const String appName = "VerTree"; // 应用名称

  static const String runRegistryPath =
      r'Software\Microsoft\Windows\CurrentVersion\Run';

  static String exePath = Platform.resolvedExecutable;

  static bool _retryWithElevation({
    required String actionName,
    required bool success,
    required bool allowElevation,
    required String operation,
    Map<String, dynamic>? payload,
  }) {
    if (success || !allowElevation) {
      return success;
    }

    logger.info('$actionName 普通权限失败，尝试请求管理员权限...');
    final elevatedSuccess = ElevatedTaskRunner.runTaskSync(
      operation,
      payload: payload,
    );
    if (elevatedSuccess) {
      logger.info('$actionName 提权执行成功');
    } else {
      logger.error(
        '$actionName 提权执行失败: ${ElevatedTaskRunner.lastError ?? "unknown error"}',
      );
    }
    return elevatedSuccess;
  }

  static void reAddContextMenu() {
    if (checkBackupKeyExists()) {
      RegistryHelper.removeContextMenuOptionByKey(registry_backupKeyName);
      addVerTreeBackupContextMenu();
    }

    if (checkMonitorKeyExists()) {
      RegistryHelper.removeContextMenuOptionByKey(registry_monitorKeyName);
      addVerTreeMonitorContextMenu();
    }

    if (checkViewTreeKeyExists()) {
      RegistryHelper.removeContextMenuOptionByKey(registry_viewTreeKeyName);
      addVerTreeViewContextMenu();
    }

    if (checkExpressBackupKeyExists()) {
      RegistryHelper.removeContextMenuOptionByKey(
        registry_expressBackupKeyName,
      );
      addVerTreeExpressBackupContextMenu();
    }
  }

  static bool addVerTreeBackupContextMenu({bool allowElevation = true}) {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(
      FileUtils.appDirPath(),
      'data',
      'flutter_assets',
      'assets',
      'img',
      'icon',
      'save.ico',
    );
    final menuText = appLocale.getText(LocaleKey.registry_backupKeyName);
    final command = '"$exePath" --backup "%1"';

    bool success = RegistryHelper.addContextMenuOption(
      registry_backupKeyName,
      menuText,
      command,
      iconPath: iconPath,
    );

    success = _retryWithElevation(
      actionName: '添加右键菜单[Backup]',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opAddContextMenu,
      payload: {
        'keyName': registry_backupKeyName,
        'menuText': menuText,
        'command': command,
        'iconPath': iconPath,
      },
    );

    return success;
  }

  static bool addVerTreeMonitorContextMenu({bool allowElevation = true}) {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(
      FileUtils.appDirPath(),
      'data',
      'flutter_assets',
      'assets',
      'img',
      'icon',
      'monit.ico',
    );
    final menuText = appLocale.getText(LocaleKey.registry_monitorKeyName);
    final command = '"$exePath" --monit "%1"';

    bool success = RegistryHelper.addContextMenuOption(
      registry_monitorKeyName,
      menuText,
      command,
      iconPath: iconPath,
    );

    success = _retryWithElevation(
      actionName: '添加右键菜单[Monitor]',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opAddContextMenu,
      payload: {
        'keyName': registry_monitorKeyName,
        'menuText': menuText,
        'command': command,
        'iconPath': iconPath,
      },
    );

    return success;
  }

  static bool addVerTreeViewContextMenu({bool allowElevation = true}) {
    final exePath = Platform.resolvedExecutable;
    final iconPath = path.join(
      FileUtils.appDirPath(),
      'data',
      'flutter_assets',
      'assets',
      'img',
      'logo',
      'logo.ico',
    );
    final menuText = appLocale.getText(LocaleKey.registry_viewTreeKeyName);
    final command = '"$exePath" --viewtree "%1"';

    bool success = RegistryHelper.addContextMenuOption(
      registry_viewTreeKeyName,
      menuText,
      command,
      iconPath: iconPath,
    );

    success = _retryWithElevation(
      actionName: '添加右键菜单[ViewTree]',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opAddContextMenu,
      payload: {
        'keyName': registry_viewTreeKeyName,
        'menuText': menuText,
        'command': command,
        'iconPath': iconPath,
      },
    );

    return success;
  }

  static bool addVerTreeExpressBackupContextMenu({bool allowElevation = true}) {
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
    final menuText = appLocale.getText(LocaleKey.registry_expressBackupKeyName);
    final command = '"$exePath" --express-backup "%1"';

    bool success = RegistryHelper.addContextMenuOption(
      registry_expressBackupKeyName,
      menuText,
      command,
      iconPath: iconPath,
    );

    success = _retryWithElevation(
      actionName: '添加右键菜单[ExpressBackup]',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opAddContextMenu,
      payload: {
        'keyName': registry_expressBackupKeyName,
        'menuText': menuText,
        'command': command,
        'iconPath': iconPath,
      },
    );

    return success;
  }

  static bool removeVerTreeExpressBackupContextMenu({
    bool allowElevation = true,
  }) {
    bool success = RegistryHelper.removeContextMenuOptionByKey(
      registry_expressBackupKeyName,
    );
    success = _retryWithElevation(
      actionName: '移除右键菜单[ExpressBackup]',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opRemoveContextMenuByKey,
      payload: {'keyName': registry_expressBackupKeyName},
    );
    return success;
  }

  static bool removeVerTreeViewContextMenu({bool allowElevation = true}) {
    bool success = RegistryHelper.removeContextMenuOptionByKey(
      registry_viewTreeKeyName,
    );
    success = _retryWithElevation(
      actionName: '移除右键菜单[ViewTree]',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opRemoveContextMenuByKey,
      payload: {'keyName': registry_viewTreeKeyName},
    );
    return success;
  }

  static bool removeVerTreeMonitorContextMenu({bool allowElevation = true}) {
    bool success = RegistryHelper.removeContextMenuOptionByKey(
      registry_monitorKeyName,
    );
    success = _retryWithElevation(
      actionName: '移除右键菜单[Monitor]',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opRemoveContextMenuByKey,
      payload: {'keyName': registry_monitorKeyName},
    );
    return success;
  }

  static bool removeVerTreeBackupContextMenu({bool allowElevation = true}) {
    bool success = RegistryHelper.removeContextMenuOptionByKey(
      registry_backupKeyName,
    );
    success = _retryWithElevation(
      actionName: '移除右键菜单[Backup]',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opRemoveContextMenuByKey,
      payload: {'keyName': registry_backupKeyName},
    );
    return success;
  }

  static bool checkBackupKeyExists() {
    return RegistryHelper.checkRegistryMenuExistsByKey(registry_backupKeyName);
  }

  static bool checkExpressBackupKeyExists() {
    return RegistryHelper.checkRegistryMenuExistsByKey(
      registry_expressBackupKeyName,
    );
  }

  static bool checkMonitorKeyExists() {
    return RegistryHelper.checkRegistryMenuExistsByKey(registry_monitorKeyName);
  }

  static bool checkViewTreeKeyExists() {
    return RegistryHelper.checkRegistryMenuExistsByKey(
      registry_viewTreeKeyName,
    );
  }

  // 开机自启相关
  static bool enableAutoStart({bool allowElevation = true}) {
    bool success = RegistryHelper.enableAutoStart(
      runRegistryPath,
      appName,
      exePath,
    );
    success = _retryWithElevation(
      actionName: '启用开机自启',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opEnableAutoStart,
      payload: {
        'runRegistryPath': runRegistryPath,
        'appName': appName,
        'appPath': exePath,
      },
    );
    return success;
  }

  static bool disableAutoStart({bool allowElevation = true}) {
    bool success = RegistryHelper.disableAutoStart(runRegistryPath, appName);
    success = _retryWithElevation(
      actionName: '禁用开机自启',
      success: success,
      allowElevation: allowElevation,
      operation: ElevatedTaskRunner.opDisableAutoStart,
      payload: {'runRegistryPath': runRegistryPath, 'appName': appName},
    );
    return success;
  }

  static bool isAutoStartEnabled() {
    return RegistryHelper.isAutoStartEnabled(runRegistryPath, appName);
  }

  static bool applyInitialSetup() {
    final entries = [
      _contextMenuPayload(
        registry_backupKeyName,
        appLocale.getText(LocaleKey.registry_backupKeyName),
        '"$exePath" --backup "%1"',
        _iconPath('save.ico'),
      ),
      _contextMenuPayload(
        registry_monitorKeyName,
        appLocale.getText(LocaleKey.registry_monitorKeyName),
        '"$exePath" --monit "%1"',
        _iconPath('monit.ico'),
      ),
      _contextMenuPayload(
        registry_viewTreeKeyName,
        appLocale.getText(LocaleKey.registry_viewTreeKeyName),
        '"$exePath" --viewtree "%1"',
        _iconPath('logo.ico', isLogo: true),
      ),
      _contextMenuPayload(
        registry_expressBackupKeyName,
        appLocale.getText(LocaleKey.registry_expressBackupKeyName),
        '"$exePath" --express-backup "%1"',
        _iconPath('express-save.ico'),
      ),
    ];

    bool success = true;
    for (final entry in entries) {
      success =
          RegistryHelper.addContextMenuOption(
            entry['keyName']!,
            entry['menuText']!,
            entry['command']!,
            iconPath: entry['iconPath'],
          ) &&
          success;
    }

    success =
        RegistryHelper.enableAutoStart(runRegistryPath, appName, exePath) &&
        success;

    if (success) {
      return true;
    }

    logger.info('初始化普通权限失败，尝试一次性提权配置...');
    final elevatedSuccess = ElevatedTaskRunner.runTaskSync(
      ElevatedTaskRunner.opApplySetup,
      payload: {
        'contextMenus': entries,
        'autostart': {
          'enable': true,
          'runRegistryPath': runRegistryPath,
          'appName': appName,
          'appPath': exePath,
        },
      },
    );

    if (elevatedSuccess) {
      logger.info('初始化提权执行成功');
    } else {
      logger.error(
        '初始化提权执行失败: ${ElevatedTaskRunner.lastError ?? "unknown error"}',
      );
    }
    return elevatedSuccess;
  }

  static Map<String, String?> _contextMenuPayload(
    String keyName,
    String menuText,
    String command,
    String? iconPath,
  ) {
    return {
      'keyName': keyName,
      'menuText': menuText,
      'command': command,
      'iconPath': iconPath,
    };
  }

  static String _iconPath(String fileName, {bool isLogo = false}) {
    return path.join(
      FileUtils.appDirPath(),
      'data',
      'flutter_assets',
      'assets',
      'img',
      isLogo ? 'logo' : 'icon',
      fileName,
    );
  }

  static const String backupMenuName = "备份文件 VerTree";
  static const String expressBackupMenuName = "快速备份文件 VerTree";
  static const String monitorMenuName = "监控文件变动 VerTree";
  static const String viewTreeMenuName = "查看文件版本树 VerTree"; // 新增菜单项名称
  static bool clearObsoleteRegistry() {
    bool success = true;

    if (checkContextMenuExists(backupMenuName)) {
      success &= RegistryHelper.removeContextMenuOptionByMenuName(
        backupMenuName,
      );
    }

    if (checkContextMenuExists(monitorMenuName)) {
      success &= RegistryHelper.removeContextMenuOptionByMenuName(
        monitorMenuName,
      );
    }

    if (checkContextMenuExists(viewTreeMenuName)) {
      success &= RegistryHelper.removeContextMenuOptionByMenuName(
        viewTreeMenuName,
      );
    }

    if (checkContextMenuExists(expressBackupMenuName)) {
      success &= RegistryHelper.removeContextMenuOptionByMenuName(
        expressBackupMenuName,
      );
    }

    return success;
  }

  /// 通用检查方法：根据菜单名称判断注册表项是否存在
  static bool checkContextMenuExists(String menuName) {
    return RegistryHelper.checkRegistryMenuExistsByMenuName(menuName);
  }
}
