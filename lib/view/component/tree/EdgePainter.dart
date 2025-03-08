import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';
import 'package:vertree/view/component/tree/Point.dart';

class Edge {
  final GlobalKey<CanvasComponentState> startPoint;
  final GlobalKey<CanvasComponentState> endPoint;

  Edge(this.startPoint, this.endPoint);
}

class FileTreeCanvasPainter extends CustomPainter {
  final List<Edge> edges;
  final Offset baseOffset;
  final bool showDebugPoints; // 调试点开关

  FileTreeCanvasPainter(this.edges, this.baseOffset, {this.showDebugPoints = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 调试用：绘制关键点的画笔
    final debugPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4.0
      ..style = PaintingStyle.fill;

    for (var edge in edges) {
      // 获取起点和终点的中心位置，并加上基础偏移
      var start = edge.startPoint.currentState?.getCenterPosition() ?? Offset.zero;
      var end = edge.endPoint.currentState?.getCenterPosition() ?? Offset.zero;
      Offset s = start + baseOffset;
      Offset e = end + baseOffset;

      // 计算水平和垂直的差值
      double dx = e.dx - s.dx;
      double dy = e.dy - s.dy;

      // 计算圆角半径，取dx和dy的最小绝对值，如果大于20则为20
      double dynamicR = min(dx.abs(), dy.abs());
      double r = dynamicR > 20 ? 20 : dynamicR;

      Path path = Path();

      // 如果水平或垂直距离不足圆角半径，则直接绘制直线
      if (dx.abs() < r || dy.abs() < r) {
        path.moveTo(s.dx, s.dy);
        path.lineTo(e.dx, e.dy);
      } else {
        // 固定采用【先垂直后水平】的路线，拐角设为 (s.dx, e.dy)
        // 计算垂直段终点 p1（预留圆角空间）
        Offset p1 = dy > 0 ? Offset(s.dx, e.dy - r) : Offset(s.dx, e.dy + r);
        // 计算水平段起点 p2（预留圆角空间）
        Offset p2 = dx > 0 ? Offset(s.dx + r, e.dy) : Offset(s.dx - r, e.dy);

        // 根据 dx 和 dy 确定圆角绘制方向：
        // 如果 endPoint 在右侧（dx > 0）则统一采用 clockwise = true；
        // 如果在左侧（dx < 0）：若 endPoint 在下方 (dy > 0) 则 clockwise = false，
        // 若在上方 (dy < 0) 则 clockwise = true。
        bool clockwise;
        if (dx > 0) {
          clockwise = dy > 0 ? false : true;
        } else {
          clockwise = dy < 0 ? false : true;
        }

        path.moveTo(s.dx, s.dy);
        path.lineTo(p1.dx, p1.dy);
        path.arcToPoint(
          p2,
          radius: Radius.circular(r),
          clockwise: clockwise,
        );
        path.lineTo(e.dx, e.dy);

        // 如果打开调试点，则绘制关键点
        if (showDebugPoints) {
          canvas.drawCircle(p1, 2, debugPaint);
          canvas.drawCircle(p2, 2, debugPaint);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
