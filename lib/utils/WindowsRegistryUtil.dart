import 'package:vertree/main.dart';
import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

import 'WindowsShellNotify.dart';

class RegistryHelper {
  static const String allUsersClassesShellPath = r'Software\Classes\*\shell';
  static const String allUsersClassesRootPath = r'Software\Classes';
  static const String approvedShellExtPath =
      r'Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved';
  static const int _hrFileNotFound = 0x80070002;
  static const int _hrPathNotFound = 0x80070003;
  static const int _hrAccessDenied = 0x80070005;

  static int _normalizeHr(int hr) => hr & 0xFFFFFFFF;

  static bool _isKeyMissingError(Object error) {
    if (error is WindowsException) {
      final hr = _normalizeHr(error.hr);
      return hr == _hrFileNotFound || hr == _hrPathNotFound;
    }
    return false;
  }

  static bool _isAccessDeniedError(Object error) {
    if (error is WindowsException) {
      return _normalizeHr(error.hr) == _hrAccessDenied;
    }
    return false;
  }

  /// 检查注册表项是否存在
  static bool checkRegistryKeyExists(RegistryHive hive, String path) {
    try {
      final key = Registry.openPath(
        hive,
        path: path,
        desiredAccessRights: AccessRights.readOnly,
      );
      key.close();
      return true;
    } catch (e) {
      if (_isKeyMissingError(e)) {
        return false;
      }
      logger.error('检查注册表path: "$path" 失败: $e');
      return false;
    }
  }

  /// 检查注册表项是否存在
  static bool checkRegistryMenuExistsByMenuName(String menuName) {
    return checkRegistryKeyExists(
      RegistryHive.localMachine,
      '$allUsersClassesShellPath\\$menuName',
    );
  }

  /// 通过注册表键名检查右键菜单项是否存在
  static bool checkRegistryMenuExistsByKey(String keyName) {
    return checkRegistryKeyExists(
      RegistryHive.localMachine,
      '$allUsersClassesShellPath\\$keyName',
    );
  }

  /// 添加或更新注册表项
  static bool addOrUpdateRegistryKey(
    String path,
    String keyName,
    String value,
  ) {
    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: path,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.createValue(RegistryValue.string(keyName, value));
      key.close();
      return true;
    } catch (e) {
      if (_isAccessDeniedError(e)) {
        return false;
      }
      logger.error('添加或更新注册表项失败: $e');
      return false;
    }
  }

  /// 删除注册表项
  static bool deleteRegistryKey(String path, String keyName) {
    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: path,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.deleteValue(keyName);
      key.close();
      return true;
    } catch (e) {
      if (_isAccessDeniedError(e)) {
        return false;
      }
      logger.error('删除注册表项失败: $e');
      return false;
    }
  }

  /// 增加右键菜单项功能按钮（适用于选中文件），支持自定义图标
  static bool addContextMenuOption(
    String keyName,
    String muiVerb,
    String command, {
    String? iconPath,
  }) {
    try {
      String registryPath = '$allUsersClassesShellPath\\$keyName';
      String commandPath = '$registryPath\\command';

      logger.info(
        '尝试创建右键菜单: registryPath="$registryPath", commandPath="$commandPath"',
      );

      // 打开或创建 registryPath
      final shellKey = Registry.openPath(
        RegistryHive.localMachine,
        path: allUsersClassesShellPath,
        desiredAccessRights: AccessRights.allAccess,
      );

      final menuKey = shellKey.createKey(keyName);
      // 使用 MUIVerb 来设置显示名称
      menuKey.createValue(RegistryValue.string('MUIVerb', muiVerb));

      // 如果提供了 iconPath，则添加图标
      if (iconPath != null && iconPath.isNotEmpty) {
        menuKey.createValue(RegistryValue.string('Icon', iconPath));
        logger.info('已为 "$keyName" 设置图标: $iconPath');
      }

      menuKey.close();
      shellKey.close();

      logger.info('成功创建 registryPath: $registryPath');

      // 打开或创建 commandPath
      final menuCommandKey = Registry.openPath(
        RegistryHive.localMachine,
        path: registryPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      final commandKey = menuCommandKey.createKey('command');
      commandKey.createValue(RegistryValue.string('', command));
      commandKey.close();
      menuCommandKey.close();

      logger.info('成功创建 commandPath: $commandPath -> $command');

      return true;
    } catch (e) {
      if (_isAccessDeniedError(e)) {
        return false;
      }
      logger.error('添加右键菜单失败: $e');
      return false;
    }
  }

  static bool removeContextMenuOptionByMenuName(String menuName) {
    try {
      String registryPath = '$allUsersClassesShellPath\\$menuName';

      // 直接打开完整路径
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: allUsersClassesShellPath,
        desiredAccessRights: AccessRights.allAccess,
      );

      // 递归删除整个键
      key.deleteKey(menuName, recursive: true);
      key.close();

      logger.info('成功删除右键菜单项: $registryPath');
      return true;
    } catch (e) {
      if (_isAccessDeniedError(e) || _isKeyMissingError(e)) {
        return false;
      }
      logger.error('删除右键菜单失败: $e');
      return false;
    }
  }

  static bool removeContextMenuOptionByKey(String keyName) {
    try {
      final parentKey = Registry.openPath(
        RegistryHive.localMachine,
        path: allUsersClassesShellPath,
        desiredAccessRights: AccessRights.allAccess,
      );

      parentKey.deleteKey(keyName, recursive: true);
      parentKey.close();

      logger.info('成功通过键名 "$keyName" 删除右键菜单项');
      return true;
    } catch (e) {
      if (_isAccessDeniedError(e) || _isKeyMissingError(e)) {
        return false;
      }
      logger.error('通过键名 "$keyName" 删除右键菜单项失败: $e');
      return false;
    }
  }

  /// 启用开机自启
  static bool enableAutoStart(
    String runRegistryPath,
    String appName,
    String appPath,
  ) {
    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: runRegistryPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.createValue(RegistryValue.string(appName, '"$appPath"')); // 必须加引号
      key.close();
      logger.info('成功设置应用 "$appName" 开机自启');
      return true;
    } catch (e) {
      if (_isAccessDeniedError(e)) {
        return false;
      }
      logger.error('设置开机自启失败: $e');
      return false;
    }
  }

  /// 禁用开机自启
  static bool disableAutoStart(String runRegistryPath, String appName) {
    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: runRegistryPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.deleteValue(appName);
      key.close();
      logger.info('成功移除应用 "$appName" 的开机自启');
      return true;
    } catch (e) {
      if (_isAccessDeniedError(e) || _isKeyMissingError(e)) {
        return false;
      }
      logger.error('移除开机自启失败: $e');
      return false;
    }
  }

  /// 检查应用是否已设置为开机自启
  static bool isAutoStartEnabled(String runRegistryPath, String appName) {
    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: runRegistryPath,
        desiredAccessRights: AccessRights.readOnly,
      );
      final exists = key.getValue(appName) != null;
      key.close();
      return exists;
    } catch (e) {
      if (_isAccessDeniedError(e) || _isKeyMissingError(e)) {
        return false;
      }
      logger.error('检查开机自启状态失败: $e');
      return false;
    }
  }

  static bool addWin11ContextMenuHandler(
    String handlerName,
    String clsid,
    String serverPath,
  ) {
    try {
      // COM server registration (LocalServer32).
      final approvedKey = Registry.openPath(
        RegistryHive.localMachine,
        path: approvedShellExtPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      approvedKey.createValue(RegistryValue.string(clsid, handlerName));
      approvedKey.close();

      final clsidRoot = Registry.openPath(
        RegistryHive.localMachine,
        path: '$allUsersClassesRootPath\\CLSID',
        desiredAccessRights: AccessRights.allAccess,
      );
      final clsidKey = clsidRoot.createKey(clsid);
      final serverKey = clsidKey.createKey('LocalServer32');
      serverKey.createValue(RegistryValue.string('', '"$serverPath"'));
      serverKey.close();
      clsidKey.close();
      clsidRoot.close();

      // Win11 context menu uses `ExplorerCommandHandler` verbs (not `ContextMenuHandlers`).
      //
      // We still clean up the obsolete registration in case it exists from previous versions.
      try {
        final legacyHandlerKey = Registry.openPath(
          RegistryHive.localMachine,
          path: '$allUsersClassesRootPath\\*\\shellex\\ContextMenuHandlers',
          desiredAccessRights: AccessRights.allAccess,
        );
        legacyHandlerKey.deleteKey(handlerName, recursive: true);
        legacyHandlerKey.close();
      } catch (e) {
        if (!_isKeyMissingError(e) && !_isAccessDeniedError(e)) {
          logger.error('清理旧 Win11 handler 失败: $e');
        }
      }

      final shellKey = Registry.openPath(
        RegistryHive.localMachine,
        path: '$allUsersClassesRootPath\\*\\shell',
        desiredAccessRights: AccessRights.allAccess,
      );
      final menuKey = shellKey.createKey(handlerName);
      menuKey.createValue(RegistryValue.string('MUIVerb', handlerName));
      menuKey.createValue(RegistryValue.string('ExplorerCommandHandler', clsid));
      menuKey.close();
      shellKey.close();

      WindowsShellNotify.associationsChanged();
      return true;
    } catch (e) {
      if (_isAccessDeniedError(e)) {
        return false;
      }
      logger.error('添加 Win11 右键菜单处理器失败: $e');
      return false;
    }
  }

  static bool removeWin11ContextMenuHandler(String handlerName, String clsid) {
    try {
      bool accessDenied = false;

      try {
        final approvedKey = Registry.openPath(
          RegistryHive.localMachine,
          path: approvedShellExtPath,
          desiredAccessRights: AccessRights.allAccess,
        );
        approvedKey.deleteValue(clsid);
        approvedKey.close();
      } catch (e) {
        if (_isAccessDeniedError(e)) {
          accessDenied = true;
        } else if (!_isKeyMissingError(e)) {
          logger.error('移除 Approved 项失败: $e');
        }
      }

      try {
        final shellKey = Registry.openPath(
          RegistryHive.localMachine,
          path: '$allUsersClassesRootPath\\*\\shell',
          desiredAccessRights: AccessRights.allAccess,
        );
        shellKey.deleteKey(handlerName, recursive: true);
        shellKey.close();
      } catch (e) {
        if (_isAccessDeniedError(e)) {
          accessDenied = true;
        } else if (!_isKeyMissingError(e)) {
          logger.error('移除 Win11 shell verb 失败: $e');
        }
      }

      // Clean up obsolete legacy handler registration if present.
      try {
        final legacyHandlerKey = Registry.openPath(
          RegistryHive.localMachine,
          path: '$allUsersClassesRootPath\\*\\shellex\\ContextMenuHandlers',
          desiredAccessRights: AccessRights.allAccess,
        );
        legacyHandlerKey.deleteKey(handlerName, recursive: true);
        legacyHandlerKey.close();
      } catch (e) {
        if (_isAccessDeniedError(e)) {
          accessDenied = true;
        } else if (!_isKeyMissingError(e)) {
          logger.error('移除旧 Win11 handler 失败: $e');
        }
      }

      try {
        final clsidKey = Registry.openPath(
          RegistryHive.localMachine,
          path: '$allUsersClassesRootPath\\CLSID',
          desiredAccessRights: AccessRights.allAccess,
        );
        clsidKey.deleteKey(clsid, recursive: true);
        clsidKey.close();
      } catch (e) {
        if (_isAccessDeniedError(e)) {
          accessDenied = true;
        } else if (!_isKeyMissingError(e)) {
          logger.error('移除 CLSID 注册失败: $e');
        }
      }

      if (accessDenied) {
        return false;
      }

      WindowsShellNotify.associationsChanged();
      return true;
    } catch (e) {
      if (_isAccessDeniedError(e)) {
        return false;
      }
      logger.error('移除 Win11 右键菜单处理器失败: $e');
      return false;
    }
  }

  static bool checkWin11ContextMenuHandler(String handlerName, String clsid) {
    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: '$allUsersClassesRootPath\\*\\shell\\$handlerName',
        desiredAccessRights: AccessRights.readOnly,
      );
      final value = key.getValue('ExplorerCommandHandler');
      key.close();
      final commandHandler = switch (value) {
        StringValue(:final value) => value,
        UnexpandedStringValue(:final value) => value,
        LinkValue(:final value) => value,
        _ => null,
      };
      if (commandHandler != null) {
        return commandHandler.toLowerCase() == clsid.toLowerCase();
      }
      return false;
    } catch (e) {
      if (_isKeyMissingError(e)) {
        return false;
      }
      logger.error('检查 Win11 右键菜单处理器失败: $e');
      return false;
    }
  }
}
