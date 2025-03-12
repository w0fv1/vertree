import 'package:flutter/material.dart';
import 'package:vertree/MonitService.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/component/Notifier.dart';
import 'package:vertree/main.dart';

class MonitTaskCard extends StatefulWidget {
  final FileMonitTask task;
  final Function(FileMonitTask task) removeTask;
  const MonitTaskCard({Key? key, required this.task, required this.removeTask}) : super(key: key);

  @override
  State<MonitTaskCard> createState() => _MonitTaskCardState();
}

class _MonitTaskCardState extends State<MonitTaskCard> {
  late FileMonitTask task = widget.task;

  @override
  void initState() {
    super.initState();
  }
  /// 内置切换监控状态
  Future<void> _toggleTask() async {
    final result = await monitService.toggleFileMonitTaskStatus(task);
    result.when(
      ok: (updatedTask) {
        setState(() {
          task = updatedTask;
        });
        showToast("${task.file.path}的监控已经${updatedTask.isRunning?"开启":"关闭"}");
      },
      err: (_, msg) {
        showToast(msg);
        setState(() {}); // 保持原状态不变
      },
    );
  }
  /// 内置打开文件夹逻辑
  void _openBackupFolder() {
    if (task.backupDirPath != null) {
      FileUtils.openFolder(task.backupDirPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.filePath,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 4),
                  if (task.backupDirPath != null)
                    Text("备份文件夹：${task.backupDirPath!}",
                        style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.6,
                  child: Switch(value: task.isRunning, onChanged: (_) => _toggleTask()),
                ),
                IconButton(
                    onPressed: (){
                      widget.removeTask(task);
                    },
                    icon: const Icon(Icons.delete_outline_rounded)),
                IconButton(
                    onPressed: _openBackupFolder,
                    icon: const Icon(Icons.open_in_new_rounded,size: 22,)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
