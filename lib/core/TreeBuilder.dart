import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';

Future<Result<FileNode, String>> buildTree(String selectedFileNodePath) async {
  FileNode? rootNode;

  try {
    if (!File(selectedFileNodePath).existsSync()) {
      return Result.eMsg("文件路径不存在");
    }
    if (!FileMeta.isSupportedTreeFilePath(selectedFileNodePath)) {
      return Result.eMsg("当前文件命名不支持版本树");
    }

    FileNode selectedFileNode = FileNode(selectedFileNodePath);
    String dirname = path.dirname(selectedFileNodePath);

    final files = await Directory(dirname).list().toList();

    // 过滤掉所有 name 与 extension 不一致，或不满足版本树命名规则的文件
    final filteredFiles = files.where((file) {
      try {
        if (file is! File) return false;
        if (!FileMeta.isSupportedTreeFilePath(file.path)) {
          return false;
        }
        final fileMeta = FileMeta(file.path);
        return fileMeta.name == selectedFileNode.mate.name &&
            fileMeta.extension == selectedFileNode.mate.extension;
      } catch (e) {
        stderr.writeln("$e");
        return false;
      }
    }).toList();

    List<FileNode> fileNodes = [];

    // 找到 version 最低的文件作为 rootNode

    for (var file in filteredFiles) {
      final fileMeta = FileMeta(file.path);
      final fileNode = FileNode(file.path);
      fileNodes.add(fileNode);

      if (rootNode == null ||
          fileMeta.version.compareTo(rootNode.mate.version) < 0) {
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
  } catch (e) {
    return Result.err(e.toString());
  }

  return Result.ok(rootNode);
}
