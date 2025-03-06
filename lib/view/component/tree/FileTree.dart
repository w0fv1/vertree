import 'package:flutter/material.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';
import 'package:vertree/view/component/tree/EdgePainter.dart';
import 'package:vertree/view/component/tree/Canvas.dart';
import 'package:vertree/view/component/tree/CanvasManager.dart';
import 'package:vertree/view/component/tree/FileLeaf.dart';

class FileTree extends StatefulWidget {
  const FileTree({super.key, required this.rootNode, required this.height, required this.width});

  final double height;
  final double width;
  final FileNode rootNode;

  @override
  State<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<FileTree> {
  final double _Xmobility = 200;
  final double _Ymobility = 60;

  FileNode get rootNode => widget.rootNode;
  final TreeCanvasManager treeCanvasManager = TreeCanvasManager();

  List<CanvasComponentContainer> canvasComponentContainers = [];
  List<Edge> edges = [];
  late final GlobalKey<CanvasComponentState> rootKey;
  late var initPosition = Offset(_Xmobility, widget.height / 2 - _Ymobility / 2);

  @override
  void initState() {
    rootKey = addChild(rootNode, initPosition);
    _buildTree(rootNode, initPosition, rootKey);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {


    return TreeCanvas(
      key: ValueKey(canvasComponentContainers.hashCode),
      height: widget.height,
      width: widget.width,
      manager: treeCanvasManager,
      children: canvasComponentContainers,
      edges: edges,
    );
  }

  void sprout(FileNode parentNode, Offset parentPosition, GlobalKey<CanvasComponentState> parentKey) async {
    Result<FileNode, String> sproutResult;


    if (parentNode.child == null) {
      sproutResult = await parentNode.backup();
      if (sproutResult.isErr) {
        return;
      }

      Offset childPosition = parentPosition + Offset(_Xmobility, 0);

      // 获取新生成的节点
      FileNode shoot = sproutResult.unwrap();
      setState(() {
        addChild(shoot, childPosition, parentKey: parentKey);
        canvasComponentContainers = List.from(canvasComponentContainers); // 强制 Flutter 识别变化
      });
    } else {
      sproutResult = await parentNode.branch();
      if (sproutResult.isErr) {
        return;
      }
      // 获取新生成的节点
      FileNode shoot = sproutResult.unwrap();

      bool top = shoot.mate.version.segments.last.branch % 2 == 0;
      double height = shoot.getParentRelativeHeight().toDouble();

      Offset branchPosition = parentPosition + Offset(_Xmobility, (top ? -_Ymobility : _Ymobility) * height);
      // 作为分支
      setState(() {
        addChild(shoot, branchPosition, parentKey: parentKey);
        canvasComponentContainers = List.from(canvasComponentContainers); // 强制 Flutter 识别变化
      });
    }
  }

  void _buildTree(FileNode fileNode, Offset parentPosition, GlobalKey<CanvasComponentState> parentKey) {
    // 处理子节点
    if (fileNode.child != null) {
      Offset childPosition = parentPosition + Offset(_Xmobility, 0);

      GlobalKey<CanvasComponentState> childKey = addChild(fileNode.child!, childPosition, parentKey: parentKey);
      _buildTree(fileNode.child!, parentPosition + Offset(_Xmobility, 0), childKey);
    }

    // 处理分支节点
    for (FileNode branch in fileNode.branches) {
      bool top = branch.mate.version.segments.last.branch % 2 == 0;

      double height = branch.getParentRelativeHeight().toDouble();

      Offset branchPosition = parentPosition + Offset(_Xmobility, (top ? -_Ymobility : _Ymobility) * height);
      GlobalKey<CanvasComponentState> childKey = addChild(branch, branchPosition, parentKey: parentKey);
      _buildTree(branch, branchPosition, childKey);
    }
  }

  /// **绘制子节点并连接**
  GlobalKey<CanvasComponentState> addChild(
    FileNode child,
    Offset childPosition, {
    GlobalKey<CanvasComponentState>? parentKey,
  }) {
    GlobalKey<CanvasComponentState> childKey = GlobalKey<CanvasComponentState>();

    canvasComponentContainers.add(
      CanvasComponentContainer.component(
        FileLeaf(child, sprout: sprout, key: childKey, treeCanvasManager: treeCanvasManager, position: childPosition),
      ),
    );

    if (parentKey != null) {
      edges.add(Edge(parentKey, childKey));
    }

    return childKey;
  }
}
