import 'package:flutter/material.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/page/BrandPage.dart';
import 'package:vertree/view/page/SettingPage.dart';
import 'package:window_manager/window_manager.dart';

class VAppBar extends StatefulWidget implements PreferredSizeWidget {
  final double height;
  final Widget title;
  final bool showMinimize;
  final bool showMaximize;
  final bool showClose;

  final bool goHome;

  const VAppBar({
    super.key,
    this.height = 40,
    required this.title,
    this.showMinimize = true,
    this.showMaximize = true,
    this.showClose = true,
    this.goHome = true,
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
    return GestureDetector(
      onPanUpdate: (_) async => await windowManager.startDragging(),
      onDoubleTap: () async {
        if (isMaximized) {
          await windowManager.restore();
          isMaximized = false;
        } else {
          await windowManager.maximize();
          isMaximized = true;
        }
        setState(() {});
      },
      child: Container(
        height: 40,
        padding: EdgeInsets.all(4),
        color: Colors.transparent,
        child: Row(
          children: [
            if (widget.goHome)
              _buildAppBarButton(Icons.arrow_back_rounded, () async {
                go(BrandPage());
              }),

            Expanded(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: widget.title,
              ),
            ),
            if (widget.goHome)
              _buildAppBarButton(Icons.home_rounded, () async {
                go(BrandPage());
              }),

            /// **窗口操作按钮**
            Row(
              children: [
                if (widget.showMinimize)
                  _buildAppBarButton(Icons.remove, () async {
                    await windowManager.minimize();
                  }),
                if (widget.showMinimize) const SizedBox(width: 6),

                if (widget.showMaximize)
                  _buildAppBarButton(isMaximized ? Icons.filter_none : Icons.crop_square, () async {
                    if (isMaximized) {
                      await windowManager.restore();
                      isMaximized = false;
                    } else {
                      await windowManager.maximize();
                      isMaximized = true;
                    }
                    setState(() {});
                  }),
                if (widget.showMaximize) const SizedBox(width: 6),

                if (widget.showClose)
                  _buildAppBarButton(Icons.close, () async {
                    await windowManager.hide(); // 仅隐藏窗口
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// **窗口按钮组件**
  Widget _buildAppBarButton(IconData icon, VoidCallback onPressed, {Color color = Colors.black87, double padding = 6}) {
    double size = widget.height - 4;

    return IconButton(
      padding: EdgeInsets.all(padding),
      onPressed: onPressed,
      icon: Icon(icon, size: size / 3 * 2 - padding, color: color),
    );
  }
}
