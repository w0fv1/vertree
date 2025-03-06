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
    static bool checkRegistryMenuExists(String menuName) {

      return checkRegistryKeyExists(
          RegistryHive.classesRoot, r'*\shell\' + menuName);
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
    static bool addContextMenuOption(String menuName, String command, {String? iconPath}) {
      try {
        String registryPath = r'*\shell\' + menuName;
        String commandPath = '$registryPath\\command';

        logger.info('尝试创建右键菜单: registryPath="$registryPath", commandPath="$commandPath"');

        // 打开或创建 registryPath
        final shellKey = Registry.openPath(RegistryHive.classesRoot,
            path: r'*\shell', desiredAccessRights: AccessRights.allAccess);

        final menuKey = shellKey.createKey(menuName);
        menuKey.createValue(RegistryValue.string('', menuName));

        // 如果提供了 iconPath，则添加图标
        if (iconPath != null && iconPath.isNotEmpty) {
          menuKey.createValue(RegistryValue.string('Icon', iconPath));
          logger.info('已为 "$menuName" 设置图标: $iconPath');
        }

        menuKey.close();
        shellKey.close();

        logger.info('成功创建 registryPath: $registryPath');

        // 打开或创建 commandPath
        final menuCommandKey = Registry.openPath(RegistryHive.classesRoot,
            path: registryPath, desiredAccessRights: AccessRights.allAccess);
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


    static bool removeContextMenuOption(String menuName) {
      try {
        String registryPath = r'*\shell\' + menuName;

        // 直接打开完整路径
        final key = Registry.openPath(RegistryHive.classesRoot, path: r'*\shell', desiredAccessRights: AccessRights.allAccess);

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





  }
