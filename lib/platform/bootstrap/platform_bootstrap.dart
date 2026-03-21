typedef AppArgsProcessor = void Function(List<String> args);
typedef SecondInstanceArgsHandler = void Function(List<String> args);
typedef AsyncActionPicker = Future<void> Function(String action);
typedef AsyncVoid = Future<void> Function();
typedef VoidCallback = void Function();

abstract class PlatformBootstrap {
  const PlatformBootstrap();

  String get name;
  bool get supportsDockTrayStartupOptimization => false;

  Future<bool> handlePreBootstrapArgs(List<String> args) async => false;

  Future<void> configureSingleInstance({
    required List<String> args,
    required SecondInstanceArgsHandler onSecondInstanceArgs,
  }) async {}

  Future<void> setupPlatformChannels({
    required AsyncVoid ensureWindowVisible,
    required VoidCallback openSettings,
    required AppArgsProcessor processArgs,
    required AsyncActionPicker pickFileAndRunAction,
  }) async {}
}
