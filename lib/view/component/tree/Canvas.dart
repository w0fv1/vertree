import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';
import 'package:vertree/view/component/tree/EdgePainter.dart';
import 'CanvasManager.dart';

class TreeCanvas extends StatefulWidget {
  final TreeCanvasManager manager;
  final double height;
  final double width;
  final List<CanvasComponentContainer>? children;
  final List<Edge>? edges;

  const TreeCanvas({super.key, required this.manager, this.height = 300, this.width = 500, this.children, this.edges});

  @override
  _TreeCanvasState createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<TreeCanvas> with TickerProviderStateMixin {
  final Map<String, CanvasComponentContainer> components = {};
  int indexCounter = 0; // 控制 index 递增
  late final List<Edge> edges = [...widget.edges ?? []]; // 存储所有的连线

  bool isDragging = false;

  Offset canvasPosition = Offset(-2000, -2000);

  Offset componentBaseOffset = Offset(2000, 2000);

  double _scale = 1.0;
  double minScale = 0.5;
  double maxScale = 3.0;
   SystemMouseCursor _cursor = SystemMouseCursors.allScroll;

  @override
  void initState() {

    widget.manager.put = put;

    widget.manager.move = move;
    widget.manager.jump = jump;

    // 新增的两个方法
    widget.manager.raiseOneLayer = raiseOneLayer;
    widget.manager.lowerOneLayer = lowerOneLayer;

    widget.manager.connectPoints = connectPoints;

    if (widget.children != null) {
      for (var child in widget.children!) {
        add(child);
      }
    }

    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          setState(() {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localFocalPoint = box.globalToLocal(pointerSignal.position);
            final zoomFactor = 0.1;
            double newScale = _scale;

            if (pointerSignal.scrollDelta.dy < 0) {
              newScale = _scale * (1 + zoomFactor);
            } else {
              newScale = _scale * (1 - zoomFactor);
            }

            newScale = newScale.clamp(minScale, maxScale);

            final scaleChange = newScale / _scale;
            canvasPosition = localFocalPoint - (localFocalPoint - canvasPosition) * scaleChange;
            _scale = newScale;
          });
        }
      },
      child: Container(
        height: widget.height,
        width: widget.width,
        child: Stack(
          children: [
            Positioned(
              top: canvasPosition.dy,
              left: canvasPosition.dx,
              child: Transform.scale(
                scale: _scale,
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onPanStart: (_) {
                    setState(() {
                      isDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      canvasPosition += (details.delta * _scale);
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      isDragging = false;
                    });
                  },
                  child: MouseRegion(
                    cursor: _cursor ,

                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(size: Size(4000, 4000), painter: FileTreeCanvasPainter(edges, Offset(2000, 2000))),

                        ...(components.values.toList()..sort((a, b) => a.index.compareTo(b.index))).map((e) {
                          e.canvasComponent.offset = componentBaseOffset;
                          return e.canvasComponent;
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void add(CanvasComponentContainer canvasComponentContainer) {
    canvasComponentContainer.index = indexCounter++;
    components[canvasComponentContainer.id] = canvasComponentContainer;
  }

  String put(CanvasComponent Function(GlobalKey<CanvasComponentState> key, TreeCanvasManager manager) builder) {
    GlobalKey<CanvasComponentState> globalKey = GlobalKey();
    var canvasComponent = builder(globalKey, widget.manager); // 递增 index

    setState(() {
      components[canvasComponent.id] = CanvasComponentContainer(canvasComponent, globalKey, indexCounter++);
    });
    return canvasComponent.id;
  }

  void move(String id, Offset offset) {
    setState(() {
      components[id]?.key.currentState?.position += offset;
    });
  }

  void jump(String id, Offset position) {
    setState(() {
      components[id]?.key.currentState?.setPosition(position);
    });
  }

  void raiseOneLayer(String id) {
    final container = components[id];
    if (container == null) return;

    // 先按 index 排好序，找出当前组件位置
    List<CanvasComponentContainer> sorted = components.values.toList()..sort((a, b) => a.index.compareTo(b.index));
    int currentPos = sorted.indexOf(container);

    // 如果已经在最顶层，就无法再升高一层
    if (currentPos >= sorted.length - 1) return;

    // 与上面一层（pos+1）交换 index
    final upper = sorted[currentPos + 1];
    final tempIndex = container.index;
    container.index = upper.index;
    upper.index = tempIndex;

    setState(() {});
  }

  /// 降低一层：与下方（index 更小）的那个组件交换 index
  void lowerOneLayer(String id) {
    final container = components[id];
    if (container == null) return;

    // 先按 index 排好序，找出当前组件位置
    List<CanvasComponentContainer> sorted = components.values.toList()..sort((a, b) => a.index.compareTo(b.index));
    int currentPos = sorted.indexOf(container);

    // 如果已经在最底层，就无法再降低一层
    if (currentPos <= 0) return;

    // 与下面一层（pos-1）交换 index
    final lower = sorted[currentPos - 1];
    final tempIndex = container.index;
    container.index = lower.index;
    lower.index = tempIndex;

    setState(() {});
  }

  void connectPoints(String startId, String endId) {
    final startComponent = components[startId];
    final endComponent = components[endId];

    if (startComponent == null || endComponent == null) return;

    setState(() {
      edges.add(Edge(startComponent.key, endComponent.key));
    });
  }
}

class CanvasComponentContainer {
  final String id;
  final CanvasComponent canvasComponent;
  late final GlobalKey<CanvasComponentState> key;
  late int index; // 组件的层级 index

  CanvasComponentContainer(this.canvasComponent, this.key, this.index) : id = canvasComponent.id;

  CanvasComponentContainer.component(this.canvasComponent)
    : id = canvasComponent.id,
      key = canvasComponent.canvasComponentKey;
}
