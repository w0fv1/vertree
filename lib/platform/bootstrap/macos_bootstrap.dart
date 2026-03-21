import 'package:vertree/platform/bootstrap/platform_bootstrap.dart';
import 'package:vertree/platform/macos/macos_service_bridge.dart';

class MacOSBootstrap extends PlatformBootstrap {
  const MacOSBootstrap();

  @override
  String get name => 'macos';

  @override
  bool get supportsDockTrayStartupOptimization => true;

  @override
  Future<void> setupPlatformChannels({
    required AsyncVoid ensureWindowVisible,
    required VoidCallback openSettings,
    required AppArgsProcessor processArgs,
    required AsyncActionPicker pickFileAndRunAction,
  }) async {
    MacOSServiceBridge.install(
      ensureWindowVisible: ensureWindowVisible,
      openSettings: openSettings,
      processArgs: processArgs,
      pickFileAndRunAction: pickFileAndRunAction,
    );
  }
}
