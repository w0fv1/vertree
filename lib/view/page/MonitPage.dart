import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:vertree/I18nLang.dart';
import 'package:vertree/MonitService.dart';
import 'package:vertree/component/FileUtils.dart';
import 'package:vertree/main.dart';
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/module/MonitTaskCard.dart';
import 'package:window_manager/window_manager.dart';

class MonitPage extends StatefulWidget {
  const MonitPage({super.key});

  @override
  State<MonitPage> createState() => _MonitPageState();
}

class _MonitPageState extends State<MonitPage> {
  List<FileMonitTask> monitTasks = [];

  @override
  void initState() {
    windowManager.restore();
    monitTasks.addAll(monitService.monitFileTasks);
    super.initState();
  }

  Future<void> _addNewTask() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      String selectedFilePath = result.files.single.path!;

      final taskResult = await monitService.addFileMonitTask(selectedFilePath);
      taskResult.when(
        ok: (task) {
          setState(() {
            monitTasks.add(task);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appLocale.getText(AppLocale.monit_addSuccess).tr([task.filePath]))),
          );
        },
        err: (error, msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appLocale.getText(AppLocale.monit_addFail).tr([msg]))),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocale.getText(AppLocale.monit_fileNotSelected))),
      );
    }
  }

  Future<void> _removeTask(FileMonitTask task) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocale.getText(AppLocale.monit_confirmDeleteTitle)),
          content: Text(appLocale.getText(AppLocale.monit_confirmDeleteContent).tr([task.filePath])),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(appLocale.getText(AppLocale.monit_cancel)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(appLocale.getText(AppLocale.monit_delete)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await monitService.removeFileMonitTask(task.filePath);
      setState(() {
        monitTasks.remove(task);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocale.getText(AppLocale.monit_deleteSuccess).tr([task.filePath]))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: VAppBar(
        title: Row(
          children: [
            const Icon(Icons.monitor_heart_rounded, size: 20),
            const SizedBox(width: 8),
            Text(appLocale.getText(AppLocale.monit_title)),
          ],
        ),
        showMaximize: false,
      ),
      body: monitTasks.isEmpty
          ? Center(child: Text(appLocale.getText(AppLocale.monit_empty)))
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
              removeTask: _removeTask,
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}
