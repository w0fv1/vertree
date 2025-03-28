import 'package:flutter/material.dart';
import 'package:vertree/I18nLang.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/TreeBuilder.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/Loading.dart';
import 'package:vertree/view/module/FileTree.dart';
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
  bool isLoading = true;

  @override
  void initState() {
    focusNode = FileNode(path);

    windowManager.maximize();

    super.initState();
    Future.wait([buildTree(path), Future.delayed(Duration(milliseconds: 500))]).then((results) {
      final fileNodeResult = results[0];
      setState(() {
        rootNode = fileNodeResult.unwrap();
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VAppBar(
        title: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage("assets/img/logo/logo.png"), fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              appLocale.getText(AppLocale.vertree_fileTreeTitle).tr([
                rootNode?.mate.name ?? "",
                rootNode?.mate.extension ?? "",
              ]),
            ),
          ],
        ),
      ),
      body: LoadingWidget(
        isLoading: isLoading,
        child:
            rootNode != null
                ? FileTree(
                  rootNode: rootNode!,
                  focusNode: focusNode,
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                )
                : Container(),
      ),
    );
  }
}
