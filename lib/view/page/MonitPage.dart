import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vertree/MonitService.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/component/MonitTaskCard.dart';
import 'package:window_manager/window_manager.dart';

class MonitPage extends StatefulWidget {
  const MonitPage({super.key});

  @override
  State<MonitPage> createState() => _MonitPageState();
}

class _MonitPageState extends State<MonitPage> {
  /// 从 MonitService 中拿到监控任务列表
  List<FileMonitTask> monitTasks = [];

  @override
  void initState() {
    windowManager.restore();

    monitTasks.addAll(monitService.monitFileTasks);
    super.initState();
    // 初始化时，先确保 monitService 初始化完成（如果在 main.dart 里已确保，则无需 await）
  }


  /// 选择文件并添加监控任务
  Future<void> _addNewTask() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // 允许选择任何文件
    );

    if (result != null && result.files.single.path != null) {
      String selectedFilePath = result.files.single.path!;

      final taskResult = await monitService.addFileMonitTask(selectedFilePath);
      taskResult.when(
        ok: (task) {
          setState(() {
            monitTasks.add(task);
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("成功添加监控任务: ${task.filePath}")));
        },
        err: (error, msg) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("添加失败: $msg")));
        },
      );
    } else {
      // 用户取消了选择
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("未选择文件")));
    }
  }

  /// 演示移除某个任务
  Future<void> _removeTask(FileMonitTask task) async {
    await monitService.removeFileMonitTask(task.filePath);
    setState(() {
      monitTasks.remove(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VAppBar(
        title: Row(
          children: const [Icon(Icons.monitor_heart_rounded, size: 20), SizedBox(width: 8), Text("Vertree 监控")],
        ),
        showMaximize: false,
      ),
      body:
          monitTasks.isEmpty
              ? const Center(child: Text("暂无监控任务"))
              : ListView.builder(
                itemCount: monitTasks.length,
                itemBuilder: (context, index) {
                  final task = monitTasks[index];
                  return Dismissible(
                    key: ValueKey(task.filePath),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) => _removeTask(task),
                    child: MonitTaskCard(
                      task: task,

                    ),
                  );
                },
              ),
      // 右下角添加任务示例按钮
      floatingActionButton: FloatingActionButton(onPressed: _addNewTask, child: const Icon(Icons.add)),
    );
  }
}
