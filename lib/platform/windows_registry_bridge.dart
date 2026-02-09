import 'dart:io';

import 'package:vertree/component/ElevatedTask.dart' deferred as elevated_task;
import 'package:vertree/component/VerTreeRegistryHelper.dart' deferred as registry;
import 'package:vertree/utils/WindowsPackageIdentity.dart' deferred as package_identity;

class WindowsRegistryBridge {
  static bool _loaded = false;
  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await elevated_task.loadLibrary();
    await registry.loadLibrary();
    await package_identity.loadLibrary();
    _loaded = true;
  }

  static Future<bool> tryHandleElevatedTask(List<String> args) async {
    if (!Platform.isWindows) return false;
    await elevated_task.loadLibrary();
    return elevated_task.ElevatedTaskRunner.tryHandleElevatedTask(args);
  }

  static Future<void> reAddContextMenu() async {
    if (!Platform.isWindows) return;
    await _ensureLoaded();
    registry.VerTreeRegistryService.reAddContextMenu();
  }

  static Future<bool> checkBackupKeyExists() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.checkBackupKeyExists();
  }

  static Future<bool> checkExpressBackupKeyExists() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.checkExpressBackupKeyExists();
  }

  static Future<bool> checkMonitorKeyExists() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.checkMonitorKeyExists();
  }

  static Future<bool> checkViewTreeKeyExists() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.checkViewTreeKeyExists();
  }

  static Future<bool> addBackupContextMenu() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.addVerTreeBackupContextMenu();
  }

  static Future<bool> removeBackupContextMenu() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.removeVerTreeBackupContextMenu();
  }

  static Future<bool> addExpressBackupContextMenu() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.addVerTreeExpressBackupContextMenu();
  }

  static Future<bool> removeExpressBackupContextMenu() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.removeVerTreeExpressBackupContextMenu();
  }

  static Future<bool> addMonitorContextMenu() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.addVerTreeMonitorContextMenu();
  }

  static Future<bool> removeMonitorContextMenu() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.removeVerTreeMonitorContextMenu();
  }

  static Future<bool> addViewTreeContextMenu() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.addVerTreeViewContextMenu();
  }

  static Future<bool> removeViewTreeContextMenu() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.removeVerTreeViewContextMenu();
  }

  static Future<bool> enableAutoStart() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.enableAutoStart();
  }

  static Future<bool> disableAutoStart() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.disableAutoStart();
  }

  static Future<bool> isAutoStartEnabled() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.isAutoStartEnabled();
  }

  static Future<void> applyLegacyMenus(bool enabled) async {
    if (!Platform.isWindows) return;
    await _ensureLoaded();
    registry.VerTreeRegistryService.applyLegacyMenus(enabled);
  }

  static Future<bool> applyInitialSetup() async {
    if (!Platform.isWindows) return true;
    await _ensureLoaded();
    return registry.VerTreeRegistryService.applyInitialSetup();
  }

  static Future<bool> isWin11PackagedOrRegistered() async {
    if (!Platform.isWindows) return false;
    await _ensureLoaded();
    return package_identity.WindowsPackageIdentity.isPackagedOrRegistered();
  }
}
