
// 封装的卡片组件
import 'package:flutter/material.dart';
import 'package:vertree/MonitService.dart';

class MonitTaskCard extends StatelessWidget {
  final FileMonitTask task;
  final ValueChanged<bool> onSwitchChanged; // switch状态变更
  final VoidCallback onOpenFolder;         // 打开文件夹动作

  const MonitTaskCard({
    Key? key,
    required this.task,
    required this.onSwitchChanged,
    required this.onOpenFolder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 左侧内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.filePath,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "备份文件夹："+task.backupDirPath,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            // 右侧Action
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.6, // 调整大小
                  child: Switch(
                    value: task.isRunning,
                    onChanged: onSwitchChanged,
                  ),
                ),

                IconButton(
                  onPressed: onOpenFolder,
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}