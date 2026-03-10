import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:window_manager/window_manager.dart';

class VAppBar extends StatefulWidget implements PreferredSizeWidget {
  final double height;
  final Widget title;
  final bool showMinimize;
  final bool showMaximize;
  final bool showClose;
  final bool goHome;

  // 添加回调函数
  final VoidCallback? onMinimize;
  final VoidCallback? onMaximize;
  final VoidCallback? onRestore;
  final VoidCallback? onClose;

  const VAppBar({
    super.key,
    this.height = 40,
    required this.title,
    this.showMinimize = true,
    this.showMaximize = true,
    this.showClose = true,
    this.goHome = true,
    this.onMinimize,
    this.onMaximize,
    this.onRestore,
    this.onClose,
  });

  @override
  State<VAppBar> createState() => _VAppBarState();

  @override
  Size get preferredSize => Size(double.infinity, height);
}

class _VAppBarState extends State<VAppBar> {
  bool isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.isMaximized().then((onValue) {
      setState(() {
        isMaximized = onValue;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMacOS = Platform.isMacOS;
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (_) async => await windowManager.startDragging(),
        onDoubleTap: () async {
          if (isMaximized) {
            await windowManager.restore();
            isMaximized = false;
            if (widget.onRestore != null) {
              widget.onRestore!();
            }
          } else {
            await windowManager.maximize();
            isMaximized = true;
            if (widget.onMaximize != null) {
              widget.onMaximize!();
            }
          }
          setState(() {});
        },
        child: Container(
          height: 40,
          padding: const EdgeInsets.all(4),
          color: Colors.transparent,
          child: isMacOS ? _buildMacLayout() : _buildDefaultLayout(),
        ),
      ),
    );
  }

  Widget _buildMacLayout() {
    const double trafficLightInset = 72;
    final bool showThemeToggle = currentThemeSetting != AppThemeSetting.system;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final IconData themeIcon = isDark
        ? Icons.light_mode_rounded
        : Icons.dark_mode_rounded;

    return Row(
      children: [
        const SizedBox(width: trafficLightInset),
        const Spacer(),
        if (widget.goHome) ...[
          _buildAppBarButton(Icons.home_rounded, () async {
            go(BrandPage());
          }),
          const SizedBox(width: 4),
        ],
        if (showThemeToggle)
          _buildAppBarButton(themeIcon, () {
            toggleLightDarkTheme();
          }),
        const SizedBox(width: 8),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Align(alignment: Alignment.centerRight, child: widget.title),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultLayout() {
    final bool showThemeToggle = currentThemeSetting != AppThemeSetting.system;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final IconData themeIcon = isDark
        ? Icons.light_mode_rounded
        : Icons.dark_mode_rounded;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final windowButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showMinimize)
          _buildAppBarButton(Icons.remove, () async {
            await windowManager.minimize();
            if (widget.onMinimize != null) {
              widget.onMinimize!();
            }
          }),
        if (widget.showMinimize) const SizedBox(width: 6),
        if (widget.showMaximize)
          _buildAppBarButton(
            isMaximized ? Icons.filter_none : Icons.crop_square,
            () async {
              if (isMaximized) {
                await windowManager.restore();
                isMaximized = false;
                if (widget.onRestore != null) {
                  widget.onRestore!();
                }
              } else {
                await windowManager.maximize();
                isMaximized = true;
                if (widget.onMaximize != null) {
                  widget.onMaximize!();
                }
              }
              setState(() {});
            },
          ),
        if (widget.showMaximize) const SizedBox(width: 6),
        if (widget.showClose)
          _buildAppBarButton(Icons.close, () async {
            await windowManager.hide(); // 仅隐藏窗口
            if (widget.onClose != null) {
              widget.onClose!();
            }
          }, color: scheme.error),
      ],
    );

    return Row(
      children: [
        if (widget.goHome) ...[
          _buildAppBarButton(Icons.home_rounded, () async {
            go(BrandPage());
          }),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 12),
            child: Align(alignment: Alignment.centerLeft, child: widget.title),
          ),
        ),
        const Spacer(),
        if (showThemeToggle)
          _buildAppBarButton(themeIcon, () {
            toggleLightDarkTheme();
          }),
        if (showThemeToggle) const SizedBox(width: 8),
        windowButtons,
      ],
    );
  }

  /// **窗口按钮组件**
  Widget _buildAppBarButton(
    IconData icon,
    VoidCallback onPressed, {
    Color? color,
    double padding = 5,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color effectiveColor =
        color ?? scheme.onSurfaceVariant.withValues(alpha: 0.9);
    double size = widget.height - 8;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: IconButton(
        padding: EdgeInsets.all(padding),
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: size / 3 * 2 - padding - 1,
          color: effectiveColor,
        ),
      ),
    );
  }
}
