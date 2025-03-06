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

  FileTreeCanvasPainter(this.edges, this.baseOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final controlPointPaint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 4.0
          ..style = PaintingStyle.fill;

    for (var edge in edges) {
      var start = edge.startPoint.currentState?.getCenterPosition() ?? Offset.zero;
      var end = edge.endPoint.currentState?.getCenterPosition() ?? Offset.zero;
      // Ensure start is always the leftmost and end is always the rightmost

      // 计算控制点，使曲线形成“圆角直角”效果
      Offset controlPoint;

      if (start.dx < end.dx) {
        controlPoint = Offset(start.dx, end.dy + (end.dy - end.dx) * 0.02);
      } else {
        controlPoint = Offset(end.dx, start.dy + (start.dy - start.dx) * 0.02);
      }

      final path =
          Path()
            ..moveTo(start.dx + baseOffset.dx, start.dy + baseOffset.dy)
            ..quadraticBezierTo(
              controlPoint.dx + baseOffset.dx,
              controlPoint.dy + baseOffset.dy,
              end.dx + baseOffset.dx,
              end.dy + baseOffset.dy,
            );

      canvas.drawPath(path, paint);

      // 绘制控制点，方便调试
      canvas.drawCircle(controlPoint + baseOffset, 2, controlPointPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
