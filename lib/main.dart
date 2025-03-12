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
Configer configer = Configer();

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

    // 隐藏窗口
    windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(600, 600),
        center: true,
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.hidden,
      ),
      () async {
        bool launch2Tray = configer.get("launch2Tray", true);
        if (launch2Tray) {
          await showWindowsNotificationWithTask("Vertree最小化运行中", "树状文件版本管理🌲", () {
            go(BrandPage());
          });
          windowManager.hide();
        }

        Future.delayed(Duration(milliseconds: 2500), () async {
          // await windowManager.hide(); // 启动时隐藏窗口

          monitService.startAll().then((_) async {
            if (monitService.runningTaskCount == 0) {
              logger.info("Vertree没有需要监控的文件");
              return;
            }
            await showWindowsNotificationWithTask("Vertree开始监控 ${monitService.runningTaskCount} 个文件", "点击查看监控任务", () {
              go(MonitPage());
            });

            return;
          });
        });
      },
    );
    String appPath = Platform.resolvedExecutable;
    logger.info("Current app path: $appPath");

    Tray().init();
    runApp(const MainPage()); // 运行设置页面
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

    await windowManager.show(); // 显示窗口
    await windowManager.focus();

    logger.info("goPage");
    Future.delayed(Duration(milliseconds: 500), () {
      logger.info("setState");
      setState(() {
        this.page = BrandPage();
      });
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
          title: Text("确认退出"),
          content: Text("确定要退出应用吗？"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // 取消关闭
              },
              child: Text("最小化"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // 允许关闭
              },
              child: Text("退出"),
            ),
          ],
        );
      },
    );

    if (confirmExit == true) {
      await windowManager.destroy(); // 允许应用关闭
    } else {
      windowManager.minimize(); // 取消关闭并最小化
    }
  }
}

void backup(String path) {
  logger.info(path);
  FileNode fileNode = FileNode(path);

  // 先延迟一段时间，确保 UI 已经渲染并且 navigatorKey.currentContext 有效
  Future.delayed(const Duration(milliseconds: 500), () async {
    await windowManager.show(); // 显示窗口
    await windowManager.focus(); // 让窗口获取焦点

    // 弹出输入备注对话框
    String? label;

    try {
      label = await showDialog<String>(
        context: navigatorKey.currentState!.overlay!.context,
        builder: (context) {
          String input = "";
          return AlertDialog(
            title: Text("请输入备份 ${fileNode.mate.name} 的备注/原因（可选）"),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: "备注信息（可选）"),
              onChanged: (value) {
                input = value;
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop('\$CANCEL_BACKUP'); // 取消备份
                },
                child: const Text("取消备份", style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null); // 无备注，直接备份
                },
                child: const Text("无备注，直接备份"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(input); // 用户输入备注
                },
                child: const Text("确定"),
              ),
            ],
          );
        },
      );
      // 处理用户取消的情况
      if (label == '\$CANCEL_BACKUP') {
        showWindowsNotification("Vertree 备份已取消", "用户取消了备份操作");
        logger.info("用户取消了文件 ${fileNode.mate.fullPath} 的备份");
        return;
      }
    } catch (e) {
      logger.error("创建询问label失败：${e}");
      showToast("创建询问label失败：${e}");
    }

    // 调用 safeBackup，同时传入用户输入的 label（可能为 null）
    fileNode.safeBackup(label).then((Result<FileNode, String> result) async {
      if (result.isErr) {
        showWindowsNotification("Vertree 备份文件失败", result.msg);
        return;
      }
      FileNode backup = result.unwrap();
      showWindowsNotificationWithFile("Vertree 已备份文件", "点击我打开新文件", backup.mate.fullPath);

      // 备份成功后，询问是否开启对新版本的监控
      bool? enableMonit = await showDialog<bool>(
        context: navigatorKey.currentState!.overlay!.context,
        builder: (context) {
          return AlertDialog(
            title: const Text("开启监控？"),
            content: const Text("是否对备份的新版本进行监控？"),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("否")),
              TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("是")),
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
      showWindowsNotification("Vertree监控失败，", fileMonitTaskResult.msg);
      return;
    }
    FileMonitTask fileMonitTask = fileMonitTaskResult.unwrap();
    if (fileMonitTask.backupDirPath != null) {
      showWindowsNotificationWithFolder("Vertree以开始监控文件，", "点击我打开备份目录", fileMonitTask.backupDirPath!);
    }
  });
}

void viewtree(String path) {
  logger.info(path);
  Future.delayed(const Duration(milliseconds: 500), () async {
    go(FileTreePage(key: UniqueKey(), path: path));
  });
}
