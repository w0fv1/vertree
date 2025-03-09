import 'package:flutter/material.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/TreeBuilder.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/Loading.dart';
import 'package:vertree/view/component/tree/FileTree.dart';
import 'package:window_manager/window_manager.dart';

class FileTreePage extends StatefulWidget {
  const FileTreePage({super.key, required this.path});

  final String path;

  @override
  State<FileTreePage> createState() => _FileTreePageState();
}
class _FileTreePageState extends State<FileTreePage> {
  late String path = widget.path;
  late FileNode focusNode;
  FileNode? rootNode;
  bool isLoading = true; // 加载状态

  @override
  void initState() {
    focusNode = FileNode(path);

    windowManager.maximize();

    super.initState();
    // 同时等待构建文件树和500ms延时
    Future.wait([
      buildTree(path),
      Future.delayed(Duration(milliseconds: 500)),
    ]).then((results) {
      // 第一个结果为构建文件树的结果
      final fileNodeResult = results[0];
      setState(() {
        rootNode = fileNodeResult.unwrap();
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertree维树',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.white)),
      home: Scaffold(
        appBar: VAppBar(
          title: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  image: DecorationImage(image: AssetImage("assets/img/logo/logo.png"), fit: BoxFit.contain),
                ),
              ),
              SizedBox(width: 8),
              Text(
                "${rootNode?.mate.name ?? ""}.${rootNode?.mate.extension ?? ""}文本版本树",
              ),
            ],
          ),
        ),
        body: LoadingWidget(
          isLoading: isLoading,
          child: rootNode != null
              ? FileTree(
            rootNode: rootNode!,
            focusNode: focusNode,
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
          )
              : Container(),
        ),
      ),
    );
  }
}

