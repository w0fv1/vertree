import 'dart:io';

import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:vertree/platform/windows_registry_bridge.dart';

class PlatformIntegration {
  static const MethodChannel _autoStartChannel =
      MethodChannel('vertree/auto_start');
  static const MethodChannel _dockChannel = MethodChannel('vertree/dock');
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;

  static bool get supportsContextMenus => isWindows;
  static bool get supportsWin11Menu => isWindows;
  static bool get supportsAutoStart => isWindows || isMacOS;

  static Future<void> init() async {
    // No-op for now. macOS auto-start uses a native channel instead of
    // launch_at_startup, which doesn't register on macOS in this project.
  }

  static Future<void> reAddContextMenu() async {
    if (!isWindows) return;
    await WindowsRegistryBridge.reAddContextMenu();
  }

  static Future<bool> checkBackupKeyExists() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.checkBackupKeyExists();
  }

  static Future<bool> checkExpressBackupKeyExists() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.checkExpressBackupKeyExists();
  }

  static Future<bool> checkMonitorKeyExists() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.checkMonitorKeyExists();
  }

  static Future<bool> checkViewTreeKeyExists() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.checkViewTreeKeyExists();
  }

  static Future<bool> addBackupContextMenu() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.addBackupContextMenu();
  }

  static Future<bool> removeBackupContextMenu() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.removeBackupContextMenu();
  }

  static Future<bool> addExpressBackupContextMenu() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.addExpressBackupContextMenu();
  }

  static Future<bool> removeExpressBackupContextMenu() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.removeExpressBackupContextMenu();
  }

  static Future<bool> addMonitorContextMenu() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.addMonitorContextMenu();
  }

  static Future<bool> removeMonitorContextMenu() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.removeMonitorContextMenu();
  }

  static Future<bool> addViewTreeContextMenu() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.addViewTreeContextMenu();
  }

  static Future<bool> removeViewTreeContextMenu() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.removeViewTreeContextMenu();
  }

  static Future<void> applyLegacyMenus(bool enabled) async {
    if (!isWindows) return;
    await WindowsRegistryBridge.applyLegacyMenus(enabled);
  }

  static Future<bool> isAutoStartEnabled() async {
    if (isWindows) {
      return WindowsRegistryBridge.isAutoStartEnabled();
    }
    if (isMacOS) {
      return _invokeMacAutoStart('isEnabled');
    }
    return false;
  }

  static Future<bool> enableAutoStart() async {
    if (isWindows) {
      return WindowsRegistryBridge.enableAutoStart();
    }
    if (isMacOS) {
      return _invokeMacAutoStart('enable');
    }
    return false;
  }

  static Future<bool> disableAutoStart() async {
    if (isWindows) {
      return WindowsRegistryBridge.disableAutoStart();
    }
    if (isMacOS) {
      return _invokeMacAutoStart('disable');
    }
    return false;
  }

  static Future<bool> _invokeMacAutoStart(String method) async {
    try {
      final value = await _autoStartChannel.invokeMethod<bool>(method);
      return value ?? false;
    } on MissingPluginException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> refreshMacOSDockIcon() async {
    if (!isMacOS) return;
    try {
      await _dockChannel.invokeMethod<bool>('refresh');
    } on MissingPluginException {
      // Ignore: channel may not be ready during early startup.
    } catch (_) {
      // ignore
    }
  }

  static Future<bool> applyInitialSetup() async {
    if (isWindows) {
      return WindowsRegistryBridge.applyInitialSetup();
    }
    return true;
  }

  static Future<bool> isWin11PackagedOrRegistered() async {
    if (!isWindows) return false;
    return WindowsRegistryBridge.isWin11PackagedOrRegistered();
  }
}
