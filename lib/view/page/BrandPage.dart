import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/component/ThemedAssets.dart';
import 'package:vertree/main.dart';
import 'package:vertree/platform/platform_integration.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/AppPageBackground.dart';
import 'package:vertree/view/page/MonitPage.dart';
import 'package:vertree/view/page/SettingPage.dart';

import 'package:window_manager/window_manager.dart';

class BrandPage extends StatefulWidget {
  const BrandPage({super.key});

  @override
  State<BrandPage> createState() => _BrandPageState();
}

class _BrandPageState extends State<BrandPage> {
  static const String _expressMenuPromptedKey =
      'expressBackupContextMenuPrompted';

  Future<void> _restoreIfMaximized() async {
    if (await windowManager.isMaximized()) {
      await windowManager.restore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: VAppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            themedLogoImage(context: context, width: 20, height: 20),
            const SizedBox(width: 8),
            Text(appLocale.getText(LocaleKey.brand_title)),
          ],
        ),
        showMaximize: false,
        goHome: false,
      ),
      body: AppPageBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card.filled(
                color: scheme.surfaceContainerLowest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      themedLogoImage(context: context, width: 240, height: 180),
                      const SizedBox(height: 12),
                      Text(
                        appLocale.getText(LocaleKey.brand_title),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Text(
                          appLocale.getText(LocaleKey.brand_slogan),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              go(MonitPage());
                            },
                            icon: const Icon(Icons.monitor_heart_rounded),
                            label: Text(
                              appLocale.getText(LocaleKey.brand_monitorPage),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              go(SettingPage());
                            },
                            icon: const Icon(Icons.settings_rounded),
                            label: Text(
                              appLocale.getText(LocaleKey.brand_settingPage),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              exit(0);
                            },
                            icon: const Icon(Icons.exit_to_app_rounded),
                            label: Text(appLocale.getText(LocaleKey.brand_exit)),
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

  Future<void> setup(BuildContext context) async {
    bool isSetupDone = configer.get<bool>('isSetupDone', false);
    if (!PlatformIntegration.isWindows) {
      if (!isSetupDone) {
        configer.set<bool>('isSetupDone', true);
      }
      return;
    }

    if (isSetupDone) {
      // 启动时不自动触发管理员授权；仅做必要的兼容/提示。

      final alreadyPrompted = configer.get<bool>(
        _expressMenuPromptedKey,
        false,
      );
      final expressExists =
          await PlatformIntegration.checkExpressBackupKeyExists();
      if (!alreadyPrompted && !expressExists) {
        configer.set<bool>(_expressMenuPromptedKey, true);

        Future.delayed(const Duration(milliseconds: 300), () async {
          if (!mounted) return;
          final consent = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text('启用“快速备份”右键菜单？'),
                content: const Text('此操作会修改系统右键菜单，需管理员权限授权。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('稍后'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('启用'),
                  ),
                ],
              );
            },
          );

          if (consent == true) {
            await PlatformIntegration.addExpressBackupContextMenu();
          }
        });
      }
      return;
    }

    bool? userConsent = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocale.getText(LocaleKey.brand_initTitle)),
          content: Text(appLocale.getText(LocaleKey.brand_initContent)),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(false),
              child: Text(appLocale.getText(LocaleKey.brand_cancel)),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(true),
              child: Text(appLocale.getText(LocaleKey.brand_confirm)),
            ),
          ],
        );
      },
    );

    if (userConsent == true) {
      final allSuccess = await PlatformIntegration.applyInitialSetup();
      if (allSuccess) {
        await showWindowsNotification(
          appLocale.getText(LocaleKey.brand_initDoneTitle),
          appLocale.getText(LocaleKey.brand_initDoneBody),
        );
        configer.set<bool>('isSetupDone', true);
      } else {
        logger.error("初始化未全部成功，请在设置页面重试并完成授权");
        await showWindowsNotification("Vertree", "初始化部分失败，请在设置页面重试并同意管理员授权。");
        configer.set<bool>('isSetupDone', false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _restoreIfMaximized();
    Future.delayed(Duration(seconds: 1), () => setup(context));
  }
}
