import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vertree/I18nLang.dart';
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
              height: 20,
              decoration: BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/img/logo/logo.png"), fit: BoxFit.contain),
              ),
            ),
            SizedBox(width: 8),
            Text(appLocale.getText(AppLocale.brand_title)),
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
                height: 180,
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage("assets/img/logo/logo.png"), fit: BoxFit.contain),
                ),
              ),
              SizedBox(height: 16),
              Text(appLocale.getText(AppLocale.brand_title), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(
                appLocale.getText(AppLocale.brand_slogan),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: appLocale.getText(AppLocale.brand_monitorPage),
                    onPressed: () async {
                      go(MonitPage());
                    },
                    icon: Icon(Icons.monitor_heart_rounded),
                  ),
                  IconButton(
                    tooltip: appLocale.getText(AppLocale.brand_settingPage),
                    onPressed: () async {
                      go(SettingPage());
                    },
                    icon: Icon(Icons.settings_rounded),
                  ),
                  IconButton(
                    tooltip: appLocale.getText(AppLocale.brand_exit),
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
      VerTreeRegistryService.clearObsoleteRegistry();

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

    bool? userConsent = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(appLocale.getText(AppLocale.brand_initTitle)),
          content: Text(appLocale.getText(AppLocale.brand_initContent)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(false),
              child: Text(appLocale.getText(AppLocale.brand_cancel)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext, rootNavigator: true).pop(true),
              child: Text(appLocale.getText(AppLocale.brand_confirm)),
            ),
          ],
        );
      },
    );

    if (userConsent == true) {
      VerTreeRegistryService.addVerTreeBackupContextMenu();
      VerTreeRegistryService.addVerTreeMonitorContextMenu();
      VerTreeRegistryService.addVerTreeViewContextMenu();
      VerTreeRegistryService.enableAutoStart();

      await showWindowsNotification(
        appLocale.getText(AppLocale.brand_initDoneTitle),
        appLocale.getText(AppLocale.brand_initDoneBody),
      );

      configer.set<bool>('isSetupDone', true);
    }
  }

  @override
  void initState() {
    windowManager.restore();
    super.initState();
    Future.delayed(Duration(seconds: 1), () => setup(context));
  }
}
