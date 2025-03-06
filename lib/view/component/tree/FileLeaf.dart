import 'package:flutter/material.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/core/FileVersionTree.dart';
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
  Widget buildComponent() {
    return GestureDetector(
      onTap: (){
        FileUtils.openFile(fileNode.mate.fullPath);
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
        padding: EdgeInsets.only(top: 4, bottom: 4, left: 18, right: 10),
        child: Row(
          children: [
            Text(
              "${fileNode.mate.name} ${fileNode.version.toString()}",
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
}
