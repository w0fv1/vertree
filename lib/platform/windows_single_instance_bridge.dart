import 'dart:io';

import 'package:windows_single_instance/windows_single_instance.dart'
    deferred as windows_single_instance;

class WindowsSingleInstanceBridge {
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    await windows_single_instance.loadLibrary();
    _loaded = true;
  }

  static Future<void> ensureSingleInstance(
    List<String> args,
    String id, {
    required void Function(List<String> args) onSecondWindow,
    required bool bringWindowToFront,
  }) async {
    if (!Platform.isWindows) return;
    await _ensureLoaded();
    await windows_single_instance.WindowsSingleInstance.ensureSingleInstance(
      args,
      id,
      onSecondWindow: onSecondWindow,
      bringWindowToFront: bringWindowToFront,
    );
  }
}
