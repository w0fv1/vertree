import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:vertree/utils/WindowsShellNotify.dart';
import 'package:win32/win32.dart';
import 'package:win32_registry/win32_registry.dart';

class ElevatedTaskRunner {
  static const int _seeMaskNoCloseProcess = 0x00000040;
  static String? lastError;
  static const String taskArg = '--elevated-task';
  static const String payloadArg = '--payload';

  static const String opAddContextMenu = 'add_context_menu';
  static const String opRemoveContextMenuByKey = 'remove_context_menu_key';
  static const String opRemoveContextMenuByMenuName =
      'remove_context_menu_name';
  static const String opEnableAutoStart = 'enable_autostart';
  static const String opDisableAutoStart = 'disable_autostart';
  static const String opApplySetup = 'apply_setup';
  static const String opAddWin11Menu = 'add_win11_menu';
  static const String opRemoveWin11Menu = 'remove_win11_menu';
  static const String opRemoveLegacyMenus = 'remove_legacy_menus';

  static const String _classesShellPath = r'Software\Classes\*\shell';

  static bool tryHandleElevatedTask(List<String> args) {
    final operation = _readOptionValue(args, taskArg);
    if (operation == null) {
      return false;
    }

    if (!Platform.isWindows) {
      exit(1);
    }

    final payload = _readPayload(args);
    final success = _executeOperation(operation, payload);
    exit(success ? 0 : 1);
  }

  static bool runTaskSync(String operation, {Map<String, dynamic>? payload}) {
    lastError = null;
    if (!Platform.isWindows) {
      lastError = 'Not running on Windows.';
      return false;
    }

    try {
      final executablePath = Platform.resolvedExecutable;
      final encodedPayload = base64UrlEncode(
        utf8.encode(jsonEncode(payload ?? const <String, dynamic>{})),
      );
      final elevatedArgs = <String>[
        taskArg,
        operation,
        payloadArg,
        encodedPayload,
      ];
      return _runElevated(executablePath, elevatedArgs);
    } catch (_) {
      lastError = 'Unexpected error while launching elevated task.';
      return false;
    }
  }

  static bool _runElevated(String executablePath, List<String> args) {
    final verbPtr = 'runas'.toNativeUtf16();
    final filePtr = executablePath.toNativeUtf16();
    final parameters = args.map(_quoteWindowsArg).join(' ');
    final parametersPtr = parameters.toNativeUtf16();
    final shellInfo = calloc<SHELLEXECUTEINFO>();
    final exitCodePtr = calloc<Uint32>();

    try {
      shellInfo.ref.cbSize = sizeOf<SHELLEXECUTEINFO>();
      shellInfo.ref.fMask = _seeMaskNoCloseProcess;
      shellInfo.ref.lpVerb = verbPtr;
      shellInfo.ref.lpFile = filePtr;
      shellInfo.ref.lpParameters = parametersPtr;
      shellInfo.ref.nShow = SW_SHOWNORMAL;

      final launched = ShellExecuteEx(shellInfo) != FALSE;
      if (!launched) {
        lastError = 'ShellExecuteEx failed. Win32Error=${GetLastError()}';
        return false;
      }

      final processHandle = shellInfo.ref.hProcess;
      if (processHandle == NULL || processHandle == 0) {
        lastError = 'Elevated process handle is null.';
        return false;
      }

      WaitForSingleObject(processHandle, INFINITE);
      final gotExitCode =
          GetExitCodeProcess(processHandle, exitCodePtr) != FALSE;
      CloseHandle(processHandle);

      if (!gotExitCode) {
        lastError = 'GetExitCodeProcess failed. Win32Error=${GetLastError()}';
        return false;
      }
      if (exitCodePtr.value != 0) {
        lastError = 'Elevated task exited with code ${exitCodePtr.value}.';
        return false;
      }
      return true;
    } finally {
      calloc.free(exitCodePtr);
      calloc.free(shellInfo);
      calloc.free(parametersPtr);
      calloc.free(filePtr);
      calloc.free(verbPtr);
    }
  }

  static String? _readOptionValue(List<String> args, String optionName) {
    final optionIndex = args.indexOf(optionName);
    if (optionIndex == -1 || optionIndex + 1 >= args.length) {
      return null;
    }
    return args[optionIndex + 1];
  }

  static Map<String, dynamic> _readPayload(List<String> args) {
    final rawPayload = _readOptionValue(args, payloadArg);
    if (rawPayload == null || rawPayload.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final normalized = base64Url.normalize(rawPayload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map<String, dynamic>) {
        return json;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  static bool _executeOperation(
    String operation,
    Map<String, dynamic> payload,
  ) {
    switch (operation) {
      case opAddContextMenu:
        return _addContextMenu(payload);
      case opRemoveContextMenuByKey:
        return _removeContextMenuByKey(payload);
      case opRemoveContextMenuByMenuName:
        return _removeContextMenuByMenuName(payload);
      case opEnableAutoStart:
        return _enableAutoStart(payload);
      case opDisableAutoStart:
        return _disableAutoStart(payload);
      case opApplySetup:
        return _applySetup(payload);
      case opAddWin11Menu:
        return _addWin11Menu(payload);
      case opRemoveWin11Menu:
        return _removeWin11Menu(payload);
      case opRemoveLegacyMenus:
        return _removeLegacyMenus(payload);
      default:
        return false;
    }
  }

  static bool _addContextMenu(Map<String, dynamic> payload) {
    final keyName = _asNonEmptyString(payload['keyName']);
    final menuText = _asNonEmptyString(payload['menuText']);
    final command = _asNonEmptyString(payload['command']);
    final iconPath = _asString(payload['iconPath']);

    if (keyName == null || menuText == null || command == null) {
      return false;
    }

    try {
      final shellKey = Registry.openPath(
        RegistryHive.localMachine,
        path: _classesShellPath,
        desiredAccessRights: AccessRights.allAccess,
      );

      final menuKey = shellKey.createKey(keyName);
      menuKey.createValue(RegistryValue.string('MUIVerb', menuText));
      if (iconPath != null && iconPath.isNotEmpty) {
        menuKey.createValue(RegistryValue.string('Icon', iconPath));
      }
      menuKey.close();
      shellKey.close();

      final menuCommandKey = Registry.openPath(
        RegistryHive.localMachine,
        path: '$_classesShellPath\\$keyName',
        desiredAccessRights: AccessRights.allAccess,
      );
      final commandKey = menuCommandKey.createKey('command');
      commandKey.createValue(RegistryValue.string('', command));
      commandKey.close();
      menuCommandKey.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _removeContextMenuByKey(Map<String, dynamic> payload) {
    final keyName = _asNonEmptyString(payload['keyName']);
    if (keyName == null) {
      return false;
    }

    try {
      final shellKey = Registry.openPath(
        RegistryHive.localMachine,
        path: _classesShellPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      shellKey.deleteKey(keyName, recursive: true);
      shellKey.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _removeContextMenuByMenuName(Map<String, dynamic> payload) {
    final menuName = _asNonEmptyString(payload['menuName']);
    if (menuName == null) {
      return false;
    }

    try {
      final shellKey = Registry.openPath(
        RegistryHive.localMachine,
        path: _classesShellPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      shellKey.deleteKey(menuName, recursive: true);
      shellKey.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _enableAutoStart(Map<String, dynamic> payload) {
    final registryPath = _asNonEmptyString(payload['runRegistryPath']);
    final appName = _asNonEmptyString(payload['appName']);
    final appPath = _asNonEmptyString(payload['appPath']);
    if (registryPath == null || appName == null || appPath == null) {
      return false;
    }

    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: registryPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.createValue(RegistryValue.string(appName, '"$appPath"'));
      key.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _disableAutoStart(Map<String, dynamic> payload) {
    final registryPath = _asNonEmptyString(payload['runRegistryPath']);
    final appName = _asNonEmptyString(payload['appName']);
    if (registryPath == null || appName == null) {
      return false;
    }

    try {
      final key = Registry.openPath(
        RegistryHive.localMachine,
        path: registryPath,
        desiredAccessRights: AccessRights.allAccess,
      );
      key.deleteValue(appName);
      key.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _applySetup(Map<String, dynamic> payload) {
    final contextMenus = payload['contextMenus'];
    final autostart = payload['autostart'];
    final win11Menu = payload['win11Menu'];
    if (contextMenus is! List) {
      return false;
    }

    bool success = true;
    for (final entry in contextMenus) {
      if (entry is! Map) {
        success = false;
        continue;
      }
      final keyName = _asNonEmptyString(entry['keyName']);
      final menuText = _asNonEmptyString(entry['menuText']);
      final command = _asNonEmptyString(entry['command']);
      final iconPath = _asString(entry['iconPath']);
      if (keyName == null || menuText == null || command == null) {
        success = false;
        continue;
      }

      success =
          _addContextMenu({
            'keyName': keyName,
            'menuText': menuText,
            'command': command,
            'iconPath': iconPath,
          }) &&
          success;
    }

    if (autostart is Map) {
      final enable = autostart['enable'] == true;
      if (enable) {
        success =
            _enableAutoStart(autostart.cast<String, dynamic>()) && success;
      } else if (autostart['disable'] == true) {
        success =
            _disableAutoStart(autostart.cast<String, dynamic>()) && success;
      }
    }

    if (win11Menu is Map) {
      success = _addWin11Menu(win11Menu.cast<String, dynamic>()) && success;
    }

    return success;
  }

  static bool _removeLegacyMenus(Map<String, dynamic> payload) {
    final keys = payload['keys'];
    if (keys is! List) {
      return false;
    }
    bool success = true;
    for (final entry in keys) {
      if (entry is! String || entry.isEmpty) {
        success = false;
        continue;
      }
      success = _removeContextMenuByKey({'keyName': entry}) && success;
    }
    return success;
  }

  static bool _addWin11Menu(Map<String, dynamic> payload) {
    final handlerName = _asNonEmptyString(payload['handlerName']);
    final clsid = _asNonEmptyString(payload['clsid']);
    final serverPath = _asNonEmptyString(payload['serverPath']);
    if (handlerName == null || clsid == null || serverPath == null) {
      return false;
    }
    try {
      final approvedKey = Registry.openPath(
        RegistryHive.localMachine,
        path:
            r'Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved',
        desiredAccessRights: AccessRights.allAccess,
      );
      approvedKey.createValue(RegistryValue.string(clsid, handlerName));
      approvedKey.close();

      final classesRoot = Registry.openPath(
        RegistryHive.localMachine,
        path: r'Software\Classes\CLSID',
        desiredAccessRights: AccessRights.allAccess,
      );
      final clsidKey = classesRoot.createKey(clsid);
      try {
        clsidKey.deleteKey('LocalServer32', recursive: true);
      } catch (_) {}

      final serverKey = clsidKey.createKey('InprocServer32');
      serverKey.createValue(RegistryValue.string('', '"$serverPath"'));
      serverKey.createValue(RegistryValue.string('ThreadingModel', 'Apartment'));
      serverKey.close();
      clsidKey.close();
      classesRoot.close();

      // Win11 context menu uses `ExplorerCommandHandler` verbs (not `ContextMenuHandlers`).
      // Clean up obsolete handler registration from older versions.
      try {
        final legacyHandlerKey = Registry.openPath(
          RegistryHive.localMachine,
          path: r'Software\Classes\*\shellex\ContextMenuHandlers',
          desiredAccessRights: AccessRights.allAccess,
        );
        legacyHandlerKey.deleteKey(handlerName, recursive: true);
        legacyHandlerKey.close();
      } catch (_) {}

      final shellKey = Registry.openPath(
        RegistryHive.localMachine,
        path: r'Software\Classes\*\shell',
        desiredAccessRights: AccessRights.allAccess,
      );
      final menuKey = shellKey.createKey(handlerName);
      menuKey.createValue(RegistryValue.string('MUIVerb', handlerName));
      menuKey.createValue(RegistryValue.string('ExplorerCommandHandler', clsid));
      menuKey.close();
      shellKey.close();

      WindowsShellNotify.associationsChanged();
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _removeWin11Menu(Map<String, dynamic> payload) {
    final handlerName = _asNonEmptyString(payload['handlerName']);
    final clsid = _asNonEmptyString(payload['clsid']);
    if (handlerName == null || clsid == null) {
      return false;
    }
    try {
      try {
        final approvedKey = Registry.openPath(
          RegistryHive.localMachine,
          path:
              r'Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved',
          desiredAccessRights: AccessRights.allAccess,
        );
        approvedKey.deleteValue(clsid);
        approvedKey.close();
      } catch (_) {}

      try {
        final shellKey = Registry.openPath(
          RegistryHive.localMachine,
          path: r'Software\Classes\*\shell',
          desiredAccessRights: AccessRights.allAccess,
        );
        shellKey.deleteKey(handlerName, recursive: true);
        shellKey.close();
      } catch (_) {}

      // Clean up obsolete legacy handler registration if present.
      try {
        final legacyHandlerKey = Registry.openPath(
          RegistryHive.localMachine,
          path: r'Software\Classes\*\shellex\ContextMenuHandlers',
          desiredAccessRights: AccessRights.allAccess,
        );
        legacyHandlerKey.deleteKey(handlerName, recursive: true);
        legacyHandlerKey.close();
      } catch (_) {}

      try {
        final clsidKey = Registry.openPath(
          RegistryHive.localMachine,
          path: r'Software\Classes\CLSID',
          desiredAccessRights: AccessRights.allAccess,
        );
        clsidKey.deleteKey(clsid, recursive: true);
        clsidKey.close();
      } catch (_) {}

      WindowsShellNotify.associationsChanged();
      return true;
    } catch (_) {
      return false;
    }
  }

  static String? _asString(Object? value) {
    if (value is String) {
      return value;
    }
    return null;
  }

  static String? _asNonEmptyString(Object? value) {
    final text = _asString(value);
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  static String _quoteWindowsArg(String value) {
    if (value.isEmpty) {
      return '""';
    }
    final escaped = value.replaceAll('"', r'\"');
    if (escaped.contains(' ') ||
        escaped.contains('\t') ||
        escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }
}
