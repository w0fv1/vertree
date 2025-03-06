import 'package:flutter/material.dart';
import 'package:vertree/VerTreeRegistryService.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/Loading.dart';
import 'package:window_manager/window_manager.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late bool backupFile = VerTreeRegistryService.checkBackupKeyExists();
  late bool monitorFile = VerTreeRegistryService.checkMonitorKeyExists();
  late bool viewTreeFile = VerTreeRegistryService.checkViewTreeKeyExists(); // 检查是否存在

  bool autoStart = false;
  bool isLoading = false;

  /// 更新 `backupFile` 状态
  Future<void> _toggleBackupFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeBackupContextMenu();
      await showWindowsNotification("Vertree", "已添加 '备份当前文件版本' 到右键菜单");
    } else {
      success = VerTreeRegistryService.removeVerTreeBackupContextMenu();
      await showWindowsNotification("Vertree", "已从右键菜单移除 '备份当前文件版本' 功能按钮");
    }
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          backupFile = value;
        }
        isLoading = false;
      });
    });
  }

  /// 更新 `monitorFile` 状态
  Future<void> _toggleMonitorFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeMonitorContextMenu();
      await showWindowsNotification("Vertree", "已添加 '监控该文件' 到右键菜单");
    } else {
      success = VerTreeRegistryService.removeVerTreeMonitorContextMenu();
      await showWindowsNotification("Vertree", "已从右键菜单移除 '监控该文件' 功能按钮");
    }
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          monitorFile = value;
        }
        isLoading = false;
      });
    });
  }

  Future<void> _toggleViewTreeFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeViewContextMenu();
      await showWindowsNotification("Vertree", "已添加 '浏览文件版本树' 到右键菜单");
    } else {
      success = VerTreeRegistryService.removeVerTreeViewContextMenu();
      await showWindowsNotification("Vertree", "已从右键菜单移除 '浏览文件版本树' 功能按钮");
    }

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          viewTreeFile = value;
        }
        isLoading = false;
      });
    });
  }

  /// 更新 `autoStart` 状态
  void _toggleAutoStart(bool? value) {
    setState(() {
      autoStart = value ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertree维树',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)),
      home: LoadingWidget(
        isLoading: isLoading,
        child: Scaffold(
          appBar: VAppBar(
            title: Row(children: [Icon(Icons.settings_rounded, size: 20), SizedBox(width: 8), Text("Vertree 设置")]),
            showMaximize: false,
          ),
          body: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 400),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 10),
                      Icon(Icons.settings, size: 24),
                      SizedBox(width: 8),
                      Text("设置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 16),
                  CheckboxListTile(title: Text("将“备份当前文件版本”增加到右键菜单"), value: backupFile, onChanged: _toggleBackupFile),
                  CheckboxListTile(title: Text("将“监控该文件”增加到右键菜单"), value: monitorFile, onChanged: _toggleMonitorFile),
                  CheckboxListTile(
                    title: Text("将“浏览文件版本树”增加到右键菜单"),
                    value: viewTreeFile,
                    onChanged: _toggleViewTreeFile,
                  ),
                  CheckboxListTile(title: Text("开机自启Vertree（推荐）"), value: autoStart, onChanged: _toggleAutoStart),
                  const SizedBox(height: 16),

                  // 新增按钮：选择文件并指定打开方式
                  ListTile(
                    leading: const Icon(Icons.open_in_new,size: 18,),
                    title: const Text("打开Config.json"),
                    onTap: (){

                      print("${configer.configFilePath}");

                      FileUtils.openFile(configer.configFilePath);

                    },
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
