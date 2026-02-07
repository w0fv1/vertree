import 'dart:io';

import 'package:flutter/material.dart';

import 'package:toastification/toastification.dart';
import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/core/MonitManager.dart';
import 'package:vertree/component/AppLogger.dart';
import 'package:vertree/component/Configer.dart';
import 'package:vertree/component/ElevatedTask.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/component/TrayManager.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:vertree/view/page/MonitPage.dart';
import 'package:vertree/view/page/VersionTreePage.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

import 'component/AppVersionInfo.dart';

final logger = AppLogger(LogLevel.debug);
late void Function(Widget page) go;
late MonitManager monitService;
Configer configer = Configer();

final AppLocale appLocale = AppLocale();

final appVersionInfo = AppVersionInfo(
  currentVersion: "V0.7.1", // 替换为你的实际当前版本
  releaseApiUrl:
      "https://api.github.com/repos/w0fv1/vertree/releases/latest", // 你的仓库 API URL
);

Future<void> fadeInWindow() async {
  const durationMs = 320;
  const frameTime = Duration(milliseconds: 16);
  final stopwatch = Stopwatch()..start();
  double lastOpacity = -1;

  while (stopwatch.elapsedMilliseconds < durationMs) {
    final t = stopwatch.elapsedMilliseconds / durationMs;
    final eased = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    if ((eased - lastOpacity).abs() > 0.002) {
      await windowManager.setOpacity(eased);
      lastOpacity = eased;
    }
    await Future.delayed(frameTime);
  }
  await windowManager.setOpacity(1);
}

void main(List<String> args) async {
  if (ElevatedTaskRunner.tryHandleElevatedTask(args)) {
    return;
  }

  await logger.init();
  await configer.init();

  monitService = MonitManager();
  logger.info("启动参数: $args");

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    await windowManager.setPreventClose(true);

    await WindowsSingleInstance.ensureSingleInstance(
      args,
      "w0fv1.dev.vertree",
      onSecondWindow: (args) {
        logger.info("onSecondWindow $args");
        processArgs(args);
      },
      bringWindowToFront: false,
    );
    await initLocalNotifier();

    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(600, 600),
        center: true,
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.hidden,
      ),
      () async {
        await windowManager.setOpacity(0);
        await windowManager.setSkipTaskbar(true);
        bool launch2Tray = configer.get("launch2Tray", true);
        bool isSetupDone = configer.get<bool>('isSetupDone', false);

        if (launch2Tray && isSetupDone) {
          await showWindowsNotificationWithTask(
            appLocale.getText(LocaleKey.app_trayNotificationTitle),
            appLocale.getText(LocaleKey.app_trayNotificationContent),
            () {
              go(BrandPage());
            },
          );
        }
        windowManager.hide();

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

    TrayManager().init();
    runApp(const MainPage());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      processArgs(args);
    });
  } catch (e) {
    logger.error('Vertree启动失败: $e');
    exit(0);
  }
}

void processArgs(List<String> args) {
  try {
    late String action;
    late String path;

    if (args.length == 3) {
      action = args[1];
      path = args.last;
    } else if (args.length == 2) {
      logger.error("传入参数似乎发生了问题，长度过短，临时兜底方案继续进行处理：$args");
      action = args.first;
      path = args.last;
    } else {
      logger.info("不需要处理的参数：$args");
      windowManager.hide();
      return;
    }

    // 增加action是否合法，path是否存在的检查
    final allowedActions = [
      "--backup",
      "--express-backup",
      "--monit",
      "--viewtree",
    ];
    if (!allowedActions.contains(action)) {
      logger.error("传入的 action 不合法: $action，允许的 action 为: $allowedActions");
      return;
    }
    final entity = FileSystemEntity.typeSync(path);
    if (entity == FileSystemEntityType.notFound) {
      logger.error("传入的 path 不存在: $path");
      showWindowsNotification("发生错误", "传入的 path 不存在: $path");
      return;
    }
    if (entity == FileSystemEntityType.directory) {
      logger.error("传入的 path 是一个文件夹，不对文件夹进行处理: $path");
      return;
    }

    if (action == "--backup") {
      backup(path);
    } else if (action == "--express-backup") {
      expressBackup(path);
    } else if (action == "--monit") {
      monit(path);
    } else if (action == "--viewtree") {
      viewtree(path);
    }
  } catch (e) {
    logger.error('Vertree处理参数失败: $e');
    return;
  }
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
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Vertree维树',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
          fontFamily: 'Microsoft YaHei',
        ),
        home: page,
      ),
    );
  }

  void goPage(Widget page) async {
    logger.info("goPage");

    if (!mounted) return;

    setState(() {
      this.page = page;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await windowManager.setOpacity(0);
      await windowManager.setSkipTaskbar(true);
      await windowManager.show();
      await windowManager.focus();
      await fadeInWindow();
    });
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
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

    String? label;

    try {
      label = await showDialog<String>(
        context: navigatorKey.currentState!.overlay!.context,
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
      logger.error("创建询问label失败：${e}");
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
        context: navigatorKey.currentState!.overlay!.context,
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
