import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:vertree/platform/platform_integration.dart';
import 'package:window_manager/window_manager.dart';

typedef AppPageCallback = void Function(Widget page);
typedef AppLogCallback = void Function(String message);
typedef AsyncVoidCallback = Future<void> Function();

class AppWindowController {
  const AppWindowController({
    required this.onShowPage,
    required this.onLogError,
    required this.onRefreshDockIcon,
    required this.onRefreshTray,
  });

  final AppPageCallback onShowPage;
  final AppLogCallback onLogError;
  final AsyncVoidCallback onRefreshDockIcon;
  final AsyncVoidCallback onRefreshTray;

  Future<void> settleWindowReveal() async {
    await Future.delayed(const Duration(milliseconds: 36));
    await windowManager.setOpacity(1);
  }

  Future<void> showMainWindow({Widget? page, bool animate = true}) async {
    try {
      if (page != null) {
        onShowPage(page);
      }
      final wasVisible = await windowManager.isVisible();
      final wasMinimized = await windowManager.isMinimized();
      await windowManager.setSkipTaskbar(false);
      await onRefreshDockIcon();
      if (wasMinimized) {
        await windowManager.restore();
      }
      final shouldAnimateReveal = animate && !wasVisible && !wasMinimized;
      if (shouldAnimateReveal) {
        await windowManager.setOpacity(0.92);
      }
      await windowManager.show();
      await windowManager.focus();
      if (shouldAnimateReveal) {
        await settleWindowReveal();
      } else {
        await windowManager.setOpacity(1);
      }
      unawaited(onRefreshTray());
    } catch (e) {
      onLogError('show main window failed: $e');
    }
  }

  Future<void> hideMainWindowToTray() async {
    try {
      if (Platform.isLinux &&
          !PlatformIntegration.supportsTrayOnlyBackgroundMode) {
        await windowManager.setSkipTaskbar(false);
        await windowManager.minimize();
        unawaited(onRefreshTray());
        return;
      }
      if (Platform.isMacOS) {
        await windowManager.setSkipTaskbar(true);
        await onRefreshDockIcon();
      }
      await windowManager.hide();
      unawaited(onRefreshTray());
    } catch (e) {
      onLogError('hide main window to tray failed: $e');
    }
  }

  Future<void> toggleMainWindowVisibility({Widget? page}) async {
    try {
      final visible = await windowManager.isVisible();
      final minimized = await windowManager.isMinimized();
      final focused = visible ? await windowManager.isFocused() : false;

      if (!visible || minimized || !focused) {
        await showMainWindow(page: page, animate: true);
        return;
      }

      await hideMainWindowToTray();
    } catch (e) {
      onLogError('toggle main window visibility failed: $e');
    }
  }
}
