import 'package:flutter/material.dart';

import 'package:vertree/I18nLang.dart';
import 'package:vertree/MonitService.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/core/FileVersionTree.dart';
import 'package:vertree/core/Result.dart';
import 'package:vertree/main.dart';
import 'package:vertree/utils/StringUtils.dart';
import 'package:vertree/view/component/tree/CanvasComponent.dart';

class FileLeaf extends CanvasComponent {
  FileLeaf(
    this.fileNode, {
    required this.sprout,
    super.key,
    required super.position,
    required super.treeCanvasManager,
    this.isFocused = false, // 新增焦点模式参数
  });

  final FileNode fileNode;
  final bool isFocused; // 判断是否为焦点模式

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
    // 内层容器，包含主要内容
    Widget content = Container(
      decoration: BoxDecoration(
        color: widget.isFocused ? Colors.white : Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 18, right: 10),
      child: Row(
        children: [
          Text(
            "${StringUtils.truncate(fileNode.mate.name, 12)} ${fileNode.version}",
            textAlign: TextAlign.center,
            style: TextStyle(color: (widget.isFocused ? Colors.black : Colors.white)),
          ),
          IconButton(
            iconSize: 20,
            icon: Center(child: Icon(Icons.save, color: (widget.isFocused ? Colors.black : Colors.white), size: 14)),
            onPressed: () {
              widget.sprout(fileNode, position, widget.canvasComponentKey);
            },
          ),
        ],
      ),
    );

    // 如果处于焦点模式，则外层增加渐变边框
    if (widget.isFocused) {
      content = Container(
        decoration: BoxDecoration(
          // 这里使用 LinearGradient 实现渐变效果，颜色可根据需求调整
          gradient: const LinearGradient(colors: [Colors.red, Colors.orange, Colors.yellow]),
          borderRadius: BorderRadius.circular(12), // 外层圆角要比内层大
        ),
        padding: const EdgeInsets.all(2), // 设定边框宽度
        child: content,
      );
    }

    return Tooltip(
      message: _getTooltipMessage(),
      textStyle: const TextStyle(color: Colors.white),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.all(8),
      waitDuration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: () {
          _showOpenFileDialog();
        },
        onSecondaryTapDown: (details) {
          _showContextMenu(details.globalPosition);
        },
        child: content,
      ),
    );
  }

  /// 生成 Tooltip 显示的信息
  String _getTooltipMessage() {
    String label = fileNode.mate.label?.isNotEmpty == true
        ? fileNode.mate.label!
        : appLocale.getText(LocaleKey.fileleaf_noLabel);
    String lastModified = fileNode.mate.lastModifiedTime.toLocal().toString().split('.')[0];
    return "${appLocale.getText(LocaleKey.fileleaf_propertyLabel)}: $label\n"
        "${appLocale.getText(LocaleKey.fileleaf_lastModified)}: $lastModified";
  }

  /// 显示打开文件的确认对话框

  void _showOpenFileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocale.getText(LocaleKey.fileleaf_openTitle)
              .tr([fileNode.mate.name, fileNode.mate.extension])),
          content: Text(appLocale.getText(LocaleKey.fileleaf_openContent)
              .tr([fileNode.mate.name, fileNode.mate.extension, fileNode.mate.version.toString()])),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(appLocale.getText(LocaleKey.fileleaf_cancel)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                FileUtils.openFile(fileNode.mate.fullPath);
              },
              child: Text(appLocale.getText(LocaleKey.fileleaf_confirm)),
            ),
          ],
        );
      },
    );
  }

  void _showContextMenu(Offset globalPosition) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          globalPosition.dx, globalPosition.dy, globalPosition.dx, globalPosition.dy),
      items: [
        PopupMenuItem(
          value: 'backup',
          child: Text(appLocale.getText(LocaleKey.fileleaf_menuBackup)),
        ),
        PopupMenuItem(
          value: 'monit',
          child: Text(appLocale.getText(LocaleKey.fileleaf_menuMonit)),
        ),
        PopupMenuItem(
          value: 'property',
          child: Text(appLocale.getText(LocaleKey.fileleaf_menuProperty)),
        ),
      ],
    );

    if (result == 'backup') {
      widget.sprout(fileNode, position, widget.canvasComponentKey);
    } else if (result == 'monit') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(appLocale.getText(LocaleKey.fileleaf_monitTitle)),
            content: Text(appLocale.getText(LocaleKey.fileleaf_monitContent)
                .tr([fileNode.mate.name, fileNode.mate.extension])),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(appLocale.getText(LocaleKey.fileleaf_cancel)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  monitService.addFileMonitTask(fileNode.mate.fullPath).then((result) {
                    if (result.isErr) {
                      showWindowsNotification(
                        appLocale.getText(LocaleKey.fileleaf_notifyFailed),
                        result.msg,
                      );
                      return;
                    }
                    final task = result.unwrap();
                    if (task.backupDirPath != null) {
                      showWindowsNotificationWithFolder(
                        appLocale.getText(LocaleKey.fileleaf_notifySuccess),
                        appLocale.getText(LocaleKey.fileleaf_notifyHint),
                        task.backupDirPath!,
                      );
                    }
                  });
                },
                child: Text(appLocale.getText(LocaleKey.fileleaf_confirm)),
              ),
            ],
          );
        },
      );
    } else if (result == 'property') {
      showDialog(
        context: context,
        builder: (context) => FilePropertiesDialog(meta: fileNode.mate),
      );
    }
  }
}

/// 文件属性弹窗组件，以表格形式展示 fileNode.mate 信息，同时支持修改备注（label）
class FilePropertiesDialog extends StatefulWidget {
  final FileMeta meta;

  const FilePropertiesDialog({Key? key, required this.meta}) : super(key: key);

  @override
  _FilePropertiesDialogState createState() => _FilePropertiesDialogState();
}

class _FilePropertiesDialogState extends State<FilePropertiesDialog> {
  bool isEditingLabel = false;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.meta.label ?? "");
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(appLocale.getText(LocaleKey.fileleaf_propertyTitle)),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
            children: [
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4.0), child: Text(appLocale.getText(LocaleKey.fileleaf_propertyFullname))),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.fullName)),
              ]),
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4.0), child: Text(appLocale.getText(LocaleKey.fileleaf_propertyName))),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.name)),
              ]),
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4.0), child: Text(appLocale.getText(LocaleKey.fileleaf_propertyLabel))),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: isEditingLabel
                      ? Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _labelController,
                        decoration: InputDecoration(
                          hintText: appLocale.getText(LocaleKey.fileleaf_propertyInputLabel),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_rounded, size: 18),
                      onPressed: () async {
                        await widget.meta.renameFile(_labelController.text);
                        setState(() => isEditingLabel = false);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      onPressed: () {
                        setState(() {
                          isEditingLabel = false;
                          _labelController.text = widget.meta.label ?? "";
                        });
                      },
                    ),
                  ])
                      : Row(children: [
                    Expanded(child: Text(widget.meta.label ?? "")),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      onPressed: () => setState(() => isEditingLabel = true),
                    ),
                  ]),
                ),
              ]),
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4.0), child: Text(appLocale.getText(LocaleKey.fileleaf_propertyVersion))),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.version.toString())),
              ]),
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4.0), child: Text(appLocale.getText(LocaleKey.fileleaf_propertyExt))),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.extension)),
              ]),
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4.0), child: Text(appLocale.getText(LocaleKey.fileleaf_propertyPath))),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.fullPath)),
              ]),
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4.0), child: Text(appLocale.getText(LocaleKey.fileleaf_propertySize))),
                Padding(padding: const EdgeInsets.all(4.0), child: Text("${widget.meta.fileSize} bytes")),
              ]),
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4.0), child: Text(appLocale.getText(LocaleKey.fileleaf_propertyCreated))),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.creationTime.toString())),
              ]),
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4.0), child: Text(appLocale.getText(LocaleKey.fileleaf_propertyModified))),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.lastModifiedTime.toString())),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocale.getText(LocaleKey.fileleaf_propertyClose)),
        ),
      ],
    );
  }

}
