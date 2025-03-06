import 'package:flutter/material.dart';

import 'CanvasComponent.dart';

class TreeCanvasManager {
  late String Function(
    CanvasComponent Function(
      GlobalKey<CanvasComponentState> key,
      TreeCanvasManager treeCanvasManager,
    )
    builder
  )
  put;
  late void Function(String id, Offset offset) move;

  late void Function(String id, Offset position) jump;


  // 新增的
  late void Function(String) raiseOneLayer;
  late void Function(String) lowerOneLayer;

  late void Function(String startId, String endId) connectPoints;
}
