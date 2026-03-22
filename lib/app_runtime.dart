import 'dart:io';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:toastification/toastification.dart';
import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/core/MonitManager.dart';
import 'package:vertree/api/LocalHttpApiServer.dart';
import 'package:vertree/component/AppLogger.dart';
import 'package:vertree/component/Configer.dart';
import 'package:vertree/component/LaunchCounter.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/component/app_command_handler.dart';
import 'package:vertree/component/app_window_controller.dart';
import 'package:vertree/component/TrayManager.dart';
import 'package:vertree/platform/bootstrap/platform_bootstrap.dart';
import 'package:vertree/platform/platform_integration.dart';
import 'package:vertree/service/LocalHttpApiService.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:vertree/view/page/MonitPage.dart';
import 'package:vertree/view/page/SettingPage.dart';
import 'package:vertree/view/page/VersionTreePage.dart';
import 'package:window_manager/window_manager.dart';

import 'component/AppVersionInfo.dart';

final logger = AppLogger(LogLevel.debug);
late void Function(Widget page) go;
late MonitManager monitService;
late LocalHttpApiServer localHttpApiServer;
Configer configer = Configer();
late final AppCommandHandler appCommandHandler;
late final AppWindowController appWindowController;

final AppLocale appLocale = AppLocale();

final appVersionInfo = AppVersionInfo(
  currentVersion: "V0.10.0-alpha3",
  releaseApiUrl:
      "https://api.github.com/repos/w0fv1/vertree/releases/latest", // 你的仓库 API URL
);

ThemeData _applyDesktopInteractionTheme(ThemeData theme) {
  final clickCursor = WidgetStateProperty.resolveWith<MouseCursor?>(
    (states) => states.contains(WidgetState.disabled)
        ? SystemMouseCursors.basic
        : SystemMouseCursors.click,
  );

  return theme.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style:
          theme.filledButtonTheme.style?.copyWith(mouseCursor: clickCursor) ??
          ButtonStyle(mouseCursor: clickCursor),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          theme.textButtonTheme.style?.copyWith(mouseCursor: clickCursor) ??
          ButtonStyle(mouseCursor: clickCursor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          theme.elevatedButtonTheme.style?.copyWith(mouseCursor: clickCursor) ??
          ButtonStyle(mouseCursor: clickCursor),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          theme.outlinedButtonTheme.style?.copyWith(mouseCursor: clickCursor) ??
          ButtonStyle(mouseCursor: clickCursor),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style:
          theme.segmentedButtonTheme.style?.copyWith(
            mouseCursor: clickCursor,
          ) ??
          ButtonStyle(mouseCursor: clickCursor),
    ),
    iconButtonTheme: IconButtonThemeData(
      style:
          theme.iconButtonTheme.style?.copyWith(mouseCursor: clickCursor) ??
          ButtonStyle(mouseCursor: clickCursor),
    ),
    floatingActionButtonTheme: theme.floatingActionButtonTheme.copyWith(
      mouseCursor: clickCursor,
    ),
    switchTheme: theme.switchTheme.copyWith(mouseCursor: clickCursor),
    checkboxTheme: theme.checkboxTheme.copyWith(mouseCursor: clickCursor),
    radioTheme: theme.radioTheme.copyWith(mouseCursor: clickCursor),
    popupMenuTheme: theme.popupMenuTheme.copyWith(mouseCursor: clickCursor),
  );
}

ThemeData _buildTheme({
  required Brightness brightness,
  required Color seedColor,
  required Color scaffoldBackgroundColor,
}) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ),
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    fontFamily: Platform.isMacOS ? 'SF Pro Text' : 'Microsoft YaHei',
    useMaterial3: true,
  );
  final scheme = base.colorScheme;

  return _applyDesktopInteractionTheme(
    base.copyWith(
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(
          scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        menuPadding: const EdgeInsets.symmetric(vertical: 8),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: base.listTileTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
  );
}

/// 统一定义全局明暗主题，默认跟随系统。
ThemeData _buildLightTheme() {
  return _buildTheme(
    brightness: Brightness.light,
    seedColor: const Color(0xFF2E7D32),
    scaffoldBackgroundColor: const Color(0xFFF5F6F2),
  );
}

ThemeData _buildDarkTheme() {
  return _buildTheme(
    brightness: Brightness.dark,
    seedColor: const Color(0xFF81C784),
    scaffoldBackgroundColor: const Color(0xFF111311),
  );
}

/// 主题配置枚举：跟随系统 / 浅色 / 深色。
enum AppThemeSetting { system, light, dark }

/// 当前主题配置（不等同于实际 ThemeMode，因为 system 需要交给 Flutter 处理）。
AppThemeSetting currentThemeSetting = AppThemeSetting.system;

/// 全局主题监听器：用于在运行时切换主题并刷新整个应用。
late ValueNotifier<ThemeMode> themeModeNotifier;

AppThemeSetting _parseThemeSetting(String value) {
  switch (value) {
    case 'light':
      return AppThemeSetting.light;
    case 'dark':
      return AppThemeSetting.dark;
    case 'system':
    default:
      return AppThemeSetting.system;
  }
}

String _themeSettingToString(AppThemeSetting setting) {
  switch (setting) {
    case AppThemeSetting.light:
      return 'light';
    case AppThemeSetting.dark:
      return 'dark';
    case AppThemeSetting.system:
      return 'system';
  }
}

ThemeMode _themeModeFromSetting(AppThemeSetting setting) {
  switch (setting) {
    case AppThemeSetting.light:
      return ThemeMode.light;
    case AppThemeSetting.dark:
      return ThemeMode.dark;
    case AppThemeSetting.system:
      return ThemeMode.system;
  }
}

bool get defaultLaunchToTray => !Platform.isLinux;

/// 从配置初始化主题（在 main 中调用，runApp 之前）。
void initThemeFromConfig() {
  final stored = configer.get<String>('themeMode', 'system');
  currentThemeSetting = _parseThemeSetting(stored);
  themeModeNotifier = ValueNotifier<ThemeMode>(
    _themeModeFromSetting(currentThemeSetting),
  );
}

/// 修改主题设置并持久化，同时刷新全局 ThemeMode。
void updateThemeSetting(AppThemeSetting setting) {
  currentThemeSetting = setting;
  configer.set<String>('themeMode', _themeSettingToString(setting));
  // system 由 Flutter 自行选择明暗，light/dark 强制指定。
  themeModeNotifier.value = _themeModeFromSetting(setting);
}

/// 在「浅色」与「深色」之间切换（当配置为跟随系统时，此方法不生效）。
void toggleLightDarkTheme() {
  if (currentThemeSetting == AppThemeSetting.system) {
    return;
  }
  final next = currentThemeSetting == AppThemeSetting.light
      ? AppThemeSetting.dark
      : AppThemeSetting.light;
  updateThemeSetting(next);
}

Future<void> showMainWindow({Widget? page, bool animate = true}) async {
  await appWindowController.showMainWindow(page: page, animate: animate);
}

Future<void> hideMainWindowToTray() async {
  await appWindowController.hideMainWindowToTray();
}

bool _isQuittingApplication = false;

Future<void> quitApplication() async {
  if (_isQuittingApplication) {
    return;
  }
  _isQuittingApplication = true;
  try {
    await windowManager.setPreventClose(false);
  } catch (_) {
    // ignore
  }
  try {
    await windowManager.destroy();
    return;
  } catch (_) {
    // ignore
  }
  exit(0);
}

Future<void> toggleMainWindowVisibility({Widget? page}) async {
  await appWindowController.toggleMainWindowVisibility(page: page);
}

bool _isNonActionableSecondArgs(List<String> args) {
  return args.isEmpty || !appCommandHandler.isActionable(args);
}

Future<void> _bringExistingWindowToFront() async {
  await showMainWindow(animate: false);
}

void _handleSecondInstance(List<String> args) {
  logger.info("onSecondWindow $args");
  unawaited(() async {
    await _bringExistingWindowToFront();

    if (_isNonActionableSecondArgs(args)) {
      // Double-clicking the app should always surface the UI.
      go(BrandPage());
      return;
    }

    processArgs(args);
  }());
}

Future<void> runVertreeApp(
  PlatformBootstrap bootstrap,
  List<String> args,
) async {
  if (await bootstrap.handlePreBootstrapArgs(args)) {
    return;
  }

  await logger.init();
  await configer.init();
  initThemeFromConfig();
  await PlatformIntegration.init();
  logger.info('Platform bootstrap: ${bootstrap.name}');
  appCommandHandler = AppCommandHandler(
    onBackup: backup,
    onExpressBackup: expressBackup,
    onMonit: monit,
    onViewTree: viewtree,
    onNotify: showWindowsNotification,
    onLogInfo: logger.info,
    onLogError: logger.error,
  );
  appWindowController = AppWindowController(
    onShowPage: (page) => go(page),
    onLogError: logger.error,
    onRefreshDockIcon: PlatformIntegration.refreshMacOSDockIcon,
    onRefreshTray: TrayManager().refreshTray,
  );

  monitService = MonitManager();
  localHttpApiServer = LocalHttpApiServer(
    apiService: LocalHttpApiService(
      configer: configer,
      monitManager: monitService,
      currentVersion: appVersionInfo.currentVersion,
      startedAt: DateTime.now(),
      currentPortResolver: () => localHttpApiServer.port,
    ),
  );
  logger.info("启动参数: $args");

  try {
    final bool launch2Tray = configer.get("launch2Tray", defaultLaunchToTray);
    final bool isSetupDone = configer.get<bool>('isSetupDone', false);
    final bool isGnomeWithoutTray =
        PlatformIntegration.isLinuxGnome &&
        !PlatformIntegration.supportsTrayOnlyBackgroundMode;
    final bool canLaunchToTray =
        PlatformIntegration.supportsTrayOnlyBackgroundMode;
    final bool shouldLaunchToTray =
        launch2Tray && isSetupDone && canLaunchToTray;

    WidgetsFlutterBinding.ensureInitialized();
    await bootstrap.setupPlatformChannels(
      ensureWindowVisible: _ensureWindowVisible,
      openSettings: () => go(SettingPage()),
      processArgs: processArgs,
      pickFileAndRunAction: _pickFileAndRunAction,
    );
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);

    // On macOS, `setSkipTaskbar(true)` switches activationPolicy to `.accessory`.
    // Doing it early avoids a brief Dock icon flash during long startup work.
    if (bootstrap.supportsDockTrayStartupOptimization && shouldLaunchToTray) {
      try {
        await windowManager.setSkipTaskbar(true);
      } catch (_) {
        // ignore
      }
    }

    await bootstrap.configureSingleInstance(
      args: args,
      onSecondInstanceArgs: _handleSecondInstance,
    );
    await initLocalNotifier();
    try {
      await localHttpApiServer.syncWithConfig();
    } catch (e) {
      logger.error('Local HTTP API startup failed: $e');
    }

    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(600, 600),
        center: true,
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.hidden,
      ),
      () async {
        await windowManager.setOpacity(0.92);

        if (shouldLaunchToTray) {
          await showWindowsNotificationWithTask(
            appLocale.getText(LocaleKey.app_trayNotificationTitle),
            appLocale.getText(LocaleKey.app_trayNotificationContent),
            () {
              go(BrandPage());
            },
          );
          await hideMainWindowToTray();
        } else {
          if (launch2Tray && isSetupDone && !canLaunchToTray) {
            logger.info('当前 Linux GNOME 未启用托盘支持，改为显示主窗口');
          }
          await showMainWindow(animate: true);
          if (isGnomeWithoutTray && launch2Tray && isSetupDone) {
            showToast(
              appLocale.getText(LocaleKey.setting_launchToTraySetupHint),
            );
          }
        }

        Future.delayed(Duration(milliseconds: 2500), () async {
          monitService.startAll().then((_) async {
            if (monitService.runningTaskCount == 0) {
              logger.info("Vertree没有需要监控的文件");
              return;
            }
            await showWindowsNotificationWithTask(
              appLocale.getText(LocaleKey.app_monitStartedTitle),
              appLocale.getText(LocaleKey.app_monitStartedContent),
              () {
                go(MonitPage());
              },
            );
          });
        });
      },
    );
    String appPath = Platform.resolvedExecutable;
    logger.info("Current app path: $appPath");

    await TrayManager().init();
    runApp(const MainPage());
    LaunchCounter.trackLaunchIfNeeded(configer: configer, logger: logger);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      processArgs(args);
    });
  } catch (e) {
    logger.error('Vertree启动失败: $e');
    exit(0);
  }
}

Future<void> _ensureWindowVisible() async {
  await showMainWindow(animate: true);
}

Future<void> _pickFileAndRunAction(String action) async {
  await _ensureWindowVisible();
  final result = await FilePicker.platform.pickFiles();
  final path = result?.files.single.path;
  if (path == null || path.isEmpty) return;
  processArgs(['--menu', action, path]);
}

void processArgs(List<String> args) {
  appCommandHandler.process(args);
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WindowListener {
  Widget page = BrandPage();

  @override
  void initState() {
    super.initState();
    go = goPage;
    windowManager.addListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: appLocale.getText(LocaleKey.app_title),
            themeMode: themeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: page,
          );
        },
      ),
    );
  }

  void goPage(Widget page) async {
    logger.info("goPage");

    if (!mounted) return;

    setState(() {
      this.page = page;
    });
  }

  @override
  void onWindowClose() async {
    await quitApplication();
  }

  @override
  void onWindowMinimize() {
    unawaited(TrayManager().refreshTray());
  }

  @override
  void onWindowRestore() {
    unawaited(TrayManager().refreshTray());
  }

  @override
  void onWindowFocus() {
    unawaited(TrayManager().refreshTray());
  }

  @override
  void onWindowBlur() {
    unawaited(TrayManager().refreshTray());
  }
}

void expressBackup(String path) {
  logger.info(path);
  FileNode fileNode = FileNode(path);

  fileNode.safeBackup().then((Result<FileNode, String> result) async {
    if (result.isErr) {
      showWindowsNotification(
        appLocale.getText(LocaleKey.app_backupFailed),
        result.msg,
      );
      return;
    }
    FileNode backup = result.unwrap();
    showWindowsNotificationWithFile(
      appLocale.getText(LocaleKey.app_backupSuccessTitle),
      appLocale.getText(LocaleKey.app_backupSuccessContent),
      backup.mate.fullPath,
    );
  });
}

void backup(String path) {
  logger.info(path);
  FileNode fileNode = FileNode(path);

  Future.delayed(const Duration(milliseconds: 500), () async {
    await windowManager.show();
    await windowManager.focus();
    final overlayContext = navigatorKey.currentState?.overlay?.context;
    if (overlayContext == null) return;

    String? label;

    try {
      label = await showDialog<String>(
        context: overlayContext,
        builder: (context) {
          String input = "";
          return AlertDialog(
            title: Text(
              appLocale.getText(LocaleKey.app_enterLabelTitle).tr([
                fileNode.mate.name,
              ]),
            ),
            content: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: appLocale.getText(LocaleKey.app_enterLabelHint),
              ),
              onChanged: (value) {
                input = value;
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop('\$CANCEL_BACKUP');
                },
                child: Text(
                  appLocale.getText(LocaleKey.app_cancelBackup),
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(input);
                },
                child: Text(appLocale.getText(LocaleKey.app_confirm)),
              ),
            ],
          );
        },
      );
      if (label == '\$CANCEL_BACKUP') {
        showWindowsNotification(
          appLocale.getText(LocaleKey.app_cancelNotificationTitle),
          appLocale.getText(LocaleKey.app_cancelNotificationContent),
        );
        logger.info("用户取消了文件 ${fileNode.mate.fullPath} 的备份");
        return;
      }
    } catch (e) {
      logger.error("创建询问label失败：$e");
      showToast(
        appLocale.getText(LocaleKey.app_labelDialogError) + e.toString(),
      );
    }

    fileNode.safeBackup(label).then((Result<FileNode, String> result) async {
      if (result.isErr) {
        showWindowsNotification(
          appLocale.getText(LocaleKey.app_backupFailed),
          result.msg,
        );
        return;
      }
      FileNode backup = result.unwrap();
      showWindowsNotificationWithFile(
        appLocale.getText(LocaleKey.app_backupSuccessTitle),
        appLocale.getText(LocaleKey.app_backupSuccessContent),
        backup.mate.fullPath,
      );

      bool? enableMonit = await showDialog<bool>(
        context: overlayContext,
        builder: (context) {
          return AlertDialog(
            title: Text(appLocale.getText(LocaleKey.app_enableMonitTitle)),
            content: Text(appLocale.getText(LocaleKey.app_enableMonitContent)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(appLocale.getText(LocaleKey.app_no)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(appLocale.getText(LocaleKey.app_yes)),
              ),
            ],
          );
        },
      );
      if (enableMonit == true) {
        monit(backup.mate.fullPath);
      }

      viewtree(backup.mate.fullPath);
    });
  });
}

void monit(String path) {
  logger.info(path);
  monitService.addFileMonitTask(path).then((
    Result<FileMonitTask, String> fileMonitTaskResult,
  ) {
    if (fileMonitTaskResult.isErr) {
      showWindowsNotification(
        appLocale.getText(LocaleKey.app_monitFailedTitle),
        fileMonitTaskResult.msg,
      );
      return;
    }
    FileMonitTask fileMonitTask = fileMonitTaskResult.unwrap();
    if (fileMonitTask.backupDirPath != null) {
      showWindowsNotificationWithFolder(
        appLocale.getText(LocaleKey.app_monitSuccessTitle),
        appLocale.getText(LocaleKey.app_monitSuccessContent),
        fileMonitTask.backupDirPath!,
      );
    }
  });
}

void viewtree(String path) {
  logger.info(path);
  go(FileTreePage(key: UniqueKey(), path: path));
}
