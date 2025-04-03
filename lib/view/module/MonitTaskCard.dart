import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vertree/I18nLang.dart';
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

  Future<void> _toggleTask() async {
    final result = await monitService.toggleFileMonitTaskStatus(task);
    result.when(
      ok: (updatedTask) {
        setState(() {
          task = updatedTask;
        });
        final status = updatedTask.isRunning ? "开启" : "关闭"; // 这里只是标记文字，建议也可做成i18n key
        showToast(appLocale.getText(LocaleKey.monitcard_monitorStatus).tr([task.file.path, status]));
      },
      err: (_, msg) {
        showToast(msg); // 错误消息保留原样
        setState(() {});
      },
    );
  }

  void _openBackupFolder() {
    if (task.backupDirPath != null) {
      FileUtils.openFolder(task.backupDirPath!);
    }
  }

  void _cleanBackupFolder() {
    if (task.backupDirPath != null) {
      showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(appLocale.getText(LocaleKey.monitcard_cleanDialogTitle)),
            content: Text(appLocale.getText(LocaleKey.monitcard_cleanDialogContent).tr([task.backupDirPath!])),
            actions: <Widget>[
              TextButton(
                child: Text(appLocale.getText(LocaleKey.monitcard_cleanDialogCancel)),
                onPressed: () {
                  Navigator.of(context).pop(false); // 返回 false，表示取消
                },
              ),
              TextButton(
                child: Text(appLocale.getText(LocaleKey.monitcard_cleanDialogConfirm)),
                onPressed: () {
                  Navigator.of(context).pop(true); // 返回 true，表示确认
                },
              ),
            ],
          );
        },
      ).then((confirmed) {
        if (confirmed != null && confirmed) {
          try {
            final directory = Directory(task.backupDirPath!);
            final files = directory.listSync();

            for (final file in files) {
              if (file is File) {
                file.deleteSync();
              }
            }
            showToast(appLocale.getText(LocaleKey.monitcard_cleanSuccess).tr([task.backupDirPath!]));
          } catch (e) {
            showToast(appLocale.getText(LocaleKey.monitcard_cleanFail).tr([task.backupDirPath!, e.toString()]));
            logger.error('删除备份文件夹中的文件时发生错误: $e');
          }
        }
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(task.filePath, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            if (task.backupDirPath != null)
              Text(
                appLocale.getText(LocaleKey.monitcard_backupFolder).tr([task.backupDirPath!]),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Spacer(),
                Tooltip(
                  message: appLocale.getText(LocaleKey.monitcard_pause),
                  child: Transform.scale(
                    scale: 0.7,
                    child: Switch(value: task.isRunning, onChanged: (_) => _toggleTask()),
                  ),
                ),
                Tooltip(
                  message: appLocale.getText(LocaleKey.monitcard_delete),
                  child: IconButton(
                    onPressed: () {
                      widget.removeTask(task);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
                Tooltip(
                  message: appLocale.getText(LocaleKey.monitcard_clean),
                  child: IconButton(
                    onPressed: _cleanBackupFolder,
                    icon: const Icon(Icons.cleaning_services_rounded, size: 22),
                  ),
                ),
                Tooltip(
                  message: appLocale.getText(LocaleKey.monitcard_openBackupFolder),
                  child: IconButton(
                    onPressed: _openBackupFolder,
                    icon: const Icon(Icons.open_in_new_rounded, size: 22),
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
