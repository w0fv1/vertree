import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:vertree/component/AppVersionInfo.dart';
import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/component/VerTreeRegistryHelper.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/utils/WindowsPackageIdentity.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/main.dart';
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

  late bool backupFile = VerTreeRegistryService.checkBackupKeyExists();
  late bool expressBackupFile =
      VerTreeRegistryService.checkExpressBackupKeyExists();
  late bool monitorFile = VerTreeRegistryService.checkMonitorKeyExists();
  late bool viewTreeFile = VerTreeRegistryService.checkViewTreeKeyExists();
  late bool autoStart = VerTreeRegistryService.isAutoStartEnabled();
  late bool legacyMenuEnabled = _allLegacyMenusEnabled();
  late bool win11MenuEnabled = configer.get("win11MenuEnabled", true);

  @override
  void initState() {
    super.initState();
    _restoreIfMaximized();
  }

  bool isLoading = false;

  bool _allLegacyMenusEnabled() {
    return VerTreeRegistryService.checkBackupKeyExists() &&
        VerTreeRegistryService.checkExpressBackupKeyExists() &&
        VerTreeRegistryService.checkMonitorKeyExists() &&
        VerTreeRegistryService.checkViewTreeKeyExists();
  }

  void _refreshLegacyMenuState() {
    setState(() {
      backupFile = VerTreeRegistryService.checkBackupKeyExists();
      expressBackupFile = VerTreeRegistryService.checkExpressBackupKeyExists();
      monitorFile = VerTreeRegistryService.checkMonitorKeyExists();
      viewTreeFile = VerTreeRegistryService.checkViewTreeKeyExists();
      legacyMenuEnabled = _allLegacyMenusEnabled();
      win11MenuEnabled = configer.get("win11MenuEnabled", true);
    });
  }

  Future<void> _toggleLegacyMenus(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    VerTreeRegistryService.applyLegacyMenus(value);

    Future.delayed(const Duration(milliseconds: 200), () {
      _refreshLegacyMenuState();
      setState(() => isLoading = false);
    });
  }

  Future<void> _toggleWin11Menu(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);
    logger.info('Win11 menu toggle start: target=$value');
    try {
      final packaged = WindowsPackageIdentity.isPackagedOrRegistered();
      logger.info('Win11 menu packagedOrRegistered=$packaged');
      if (!packaged) {
        showToast('Win11 新菜单需要 Sparse Package/MSIX 身份');
        _refreshLegacyMenuState();
        return;
      }

      configer.set("win11MenuEnabled", value);
      logger.info('Win11 menu config updated: $value');
    } catch (e) {
      logger.error('Win11 menu toggle failed: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 200), () {
        _refreshLegacyMenuState();
        if (mounted) {
          setState(() => isLoading = false);
        }
        logger.info('Win11 menu toggle end');
      });
    }
  }

  Future<void> _toggleBackupFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeBackupContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyAddBackup),
      );
    } else {
      success = VerTreeRegistryService.removeVerTreeBackupContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyRemoveBackup),
      );
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          backupFile = value;
        }
        isLoading = false;
        legacyMenuEnabled = _allLegacyMenusEnabled();
      });
    });
  }

  Future<void> _toggleMonitorFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeMonitorContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyAddMonitor),
      );
    } else {
      success = VerTreeRegistryService.removeVerTreeMonitorContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyRemoveMonitor),
      );
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          monitorFile = value;
        }
        isLoading = false;
        legacyMenuEnabled = _allLegacyMenusEnabled();
      });
    });
  }

  Future<void> _toggleViewTreeFile(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.addVerTreeViewContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyAddView),
      );
    } else {
      success = VerTreeRegistryService.removeVerTreeViewContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyRemoveView),
      );
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        if (success) {
          viewTreeFile = value;
        }
        isLoading = false;
        legacyMenuEnabled = _allLegacyMenusEnabled();
      });
    });
  }

  Future<void> _toggleAutoStart(bool? value) async {
    if (value == null) return;
    setState(() => isLoading = true);

    bool success;
    if (value) {
      success = VerTreeRegistryService.enableAutoStart();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyEnableAutostart),
      );
    } else {
      success = VerTreeRegistryService.disableAutoStart();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyDisableAutostart),
      );
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
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyAddExpress),
      );
    } else {
      success = VerTreeRegistryService.removeVerTreeExpressBackupContextMenu();
      await showWindowsNotification(
        "Vertree",
        appLocale.getText(LocaleKey.setting_notifyRemoveExpress),
      );
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        setState(() {
          if (success) expressBackupFile = value;
          isLoading = false;
          legacyMenuEnabled = _allLegacyMenusEnabled();
        });
      });
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
                              text: configer.get("monitorRate", 1).toString(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                var monitorRate =
                                    int.tryParse(value) ??
                                    configer.get("monitorRate", 1).toString();
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
                                  .get("monitorMaxSize", 9999)
                                  .toString(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                var monitorMaxSize =
                                    int.tryParse(value) ??
                                    configer
                                        .get("monitorMaxSize", 9999)
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
                  SwitchListTile(
                    secondary: const Icon(Icons.power_settings_new, size: 22),
                    title: Text(
                      appLocale.getText(LocaleKey.setting_enableAutostart),
                    ),
                    value: autoStart,
                    onChanged: _toggleAutoStart,
                  ),

                  const SizedBox(height: 16),
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
