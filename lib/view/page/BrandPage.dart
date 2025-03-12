import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vertree/VerTreeRegistryService.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/page/MonitPage.dart';
import 'package:vertree/view/page/SettingPage.dart';
import 'package:window_manager/window_manager.dart';

class BrandPage extends StatefulWidget {
  const BrandPage({super.key});

  @override
  State<BrandPage> createState() => _BrandPageState();
}

class _BrandPageState extends State<BrandPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VAppBar(
        title: Row(
          children: [
            Container(
              width: 20,
              height: 20, // 4:3 aspect ratio (400x300)
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/img/logo/logo.png"), fit: BoxFit.contain),
              ),
            ),
            SizedBox(width: 8),
            Text("Vertree"),
          ],
        ),
        showMaximize: false,
        goHome: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 240,
                height: 180, // 4:3 aspect ratio (400x300)
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage("assets/img/logo/logo.png"), fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 16),
              Text("Vertree维树", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                "Vertree维树，树状文件版本管理🌲，让每一次迭代都有备无患！",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: "监控页",
                    onPressed: () async {
                      go(MonitPage());
                    },
                    icon: Icon(Icons.monitor_heart_rounded),
                  ),
                  IconButton(
                    tooltip: "设置页",
                    onPressed: () async {
                      go(SettingPage());
                    },
                    icon: Icon(Icons.settings_rounded),
                  ),
                  IconButton(
                    tooltip: "完全退出维树",
                    onPressed: () async {
                      exit(0);
                    },
                    icon: Icon(Icons.exit_to_app_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> setup(BuildContext context) async {
    bool isSetupDone = configer.get<bool>('isSetupDone', false);
    if (isSetupDone) {
      if (VerTreeRegistryService.checkBackupKeyExists()) {
        VerTreeRegistryService.addVerTreeBackupContextMenu();
      }
      if (VerTreeRegistryService.checkMonitorKeyExists()) {
        VerTreeRegistryService.addVerTreeMonitorContextMenu();
      }
      if (VerTreeRegistryService.checkViewTreeKeyExists()) {
        VerTreeRegistryService.addVerTreeViewContextMenu();
      }
      return;
    }

    // Show confirmation dialog after UI is ready
    bool? userConsent = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("初始化设置"),
          content: const Text("是否允许Vertree添加右键菜单和开机启动？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(false),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(true),
              child: const Text("确定"),
            ),
          ],
        );
      },
    );

    if (userConsent == true) {
      // Perform setup actions
      VerTreeRegistryService.addVerTreeBackupContextMenu();

      VerTreeRegistryService.addVerTreeMonitorContextMenu();

      VerTreeRegistryService.addVerTreeViewContextMenu();
      VerTreeRegistryService.enableAutoStart();

      await showWindowsNotification("Vertree初始设置已完成！", "开始使用吧！");

      // Mark setup as done
      configer.set<bool>('isSetupDone', true);
    }
  }

  @override
  void initState() {
    windowManager.restore();
    super.initState();
    Future.delayed(Duration(seconds: 1), () => setup(context));
    //
  }
}
