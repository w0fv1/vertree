import 'package:flutter/material.dart';

class AnchorLayout extends StatelessWidget {
  const AnchorLayout({
    super.key,
    required this.child,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final Widget child;
  final Widget? top;
  final Widget? right;
  final Widget? bottom;
  final Widget? left;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (top != null) top!,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (left != null) left!,
              child,
              if (right != null) right!,
            ],
          ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}
