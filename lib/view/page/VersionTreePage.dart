import 'package:flutter/material.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/TreeBuilder.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/tree/FileTree.dart';

class FileTreePage extends StatefulWidget {
  const FileTreePage({super.key, required this.path});

  final String path;

  @override
  State<FileTreePage> createState() => _FileTreePageState();
}

class _FileTreePageState extends State<FileTreePage> {
  late String path = widget.path;
  FileNode? rootNode;

  @override
  void initState() {
    super.initState();
    buildTree(path).then((fileNodeResult) {
      setState(() {
        rootNode = fileNodeResult.unwrap();
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
                height: 20, // 4:3 aspect ratio (400x300)
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
          showMaximize: false,
        ),
        body:
            rootNode != null
                ? FileTree(
                  rootNode: rootNode!,
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                )
                : Container(),
      ),
    );
  }
}
