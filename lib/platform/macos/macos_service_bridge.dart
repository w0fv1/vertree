import 'package:flutter/services.dart';
import 'package:vertree/platform/bootstrap/platform_bootstrap.dart';

class MacOSServiceBridge {
  static const MethodChannel _channel = MethodChannel('vertree/service');
  static const Set<String> _allowedActions = {
    'backup',
    'express-backup',
    'monit',
    'monitor',
    'share',
    'viewtree',
  };

  static void install({
    required AsyncVoid ensureWindowVisible,
    required VoidCallback openSettings,
    required AppArgsProcessor processArgs,
    required AsyncActionPicker pickFileAndRunAction,
  }) {
    _channel.setMethodCallHandler((call) async {
      final raw = call.arguments;
      if (raw is! Map) return;
      final action = raw['action']?.toString();
      if (action == null || action.isEmpty) return;

      if (call.method == 'serviceAction') {
        final path = raw['path']?.toString();
        if (path == null || path.isEmpty) return;
        processArgs(['--service', action, path]);
        return;
      }

      if (call.method != 'menuAction') return;
      if (action == 'openSettings') {
        await ensureWindowVisible();
        openSettings();
        return;
      }
      if (!_allowedActions.contains(action)) return;
      await pickFileAndRunAction(action);
    });
  }
}
