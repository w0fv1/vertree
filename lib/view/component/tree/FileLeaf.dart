import 'package:flutter/material.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/utils/StringUtils.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';

class FileLeaf extends CanvasComponent {
  FileLeaf(this.fileNode, {required this.sprout, super.key, required super.position, required super.treeCanvasManager});

  final FileNode fileNode;

  final void Function(FileNode parentNode, Offset parentPosition, GlobalKey<CanvasComponentState> parentKey) sprout;

  @override
  _FileNodeState createState() => _FileNodeState();
}

class _FileNodeState extends CanvasComponentState<FileLeaf> {
  FileNode get fileNode => widget.fileNode;

  String? childId;
  List<String> topBranchIds = [];
  List<String> bottomBranchIds = [];

  @override
  void onInitState() {
    super.dragable = false;
  }

  @override
  Widget buildComponent() {
    return GestureDetector(
      onTap: () {
        _showOpenFileDialog();
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.only(top: 4, bottom: 4, left: 18, right: 10),
        child: Row(
          children: [
            Text(
              "${StringUtils.truncate(fileNode.mate.name, 12)} ${fileNode.version.toString()}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            IconButton(
              iconSize: 20,
              icon: Center(child: Icon(Icons.save, color: Colors.white, size: 14)),
              onPressed: () {
                widget.sprout(fileNode, position, widget.canvasComponentKey);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示打开文件的确认对话框
  void _showOpenFileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("打开文件 ${fileNode.mate.name}.${fileNode.mate.extension} ?"),
          content: Text("即将打开 \"${fileNode.mate.name}.${fileNode.mate.extension}\" ${fileNode.mate.version} 版"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
              },
              child: Text("取消"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
                FileUtils.openFile(fileNode.mate.fullPath); // 执行打开文件
              },
              child: Text("确认"),
            ),
          ],
        );
      },
    );
  }
}
