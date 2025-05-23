import 'package:flutter/material.dart';

import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/component/Loading.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';
import 'package:vertree/view/component/tree/EdgePainter.dart';
import 'package:vertree/view/component/tree/Canvas.dart';
import 'package:vertree/view/component/tree/CanvasManager.dart';
import 'package:vertree/view/module/FileLeaf.dart';

class FileTree extends StatefulWidget {
  const FileTree({super.key, required this.rootNode, required this.height, required this.width, this.focusNode});

  final double height;
  final double width;
  final FileNode rootNode;
  final FileNode? focusNode;

  @override
  State<FileTree> createState() => _FileTreeState();
}

class _FileTreeState extends State<FileTree> {
  final double _Xmobility = 260;
  final double _Ymobility = 60;

  late FileNode rootNode = widget.rootNode;
  final TreeCanvasManager treeCanvasManager = TreeCanvasManager();

  List<CanvasComponentContainer> canvasComponentContainers = [];
  List<Edge> edges = [];
  late GlobalKey<CanvasComponentState> rootKey;
  late var initPosition = Offset(_Xmobility, widget.height / 2 - _Ymobility / 2);

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshTree();
  }

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      isLoading: isLoading,
      child: TreeCanvas(
        key: UniqueKey(),
        height: widget.height,
        width: widget.width,
        manager: treeCanvasManager,
        children: canvasComponentContainers,
        edges: edges,
        refresh: _refreshTree, // 如果 TreeCanvas 支持 refresh 参数
      ),
    );
  }

  /// 当树结构发生变化时，清空所有旧的组件与连线，并重新构建树
  void _refreshTree() {
    // 清空现有组件列表和边
    canvasComponentContainers.clear();
    edges.clear();

    // 从根节点开始重新构建树
    rootKey = addChild(rootNode, initPosition);
    _buildTree(rootNode, initPosition, rootKey);

    // 调用 setState 通知刷新
    setState(() {});
  }

  /// 弹出对话框，询问用户输入备注（label），用户取消则返回 null
  Future<String?> _askForLabel() async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String label = "";
        return AlertDialog(
          title: Text(appLocale.getText(LocaleKey.filetree_inputLabelTitle)),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: appLocale.getText(LocaleKey.filetree_inputLabelHint),
            ),
            onChanged: (value) {
              label = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(appLocale.getText(LocaleKey.filetree_inputCancel)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(label),
              child: Text(appLocale.getText(LocaleKey.filetree_inputConfirm)),
            ),
          ],
        );
      },
    );
  }


  /// sprout 方法：更新数据模型后刷新整个树，同时展示 loading 效果 500ms
  void sprout(FileNode parentNode, Offset parentPosition, GlobalKey<CanvasComponentState> parentKey) async {
    // 弹出对话框询问备注信息
    final label = await _askForLabel();

    setState(() {
      isLoading = true;
    });

    Result<FileNode, String> sproutResult;

    if (parentNode.child == null) {
      sproutResult = await parentNode.backup(label);
      if (sproutResult.isErr) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      // 更新数据模型，设置 child 属性
      parentNode.child = sproutResult.unwrap();
    } else {
      sproutResult = await parentNode.branch(label);
      if (sproutResult.isErr) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      // 添加到分支列表中
      parentNode.branches.add(sproutResult.unwrap());
    }

    // 保证 loading 状态至少展示 500ms
    Future.delayed(const Duration(milliseconds: 500)).then((_) {
      // 数据更新后，刷新整棵树，并取消 loading 状态
      _refreshTree();
      setState(() {
        isLoading = false;
      });
    });
  }

  /// **绘制子节点并连接**
  GlobalKey<CanvasComponentState> addChild(
    FileNode child,
    Offset childPosition, {
    GlobalKey<CanvasComponentState>? parentKey,
  }) {
    GlobalKey<CanvasComponentState> childKey = GlobalKey<CanvasComponentState>();
    bool isFocused = widget.focusNode != null && (widget.focusNode!.version.compareTo(child.version) == 0);
    logger.info(
      "isFocused: $isFocused, widget.focusNode version: ${widget.focusNode?.version}, child version: ${child.version}",
    );

    canvasComponentContainers.add(
      CanvasComponentContainer.component(
        FileLeaf(
          child,
          sprout: sprout,
          key: childKey,
          treeCanvasManager: treeCanvasManager,
          position: childPosition,
          isFocused: isFocused, // 传入焦点状态
        ),
      ),
    );

    if (parentKey != null) {
      edges.add(Edge(parentKey, childKey));
    }

    return childKey;
  }

  void _buildTree(FileNode fileNode, Offset parentPosition, GlobalKey<CanvasComponentState> parentKey) {
    // 处理子节点
    if (fileNode.child != null) {
      Offset childPosition = parentPosition + Offset(_Xmobility, 0);
      GlobalKey<CanvasComponentState> childKey = addChild(fileNode.child!, childPosition, parentKey: parentKey);
      _buildTree(fileNode.child!, childPosition, childKey);
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
}
