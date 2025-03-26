import 'dart:math';

import 'package:vertree/main.dart';
import 'package:win32_registry/win32_registry.dart';

class RegistryHelper {
  /// 检查注册表项是否存在
  static bool checkRegistryKeyExists(RegistryHive hive, String path) {
    try {
      final key = Registry.openPath(hive, path: path, desiredAccessRights: AccessRights.readOnly);
      key.close();
      return true;
    } catch (e) {
      logger.error('检查注册表path: "$path" 失败: $e');
      return false;
    }
  }

  /// 检查注册表项是否存在
  static bool checkRegistryMenuExistsByMenuName(String menuName) {
    return checkRegistryKeyExists(RegistryHive.classesRoot, r'*\shell\' + menuName);
  }

  /// 通过注册表键名检查右键菜单项是否存在
  static bool checkRegistryMenuExistsByKey(String keyName) {
    return checkRegistryKeyExists(RegistryHive.classesRoot, r'*\shell\' + keyName);
  }

  /// 添加或更新注册表项
  static bool addOrUpdateRegistryKey(String path, String keyName, String value) {
    try {
      final key = Registry.openPath(RegistryHive.localMachine, path: path, desiredAccessRights: AccessRights.allAccess);
      key.createValue(RegistryValue.string(keyName, value));
      key.close();
      return true;
    } catch (e) {
      logger.error('添加或更新注册表项失败: $e');
      return false;
    }
  }

  /// 删除注册表项
  static bool deleteRegistryKey(String path, String keyName) {
    try {
      final key = Registry.openPath(RegistryHive.localMachine, path: path, desiredAccessRights: AccessRights.allAccess);
      key.deleteValue(keyName);
      key.close();
      return true;
    } catch (e) {
      logger.error('删除注册表项失败: $e');
      return false;
    }
  }

  /// 增加右键菜单项功能按钮（适用于选中文件），支持自定义图标
  static bool addContextMenuOption(String keyName, String muiVerb, String command, {String? iconPath}) {
    try {
      String registryPath = r'*\shell\' + keyName;
      String commandPath = '$registryPath\\command';

      logger.info('尝试创建右键菜单: registryPath="$registryPath", commandPath="$commandPath"');

      // 打开或创建 registryPath
      final shellKey = Registry.openPath(
        RegistryHive.classesRoot,
        path: r'*\shell',
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
        RegistryHive.classesRoot,
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
      logger.error('添加右键菜单失败: $e');
      return false;
    }
  }

  static bool removeContextMenuOptionByMenuName(String menuName) {
    try {
      String registryPath = r'*\shell\' + menuName;

      // 直接打开完整路径
      final key = Registry.openPath(
        RegistryHive.classesRoot,
        path: r'*\shell',
        desiredAccessRights: AccessRights.allAccess,
      );

      // 递归删除整个键
      key.deleteKey(menuName, recursive: true);
      key.close();

      logger.info('成功删除右键菜单项: $registryPath');
      return true;
    } catch (e) {
      logger.error('删除右键菜单失败: $e');
      return false;
    }
  }

  static bool removeContextMenuOptionByKey(String keyName) {
    try {
      final parentKey = Registry.openPath(
        RegistryHive.classesRoot,
        path: r'*\shell',
        desiredAccessRights: AccessRights.allAccess,
      );

      parentKey.deleteKey(keyName, recursive: true);
      parentKey.close();

      logger.info('成功通过键名 "$keyName" 删除右键菜单项');
      return true;
    } catch (e) {
      logger.error('通过键名 "$keyName" 删除右键菜单项失败: $e');
      return false;
    }
  }

  /// 启用开机自启
  static bool enableAutoStart(String runRegistryPath, String appName, String appPath) {
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: runRegistryPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.createValue(RegistryValue.string(appName, '"$appPath"')); // 必须加引号
      key.close();
      logger.info('成功设置应用 "$appName" 开机自启');
      return true;
    } catch (e) {
      logger.error('设置开机自启失败: $e');
      return false;
    }
  }

  /// 禁用开机自启
  static bool disableAutoStart(String runRegistryPath, String appName) {
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: runRegistryPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.deleteValue(appName);
      key.close();
      logger.info('成功移除应用 "$appName" 的开机自启');
      return true;
    } catch (e) {
      logger.error('移除开机自启失败: $e');
      return false;
    }
  }

  /// 检查应用是否已设置为开机自启
  static bool isAutoStartEnabled(String runRegistryPath, String appName) {
    try {
      final key = Registry.openPath(
        RegistryHive.currentUser,
        path: runRegistryPath,
        desiredAccessRights: AccessRights.readOnly,
      );
      final exists = key.getValue(appName) != null;
      key.close();
      return exists;
    } catch (e) {
      logger.error('检查开机自启状态失败: $e');
      return false;
    }
  }
}
