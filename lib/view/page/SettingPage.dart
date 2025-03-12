import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  late bool viewTreeFile = VerTreeRegistryService.checkViewTreeKeyExists();
  late bool autoStart = VerTreeRegistryService.isAutoStartEnabled();

  @override
  void initState() {
    windowManager.restore();

    super.initState();
  } // 初始化开机自启状态

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
    Future.delayed(const Duration(milliseconds: 500), () {
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
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          monitorFile = value;
        }
        isLoading = false;
      });
    });
  }

  /// 更新 `viewTreeFile` 状态
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

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          viewTreeFile = value;
        }
        isLoading = false;
      });
    });
  }

  /// 更新 `autoStart` 状态
  Future<void> _toggleAutoStart(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.enableAutoStart();
      await showWindowsNotification("Vertree", "已启用开机自启");
    } else {
      success = VerTreeRegistryService.disableAutoStart();
      await showWindowsNotification("Vertree", "已禁用开机自启");
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        if (success) {
          autoStart = value;
        }
        isLoading = false;
      });
    });
  }

  /// 打开网址
  void _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw '无法打开 $url';
    }
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
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      const Icon(Icons.settings, size: 24),
                      const SizedBox(width: 8),
                      const Text("设置", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text("将“备份当前文件版本”增加到右键菜单"),
                    value: backupFile,
                    onChanged: _toggleBackupFile,
                  ),
                  SwitchListTile(
                    title: const Text("将“监控该文件”增加到右键菜单"),
                    value: monitorFile,
                    onChanged: _toggleMonitorFile,
                  ),
                  SwitchListTile(
                    title: const Text("将“浏览文件版本树”增加到右键菜单"),
                    value: viewTreeFile,
                    onChanged: _toggleViewTreeFile,
                  ),
                  SwitchListTile(
                    title: const Text("开机自启 Vertree（推荐）"),
                    value: autoStart,
                    onChanged: _toggleAutoStart,
                  ),
                  const SizedBox(height: 16),

                  // 新增按钮：选择文件并指定打开方式
                  ListTile(
                    leading: const Icon(Icons.open_in_new, size: 18),
                    title: const Text("打开 config.json"),
                    onTap: () {
                      print("${configer.configFilePath}");
                      FileUtils.openFile(configer.configFilePath);
                    },
                  ),

                  const SizedBox(height: 16),

                  // 网址快捷方式
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.language),
                          tooltip: "访问官方网站",
                          onPressed: () => _openUrl("https://w0fv1.github.io/vertree/"),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.code),
                          tooltip: "查看 GitHub 仓库",
                          onPressed: () => _openUrl("https://github.com/w0fv1/vertree"),
                        ),
                      ],
                    ),
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
