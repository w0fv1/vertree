import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:vertree/view/page/SettingPage.dart';
import 'package:window_manager/window_manager.dart';

class Tray with TrayListener {
  ValueNotifier<bool> shouldForegroundOnContextMenu = ValueNotifier(false);

  void init() {
    trayManager.addListener(this);
    initTray();
  }

  void initTray() async {
    // 设置托盘图标
    String iconPath = Platform.isWindows ? 'assets/img/logo/logo.ico' : 'assets/img/logo/logo.png';

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

    await trayManager.setContextMenu(menu);
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
