import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/main.dart';

Future<Result<FileNode, void>> buildTree(String selectedFileNodePath) async {
  // print("selectedFileNodePath $selectedFileNodePath");

  final Map<String, FileNode> fileVersionMap = {};
  FileNode selectedFileNode = FileNode(selectedFileNodePath);
  // print("selectedFileNode $selectedFileNode");
  String dirname = path.dirname(selectedFileNodePath);

  final files = await Directory(dirname).list().toList();

  // 过滤掉所有 name 与 selectedFileNode 不相同的文件
  final filteredFiles =
      files.where((file) {
        FileMeta? fileMeta;
        try {
          if (file is! File) return false;

          fileMeta = FileMeta(file.path);
        } catch (e) {
          logger.error("$e");
          return false;
        }

        return fileMeta.name == selectedFileNode.mate.name;
      }).toList();

  List<FileNode> fileNodes = [];

  // 找到 version 最低的文件作为 rootNode
  FileNode? rootNode;

  for (var file in filteredFiles) {
    final fileMeta = FileMeta(file.path);
    final fileNode = FileNode(file.path);
    fileNodes.add(fileNode);

    if (rootNode == null || fileMeta.version.compareTo(rootNode.mate.version) < 0) {
      rootNode = fileNode;
    }
  }

  if (rootNode == null) {
    return Result.eMsg("未找到根节点");
  }

  // 自定义排序方法：
  fileNodes.sort((a, b) => a.mate.version.compareTo(b.mate.version));

  List<FileNode> sortedFileNodes = fileNodes;

  for (var node in sortedFileNodes) {
    // print(node.mate.version.toString());
    rootNode.push(node);
  }

  return Result.ok(rootNode);
}
