import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:vertree/I18nLang.dart';
import 'package:vertree/MonitService.dart';
import 'package:vertree/component/FileUtils.dart'; // Assuming this exists and is needed
import 'package:vertree/component/Notifier.dart'; // Assuming showToast is here
import 'package:vertree/main.dart'; // Assuming monitService and appLocale are here
import 'package:vertree/view/component/AppBar.dart';
import 'package:vertree/view/module/MonitTaskCard.dart';
import 'package:window_manager/window_manager.dart';

class MonitPage extends StatefulWidget {
  const MonitPage({super.key});

  @override
  State<MonitPage> createState() => _MonitPageState();
}

class _MonitPageState extends State<MonitPage> {
  // Original list of all tasks
  List<FileMonitTask> _allMonitTasks = [];

  // List of tasks currently displayed (filtered)
  List<FileMonitTask> _filteredMonitTasks = [];

  // Controller for the search text field
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    // Load initial tasks
    _allMonitTasks = List.from(monitService.monitFileTasks); // Make a copy
    _filteredMonitTasks = List.from(_allMonitTasks); // Initially show all
    sortTasks();

    super.initState();
    windowManager.restore();

    // Listen to search input changes
    _searchController.addListener(_onSearchChanged);
  }

  void sortTasks() {
    _filteredMonitTasks.sort((a, b) {
      if (a.isRunning && !b.isRunning) {
        return -1; // a is running, b is not, so a comes first
      } else if (!a.isRunning && b.isRunning) {
        return 1; // b is running, a is not, so b comes first
      } else {
        return 0; // Both have the same running status, maintain original order (or sort by another criteria if needed)
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Called when search text changes
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterTasks();
    });
  }

  // Filters the tasks based on the search query
  void _filterTasks() {
    if (_searchQuery.isEmpty) {
      // If search is empty, show all tasks
      _filteredMonitTasks = List.from(_allMonitTasks);
    } else {
      // Otherwise, filter by filePath containing the query (case-insensitive)
      _filteredMonitTasks =
          _allMonitTasks.where((task) => task.filePath.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    // No need to call setState here as it's called within _onSearchChanged
    // or after add/remove operations that also call setState.
  }

  Future<void> _addNewTask() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null && result.files.single.path != null) {
      String selectedFilePath = result.files.single.path!;

      final taskResult = await monitService.addFileMonitTask(selectedFilePath);
      taskResult.when(
        ok: (task) {
          setState(() {
            // Add to the original list
            _allMonitTasks.add(task);
            // Re-apply the filter to update the displayed list
            _filterTasks();
            sortTasks();
          });
          if (mounted) {
            showToast(appLocale.getText(LocaleKey.monit_addSuccess).tr([task.filePath]));
          }
        },
        err: (error, msg) {
          if (mounted) {
            showToast(appLocale.getText(LocaleKey.monit_addFail).tr([msg]));
          }
        },
      );
    } else {
      if (mounted) {
        showToast(appLocale.getText(LocaleKey.monit_fileNotSelected));
      }
    }
  }

  Future<void> _removeTask(FileMonitTask task) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocale.getText(LocaleKey.monit_deleteDialogTitle)),
          content: Text(appLocale.getText(LocaleKey.monit_deleteDialogContent).tr([task.filePath])),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(appLocale.getText(LocaleKey.monit_cancel)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(appLocale.getText(LocaleKey.monit_delete)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await monitService.removeFileMonitTask(task.filePath);
      setState(() {
        // Remove from the original list
        _allMonitTasks.removeWhere((t) => t.filePath == task.filePath);
        // Re-apply the filter to update the displayed list
        _filterTasks();
      });
      showToast(appLocale.getText(LocaleKey.monit_deleteSuccess).tr([task.filePath]));
      // Safely delete directory if it exists
      try {
        final backupDir = Directory(task.backupDirPath!);
        if (await backupDir.exists()) {
          await backupDir.delete(recursive: true);
        }
      } catch (e) {
        // Handle potential errors during deletion (e.g., permissions)
        print("Error deleting backup directory ${task.backupDirPath}: $e");
        // Optionally show a message to the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting backup: ${e.toString()}")));
        }
      }
    }
  }

  Future<void> _cleanInvalidTask() async {
    List<FileMonitTask> invalidTasks = [];
    for (var task in _allMonitTasks) {
      if (!File(task.filePath).existsSync() ||
          (task.backupDirPath != null && !Directory(task.backupDirPath!).existsSync())) {
        invalidTasks.add(task);
      }
    }

    if (invalidTasks.isEmpty) {
      if (mounted) {
        showToast(appLocale.getText(LocaleKey.monit_cleanInvalidTaskDialogNoInvalidTasks));
      }
      return;
    }

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(appLocale.getText(LocaleKey.monit_cleanInvalidTasksDialogTitle)),
          content: SingleChildScrollView(
            child: ListBody(
              children:
                  invalidTasks.map((task) {
                    return Text(
                      appLocale.getText(LocaleKey.monit_invalidTaskDialogItem).tr([
                        task.filePath,
                        task.backupDirPath ?? appLocale.getText(LocaleKey.monit_cleanInvalidTaskDialogBackupDirNotSet),
                      ]),
                    );
                  }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(appLocale.getText(LocaleKey.monit_cancel)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(appLocale.getText(LocaleKey.monit_delete)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      for (var task in invalidTasks) {
        await monitService.removeFileMonitTask(task.filePath);
        // Safely delete directory if it exists
        try {
          final backupDir = Directory(task.backupDirPath!);
          if (await backupDir.exists()) {
            await backupDir.delete(recursive: true);
          }
        } catch (e) {
          // Handle potential errors during deletion (e.g., permissions)
          print("Error deleting backup directory ${task.backupDirPath}: $e");
          // Optionally show a message to the user
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error deleting backup: ${e.toString()}")));
          }
        }
      }

      setState(() {
        _allMonitTasks.removeWhere((task) => invalidTasks.contains(task));
        _filterTasks();
      });

      if (mounted) {
        showToast(appLocale.getText(LocaleKey.monit_cleanInvalidTaskDialogCleaned));
      }
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
            Text(appLocale.getText(LocaleKey.monit_title)),
          ],
        ),
        showMaximize: false,
      ),
      body: Column(
        // Use Column to stack Search Bar and List
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 8, bottom: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: appLocale.getText(LocaleKey.monit_searchHint),
                // Add a locale string for hint
                hintText: appLocale.getText(LocaleKey.monit_searchHint),
                prefixIcon: Padding(padding: const EdgeInsets.only(left: 12.0), child: const Icon(Icons.search)),
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25.0))),
                // Add a clear button
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              // _onSearchChanged will be triggered by the controller listener
                            },
                          ),
                        )
                        : null,
              ),
            ),
          ),
          // --- Task List ---
          Expanded(
            // Make the ListView take remaining space
            child:
                _filteredMonitTasks.isEmpty
                    ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? appLocale.getText(LocaleKey.monit_empty) // No tasks at all
                            : appLocale.getText(
                              LocaleKey.monit_noResults,
                            ), // No tasks match search - Add this locale string
                      ),
                    )
                    : ListView.builder(
                  key: UniqueKey(),
                      itemCount: _filteredMonitTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredMonitTasks[index];

                        if (index == _filteredMonitTasks.length - 1) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 68.0),
                            child: MonitTaskCard(task: task, removeTask: _removeTask),
                          );
                        }
                        // Build the list using the filtered tasks
                        return MonitTaskCard(task: task, removeTask: _removeTask);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _cleanInvalidTask,
            child: const Icon(Icons.cleaning_services_rounded, size: 18),
          ),
          SizedBox(width: 10),
          FloatingActionButton(onPressed: _addNewTask, child: const Icon(Icons.add)),
        ],
      ),
    );
  }
}
