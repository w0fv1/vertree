import 'dart:io';

import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:vertree/MonitService.dart';
import 'package:vertree/VerTreeRegistryService.dart';
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

final logger = AppLogger(LogLevel.debug);
late void Function(Widget page) go;
late MonitService monitService;
Configer configer  = Configer();
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
    await initLocalNotifier(); // 确保通知系统已初始化
    await showWindowsNotification("Vertree运行中", "树状文件版本管理🌲");

    // 隐藏窗口
    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(600, 600),
        center: true,
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.hidden,
      ),
      () async {
        Future.delayed(Duration(milliseconds: 1500), () async {
          // await windowManager.hide(); // 启动时隐藏窗口

          monitService.startAll().then((_) async {
            if (monitService.runningTaskCount == 0) {
              logger.info("Vertree没有需要监控的文件");
              return;
            }
            await showWindowsNotificationWithTask(
              "Vertree开始监控 ${monitService.runningTaskCount} 个文件",
              "点击查看监控任务",
              (_) {
                go(MonitPage());
              },
            );

            return;
          });
        });
      },
    );
    String appPath = Platform.resolvedExecutable;
    logger.info("Current app path: $appPath");

    Tray().init();
    runApp(const MainPage()); // 运行设置页面
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
    logger.info(path);
    FileNode fileNode = FileNode(path);
    fileNode.safeBackup().then((Result<FileNode, String> result) {
      if (result.isErr) {
        showWindowsNotification("Vertree备份文件失败，", result.msg);
        return;
      }
      FileNode backup = result.unwrap();

      showWindowsNotificationWithFile("Vertree已备份文件，", "点击我打开新文件", backup.mate.fullPath);
    });
  } else if (action == "--monitor") {
    logger.info(path);
    monitService.addFileMonitTask(path).then((Result<FileMonitTask, String> fileMonitTaskResult) {
      if (fileMonitTaskResult.isErr) {
        showWindowsNotification("Vertree监控失败，", fileMonitTaskResult.msg);
        return;
      }
      FileMonitTask fileMonitTask = fileMonitTaskResult.unwrap();
      if(fileMonitTask.backupDirPath != null){
        showWindowsNotificationWithFolder("Vertree以开始监控文件，", "点击我打开备份目录", fileMonitTask.backupDirPath!);
      }

    });
  } else if (action == "--viewtree") {
    logger.info(path);
    go(FileTreePage(path: path));
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  Widget page = BrandPage();

  @override
  void initState() {
    super.initState();
    go = goPage;

  }

  @override
  Widget build(BuildContext context) {

    return ToastificationWrapper(
      child: MaterialApp(
        title: 'Vertree维树',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)),
        home: page,
      ),
    );
  }

  void goPage(Widget page) async {
    await windowManager.show(); // 显示窗口
    setState(() {
      this.page = page;
    });
  }

}
