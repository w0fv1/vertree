import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:vertree/view/component/SizeListenerWidget.dart';
import 'package:vertree/view/component/tree/CanvasManager.dart';

abstract class CanvasComponent extends StatefulWidget {
  final GlobalKey<CanvasComponentState> canvasComponentKey;
  final String id;
  final TreeCanvasManager treeCanvasManager;
  Offset position;
  late Offset offset = Offset.zero;

  // 修正 constructor，确保传递的 key 被赋值给 canvasComponentKey
  CanvasComponent({
    required super.key, // 父类的 key
    required this.treeCanvasManager,
    this.position = Offset.zero,
  }) : // 备份传递的 key 到 canvasComponentKey
       canvasComponentKey = key as GlobalKey<CanvasComponentState>,
       id = const Uuid().v4();
}

abstract class CanvasComponentState<T extends CanvasComponent> extends State<T> with SingleTickerProviderStateMixin {
  late Offset position = widget.position;
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  SystemMouseCursor _cursor = SystemMouseCursors.click;

  @override
  void initState() {
    onInitState();

    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _animation = Tween<Offset>(
      begin: widget.position,
      end: widget.position,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animation.addListener(() {
      setPosition(_animation.value);
    });
  }

  void onInitState() {
    return;
  }

  String getId() {
    return widget.id;
  }

  Offset getCenterPosition() {
    return position + Offset(size.width / 2, size.height / 2);
  }

  bool isDragging = false;

  bool dragable = false;

  double scale = 1.0; // 初始缩放比例
  bool isHovered = false;

  void setPosition(Offset position) {
    setState(() {
      this.position = position;
    });
  }

  Size size = Size.zero;

  @override
  Widget build(BuildContext context) {
    return SizeListenerWidget(
      onSizeChange: (Size size) {
        setState(() {
          this.size = size;
        });
      },
      child: Positioned(
        left: position.dx + widget.offset.dx,
        top: position.dy + widget.offset.dy,
        child: MouseRegion(
          cursor: _cursor,
          onEnter: (_) {
            if (!isDragging) {
              setState(() {
                scale = 1.02; // 鼠标悬停放大 1.1 倍
              });
              isHovered = true;
            }
          },
          onExit: (_) {
            if (!isDragging) {
              setState(() {
                scale = 1.0; // 鼠标移出恢复正常大小
              });
              isHovered = false;
            }
          },
          child: GestureDetector(
            onPanStart: (_) {
              setState(() {
                isDragging = true;
                scale = 1.1; // 拖动时放大 1.2 倍
                _cursor = SystemMouseCursors.allScroll;
              });
            },
            onPanUpdate: (details) {
              if (!dragable) {
                return;
              }
              setState(() {
                position += details.delta;
                _cursor = SystemMouseCursors.allScroll;
              });
            },
            onPanEnd: (_) {
              setState(() {
                isDragging = false;
                if (isHovered) {
                  scale = 1.02;
                } else {
                  scale = 1.0; // 拖动结束恢复正常大小
                }
                _cursor = SystemMouseCursors.grab;
              });
            },
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 200), // 200ms 动画
              curve: Curves.easeInOut,
              child: buildComponent(),
            ),
          ),
        ),
      ),
    );
  }

  String put(
    CanvasComponent Function(GlobalKey<CanvasComponentState> key, TreeCanvasManager treeCanvasManager) builder,
    Offset position,
  ) {
    return widget.treeCanvasManager.put(builder);
  }

  void animateMove(Offset targetOffset) {
    _animation = Tween<Offset>(
      begin: position,
      end: position + targetOffset,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward(from: 0.0); // 重新启动动画
  }

  void move(Offset offset) {
    setPosition(position += offset);
  }

  void raiseLayer() {
    setState(() {
      widget.treeCanvasManager.raiseOneLayer(widget.id);
    });
  }

  void lowerLayer() {
    setState(() {
      widget.treeCanvasManager.lowerOneLayer(widget.id);
    });
  }

  Widget buildComponent();

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
