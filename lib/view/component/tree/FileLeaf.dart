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
    return Tooltip(
      message: _getTooltipMessage(),
      textStyle: const TextStyle(color: Colors.white),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      waitDuration: const Duration(milliseconds: 200), // 鼠标悬停 500ms 后显示

      child: GestureDetector(
        onTap: () {
          _showOpenFileDialog();
        },
        onSecondaryTapDown: (details) {
          _showContextMenu(details.globalPosition);
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
      ),
    );
  }
  /// 生成 Tooltip 显示的信息
  String _getTooltipMessage() {
    String label = fileNode.mate.label?.isNotEmpty == true ? fileNode.mate.label! : "无备注";
    String lastModified = fileNode.mate.lastModifiedTime.toLocal().toString().split('.')[0]; // 格式化去掉毫秒部分
    return "备注: $label\n最后修改: $lastModified";
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

  /// 显示右键菜单，包含“备份”和“属性”两个选项
  void _showContextMenu(Offset globalPosition) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx,
        globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(
          value: 'backup',
          child: Text('备份'),
        ),
        PopupMenuItem(
          value: 'property',
          child: Text('属性'),
        ),
      ],
    );
    if (result == 'backup') {
      widget.sprout(fileNode, position, widget.canvasComponentKey);
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
      title: const Text("文件属性"),
      content: SizedBox(
        width: 500, // 设定对话框宽度

        child: SingleChildScrollView(
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              TableRow(children: [
                const Padding(padding: EdgeInsets.all(4.0), child: Text("全名:")),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.fullName)),
              ]),
              TableRow(children: [
                const Padding(padding: EdgeInsets.all(4.0), child: Text("名称:")),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.name)),
              ]),
              TableRow(
                children: [
                  const Padding(padding: EdgeInsets.all(4.0), child: Text("备注:")),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: isEditingLabel
                        ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _labelController,
                            decoration: const InputDecoration(hintText: "请输入备注"),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_rounded,size: 18,),
                          onPressed: () async {
                            // 保存修改后的备注，调用重命名更新文件名及元数据
                            String newLabel = _labelController.text;
                            await widget.meta.renameFile(newLabel);
                            setState(() {
                              isEditingLabel = false;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined,size: 18,),
                          onPressed: () {
                            setState(() {
                              isEditingLabel = false;
                              _labelController.text = widget.meta.label ?? "";
                            });
                          },
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(child: Text(widget.meta.label ?? "")),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded,size: 18,),
                          onPressed: () {
                            setState(() {
                              isEditingLabel = true;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TableRow(children: [
                const Padding(padding: EdgeInsets.all(4.0), child: Text("版本:")),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.version.toString())),
              ]),
              TableRow(children: [
                const Padding(padding: EdgeInsets.all(4.0), child: Text("扩展名:")),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.extension)),
              ]),
              TableRow(children: [
                const Padding(padding: EdgeInsets.all(4.0), child: Text("路径:")),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.fullPath)),
              ]),
              TableRow(children: [
                const Padding(padding: EdgeInsets.all(4.0), child: Text("文件大小:")),
                Padding(padding: const EdgeInsets.all(4.0), child: Text("${widget.meta.fileSize} bytes")),
              ]),
              TableRow(children: [
                const Padding(padding: EdgeInsets.all(4.0), child: Text("创建时间:")),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.creationTime.toString())),
              ]),
              TableRow(children: [
                const Padding(padding: EdgeInsets.all(4.0), child: Text("修改时间:")),
                Padding(padding: const EdgeInsets.all(4.0), child: Text(widget.meta.lastModifiedTime.toString())),
              ]),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("关闭"),
        ),
      ],
    );
  }
}
