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
  final Size sceneSize;
  final List<CanvasComponentContainer>? children;
  final List<Edge>? edges;
  final int revision;

  final Future<void> Function() refresh;

  const TreeCanvas({
    super.key,
    required this.manager,
    this.height = 300,
    this.width = 500,
    this.sceneSize = Size.zero,
    this.children,
    this.edges,
    this.revision = 0,
    required this.refresh,
  });

  @override
  _TreeCanvasState createState() => _TreeCanvasState();
}

class _TreeCanvasState extends State<TreeCanvas> with TickerProviderStateMixin {
  static const double _fitPadding = 40;
  final Map<String, CanvasComponentContainer> components = {};
  int indexCounter = 0; // 控制 index 递增
  List<Edge> edges = []; // 存储所有的连线

  bool isDragging = false;

  Offset canvasPosition = Offset.zero;

  double _scale = 1.0;
  double minScale = 0.18;
  double maxScale = 3.0;
  SystemMouseCursor _cursor = SystemMouseCursors.allScroll;

  @override
  void initState() {
    widget.manager.put = put;
    widget.manager.move = move;
    widget.manager.jump = jump;
    widget.manager.raiseOneLayer = raiseOneLayer;
    widget.manager.lowerOneLayer = lowerOneLayer;
    widget.manager.connectPoints = connectPoints;
    widget.manager.setScale = setScale;
    widget.manager.fitScene = fitScene;
    widget.manager.getScale = getScale;

    _syncCanvasContent();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant TreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _syncCanvasContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sceneSize = widget.sceneSize == Size.zero
        ? Size(widget.width, widget.height)
        : widget.sceneSize;

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          setState(() {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localFocalPoint = box.globalToLocal(pointerSignal.position);
            final zoomFactor = pointerSignal.scrollDelta.dy < 0 ? 1.1 : 0.9;
            _applyScale(_scale * zoomFactor, focalPoint: localFocalPoint);
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) {
          setState(() {
            isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            canvasPosition += details.delta;
          });
        },
        onPanEnd: (_) {
          setState(() {
            isDragging = false;
          });
        },
        child: MouseRegion(
          cursor: _cursor,
          child: SizedBox(
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
                    child: SizedBox(
                      width: sceneSize.width,
                      height: sceneSize.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: sceneSize,
                            painter: FileTreeCanvasPainter(
                              edges,
                              Offset.zero,
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.92,
                              ),
                              debugColor: scheme.primary,
                              repaint: widget.manager.repaintNotifier,
                            ),
                          ),
                          ...(components.values.toList()
                                ..sort((a, b) => a.index.compareTo(b.index)))
                              .map((e) {
                                return e.canvasComponent;
                              }),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Card.filled(
                    color: scheme.surfaceContainerHigh.withValues(alpha: 0.94),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: IconButton.filledTonal(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).refreshIndicatorSemanticLabel,
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () async {
                          await widget.refresh();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void add(CanvasComponentContainer canvasComponentContainer) {
    canvasComponentContainer.index = indexCounter++;
    components[canvasComponentContainer.id] = canvasComponentContainer;
  }

  void _syncCanvasContent() {
    components.clear();
    edges = [...widget.edges ?? []];
    indexCounter = 0;

    if (widget.children != null) {
      for (final child in widget.children!) {
        add(child);
      }
    }
  }

  double getScale() {
    return _scale;
  }

  void setScale(double scale) {
    setState(() {
      _applyScale(scale);
    });
  }

  void fitScene() {
    final sceneSize = widget.sceneSize == Size.zero
        ? Size(widget.width, widget.height)
        : widget.sceneSize;
    final availableWidth = (widget.width - (_fitPadding * 2)).clamp(
      1.0,
      double.infinity,
    );
    final availableHeight = (widget.height - (_fitPadding * 2)).clamp(
      1.0,
      double.infinity,
    );
    final fittedScale = [
      availableWidth / sceneSize.width,
      availableHeight / sceneSize.height,
    ].reduce((value, element) => value < element ? value : element);

    setState(() {
      _scale = fittedScale.clamp(minScale, maxScale);
      canvasPosition = Offset(
        (widget.width - (sceneSize.width * _scale)) / 2,
        (widget.height - (sceneSize.height * _scale)) / 2,
      );
    });
  }

  void _applyScale(double nextScale, {Offset? focalPoint}) {
    final clampedScale = nextScale.clamp(minScale, maxScale);
    if (focalPoint == null) {
      _scale = clampedScale;
      return;
    }
    final scaleChange = clampedScale / _scale;
    canvasPosition = focalPoint - (focalPoint - canvasPosition) * scaleChange;
    _scale = clampedScale;
  }

  String put(
    CanvasComponent Function(
      GlobalKey<CanvasComponentState> key,
      TreeCanvasManager manager,
    )
    builder,
  ) {
    GlobalKey<CanvasComponentState> globalKey = GlobalKey();
    var canvasComponent = builder(globalKey, widget.manager); // 递增 index

    setState(() {
      components[canvasComponent.id] = CanvasComponentContainer(
        canvasComponent,
        globalKey,
        indexCounter++,
      );
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
    List<CanvasComponentContainer> sorted = components.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
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
    List<CanvasComponentContainer> sorted = components.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
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
      edges.add(
        Edge(startComponent.key, endComponent.key, id: '$startId->$endId'),
      );
    });
  }
}

class CanvasComponentContainer {
  final String id;
  final CanvasComponent canvasComponent;
  late final GlobalKey<CanvasComponentState> key;
  late int index; // 组件的层级 index

  CanvasComponentContainer(this.canvasComponent, this.key, this.index)
    : id = canvasComponent.id;

  CanvasComponentContainer.component(this.canvasComponent)
    : id = canvasComponent.id,
      key = canvasComponent.canvasComponentKey;
}
