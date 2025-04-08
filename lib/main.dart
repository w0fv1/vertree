import 'dart:io';

import 'package:flutter/material.dart';

import 'package:toastification/toastification.dart';
import 'package:vertree/I18nLang.dart';
import 'package:vertree/MonitService.dart';
import 'package:vertree/component/AppLogger.dart';
import 'package:vertree/component/Configer.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/tray.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:vertree/view/page/MonitPage.dart';
import 'package:vertree/view/page/VersionTreePage.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

import 'AppVersionInfo.dart';

final logger = AppLogger(LogLevel.debug);
late void Function(Widget page) go;
late MonitService monitService;
Configer configer = Configer();

final AppLocale appLocale = AppLocale();

final appVersionInfo = AppVersionInfo(
  currentVersion: "V0.7.0", // 替换为你的实际当前版本
  releaseApiUrl: "https://api.github.com/repos/w0fv1/vertree/releases/latest", // 你的仓库 API URL
);


void main(List<String> args) async {
  await logger.init();
  await configer.init();

  monitService = MonitService();
  logger.info("启动参数: $args");

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();

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
          windowManager.hide();
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

    Tray().init();
    runApp(const MainPage());
    processArgs(args);
  } catch (e) {
    logger.error('Vertree启动失败: $e');
    exit(0);
  }
}

void processArgs(List<String> args) {
  if (args.length < 3) {
    windowManager.hide();
    return;
  }
  String action = args[1];
  String path = args.last;

  if (action == "--backup") {
    backup(path);
  } else if (action == "--express-backup") {
    expressBackup(path);
  } else if (action == "--monit") {
    monit(path);
  } else if (action == "--viewtree") {
    viewtree(path);
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
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white), fontFamily: 'Microsoft YaHei'),
        home: page,
      ),
    );
  }

  void goPage(Widget page) async {
    logger.info("goPage");

    await windowManager.show();
    await windowManager.focus();

    Future.delayed(Duration(milliseconds: 100), () {
      setState(() {
        this.page = Container();
        this.page = page;
      });
    });
  }

  @override
  void onWindowClose() async {
    bool? confirmExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(appLocale.getText(LocaleKey.app_confirmExitTitle)),
          content: Text(appLocale.getText(LocaleKey.app_confirmExitContent)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(appLocale.getText(LocaleKey.app_minimize)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(appLocale.getText(LocaleKey.app_exit)),
            ),
          ],
        );
      },
    );

    if (confirmExit == true) {
      await windowManager.destroy();
    } else {
      windowManager.minimize();
    }
  }
}

void expressBackup(String path) {
  logger.info(path);
  FileNode fileNode = FileNode(path);

  fileNode.safeBackup().then((Result<FileNode, String> result) async {
    if (result.isErr) {
      showWindowsNotification(appLocale.getText(LocaleKey.app_backupFailed), result.msg);
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
            title: Text(appLocale.getText(LocaleKey.app_enterLabelTitle).tr([fileNode.mate.name])),
            content: TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: appLocale.getText(LocaleKey.app_enterLabelHint)),
              onChanged: (value) {
                input = value;
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop('\$CANCEL_BACKUP');
                },
                child: Text(appLocale.getText(LocaleKey.app_cancelBackup), style: TextStyle(color: Colors.red)),
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
      showToast(appLocale.getText(LocaleKey.app_labelDialogError) + e.toString());
    }

    fileNode.safeBackup(label).then((Result<FileNode, String> result) async {
      if (result.isErr) {
        showWindowsNotification(appLocale.getText(LocaleKey.app_backupFailed), result.msg);
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
  monitService.addFileMonitTask(path).then((Result<FileMonitTask, String> fileMonitTaskResult) {
    if (fileMonitTaskResult.isErr) {
      showWindowsNotification(appLocale.getText(LocaleKey.app_monitFailedTitle), fileMonitTaskResult.msg);
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
  Future.delayed(const Duration(milliseconds: 500), () async {
    go(FileTreePage(key: UniqueKey(), path: path));
  });
}
