import 'package:flutter/material.dart';
import 'package:vertree/component/I18nLang.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
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

    var fileTreeWindowsStatus = configer.get("fileTreeWindowsStatus", "maximize");

    if (fileTreeWindowsStatus == "maximize") {
      windowManager.maximize();
    } else {
      windowManager.restore();
    }

    super.initState();

    Future.wait([buildTree(path), Future.delayed(Duration(milliseconds: 200))]).then((results) {
      Result<FileNode, void> buildTreeResult = results[0];
      if (buildTreeResult.isErr) {
        showToast(buildTreeResult.msg);
        isLoading = false;
        return;
      }
      setState(() {
        rootNode = buildTreeResult.unwrap();
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
              appLocale.getText(LocaleKey.vertree_fileTreeTitle).tr([
                rootNode?.mate.name ?? "",
                rootNode?.mate.extension ?? "",
              ]),
            ),
          ],
        ),
        onMinimize: () {
          print('Window minimized');
        },
        onMaximize: () {
          configer.set("fileTreeWindowsStatus", "maximize");
        },
        onRestore: () {
          configer.set("fileTreeWindowsStatus", "restore");
        },
        onClose: () {
          print('Window closed');
        },
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
