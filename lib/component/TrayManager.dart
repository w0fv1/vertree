import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vertree/main.dart';
import 'package:vertree/platform/platform_integration.dart';
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
    String iconPath = Platform.isWindows
        ? 'assets/img/logo/logo.ico'
        : (Platform.isMacOS
            ? 'assets/img/logo/tray_template.png'
            : 'assets/img/logo/logo.png');
    _iconPath = iconPath;

    // macOS 使用 template 图标以适配深色/浅色模式，其它平台仍使用普通位图。
    final isTemplate = Platform.isMacOS;
    await trayManager.setIcon(iconPath, isTemplate: isTemplate);

    // 设置托盘菜单
    List<MenuItem> menuItems = _buildMenuItems();
    Menu menu = Menu(items: menuItems);
    _menu = menu;

    await trayManager.setContextMenu(menu);
  }

  List<MenuItem> _buildMenuItems() {
    final items = <MenuItem>[];

    if (Platform.isMacOS) {
      items.addAll([
        MenuItem(
          key: 'backup',
          label: '备份文件',
          toolTip: '选择文件进行备份',
          icon: "assets/img/icon/save.png",
          onClick: (_) => _pickFileAndRun(backup, bringToFront: true),
        ),
        MenuItem(
          key: 'expressBackup',
          label: '快速备份',
          toolTip: '选择文件进行快速备份',
          icon: "assets/img/icon/express-save.png",
          onClick: (_) => _pickFileAndRun(expressBackup),
        ),
        MenuItem(
          key: 'monit',
          label: '监控文件',
          toolTip: '选择文件加入监控',
          icon: "assets/img/icon/monit.png",
          onClick: (_) => _pickFileAndRun(monit),
        ),
        MenuItem(
          key: 'viewtree',
          label: '查看版本树',
          toolTip: '选择文件查看版本树',
          icon: "assets/img/icon/save.png",
          onClick: (_) => _pickFileAndRun(viewtree),
        ),
        MenuItem.separator(),
      ]);
    }

    items.addAll([
      MenuItem(
        key: 'setting',
        label: '设置',
        toolTip: 'App设置',
        icon: Platform.isWindows ? "assets/img/icon/setting.ico" : "assets/img/icon/setting.png",
        onClick: (_) async {
          go(SettingPage());
        },
      ),
      MenuItem(
        key: 'exit',
        label: '退出',
        toolTip: '退出APP',
        icon: Platform.isWindows ? "assets/img/icon/exit.ico" : "assets/img/icon/exit.png",
        onClick: (_) {
          exit(0); // 退出程序
        },
      ),
    ]);

    return items;
  }

  Future<void> _ensureWindowVisible() async {
    try {
      await windowManager.setSkipTaskbar(false);
      await PlatformIntegration.refreshMacOSDockIcon();
      await windowManager.show();
      await windowManager.focus();
      await fadeInWindow();
    } catch (_) {
      // ignore
    }
  }

  Future<void> _pickFileAndRun(void Function(String path) action,
      {bool bringToFront = false}) async {
    if (bringToFront) {
      await _ensureWindowVisible();
    }
    final result = await FilePicker.platform.pickFiles();
    final filePath = result?.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      return;
    }
    action(filePath);
  }

  Future<void> refreshTray() async {
    if (_iconPath == null || _menu == null) {
      return;
    }
    try {
      final isTemplate = Platform.isMacOS;
      await trayManager.setIcon(_iconPath!, isTemplate: isTemplate);
      await trayManager.setContextMenu(_menu!);
    } catch (_) {
      // ignore
    }
  }

  @override
  void onTrayIconMouseDown() {
    _ensureWindowVisible();
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
