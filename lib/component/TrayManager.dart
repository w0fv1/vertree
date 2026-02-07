import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:vertree/view/page/SettingPage.dart';
import 'package:window_manager/window_manager.dart';

class TrayManager with TrayListener {
  TrayManager._internal();
  static final TrayManager _instance = TrayManager._internal();
  factory TrayManager() => _instance;

  bool _initialized = false;
  Timer? _refreshTimer;
  String? _iconPath;
  Menu? _menu;

  ValueNotifier<bool> shouldForegroundOnContextMenu = ValueNotifier(false);

  void init() {
    if (!_initialized) {
      trayManager.addListener(this);
      _initialized = true;
    }
    initTray();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      refreshTray();
    });
  }

  void initTray() async {
    // 设置托盘图标
    String iconPath =
        Platform.isWindows ? 'assets/img/logo/logo.ico' : 'assets/img/logo/logo.png';
    _iconPath = iconPath;

    await trayManager.setIcon(iconPath);

    // 设置托盘菜单
    List<MenuItem> menuItems = [
      MenuItem(
        key: 'setting',
        label: '设置',
        toolTip: 'App设置',
        icon: Platform.isWindows ? "assets/img/icon/setting.ico" : "assets/img/icon/setting.png",
        onClick: (MenuItem menuItem) async {
          go(SettingPage());
        },
      ),
      MenuItem(
        key: 'exit',
        label: '退出',
        toolTip: '退出APP',
        icon: Platform.isWindows ? "assets/img/icon/exit.ico" : "assets/img/icon/exit.png",
        onClick: (MenuItem menuItem) {
          exit(0); // 退出程序
        },
      ),
    ];
    Menu menu = Menu(items: menuItems);
    _menu = menu;

    await trayManager.setContextMenu(menu);
  }

  Future<void> refreshTray() async {
    if (_iconPath == null || _menu == null) {
      return;
    }
    try {
      await trayManager.setIcon(_iconPath!);
      await trayManager.setContextMenu(_menu!);
    } catch (_) {
      // ignore
    }
  }

  @override
  void onTrayIconMouseDown() {
    go(BrandPage());
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == "setting") {}
  }
}
