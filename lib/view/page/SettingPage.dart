import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vertree/component/AppVersionInfo.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/main.dart';
import 'package:vertree/platform/platform_integration.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/AppPageBackground.dart';
import 'package:vertree/view/component/AppVersionButton.dart';
import 'package:vertree/view/component/Loading.dart';
import 'package:window_manager/window_manager.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late final TextEditingController _monitorRateController;
  late final TextEditingController _monitorMaxSizeController;

  bool backupFile = false;
  bool expressBackupFile = false;
  bool monitorFile = false;
  bool viewTreeFile = false;
  bool autoStart = false;
  bool legacyMenuEnabled = false;
  bool win11MenuEnabled = false;
  bool _showLegacyMenuDetails = false;
  bool isLoading = false;
  String _themeModeSetting = 'system';

  Future<void> _restoreIfMaximized() async {
    if (await windowManager.isMaximized()) {
      await windowManager.restore();
    }
  }

  @override
  void initState() {
    super.initState();
    _monitorRateController = TextEditingController(
      text: configer.get("monitorRate", 5).toString(),
    );
    _monitorMaxSizeController = TextEditingController(
      text: configer.get("monitorMaxSize", 50).toString(),
    );
    _restoreIfMaximized();
    _loadPlatformState();
  }

  @override
  void dispose() {
    _monitorRateController.dispose();
    _monitorMaxSizeController.dispose();
    super.dispose();
  }

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
    _themeModeSetting = configer.get<String>('themeMode', 'system');
    _syncMonitorControllers();
    if (!mounted) return;
    setState(() {});
  }

  void _syncMonitorControllers() {
    _setControllerText(
      _monitorRateController,
      configer.get("monitorRate", 5).toString(),
    );
    _setControllerText(
      _monitorMaxSizeController,
      configer.get("monitorMaxSize", 50).toString(),
    );
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
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

    late final bool success;
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

    late final bool success;
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

    late final bool success;
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

    late final bool success;
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

    late final bool success;
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
      if (success) {
        expressBackupFile = value;
      }
      isLoading = false;
      legacyMenuEnabled =
          backupFile && expressBackupFile && monitorFile && viewTreeFile;
    });
  }

  void _updateLanguage(Lang lang) {
    setState(() {
      appLocale.changeLang(lang);
    });
  }

  void _updateThemeMode(String value) {
    setState(() {
      _themeModeSetting = value;
    });
    switch (value) {
      case 'system':
        updateThemeSetting(AppThemeSetting.system);
        break;
      case 'light':
        updateThemeSetting(AppThemeSetting.light);
        break;
      case 'dark':
        updateThemeSetting(AppThemeSetting.dark);
        break;
    }
  }

  void _handleIntegerSettingChanged(String key, String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0) {
      configer.set(key, parsed);
    }
  }

  void _finalizeIntegerSetting(
    String key,
    TextEditingController controller,
    int fallback,
  ) {
    final parsed = int.tryParse(controller.text);
    if (parsed != null && parsed > 0) {
      configer.set(key, parsed);
    }
    final current = configer.get(key, fallback).toString();
    _setControllerText(controller, current);
  }

  void _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw '无法打开 $url';
    }
  }

  List<Widget> _withDividers(List<Widget> children) {
    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i != children.length - 1) {
        result.add(const SizedBox(height: 14));
      }
    }
    return result;
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: Card.outlined(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ..._withDividers(children),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedPreference<T>({
    required IconData icon,
    required String title,
    required Set<T> selected,
    required List<ButtonSegment<T>> segments,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SegmentedButton<T>(
                segments: segments,
                selected: selected,
                showSelectedIcon: false,
                expandedInsets: EdgeInsets.zero,
                onSelectionChanged: (values) {
                  if (values.isEmpty) return;
                  onSelected(values.first);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return SwitchListTile(
      mouseCursor: SystemMouseCursors.click,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      secondary: Icon(icon, size: 20),
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildSubsectionCard({
    required IconData icon,
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: Card.filled(
        color: scheme.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
              const SizedBox(height: 12),
              ..._withDividers(children),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntegerSettingTile({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required String configKey,
    required int fallback,
  }) {
    return ListTile(
      mouseCursor: SystemMouseCursors.basic,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(icon, size: 20),
      title: Text(title),
      trailing: SizedBox(
        width: 120,
        child: TextFormField(
          controller: controller,
          mouseCursor: SystemMouseCursors.text,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.end,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) => _handleIntegerSettingChanged(configKey, value),
          onEditingComplete: () {
            _finalizeIntegerSetting(configKey, controller, fallback);
            FocusScope.of(context).unfocus();
          },
          onFieldSubmitted: (_) {
            _finalizeIntegerSetting(configKey, controller, fallback);
          },
          onTapOutside: (_) {
            _finalizeIntegerSetting(configKey, controller, fallback);
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      isLoading: isLoading,
      child: Scaffold(
        appBar: VAppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_rounded, size: 18),
              const SizedBox(width: 8),
              Text(appLocale.getText(LocaleKey.setting_titleBar)),
            ],
          ),
          showMaximize: false,
        ),
        body: AppPageBackground(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Scrollbar(
                  child: ListView(
                    children: [
                      _buildSection(
                        icon: Icons.palette_outlined,
                        title: appLocale.getText(
                          LocaleKey.setting_appearanceGroup,
                        ),
                        children: [
                          _buildSegmentedPreference<Lang>(
                            icon: Icons.language_rounded,
                            title: appLocale.getText(
                              LocaleKey.setting_language,
                            ),
                            selected: {appLocale.lang},
                            segments: appLocale.supportedLangs
                                .map(
                                  (lang) => ButtonSegment<Lang>(
                                    value: lang,
                                    label: Text(lang.label),
                                  ),
                                )
                                .toList(),
                            onSelected: _updateLanguage,
                          ),
                          _buildSegmentedPreference<String>(
                            icon: Icons.dark_mode_rounded,
                            title: appLocale.getText(
                              LocaleKey.setting_themeModeLabel,
                            ),
                            selected: {_themeModeSetting},
                            segments: [
                              ButtonSegment<String>(
                                value: 'system',
                                icon: const Icon(Icons.brightness_auto_rounded),
                                label: Text(
                                  appLocale.getText(
                                    LocaleKey.setting_themeModeSystem,
                                  ),
                                ),
                              ),
                              ButtonSegment<String>(
                                value: 'light',
                                icon: const Icon(Icons.light_mode_rounded),
                                label: Text(
                                  appLocale.getText(
                                    LocaleKey.setting_themeModeLight,
                                  ),
                                ),
                              ),
                              ButtonSegment<String>(
                                value: 'dark',
                                icon: const Icon(Icons.dark_mode_rounded),
                                label: Text(
                                  appLocale.getText(
                                    LocaleKey.setting_themeModeDark,
                                  ),
                                ),
                              ),
                            ],
                            onSelected: _updateThemeMode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (PlatformIntegration.supportsContextMenus ||
                          PlatformIntegration.supportsAutoStart) ...[
                        _buildSection(
                          icon: Icons.extension_outlined,
                          title: appLocale.getText(
                            LocaleKey.setting_integrationsGroup,
                          ),
                          children: [
                            if (PlatformIntegration.supportsContextMenus)
                              _buildSwitchTile(
                                icon: Icons.apps_rounded,
                                title: appLocale.getText(
                                  LocaleKey.setting_contextMenuGroup,
                                ),
                                value: win11MenuEnabled,
                                onChanged: _toggleWin11Menu,
                              ),
                            if (PlatformIntegration.supportsContextMenus)
                              _buildSubsectionCard(
                                icon: Icons.history_toggle_off_rounded,
                                title:
                                    "${appLocale.getText(LocaleKey.setting_contextMenuGroup)}（旧版）",
                                trailing: IconButton.filledTonal(
                                  onPressed: () {
                                    setState(() {
                                      _showLegacyMenuDetails =
                                          !_showLegacyMenuDetails;
                                    });
                                  },
                                  icon: Icon(
                                    _showLegacyMenuDetails
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                  ),
                                ),
                                children: [
                                  _buildSwitchTile(
                                    icon: Icons.toggle_on_rounded,
                                    title: appLocale.getText(
                                      LocaleKey.setting_contextMenuToggle,
                                    ),
                                    value: legacyMenuEnabled,
                                    onChanged: _toggleLegacyMenus,
                                  ),
                                  AnimatedCrossFade(
                                    duration: const Duration(milliseconds: 180),
                                    crossFadeState: _showLegacyMenuDetails
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    firstChild: const SizedBox.shrink(),
                                    secondChild: Column(
                                      children: [
                                        _buildSwitchTile(
                                          icon: Icons.save_outlined,
                                          title: appLocale.getText(
                                            LocaleKey.setting_addBackupMenu,
                                          ),
                                          value: backupFile,
                                          onChanged: _toggleBackupFile,
                                        ),
                                        _buildSwitchTile(
                                          icon: Icons.flash_on_outlined,
                                          title: appLocale.getText(
                                            LocaleKey
                                                .setting_addExpressBackupMenu,
                                          ),
                                          value: expressBackupFile,
                                          onChanged: _toggleExpressBackupFile,
                                        ),
                                        _buildSwitchTile(
                                          icon: Icons.monitor_heart_outlined,
                                          title: appLocale.getText(
                                            LocaleKey.setting_addMonitorMenu,
                                          ),
                                          value: monitorFile,
                                          onChanged: _toggleMonitorFile,
                                        ),
                                        _buildSwitchTile(
                                          icon: Icons.account_tree_outlined,
                                          title: appLocale.getText(
                                            LocaleKey.setting_addViewtreeMenu,
                                          ),
                                          value: viewTreeFile,
                                          onChanged: _toggleViewTreeFile,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            if (PlatformIntegration.supportsAutoStart)
                              _buildSwitchTile(
                                icon: Icons.power_settings_new_rounded,
                                title: appLocale.getText(
                                  LocaleKey.setting_enableAutostart,
                                ),
                                value: autoStart,
                                onChanged: _toggleAutoStart,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildSection(
                        icon: Icons.monitor_heart_outlined,
                        title: appLocale.getText(LocaleKey.setting_monitGroup),
                        children: [
                          _buildIntegerSettingTile(
                            icon: Icons.schedule_rounded,
                            title: appLocale.getText(
                              LocaleKey.setting_monitRate,
                            ),
                            controller: _monitorRateController,
                            configKey: "monitorRate",
                            fallback: 5,
                          ),
                          _buildIntegerSettingTile(
                            icon: Icons.inventory_2_outlined,
                            title: appLocale.getText(
                              LocaleKey.setting_monitMaxSize,
                            ),
                            controller: _monitorMaxSizeController,
                            configKey: "monitorMaxSize",
                            fallback: 50,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        icon: Icons.folder_outlined,
                        title: appLocale.getText(
                          LocaleKey.setting_resourcesGroup,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: () => FileUtils.openFile(
                                    configer.configFilePath,
                                  ),
                                  icon: const Icon(Icons.description_outlined),
                                  label: Text(
                                    appLocale.getText(
                                      LocaleKey.setting_openConfig,
                                    ),
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () =>
                                      FileUtils.openFolder(logger.logDirPath),
                                  icon: const Icon(Icons.receipt_long_outlined),
                                  label: Text(
                                    appLocale.getText(
                                      LocaleKey.setting_openLogs,
                                    ),
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => _openUrl(
                                    "https://w0fv1.github.io/vertree/",
                                  ),
                                  icon: const Icon(Icons.language_rounded),
                                  label: Text(
                                    appLocale.getText(
                                      LocaleKey.setting_visitWebsite,
                                    ),
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => _openUrl(
                                    "https://github.com/w0fv1/vertree",
                                  ),
                                  icon: const Icon(
                                    MaterialCommunityIcons.github,
                                  ),
                                  label: Text(
                                    appLocale.getText(
                                      LocaleKey.setting_openGithub,
                                    ),
                                  ),
                                ),
                                Tooltip(
                                  message: appLocale.getText(
                                    LocaleKey.setting_versionInfo,
                                  ),
                                  child: AppVersionDisplay(
                                    appVersion: appVersionInfo.currentVersion,
                                    defaultLink:
                                        "https://github.com/w0fv1/vertree/releases",
                                    checkNewVersion: () async {
                                      final Result<UpdateInfo, String>
                                      checkUpdateResult = await appVersionInfo
                                          .checkUpdate();

                                      if (checkUpdateResult.isErr) {
                                        logger.error(checkUpdateResult.msg);
                                        return false;
                                      }

                                      final hasNewVersion = checkUpdateResult
                                          .unwrap()
                                          .hasUpdate;
                                      final newVersionTag = checkUpdateResult
                                          .unwrap()
                                          .latestVersionTag;

                                      if (hasNewVersion &&
                                          newVersionTag != null &&
                                          newVersionTag.isNotEmpty) {
                                        showToast(
                                          appLocale
                                              .getText(
                                                LocaleKey.setting_hasNewVertion,
                                              )
                                              .tr([newVersionTag]),
                                        );
                                      }
                                      return hasNewVersion;
                                    },
                                    getNewVersionDownloadUrl: () async {
                                      final Result<String?, String>
                                      checkUpdateResult = await appVersionInfo
                                          .getLatestReleaseUrl();
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
