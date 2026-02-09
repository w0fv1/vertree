import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:vertree/component/AppVersionInfo.dart';
import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/main.dart';
import 'package:vertree/platform/platform_integration.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/AppVersionButton.dart';
import 'package:vertree/view/component/Loading.dart';
import 'package:window_manager/window_manager.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  Future<void> _restoreIfMaximized() async {
    if (await windowManager.isMaximized()) {
      await windowManager.restore();
    }
  }

  bool backupFile = false;
  bool expressBackupFile = false;
  bool monitorFile = false;
  bool viewTreeFile = false;
  bool autoStart = false;
  bool legacyMenuEnabled = false;
  bool win11MenuEnabled = false;

  @override
  void initState() {
    super.initState();
    _restoreIfMaximized();
    _loadPlatformState();
  }

  bool isLoading = false;

  Future<void> _loadPlatformState() async {
    if (PlatformIntegration.isWindows) {
      backupFile = await PlatformIntegration.checkBackupKeyExists();
      expressBackupFile =
          await PlatformIntegration.checkExpressBackupKeyExists();
      monitorFile = await PlatformIntegration.checkMonitorKeyExists();
      viewTreeFile = await PlatformIntegration.checkViewTreeKeyExists();
      legacyMenuEnabled =
          backupFile && expressBackupFile && monitorFile && viewTreeFile;
      win11MenuEnabled = configer.get("win11MenuEnabled", true);
    }
    if (PlatformIntegration.supportsAutoStart) {
      autoStart = await PlatformIntegration.isAutoStartEnabled();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _refreshLegacyMenuState() async {
    await _loadPlatformState();
  }

  Future<void> _toggleLegacyMenus(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    await PlatformIntegration.applyLegacyMenus(value);

    await Future.delayed(const Duration(milliseconds: 200));
    await _refreshLegacyMenuState();
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleWin11Menu(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);
    logger.info('Win11 menu toggle start: target=$value');
    try {
      final packaged = await PlatformIntegration.isWin11PackagedOrRegistered();
      logger.info('Win11 menu packagedOrRegistered=$packaged');
      if (!packaged) {
        showToast('Win11 新菜单需要 Sparse Package/MSIX 身份');
        await _refreshLegacyMenuState();
        return;
      }

      configer.set("win11MenuEnabled", value);
      logger.info('Win11 menu config updated: $value');
    } catch (e) {
      logger.error('Win11 menu toggle failed: $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 200));
      await _refreshLegacyMenuState();
      if (mounted) {
        setState(() => isLoading = false);
      }
      logger.info('Win11 menu toggle end');
    }
  }

  Future<void> _toggleBackupFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = await PlatformIntegration.addBackupContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyAddBackup),
      );
    } else {
      success = await PlatformIntegration.removeBackupContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyRemoveBackup),
      );
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      if (success) {
        backupFile = value;
      }
      isLoading = false;
      legacyMenuEnabled =
          backupFile && expressBackupFile && monitorFile && viewTreeFile;
    });
  }

  Future<void> _toggleMonitorFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = await PlatformIntegration.addMonitorContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyAddMonitor),
      );
    } else {
      success = await PlatformIntegration.removeMonitorContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyRemoveMonitor),
      );
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      if (success) {
        monitorFile = value;
      }
      isLoading = false;
      legacyMenuEnabled =
          backupFile && expressBackupFile && monitorFile && viewTreeFile;
    });
  }

  Future<void> _toggleViewTreeFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = await PlatformIntegration.addViewTreeContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyAddView),
      );
    } else {
      success = await PlatformIntegration.removeViewTreeContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyRemoveView),
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      if (success) {
        viewTreeFile = value;
      }
      isLoading = false;
      legacyMenuEnabled =
          backupFile && expressBackupFile && monitorFile && viewTreeFile;
    });
  }

  Future<void> _toggleAutoStart(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = await PlatformIntegration.enableAutoStart();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyEnableAutostart),
      );
    } else {
      success = await PlatformIntegration.disableAutoStart();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyDisableAutostart),
      );
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      if (success) {
        autoStart = value;
      }
      isLoading = false;
    });
  }

  Future<void> _toggleExpressBackupFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = await PlatformIntegration.addExpressBackupContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyAddExpress),
      );
    } else {
      success = await PlatformIntegration.removeExpressBackupContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyRemoveExpress),
      );
    }

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() {
      if (success) expressBackupFile = value;
      isLoading = false;
      legacyMenuEnabled =
          backupFile && expressBackupFile && monitorFile && viewTreeFile;
    });
  }

  Future<void> _pickFileAndRun(void Function(String path) action) async {
    final result = await FilePicker.platform.pickFiles();
    final filePath = result?.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      return;
    }
    action(filePath);
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
              Text(appLocale.getText(LocaleKey.setting_titleBar)),
            ],
          ),
          showMaximize: false,
        ),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 14.0),
                    child: Row(
                      children: [
                        const Icon(Icons.language),
                        const SizedBox(width: 8),
                        Text(
                          "${appLocale.getText(LocaleKey.setting_language)}: ",
                        ),
                        const SizedBox(width: 8),
                        Spacer(),
                        DropdownButton<Lang>(
                          value: appLocale.lang,
                          onChanged: (Lang? newLang) {
                            if (newLang != null) {
                              setState(() => isLoading = true);

                              setState(() {
                                appLocale.changeLang(newLang);
                              });

                              Future.delayed(
                                const Duration(milliseconds: 200),
                                () {
                                  setState(() {
                                    isLoading = false;
                                  });
                                },
                              );
                            }
                          },
                          items: appLocale.supportedLangs.map((Lang lang) {
                            return DropdownMenuItem<Lang>(
                              value: lang,
                              child: Text("    " + lang.label + "    "),
                            );
                          }).toList(),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (PlatformIntegration.supportsContextMenus) ...[
                    SwitchListTile(
                      secondary: const Icon(Icons.build, size: 20),
                      title: const Text("右键菜单选项设置"),
                      value: win11MenuEnabled,
                      onChanged: _toggleWin11Menu,
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      leading: Icon(Icons.build, size: 20),
                      title: Text(
                        "${appLocale.getText(LocaleKey.setting_contextMenuGroup)}（旧版）",
                      ),
                      children: [
                        SwitchListTile(
                          title: const Text("右键菜单选项"),
                          value: legacyMenuEnabled,
                          onChanged: _toggleLegacyMenus,
                        ),
                        SwitchListTile(
                          title: Text(
                            appLocale.getText(LocaleKey.setting_addBackupMenu),
                          ),
                          value: backupFile,
                          onChanged: _toggleBackupFile,
                        ),
                        SwitchListTile(
                          title: Text(
                            appLocale.getText(
                              LocaleKey.setting_addExpressBackupMenu,
                            ),
                          ),
                          value: expressBackupFile,
                          onChanged: _toggleExpressBackupFile,
                        ),
                        SwitchListTile(
                          title: Text(
                            appLocale.getText(LocaleKey.setting_addMonitorMenu),
                          ),
                          value: monitorFile,
                          onChanged: _toggleMonitorFile,
                        ),
                        SwitchListTile(
                          title: Text(
                            appLocale.getText(LocaleKey.setting_addViewtreeMenu),
                          ),
                          value: viewTreeFile,
                          onChanged: _toggleViewTreeFile,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else ...[],
                  ExpansionTile(
                    leading: Icon(Icons.monitor_heart_rounded, size: 20),
                    title: Text(
                      appLocale.getText(LocaleKey.setting_monitGroup),
                    ),
                    children: [
                      ListTile(
                        title: Text(
                          appLocale.getText(LocaleKey.setting_monitRate),
                        ),
                        trailing: SizedBox(
                          width: 60, // 固定输入框宽度
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: configer.get("monitorRate", 5).toString(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                var monitorRate =
                                    int.tryParse(value) ??
                                    configer.get("monitorRate", 5).toString();
                                configer.set("monitorRate", monitorRate);
                              });
                            },
                          ),
                        ),
                      ),
                      ListTile(
                        title: Text(
                          appLocale.getText(LocaleKey.setting_monitMaxSize),
                        ),
                        trailing: SizedBox(
                          width: 60, // 固定输入框宽度
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(
                              text: configer
                                  .get("monitorMaxSize", 50)
                                  .toString(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                var monitorMaxSize =
                                    int.tryParse(value) ??
                                    configer
                                        .get("monitorMaxSize", 50)
                                        .toString();
                                configer.set("monitorMaxSize", monitorMaxSize);
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (PlatformIntegration.supportsAutoStart) ...[
                    SwitchListTile(
                      secondary: const Icon(
                        Icons.power_settings_new,
                        size: 22,
                      ),
                      title: Text(
                        appLocale.getText(LocaleKey.setting_enableAutostart),
                      ),
                      value: autoStart,
                      onChanged: _toggleAutoStart,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Icons.open_in_new, size: 20),
                          title: Text(
                            appLocale.getText(LocaleKey.setting_openConfig),
                          ),
                          onTap: () =>
                              FileUtils.openFile(configer.configFilePath),
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          leading: const Icon(Icons.open_in_new, size: 20),
                          title: Text(
                            appLocale.getText(LocaleKey.setting_openLogs),
                          ),
                          onTap: () => FileUtils.openFolder(logger.logDirPath),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.language_rounded),
                          tooltip: appLocale.getText(
                            LocaleKey.setting_visitWebsite,
                          ),
                          onPressed: () =>
                              _openUrl("https://w0fv1.github.io/vertree/"),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(MaterialCommunityIcons.github),
                          tooltip: appLocale.getText(
                            LocaleKey.setting_openGithub,
                          ),
                          onPressed: () =>
                              _openUrl("https://github.com/w0fv1/vertree"),
                        ),
                        const SizedBox(width: 16),
                        Tooltip(
                          message: appLocale.getText(
                            LocaleKey.setting_versionInfo,
                          ),
                          child: AppVersionDisplay(
                            appVersion: appVersionInfo.currentVersion,
                            defaultLink:
                                "https://github.com/w0fv1/vertree/releases",
                            checkNewVersion: () async {
                              Result<UpdateInfo, String> checkUpdateResult =
                                  await appVersionInfo.checkUpdate();

                              if (checkUpdateResult.isErr) {
                                logger.error(checkUpdateResult.msg);
                                return false;
                              }

                              bool hasNewVersion = checkUpdateResult
                                  .unwrap()
                                  .hasUpdate;

                              var newVersionTag = checkUpdateResult
                                  .unwrap()
                                  .latestVersionTag;

                              if (hasNewVersion &&
                                  newVersionTag != null &&
                                  newVersionTag.isNotEmpty) {
                                showToast(
                                  appLocale
                                      .getText(LocaleKey.setting_hasNewVertion)
                                      .tr([newVersionTag ?? ""]),
                                );
                              }
                              return hasNewVersion;
                            },
                            getNewVersionDownloadUrl: () async {
                              Result<String?, String> checkUpdateResult =
                                  await appVersionInfo.getLatestReleaseUrl();
                              if (checkUpdateResult.isErr) {
                                logger.info(checkUpdateResult.msg);
                                return "https://github.com/w0fv1/vertree/releases";
                              }
                              return checkUpdateResult.unwrap();
                            },
                          ),
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
