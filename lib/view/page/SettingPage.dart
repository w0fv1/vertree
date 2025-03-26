import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:vertree/I18nLang.dart';
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
  late bool expressBackupFile = VerTreeRegistryService.checkExpressBackupKeyExists();
  late bool monitorFile = VerTreeRegistryService.checkMonitorKeyExists();
  late bool viewTreeFile = VerTreeRegistryService.checkViewTreeKeyExists();
  late bool autoStart = VerTreeRegistryService.isAutoStartEnabled();

  @override
  void initState() {
    windowManager.restore();
    super.initState();
  }

  bool isLoading = false;

  Future<void> _toggleBackupFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeBackupContextMenu();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyAddBackup));
    } else {
      success = VerTreeRegistryService.removeVerTreeBackupContextMenu();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyRemoveBackup));
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

  Future<void> _toggleMonitorFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeMonitorContextMenu();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyAddMonitor));
    } else {
      success = VerTreeRegistryService.removeVerTreeMonitorContextMenu();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyRemoveMonitor));
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

  Future<void> _toggleViewTreeFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeViewContextMenu();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyAddView));
    } else {
      success = VerTreeRegistryService.removeVerTreeViewContextMenu();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyRemoveView));
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

  Future<void> _toggleAutoStart(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.enableAutoStart();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyEnableAutostart));
    } else {
      success = VerTreeRegistryService.disableAutoStart();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyDisableAutostart));
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

  Future<void> _toggleExpressBackupFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeExpressBackupContextMenu();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyAddExpress));
    } else {
      success = VerTreeRegistryService.removeVerTreeExpressBackupContextMenu();
      await showWindowsNotification("Vertree", appLocale.getText(AppLocale.setting_notifyRemoveExpress));
    }
    setState(() {
      if (success) expressBackupFile = value;
      isLoading = false;
    });
  }

  void _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw '无法打开 $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      isLoading: isLoading,
      child: Scaffold(
        appBar: VAppBar(
          title: Row(
            children: [
              Icon(Icons.settings_rounded, size: 20),
              SizedBox(width: 8),
              Text(appLocale.getText(AppLocale.setting_titleBar)),
            ],
          ),
          showMaximize: false,
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 500),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      const Icon(Icons.settings, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        appLocale.getText(AppLocale.setting_title),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.language),
                        const SizedBox(width: 8),
                        Text("${appLocale.getText(AppLocale.setting_language)}: "),
                        const SizedBox(width: 8),
                        DropdownButton<Lang>(
                          value: appLocale.lang,
                          onChanged: (Lang? newLang) {
                            if (newLang != null) {
                              setState(() {
                                appLocale.changeLang(newLang);
                              });
                            }
                          },
                          items:
                              appLocale.supportedLangs.map((Lang lang) {
                                return DropdownMenuItem<Lang>(value: lang, child: Text(lang.label));
                              }).toList(),
                        ),
                      ],
                    ),
                  ),

                  SwitchListTile(
                    title: Text(appLocale.getText(AppLocale.setting_addBackupMenu)),
                    value: backupFile,
                    onChanged: _toggleBackupFile,
                  ),
                  SwitchListTile(
                    title: Text(appLocale.getText(AppLocale.setting_addExpressBackupMenu)),
                    value: expressBackupFile,
                    onChanged: _toggleExpressBackupFile,
                  ),
                  SwitchListTile(
                    title: Text(appLocale.getText(AppLocale.setting_addMonitorMenu)),
                    value: monitorFile,
                    onChanged: _toggleMonitorFile,
                  ),
                  SwitchListTile(
                    title: Text(appLocale.getText(AppLocale.setting_addViewtreeMenu)),
                    value: viewTreeFile,
                    onChanged: _toggleViewTreeFile,
                  ),
                  SwitchListTile(
                    title: Text(appLocale.getText(AppLocale.setting_enableAutostart)),
                    value: autoStart,
                    onChanged: _toggleAutoStart,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.open_in_new, size: 18),
                    title: Text(appLocale.getText(AppLocale.setting_openConfig)),
                    onTap: () => FileUtils.openFile(configer.configFilePath),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.language),
                          tooltip: appLocale.getText(AppLocale.setting_visitWebsite),
                          onPressed: () => _openUrl("https://w0fv1.github.io/vertree/"),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.code),
                          tooltip: appLocale.getText(AppLocale.setting_openGithub),
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
